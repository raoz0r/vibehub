import 'package:flutter/material.dart';
import 'package:vibehub/ui/shell/vibehub_section.dart';
import 'package:vibehub/ui/widgets/shell_chrome.dart';

class PlaceholderSectionView extends StatelessWidget {
  const PlaceholderSectionView({super.key, required this.section});

  final VibeHubSection section;

  @override
  Widget build(BuildContext context) {
    return CrmContainer(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(icon: section.icon, size: 56),
              const SizedBox(height: 18),
              Text(
                '${section.label} workspace',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'This Milestone 1 screen is ready for the feature implementation that follows.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
