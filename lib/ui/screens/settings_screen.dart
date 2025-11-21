import 'package:flutter/material.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// Actually I didn't add package_info_plus to pubspec, so I'll just hardcode version for now or use a placeholder.

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader("About"),
          ListTile(
            title: const Text("Version"),
            subtitle: const Text("v1.0.0"),
            leading: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text("Engine"),
            subtitle: const Text("Built with Real-ESRGAN"),
            leading: const Icon(Icons.memory),
          ),
          ListTile(
            title: const Text("Privacy Policy"),
            leading: const Icon(Icons.privacy_tip_outlined),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text("Privacy Policy"),
                      content: const Text(
                        "This app runs locally. No data is collected. Your photos never leave your device.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
              );
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader("Support Us"),
          ListTile(
            title: const Text("Rate this App"),
            leading: const Icon(Icons.star_outline),
            onTap: () {
              // TODO: Open store
            },
          ),
          ListTile(
            title: const Text("Share with Friends"),
            leading: const Icon(Icons.share_outlined),
            onTap: () {
              // TODO: Share intent
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
