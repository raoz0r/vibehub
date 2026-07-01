import 'package:flutter/material.dart';
import 'package:vibehub/ui/theme/vibehub_theme.dart';

class CrmContainer extends StatelessWidget {
  const CrmContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VibeHubTheme.slate100),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(22), child: child),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.size = 44});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: VibeHubTheme.slate100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: VibeHubTheme.slate700),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: VibeHubTheme.slate100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: VibeHubTheme.slate700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
