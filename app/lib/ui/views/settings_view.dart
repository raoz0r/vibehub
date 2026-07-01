import 'package:flutter/material.dart';
import 'package:vibehub/api/paths.dart';
import 'package:vibehub/ui/theme/vibehub_theme.dart';
import 'package:vibehub/ui/widgets/shell_chrome.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return CrmContainer(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings_outlined,
                size: 28,
                color: VibeHubTheme.slate850,
              ),
              const SizedBox(width: 10),
              Text(
                'Application Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: VibeHubTheme.slate850,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Active Paths Configuration',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: VibeHubTheme.slate850,
            ),
          ),
          const SizedBox(height: 12),
          _PathRow(label: 'Data Directory', path: VibeHubPaths.dataDir),
          _PathRow(label: 'Config Directory', path: VibeHubPaths.configDir),
          _PathRow(label: 'Cache Directory', path: VibeHubPaths.cacheDir),
          _PathRow(label: 'Log Directory', path: VibeHubPaths.logDir),
          _PathRow(label: 'Temp Directory', path: VibeHubPaths.tempDir),
        ],
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: VibeHubTheme.slate400,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: VibeHubTheme.slate50,
              border: Border.all(color: VibeHubTheme.slate100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              path,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: VibeHubTheme.slate850,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
