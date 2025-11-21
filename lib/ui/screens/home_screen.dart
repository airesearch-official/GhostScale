import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:ghost_scale/ui/widgets/comparison_slider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ghost_scale/services/upscale_service.dart';
import 'package:ghost_scale/providers/app_state.dart';
import 'package:ghost_scale/ui/screens/settings_screen.dart';

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Request permission first
    if (Platform.isAndroid) {
      // Android 13+
      if (await Permission.mediaLibrary.request().isGranted ||
          await Permission.photos.request().isGranted) {
        // Granted
      } else if (await Permission.storage.request().isGranted) {
        // Android < 13
      } else {
        // Handle denied
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

    setState(() {
      _isProcessing = true;
    });

    try {
      // Check resolution warning
      final decoded = await decodeImageFromList(
        _selectedImage!.readAsBytesSync(),
      );
      if (decoded.width > 2000 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image is large. Processing may be slow.'),
          ),
        );
      }

      final result = await _upscaleService.upscaleImage(_selectedImage!);

      if (mounted) {
        setState(() {
          _upscaledImage = result;
          _isProcessing = false;
        });
        ref.read(appStateProvider.notifier).incrementUpscaleCount();
        _checkRateUs();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _checkRateUs() {
    final count = ref.read(successfulUpscalesProvider);
    if (count == 3) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Loving the privacy?"),
              content: const Text(
                "Rate us 5 stars to keep this app free forever.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("No thanks"),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Open store
                    Navigator.pop(context);
                  },
                  child: const Text("Rate Now"),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _saveImage() async {
    if (_upscaledImage == null) return;

    try {
      // Gal handles permissions automatically for saving
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
