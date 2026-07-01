import 'package:flutter/material.dart';

enum VibeHubSection {
  overview('Overview', Icons.dashboard_outlined),
  repositories('Repositories', Icons.folder_copy_outlined),
  skills('Skills', Icons.auto_awesome_motion_outlined),
  mcp('MCP', Icons.hub_outlined),
  secretManager('Secret Manager', Icons.key_outlined),
  blueprints('Blueprints', Icons.architecture_outlined),
  settings('Settings', Icons.settings_outlined);

  const VibeHubSection(this.label, this.icon);

  final String label;
  final IconData icon;
}
