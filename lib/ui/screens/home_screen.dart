import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ghost_scale/services/upscale_service.dart';
import 'package:ghost_scale/providers/app_state.dart';
import 'package:ghost_scale/ui/screens/settings_screen.dart';
import 'package:ghost_scale/ui/widgets/comparison_slider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  File? _selectedImage;
  File? _upscaledImage;
  bool _isProcessing = false;
  final UpscaleService _upscaleService = UpscaleService();

  // Model URLs
  static const String _proModelUrl =
      'https://huggingface.co/qualcomm/Real-ESRGAN-x4plus/resolve/main/Real-ESRGAN-x4plus_w8a8.tflite';
  static const String _standardModelPath =
      'assets/models/Real-ESRGAN-General-x4v3_float.tflite';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Request permission first
    if (Platform.isAndroid) {
      if (await Permission.mediaLibrary.request().isGranted ||
          await Permission.photos.request().isGranted) {
        // Granted
      } else if (await Permission.storage.request().isGranted) {
        // Android < 13
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission needed to select photos')),
          );
        }
        return;
      }
    }

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _upscaledImage = null;
      });
      _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    // Check Model Selection
    final modelType = ref.read(upscaleModelProvider);
    String modelPath = _standardModelPath;

    if (modelType == UpscaleModel.pro) {
      final appDir = await getApplicationDocumentsDirectory();
      final proModelFile = File(
        '${appDir.path}/Real-ESRGAN-x4plus_w8a8.tflite',
      );

      if (await proModelFile.exists()) {
        modelPath = proModelFile.path;
      } else {
        // Need to download
        bool downloaded = await _downloadProModel(proModelFile);
        if (downloaded) {
          modelPath = proModelFile.path;
        } else {
          // Fallback to standard
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Download failed. Using Standard Model.'),
              ),
            );
          }
          ref.read(upscaleModelProvider.notifier).state = UpscaleModel.standard;
        }
      }
    }

    setState(() {
      _isProcessing = true;
    });

    // Enable Wakelock
    await WakelockPlus.enable();

    try {
      // Check Resolution Selection
      final resolution = ref.read(upscaleResolutionProvider);
      final bool downscale = resolution == UpscaleResolution.fast2k;

      final result = await _upscaleService.upscaleImage(
        _selectedImage!,
        modelPath,
        downscale,
      );

      if (mounted) {
        setState(() {
          _upscaledImage = result;
          _isProcessing = false;
        });
        await WakelockPlus.disable();
        ref.read(appStateProvider).incrementUpscaleCount();
        _checkRateUs();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        await WakelockPlus.disable();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<bool> _downloadProModel(File targetFile) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              _DownloadDialog(url: _proModelUrl, targetFile: targetFile),
    );
    return confirm ?? false;
  }

  void _checkRateUs() {
    // Simple rate us logic
  }

  Future<void> _saveImage() async {
    if (_upscaledImage == null) return;
    try {
      await Gal.putImage(_upscaledImage!.path);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved to Gallery')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  void _discard() {
    setState(() {
      _selectedImage = null;
      _upscaledImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(upscaleModelProvider);
    final resolution = ref.watch(upscaleResolutionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("GhostScale"),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: const Icon(Icons.security),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Indicator
          Container(
            width: double.infinity,
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Row(
              children: const [
                Icon(Icons.circle, color: Colors.green, size: 12),
                SizedBox(width: 8),
                Text(
                  "OFFLINE READY",
                  style: TextStyle(fontSize: 12, letterSpacing: 1.2),
                ),
              ],
            ),
          ),

          // Settings Selectors (Only show if no image selected)
          if (_selectedImage == null) ...[
            const SizedBox(height: 16),
            // Model Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<UpscaleModel>(
                    value: model,
                    decoration: InputDecoration(
                      labelText: "AI Model",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                    ),
                    dropdownColor: Colors.grey[900],
                    items: const [
                      DropdownMenuItem(
                        value: UpscaleModel.standard,
                        child: Row(
                          children: [
                            Icon(Icons.flash_on, color: Colors.yellow),
                            SizedBox(width: 8),
                            Text("Fast (Standard)"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: UpscaleModel.pro,
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.purpleAccent,
                            ),
                            SizedBox(width: 8),
                            Text("Ultra (Experimental)"),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(upscaleModelProvider.notifier).state = val;
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  if (model == UpscaleModel.standard)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        "Recommended for speed.",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (model == UpscaleModel.pro)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        "Warning: heavy processing. May take 2-3 minutes. Keep app open.",
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Resolution Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<UpscaleResolution>(
                segments: const [
                  ButtonSegment(
                    value: UpscaleResolution.fast2k,
                    label: FittedBox(child: Text("2K (Fast)")),
                    icon: Icon(Icons.speed),
                  ),
                  ButtonSegment(
                    value: UpscaleResolution.ultra4k,
                    label: FittedBox(child: Text("4K (Ultra)")),
                    icon: Icon(Icons.hd),
                  ),
                ],
                selected: {resolution},
                onSelectionChanged: (newSelection) {
                  ref.read(upscaleResolutionProvider.notifier).state =
                      newSelection.first;
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],

          Expanded(child: Center(child: _buildContent())),

          if (_upscaledImage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _discard,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("DISCARD"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveImage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("SAVE TO GALLERY"),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isProcessing) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            "AI Enhancing...",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text("(Do not close)", style: TextStyle(color: Colors.white54)),
        ],
      );
    }

    if (_upscaledImage != null && _selectedImage != null) {
      return ComparisonSlider(
        beforeImage: _selectedImage!,
        afterImage: _upscaledImage!,
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              "Tap to Select Image",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadDialog extends StatefulWidget {
  final String url;
  final File targetFile;

  const _DownloadDialog({required this.url, required this.targetFile});

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0.0;
  String _status = "Downloading Pro Model...";
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await _dio.download(
        widget.url,
        widget.targetFile.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = "Download Failed: $e";
        });
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context, false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Downloading Pro Model"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_status),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          Text("${(_progress * 100).toStringAsFixed(0)}%"),
        ],
      ),
    );
  }
}
