import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibehub/api/skills_api.dart';
import 'package:vibehub/ui/bloc/repositories/repositories_bloc.dart';
import 'package:vibehub/ui/bloc/repositories/repositories_event.dart';
import 'package:vibehub/ui/bloc/repositories/repositories_state.dart';
import 'package:vibehub/ui/theme/vibehub_theme.dart';

class SkillDisplayInfo {
  final String name;
  final String category;
  final String description;

  const SkillDisplayInfo({
    required this.name,
    required this.category,
    required this.description,
  });
}

SkillDisplayInfo getSkillDisplayInfo(Skill skill) {
  final id = skill.id.split('@').first;
  final metadataDescription = _skillDescriptionFromMetadata(skill);
  if (id.endsWith('accessibility-review')) {
    return SkillDisplayInfo(
      name: 'Accessibility Auditor',
      category: 'A11y',
      description:
          metadataDescription ??
          _truncateSkillDescription(
            'Scans design assets and pages for WCAG 2.1 AA accessibility guidelines.',
          ),
    );
  }
  if (id.endsWith('flutter-add-widget-test')) {
    return SkillDisplayInfo(
      name: 'Flutter Widget Tester',
      category: 'Testing',
      description:
          metadataDescription ??
          _truncateSkillDescription(
            'Generates robust widget test scripts for tapping, entry, and verification.',
          ),
    );
  }
  if (id.endsWith('flutter-build-responsive-layout')) {
    return SkillDisplayInfo(
      name: 'Layout Builder',
      category: 'Responsive',
      description:
          metadataDescription ??
          _truncateSkillDescription(
            'Analyzes screen scaling needs and provides responsive layout widgets.',
          ),
    );
  }
  // Fallback friendly name
  final lastSlash = id.lastIndexOf('/');
  final shortName = lastSlash >= 0 ? id.substring(lastSlash + 1) : id;
  final friendlyName = shortName
      .split('-')
      .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
      .join(' ');
  return SkillDisplayInfo(
    name: friendlyName,
    category: 'General',
    description:
        metadataDescription ??
        _truncateSkillDescription(
          'Programmatic helper skill for managing MCP context and workflow features.',
        ),
  );
}

String? _skillDescriptionFromMetadata(Skill skill) {
  if (skill.description.trim().isNotEmpty) {
    return _truncateSkillDescription(skill.description.trim());
  }

  final description = skill.metadata['description'];
  if (description is! String || description.trim().isEmpty) {
    return null;
  }
  return _truncateSkillDescription(description.trim());
}

String _truncateSkillDescription(String description) {
  const maxLength = 140;
  if (description.length <= maxLength) {
    return description;
  }
  return '${description.substring(0, maxLength - 3).trimRight()}...';
}

class RegisteredDirectoryCard extends StatelessWidget {
  const RegisteredDirectoryCard({
    super.key,
    required this.repo,
    required this.isExpanded,
    required this.isCompact,
    required this.lockedSkillIds,
    required this.onToggleExpand,
  });

  final RepositoryEntry repo;
  final bool isExpanded;
  final bool isCompact;
  final Set<String> lockedSkillIds;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: isExpanded
              ? const BorderSide(color: VibeHubTheme.slate700, width: 3)
              : BorderSide.none,
          bottom: const BorderSide(color: VibeHubTheme.slate100),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isExpanded ? 20 : 22,
          20,
          20,
          isExpanded ? 20 : 18,
        ),
        child: Column(
          children: [
            _DirectorySummary(
              repo: repo,
              isExpanded: isExpanded,
              isCompact: isCompact,
              onToggleExpand: onToggleExpand,
            ),
            if (isExpanded) ...[
              const SizedBox(height: 20),
              _SkillsPanel(
                repo: repo,
                isCompact: isCompact,
                lockedSkillIds: lockedSkillIds,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DirectorySummary extends StatelessWidget {
  const _DirectorySummary({
    required this.repo,
    required this.isExpanded,
    required this.isCompact,
    required this.onToggleExpand,
  });

  final RepositoryEntry repo;
  final bool isExpanded;
  final bool isCompact;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          repo.name,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            color: VibeHubTheme.slate850,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          repo.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: VibeHubTheme.slate500,
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _MetaItem(
              icon: Icons.settings_suggest_outlined,
              text: 'Skills inside: ${repo.skills.length}',
            ),
            const _MetaItem(
              icon: Icons.schedule_outlined,
              text: 'Scanning active',
            ),
          ],
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FolderTile(),
        const SizedBox(width: 16),
        Expanded(child: title),
        if (!isCompact) ...[
          const SizedBox(width: 14),
          _DirectoryActions(
            repo: repo,
            isExpanded: isExpanded,
            onToggleExpand: onToggleExpand,
          ),
        ],
      ],
    );
  }
}

class _DirectoryActions extends StatelessWidget {
  const _DirectoryActions({
    required this.repo,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  final RepositoryEntry repo;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconActionButton(
          icon: Icons.sync_outlined,
          tooltip: 'Sync',
          onPressed: () {
            context.read<RepositoriesBloc>().add(const RepositoriesStarted());
          },
        ),
        const SizedBox(width: 8),
        _IconActionButton(
          icon: Icons.delete_outline,
          tooltip: 'Remove',
          onPressed: () {
            context.read<RepositoriesBloc>().add(
              RepositoryDeleteRequested(
                repositoryId: repo.id,
                repositoryPath: repo.path,
              ),
            );
          },
        ),
        const SizedBox(width: 14),
        _IconActionButton(
          icon: isExpanded ? Icons.expand_more : Icons.chevron_right,
          tooltip: isExpanded ? 'Collapse' : 'Expand',
          onPressed: onToggleExpand,
        ),
      ],
    );
  }
}

class _SkillsPanel extends StatelessWidget {
  const _SkillsPanel({
    required this.repo,
    required this.isCompact,
    required this.lockedSkillIds,
  });

  final RepositoryEntry repo;
  final bool isCompact;
  final Set<String> lockedSkillIds;

  void _showLinkSkillDialog(BuildContext context, RepositoryEntry repo) {
    final bloc = context.read<RepositoriesBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: _LinkSkillDialog(
          repo: repo,
          installedSkills: bloc.state.installedSkills,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VibeHubTheme.slate150),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: VibeHubTheme.slate500,
                ),
                const SizedBox(width: 7),
                Text(
                  'SKILLS INSIDE FOLDER (${repo.skills.length})',
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: VibeHubTheme.slate700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showLinkSkillDialog(context, repo),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text(
                    'Link Skill',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: VibeHubTheme.slate600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: VibeHubTheme.slate100),
          if (repo.skills.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No skills linked to this repository.',
                style: TextStyle(color: VibeHubTheme.slate400, fontSize: 12),
              ),
            )
          else
            for (final skill in repo.skills)
              _SkillRow(
                repo: repo,
                skill: skill,
                isCompact: isCompact,
                isLocked: lockedSkillIds.contains(skill.id),
              ),
        ],
      ),
    );
  }
}

class _LinkSkillDialog extends StatefulWidget {
  const _LinkSkillDialog({required this.repo, required this.installedSkills});

  final RepositoryEntry repo;
  final List<Skill> installedSkills;

  @override
  State<_LinkSkillDialog> createState() => _LinkSkillDialogState();
}

class _LinkSkillDialogState extends State<_LinkSkillDialog> {
  String? _selectedSkillId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final repoSkillsIds = widget.repo.skills.map((s) => s.id).toSet();
    final availableSkills = widget.installedSkills
        .where((s) => !repoSkillsIds.contains(s.id))
        .toList();
    if (availableSkills.isNotEmpty) {
      _selectedSkillId = availableSkills.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repoSkillsIds = widget.repo.skills.map((s) => s.id).toSet();
    final availableSkills = widget.installedSkills
        .where((s) => !repoSkillsIds.contains(s.id))
        .toList();
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth / 3 < 400 ? 400 : screenWidth / 3,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Link Skill to Repository',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: VibeHubTheme.slate850,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select an installed skill to link to "${widget.repo.name}" via symlink.',
                  style: const TextStyle(
                    color: VibeHubTheme.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                if (availableSkills.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No available skills to link. Please install new skills from the Skills Catalog first.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedSkillId,
                    style: const TextStyle(
                      fontSize: 13,
                      color: VibeHubTheme.slate850,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Select Skill',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: VibeHubTheme.slate150),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: VibeHubTheme.slate300),
                      ),
                    ),
                    items: availableSkills.map((skill) {
                      final info = getSkillDisplayInfo(skill);
                      return DropdownMenuItem<String>(
                        value: skill.id,
                        child: Text(
                          '${skill.owner} > ${skill.repo} > ${info.name} (${skill.version})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSkillId = val;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a skill.';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: VibeHubTheme.slate400,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VibeHubTheme.slate600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: availableSkills.isEmpty
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                context.read<RepositoriesBloc>().add(
                                  RepositoryLinkSkillRequested(
                                    repositoryId: widget.repo.id,
                                    repositoryName: widget.repo.name,
                                    repositoryPath: widget.repo.path,
                                    skillId: _selectedSkillId!,
                                  ),
                                );
                                Navigator.of(context).pop();
                              }
                            },
                      child: const Text(
                        'Link Skill',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.repo,
    required this.skill,
    required this.isCompact,
    required this.isLocked,
  });

  final RepositoryEntry repo;
  final Skill skill;
  final bool isCompact;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final info = getSkillDisplayInfo(skill);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.name,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            color: VibeHubTheme.slate850,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          info.description,
          maxLines: isCompact ? 3 : 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: VibeHubTheme.slate500,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: 15,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: VibeHubTheme.slate100)),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SkillTile(),
                    const SizedBox(width: 12),
                    Expanded(child: content),
                  ],
                ),
                const SizedBox(height: 12),
                _SkillActions(
                  repo: repo,
                  skill: skill,
                  isLocked: isLocked,
                  isCompact: true,
                ),
              ],
            )
          : Row(
              children: [
                const _SkillTile(),
                const SizedBox(width: 14),
                Expanded(child: content),
                const SizedBox(width: 16),
                _SkillActions(repo: repo, skill: skill, isLocked: isLocked),
              ],
            ),
    );
  }
}

class _SkillActions extends StatelessWidget {
  const _SkillActions({
    required this.repo,
    required this.skill,
    required this.isLocked,
    this.isCompact = false,
  });

  final RepositoryEntry repo;
  final Skill skill;
  final bool isLocked;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
      children: [
        Text(
          skill.version,
          style: const TextStyle(
            color: VibeHubTheme.slate400,
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        _SkillStatusBadge(isUpdateAvailable: skill.updateAvailable),
        if (skill.updateAvailable)
          _FilledIconActionButton(
            icon: Icons.sync_outlined,
            tooltip: isLocked ? 'Skill is locked' : 'Update',
            onPressed: isLocked
                ? null
                : () {
                    context.read<RepositoriesBloc>().add(
                      RepositoryInstallSkillRequested(
                        repositoryId: repo.id,
                        repositoryName: repo.name,
                        repositoryPath: repo.path,
                        skill: skill,
                      ),
                    );
                  },
          ),
        _IconActionButton(
          icon: isLocked ? Icons.lock : Icons.lock_open_outlined,
          tooltip: isLocked ? 'Unlock Skill' : 'Lock Skill',
          color: isLocked ? Colors.red.shade600 : VibeHubTheme.slate400,
          onPressed: () {
            context.read<RepositoriesBloc>().add(
              RepositorySkillLockToggled(skillId: skill.id),
            );
          },
        ),
        _IconActionButton(
          icon: Icons.link_off_outlined,
          tooltip: 'Unlink Skill',
          onPressed: () {
            context.read<RepositoriesBloc>().add(
              RepositoryUnlinkSkillRequested(
                repositoryId: repo.id,
                repositoryPath: repo.path,
                skillId: skill.id,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SkillStatusBadge extends StatelessWidget {
  const _SkillStatusBadge({required this.isUpdateAvailable});

  final bool isUpdateAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: isUpdateAvailable ? Colors.white : const Color(0xFFE8FFF5),
        border: Border.all(
          color: isUpdateAvailable
              ? const Color(0xFFEA580C)
              : const Color(0xFF047857),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isUpdateAvailable) ...[
            const Icon(Icons.check, size: 13, color: Color(0xFF047857)),
            const SizedBox(width: 5),
          ],
          Text(
            isUpdateAvailable ? 'Update Available' : 'Current',
            style: TextStyle(
              color: isUpdateAvailable
                  ? const Color(0xFFEA580C)
                  : const Color(0xFF047857),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: VibeHubTheme.slate400),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: VibeHubTheme.slate400,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        border: Border.all(color: VibeHubTheme.slate100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.drive_folder_upload_outlined,
        color: VibeHubTheme.slate500,
        size: 22,
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: VibeHubTheme.slate50,
        border: Border.all(color: VibeHubTheme.slate100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.developer_board_outlined,
        color: VibeHubTheme.slate500,
        size: 19,
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    this.color,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color ?? VibeHubTheme.slate400,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(34),
          minimumSize: const Size.square(34),
          padding: EdgeInsets.zero,
          side: const BorderSide(color: VibeHubTheme.slate100),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _FilledIconActionButton extends StatelessWidget {
  const _FilledIconActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: VibeHubTheme.slate700,
          fixedSize: const Size.square(34),
          minimumSize: const Size.square(34),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

enum _BadgeTone { success, info }
