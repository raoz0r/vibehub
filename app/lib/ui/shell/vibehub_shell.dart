import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibehub/ui/bloc/shell/shell_bloc.dart';
import 'package:vibehub/ui/bloc/shell/shell_event.dart';
import 'package:vibehub/ui/bloc/shell/shell_state.dart';
import 'package:vibehub/ui/shell/vibehub_section.dart';
import 'package:vibehub/ui/theme/vibehub_theme.dart';
import 'package:vibehub/ui/views/blueprints_view.dart';
import 'package:vibehub/ui/views/mcp_view.dart';
import 'package:vibehub/ui/views/overview_view.dart';
import 'package:vibehub/ui/views/repositories_view.dart';
import 'package:vibehub/ui/views/secret_manager_view.dart';
import 'package:vibehub/ui/views/settings_view.dart';
import 'package:vibehub/ui/views/skills_view.dart';
import 'package:vibehub/ui/widgets/shell_chrome.dart';

class VibeHubShell extends StatelessWidget {
  const VibeHubShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShellBloc, ShellState>(
      builder: (context, state) {
        return Scaffold(
          body: Row(
            children: [
              VibeHubSidebar(state: state),
              Expanded(child: SectionContent(section: state.selectedSection)),
            ],
          ),
        );
      },
    );
  }
}

class VibeHubSidebar extends StatelessWidget {
  const VibeHubSidebar({super.key, required this.state});

  final ShellState state;

  @override
  Widget build(BuildContext context) {
    final width = state.isSidebarExpanded ? 252.0 : 82.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: width,
      color: VibeHubTheme.slate800,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SidebarHeader(isExpanded: state.isSidebarExpanded),
              const SizedBox(height: 22),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final section in VibeHubSection.values)
                      _SidebarItem(
                        section: section,
                        isExpanded: state.isSidebarExpanded,
                        isSelected: section == state.selectedSection,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SidebarToggle(isExpanded: state.isSidebarExpanded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.isExpanded});

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: VibeHubTheme.slate700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bolt, color: Colors.white),
        ),
        if (isExpanded) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VibeHub',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Workspace Manager',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: VibeHubTheme.slate300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.isExpanded,
    required this.isSelected,
  });

  final VibeHubSection section;
  final bool isExpanded;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? Colors.white : VibeHubTheme.slate300;
    final background = isSelected ? VibeHubTheme.slate700 : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tooltip(
        message: isExpanded ? '' : section.label,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            hoverColor: VibeHubTheme.slate850,
            onTap: () =>
                context.read<ShellBloc>().add(ShellSectionSelected(section)),
            child: SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isExpanded ? 48 : 54,
                    child: Icon(section.icon, color: foreground, size: 21),
                  ),
                  if (isExpanded)
                    Expanded(
                      child: Text(
                        section.label,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: foreground),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarToggle extends StatelessWidget {
  const _SidebarToggle({required this.isExpanded});

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isExpanded ? 'Hide sidebar' : 'Show sidebar',
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: VibeHubTheme.slate850),
        ),
        child: InkWell(
          key: const ValueKey('sidebar-toggle'),
          borderRadius: BorderRadius.circular(8),
          onTap: () =>
              context.read<ShellBloc>().add(const ShellSidebarToggled()),
          child: SizedBox(
            height: 44,
            child: Center(
              child: FittedBox(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isExpanded ? Icons.chevron_left : Icons.chevron_right,
                      color: Colors.white,
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 8),
                      const Text('Hide', style: TextStyle(color: Colors.white)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionContent extends StatelessWidget {
  const SectionContent({super.key, required this.section});

  final VibeHubSection section;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(section: section),
            const SizedBox(height: 24),
            Expanded(child: _viewForSection(section)),
          ],
        ),
      ),
    );
  }

  Widget _viewForSection(VibeHubSection section) {
    return switch (section) {
      VibeHubSection.overview => const OverviewView(),
      VibeHubSection.repositories => const RepositoriesView(),
      VibeHubSection.skills => const SkillsView(),
      VibeHubSection.mcp => const McpView(),
      VibeHubSection.secretManager => const SecretManagerView(),
      VibeHubSection.blueprints => const BlueprintsView(),
      VibeHubSection.settings => const SettingsView(),
    };
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.section});

  final VibeHubSection section;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.label,
                key: ValueKey('page-title-${section.name}'),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Local desktop orchestration for project context, prompts, and MCP skills.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const StatusBadge(label: 'Ready'),
      ],
    );
  }
}
