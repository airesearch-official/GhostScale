import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';

class UpscaleService {
  // --- Advanced Tiling Configuration ---
  // Input
  static const int _tileSize = 128; // Fixed Model Input
  static const int _effectiveInputSize = 100; // Trust center 100x100
  static const int _padding = (_tileSize - _effectiveInputSize) ~/ 2; // 14
  static const int _stride = _effectiveInputSize; // 100

  // Output
  static const int _scale = 4;
  static const int _outputTileSize = _tileSize * _scale; // 512
  static const int _effectiveOutputSize = _effectiveInputSize * _scale; // 400
  static const int _outputPadding = _padding * _scale; // 56

  Future<File?> upscaleImage(
    File imageFile,
    String modelPath,
    bool downscale,
  ) async {
    final tempDir = await getTemporaryDirectory();
    String finalModelPath = modelPath;

    // If it's an asset path, copy it to a temp file
    if (modelPath.startsWith('assets/')) {
      final modelFile = File('${tempDir.path}/temp_model.tflite');
      if (!await modelFile.exists() || true) {
        final byteData = await rootBundle.load(modelPath);
        await modelFile.writeAsBytes(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
        );
      }
      finalModelPath = modelFile.path;
    }

    try {
      // Use compute() to run in a background isolate
      final resultPath = await compute(
        _runInference,
        _IsolateData(
          imagePath: imageFile.path,
          modelPath: finalModelPath,
          outputPath: tempDir.path,
          downscale: downscale,
        ),
      );
      return File(resultPath);
    } catch (e) {
      print("Upscale failed: $e");
      rethrow;
    }
  }

  // Static function for compute()
  static Future<String> _runInference(_IsolateData data) async {
    Interpreter? interpreter;
    GpuDelegateV2? gpuDelegate;

    try {
      // 1. Initialize Interpreter & Delegate (Strict Lifecycle)
      try {
        gpuDelegate = GpuDelegateV2(
          options: GpuDelegateOptionsV2(
            isPrecisionLossAllowed: true, // Performance Tweak
          ),
        );
        var options = InterpreterOptions()..addDelegate(gpuDelegate);
        interpreter = Interpreter.fromFile(
          File(data.modelPath),
          options: options,
        );
        print("Initialized TFLite with GPU Delegate");
      } catch (e) {
        print("GPU Delegate failed, falling back to CPU: $e");
        gpuDelegate = null; // Ensure null if failed
        var options = InterpreterOptions()..threads = 4;
        interpreter = Interpreter.fromFile(
          File(data.modelPath),
          options: options,
        );
      }

      // 2. Load Image
      var image = img.decodeImage(File(data.imagePath).readAsBytesSync())!;

      // Handle Downscaling (Fast 2K Mode)
      if (data.downscale) {
        image = img.copyResize(
          image,
          width: image.width ~/ 2,
          height: image.height ~/ 2,
        );
      }

      final width = image.width;
      final height = image.height;

      final outputWidth = width * _scale;
      final outputHeight = height * _scale;
      final outputImage = img.Image(width: outputWidth, height: outputHeight);

      // 3. Detect Layout (NCHW vs NHWC) and Type (Float32 vs Uint8)
      var inputTensor = interpreter!.getInputTensor(0);
      var inputShape = inputTensor.shape;
      var inputType = inputTensor.type;
      bool inputNCHW = inputShape[1] == 3; // [1, 3, H, W] vs [1, H, W, 3]
      bool isQuantized = inputType == TensorType.uint8;

      // Resize Input Tensor to fixed 128x128
      if (inputNCHW) {
        interpreter.resizeInputTensor(0, [1, 3, _tileSize, _tileSize]);
      } else {
        interpreter.resizeInputTensor(0, [1, _tileSize, _tileSize, 3]);
      }
      interpreter.allocateTensors();

      var outputTensor = interpreter.getOutputTensor(0);
      var outputShape = outputTensor.shape;
      bool outputNCHW = outputShape[1] == 3;
      bool outputQuantized = outputTensor.type == TensorType.uint8;

      // Pre-allocate buffers
      // Input buffer size depends on type
      final int inputSize = 1 * _tileSize * _tileSize * 3;
      final ByteBuffer inputBuffer =
          isQuantized
              ? Uint8List(inputSize).buffer
              : Float32List(inputSize).buffer;

      // Output buffer size depends on type
      final int outputSize = 1 * _outputTileSize * _outputTileSize * 3;
      final ByteBuffer outputBuffer =
          outputQuantized
              ? Uint8List(outputSize).buffer
              : Float32List(outputSize).buffer;

      // 4. Tiling Loop
      for (var y = 0; y < height; y += _stride) {
        for (var x = 0; x < width; x += _stride) {
          // Calculate Source Tile Coordinates (128x128)
          final startX = x - _padding;
          final startY = y - _padding;

          // Fill Input Buffer
          if (isQuantized) {
            final inputBytes = inputBuffer.asUint8List();
            if (inputNCHW) {
              final planeSize = _tileSize * _tileSize;
              for (var ty = 0; ty < _tileSize; ty++) {
                for (var tx = 0; tx < _tileSize; tx++) {
                  final srcX = (startX + tx).clamp(0, width - 1);
                  final srcY = (startY + ty).clamp(0, height - 1);
                  final pixel = image.getPixel(srcX, srcY);
                  final index = ty * _tileSize + tx;
                  inputBytes[index] = pixel.r.toInt();
                  inputBytes[planeSize + index] = pixel.g.toInt();
                  inputBytes[planeSize * 2 + index] = pixel.b.toInt();
                }
              }
            } else {
              int pIndex = 0;
              for (var ty = 0; ty < _tileSize; ty++) {
                for (var tx = 0; tx < _tileSize; tx++) {
                  final srcX = (startX + tx).clamp(0, width - 1);
                  final srcY = (startY + ty).clamp(0, height - 1);
                  final pixel = image.getPixel(srcX, srcY);
                  inputBytes[pIndex++] = pixel.r.toInt();
                  inputBytes[pIndex++] = pixel.g.toInt();
                  inputBytes[pIndex++] = pixel.b.toInt();
                }
              }
            }
          } else {
            final inputFloats = inputBuffer.asFloat32List();
            if (inputNCHW) {
              final planeSize = _tileSize * _tileSize;
              for (var ty = 0; ty < _tileSize; ty++) {
                for (var tx = 0; tx < _tileSize; tx++) {
                  final srcX = (startX + tx).clamp(0, width - 1);
                  final srcY = (startY + ty).clamp(0, height - 1);
                  final pixel = image.getPixel(srcX, srcY);
                  final index = ty * _tileSize + tx;
                  inputFloats[index] = pixel.r / 255.0;
                  inputFloats[planeSize + index] = pixel.g / 255.0;
                  inputFloats[planeSize * 2 + index] = pixel.b / 255.0;
                }
              }
            } else {
              int pIndex = 0;
              for (var ty = 0; ty < _tileSize; ty++) {
                for (var tx = 0; tx < _tileSize; tx++) {
                  final srcX = (startX + tx).clamp(0, width - 1);
                  final srcY = (startY + ty).clamp(0, height - 1);
                  final pixel = image.getPixel(srcX, srcY);
                  inputFloats[pIndex++] = pixel.r / 255.0;
                  inputFloats[pIndex++] = pixel.g / 255.0;
                  inputFloats[pIndex++] = pixel.b / 255.0;
                }
              }
            }
          }

          // Run Inference
          interpreter.runForMultipleInputs([inputBuffer], {0: outputBuffer});

          // Write Output (Crop & Stitch)
          for (var oy = 0; oy < _effectiveOutputSize; oy++) {
            for (var ox = 0; ox < _effectiveOutputSize; ox++) {
              // Coordinates in the 512x512 output tile
              final tileY = oy + _outputPadding;
              final tileX = ox + _outputPadding;

              // Coordinates in the final image
              final dstX = (x * _scale) + ox;
              final dstY = (y * _scale) + oy;

              if (dstX < outputWidth && dstY < outputHeight) {
                double r, g, b;

                if (outputQuantized) {
                  final outputBytes = outputBuffer.asUint8List();
                  if (outputNCHW) {
                    final planeSize = _outputTileSize * _outputTileSize;
                    final index = tileY * _outputTileSize + tileX;
                    r = outputBytes[index].toDouble() / 255.0;
                    g = outputBytes[planeSize + index].toDouble() / 255.0;
                    b = outputBytes[planeSize * 2 + index].toDouble() / 255.0;
                  } else {
                    final index = (tileY * _outputTileSize + tileX) * 3;
                    r = outputBytes[index].toDouble() / 255.0;
                    g = outputBytes[index + 1].toDouble() / 255.0;
                    b = outputBytes[index + 2].toDouble() / 255.0;
                  }
                } else {
                  final outputFloats = outputBuffer.asFloat32List();
                  if (outputNCHW) {
                    final planeSize = _outputTileSize * _outputTileSize;
                    final index = tileY * _outputTileSize + tileX;
                    r = outputFloats[index];
                    g = outputFloats[planeSize + index];
                    b = outputFloats[planeSize * 2 + index];
                  } else {
                    final index = (tileY * _outputTileSize + tileX) * 3;
                    r = outputFloats[index];
                    g = outputFloats[index + 1];
                    b = outputFloats[index + 2];
                  }
                }

                outputImage.setPixelRgb(
                  dstX,
                  dstY,
                  (r * 255).clamp(0, 255).toInt(),
                  (g * 255).clamp(0, 255).toInt(),
                  (b * 255).clamp(0, 255).toInt(),
                );
              }
            }
          }
        }
      }

      final resultPath =
          '${data.outputPath}/upscaled_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Save as JPG with 80% quality to reduce file size
      File(
        resultPath,
      ).writeAsBytesSync(img.encodeJpg(outputImage, quality: 80));

      return resultPath;
    } catch (e, stack) {
      print("Error in isolate: $e\n$stack");
      rethrow;
    } finally {
      // STRICT CLEANUP
      interpreter?.close();
      gpuDelegate?.delete();
    }
  }
}

class _IsolateData {
  final String imagePath;
  final String modelPath;
  final String outputPath;
  final bool downscale;

  _IsolateData({
    required this.imagePath,
    required this.modelPath,
    required this.outputPath,
    required this.downscale,
  });
}
