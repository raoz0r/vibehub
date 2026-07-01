import 'package:flutter/material.dart';
import 'package:vibehub/ui/theme/vibehub_theme.dart';
import 'package:vibehub/ui/widgets/shell_chrome.dart';

class OverviewView extends StatelessWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisExtent: 270,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      children: const [
        MetricCard(
          title: 'Repositories',
          value: '0',
          detail: 'No repositories connected',
          icon: Icons.folder_copy_outlined,
        ),
        MetricCard(
          title: 'Installed Skills',
          value: '0',
          detail: 'Ready for future milestones',
          icon: Icons.auto_awesome_motion_outlined,
        ),
        MetricCard(
          title: 'MCP Servers',
          value: '0',
          detail: 'No active server sessions',
          icon: Icons.hub_outlined,
        ),
        InfoCard(
          title: 'Workspace Status',
          detail: 'Desktop shell compiled and ready for feature modules.',
          command: '~/.vibehub',
        ),
        InfoCard(
          title: 'Secret Manager',
          detail: 'Secure storage wiring is intentionally out of scope.',
          command: 'flutter_secure_storage',
        ),
        InfoCard(
          title: 'Blueprints',
          detail: 'Blueprint surfaces are placeholders for Milestone 1.',
          command: 'project_information/Milestone_1.md',
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CrmContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: icon),
              const Spacer(),
              const StatusBadge(label: 'Active'),
            ],
          ),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(detail, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.detail,
    required this.command,
  });

  final String title;
  final String detail;
  final String command;

  @override
  Widget build(BuildContext context) {
    return CrmContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(detail, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: VibeHubTheme.slate50,
              border: Border.all(color: VibeHubTheme.slate100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              command,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: VibeHubTheme.slate400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
