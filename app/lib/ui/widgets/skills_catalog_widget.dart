export 'package:vibehub/ui/bloc/skills_catalog/skills_catalog_data.dart';
export 'package:vibehub/ui/bloc/skills_catalog/skills_catalog_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibehub/api/skills_api.dart';
import 'package:vibehub/api/skills_catalog_api.dart';
import 'package:vibehub/ui/bloc/skills_catalog/skills_catalog_bloc.dart';
import 'package:vibehub/ui/bloc/skills_catalog/skills_catalog_event.dart';
import 'package:vibehub/ui/bloc/skills_catalog/skills_catalog_state.dart';
import 'package:vibehub/ui/theme/vibehub_theme.dart';

class SkillsCatalogWidget extends StatelessWidget {
  const SkillsCatalogWidget({
    super.key,
    this.skillsApi,
    this.skillsCatalogApi,
    this.installSkillFn,
    this.uninstallSkillFn,
  });

  final SkillsApi? skillsApi;
  final SkillsCatalogApi? skillsCatalogApi;
  final Future<String> Function(Skill, SkillsApi)? installSkillFn;
  final Future<String> Function(Skill, SkillsApi)? uninstallSkillFn;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SkillsCatalogBloc(
        skillsApi: skillsApi,
        skillsCatalogApi: skillsCatalogApi ?? context.read<SkillsCatalogApi>(),
        installSkillFn: installSkillFn,
        uninstallSkillFn: uninstallSkillFn,
      )..add(const SkillsCatalogStarted()),
      child: const _SkillsCatalogView(),
    );
  }
}

class _SkillsCatalogView extends StatelessWidget {
  const _SkillsCatalogView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SkillsCatalogBloc, SkillsCatalogState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null) {
          return _CatalogMessage(
            icon: Icons.error_outline,
            title: 'Skills catalog unavailable',
            message: state.errorMessage!,
          );
        }

        if (state.items.isEmpty) {
          return const _CatalogMessage(
            icon: Icons.inventory_2_outlined,
            title: 'No skills found',
            message: 'The local catalog did not contain any skills.',
          );
        }

        return _CatalogLayout(state: state);
      },
    );
  }
}

class _CatalogLayout extends StatelessWidget {
  const _CatalogLayout({required this.state});

  static const double wideLayoutWidth = 980;

  final SkillsCatalogState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ownersColumn = _OwnersColumn(state: state);
        final repositoriesColumn = _RepositoriesColumn(state: state);
        final skillsColumn = _SkillsColumn(state: state);

        if (constraints.maxWidth >= wideLayoutWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 250, child: ownersColumn),
              const SizedBox(width: 18),
              SizedBox(width: 330, child: repositoriesColumn),
              const SizedBox(width: 18),
              Expanded(child: skillsColumn),
            ],
          );
        }

        return Column(
          children: [
            SizedBox(height: 170, child: ownersColumn),
            const SizedBox(height: 12),
            SizedBox(height: 170, child: repositoriesColumn),
            const SizedBox(height: 12),
            Expanded(child: skillsColumn),
          ],
        );
      },
    );
  }
}

class _OwnersColumn extends StatelessWidget {
  const _OwnersColumn({required this.state});

  final SkillsCatalogState state;

  @override
  Widget build(BuildContext context) {
    final owners = _filterStrings(state.index.owners, state.ownerQuery);

    return _CatalogColumn(
      title: 'Owners',
      count: owners.length,
      searchHint: 'Filter owners...',
      query: state.ownerQuery,
      onQueryChanged: (query) => context.read<SkillsCatalogBloc>().add(
        SkillsCatalogOwnerQueryChanged(query),
      ),
      child: ListView.builder(
        itemCount: owners.length,
        itemBuilder: (context, index) {
          final owner = owners[index];
          return _SelectableCatalogTile(
            key: ValueKey('owner-$owner'),
            label: owner,
            trailingText: '${state.index.skillCountForOwner(owner)}',
            selected: owner == state.selectedOwner,
            onTap: () => context.read<SkillsCatalogBloc>().add(
              SkillsCatalogOwnerSelected(owner),
            ),
          );
        },
      ),
    );
  }
}

class _RepositoriesColumn extends StatelessWidget {
  const _RepositoriesColumn({required this.state});

  final SkillsCatalogState state;

  @override
  Widget build(BuildContext context) {
    final repositories = _filterStrings(
      _repositoriesForState(state),
      state.repoQuery,
    );

    return _CatalogColumn(
      title: 'Repositories',
      count: repositories.length,
      metaText: state.selectedOwner == null ? null : '@${state.selectedOwner}',
      searchHint: state.selectedOwner == null
          ? 'Search repositories...'
          : 'Search @${state.selectedOwner} repositories...',
      query: state.repoQuery,
      onQueryChanged: (query) => context.read<SkillsCatalogBloc>().add(
        SkillsCatalogRepoQueryChanged(query),
      ),
      child: ListView.builder(
        itemCount: repositories.length,
        itemBuilder: (context, index) {
          final repo = repositories[index];
          return _SelectableCatalogTile(
            key: ValueKey('repo-${state.selectedOwner ?? 'all'}-$repo'),
            label: repo,
            trailingText: '${_repoSkillCountForState(state, repo)}',
            selected: repo == state.selectedRepo,
            onTap: () => context.read<SkillsCatalogBloc>().add(
              SkillsCatalogRepoSelected(repo),
            ),
          );
        },
      ),
    );
  }
}

class _SkillsColumn extends StatelessWidget {
  const _SkillsColumn({required this.state});

  final SkillsCatalogState state;

  @override
  Widget build(BuildContext context) {
    final skills = _filterSkills(
      _skillsForState(state),
      state.skillQuery,
      state.skillFilter,
    );

    return _CatalogColumn(
      title: 'Skills',
      count: skills.length,
      metaText: state.selectedRepo == null ? null : '~${state.selectedRepo}',
      searchHint: 'Filter skills in skills...',
      query: state.skillQuery,
      onQueryChanged: (query) => context.read<SkillsCatalogBloc>().add(
        SkillsCatalogSkillQueryChanged(query),
      ),
      controls: _SkillToolbar(skills: skills, state: state),
      statusText: state.actionStatus,
      child: ListView.builder(
        itemCount: skills.length,
        itemBuilder: (context, index) {
          final item = skills[index];
          return _SkillRow(
            item: item,
            isBusy: state.busySkillIds.contains(item.id),
          );
        },
      ),
    );
  }
}

class _CatalogColumn extends StatelessWidget {
  const _CatalogColumn({
    required this.title,
    required this.count,
    required this.child,
    this.metaText,
    this.searchHint,
    this.query = '',
    this.onQueryChanged,
    this.controls,
    this.statusText,
  });

  final String title;
  final int count;
  final Widget child;
  final String? metaText;
  final String? searchHint;
  final String query;
  final ValueChanged<String>? onQueryChanged;
  final Widget? controls;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    title.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CountBadge(count: count),
                const Spacer(),
                if (metaText != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    metaText!,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.72),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            if (searchHint != null && onQueryChanged != null) ...[
              const SizedBox(height: 18),
              _CatalogSearchField(
                hint: searchHint!,
                value: query,
                onChanged: onQueryChanged!,
              ),
            ],
            if (controls != null) ...[const SizedBox(height: 12), controls!],
            if (statusText != null) ...[
              const SizedBox(height: 10),
              _ActionStatusText(statusText!),
            ],
            const SizedBox(height: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _CatalogSearchField extends StatelessWidget {
  const _CatalogSearchField({
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 34,
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodySmall,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(
            color: colors.onSurfaceVariant.withValues(alpha: 0.62),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 17,
            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 34,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          filled: true,
          fillColor: colors.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: colors.primary),
          ),
        ),
      ),
    );
  }
}

class _ActionStatusText extends StatelessWidget {
  const _ActionStatusText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SelectableCatalogTile extends StatelessWidget {
  const _SelectableCatalogTile({
    super.key,
    required this.label,
    this.trailingText,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? trailingText;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = selected ? colors.onSurface : colors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.07)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            if (selected)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: SizedBox(
                height: 42,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (trailingText != null) ...[
                          const SizedBox(width: 8),
                          _QuietCountText(label: trailingText!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillToolbar extends StatelessWidget {
  const _SkillToolbar({required this.skills, required this.state});

  final List<SkillFeedItem> skills;
  final SkillsCatalogState state;

  @override
  Widget build(BuildContext context) {
    final missingSkills = skills
        .where((item) => item.status == SkillFeedStatus.notInstalled)
        .toList();
    final isBulkBusy =
        state.isBulkInstalling ||
        missingSkills.isNotEmpty &&
            missingSkills.every((item) => state.busySkillIds.contains(item.id));

    return Row(
      children: [
        _SkillFilterControl(
          filter: state.skillFilter,
          onChanged: (filter) => context.read<SkillsCatalogBloc>().add(
            SkillsCatalogSkillFilterChanged(filter),
          ),
        ),
        const Spacer(),
        if (missingSkills.isNotEmpty)
          TextButton.icon(
            onPressed: isBulkBusy
                ? null
                : () => context.read<SkillsCatalogBloc>().add(
                    SkillsCatalogInstallAllRequested(missingSkills),
                  ),
            icon: isBulkBusy
                ? const _ButtonSpinner(size: 14)
                : const Icon(Icons.download_outlined, size: 15),
            label: Text('Install All (${missingSkills.length})'),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _SkillFilterControl extends StatelessWidget {
  const _SkillFilterControl({required this.filter, required this.onChanged});

  final SkillListFilter filter;
  final ValueChanged<SkillListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.62),
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SkillFilterSegment(
              label: 'All',
              selected: filter == SkillListFilter.all,
              onTap: () => onChanged(SkillListFilter.all),
            ),
            _SkillFilterSegment(
              label: 'Current',
              selected: filter == SkillListFilter.current,
              onTap: () => onChanged(SkillListFilter.current),
            ),
            _SkillFilterSegment(
              label: 'Missing',
              selected: filter == SkillListFilter.missing,
              onTap: () => onChanged(SkillListFilter.missing),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillFilterSegment extends StatelessWidget {
  const _SkillFilterSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? colors.onSurface : colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillRow extends StatefulWidget {
  const _SkillRow({required this.item, required this.isBusy});

  final SkillFeedItem item;
  final bool isBusy;

  @override
  State<_SkillRow> createState() => _SkillRowState();
}

class _SkillRowState extends State<_SkillRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        key: ValueKey('skill-${widget.item.comparisonKey}'),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: BlocBuilder<SkillsCatalogBloc, SkillsCatalogState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkillIdLink(
                              id: widget.item.id,
                              repoUrl: widget.item.repoUrl,
                            ),
                            const SizedBox(height: 4),
                            _SkillMetaLine(item: widget.item),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatusPill(status: widget.item.status),
                      const SizedBox(width: 8),
                      _SkillActionButton(
                        item: widget.item,
                        isBusy: widget.isBusy,
                      ),
                      if (widget.item.installedVersions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _isExpanded = !_isExpanded),
                          tooltip: _isExpanded
                              ? 'Collapse versions'
                              : 'Expand versions',
                          style: IconButton.styleFrom(
                            fixedSize: const Size.square(34),
                            minimumSize: const Size.square(34),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: BorderSide(color: colors.outlineVariant),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_isExpanded &&
                      widget.item.installedVersions.isNotEmpty) ...[
                    const Divider(height: 20),
                    Text(
                      'Installed Versions:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.item.installedVersions.map((installedSkill) {
                      final versionIsBusy =
                          widget.isBusy ||
                          state.busySkillIds.contains(installedSkill.id);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.commit_outlined,
                              size: 14,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              installedSkill.version,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'JetBrains Mono',
                                    fontWeight: FontWeight.normal,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            if (installedSkill.projects.isNotEmpty)
                              Tooltip(
                                message:
                                    'Used in ${installedSkill.projects.length} project(s)',
                                child: _CountBadge(
                                  count: installedSkill.projects.length,
                                ),
                              ),
                            const Spacer(),
                            IconButton(
                              icon: versionIsBusy
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline, size: 16),
                              onPressed: versionIsBusy
                                  ? null
                                  : () => context.read<SkillsCatalogBloc>().add(
                                      SkillsCatalogUninstallVersionRequested(
                                        installedSkill,
                                      ),
                                    ),
                              tooltip:
                                  'Uninstall version ${installedSkill.version}',
                              color: colors.error,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SkillIdLink extends StatelessWidget {
  const _SkillIdLink({required this.id, required this.repoUrl});

  final String id;
  final String repoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final parts = _splitVersionedSkillId(id);
    final nameStyle = TextStyle(
      fontFamily: 'Space Grotesk',
      color: colors.onSurface,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none,
    );
    final versionStyle = nameStyle.copyWith(
      color: colors.onSurfaceVariant.withValues(alpha: 0.74),
      fontFamily: 'JetBrains Mono',
      fontWeight: FontWeight.normal,
    );

    final fullName = parts.$1;
    final lastSlash = fullName.lastIndexOf('/');
    final shortName = lastSlash > 0
        ? fullName.substring(lastSlash + 1)
        : fullName;

    return Tooltip(
      message: repoUrl.isEmpty ? id : repoUrl,
      child: InkWell(
        onTap: repoUrl.isEmpty ? null : () => launchUrl(Uri.parse(repoUrl)),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: shortName, style: nameStyle),
              if (parts.$2 != null)
                TextSpan(text: '@${parts.$2}', style: versionStyle),
            ],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SkillMetaLine extends StatelessWidget {
  const _SkillMetaLine({required this.item});

  final SkillFeedItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant.withValues(alpha: 0.78),
      fontSize: 11,
    );

    return Wrap(
      spacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (item.isOutdated && item.localVersion != null) ...[
          Text('Local', style: labelStyle),
          _CodeToken(label: item.localVersion!),
          Text('->', style: labelStyle),
        ],
        Text('SHA', style: labelStyle),
        _CodeToken(
          label: item.sha.isEmpty ? 'unavailable' : _shortSha(item.sha),
        ),
      ],
    );
  }
}

class _CodeToken extends StatelessWidget {
  const _CodeToken({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.primary.withValues(alpha: 0.86),
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}

class _SkillActionButton extends StatelessWidget {
  const _SkillActionButton({required this.item, required this.isBusy});

  final SkillFeedItem item;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    switch (item.status) {
      case SkillFeedStatus.notInstalled:
        return IconButton.filled(
          key: ValueKey('skill-action-install-${item.comparisonKey}'),
          onPressed: isBusy
              ? null
              : () => context.read<SkillsCatalogBloc>().add(
                  SkillsCatalogInstallRequested(item),
                ),
          icon: isBusy
              ? const _ButtonSpinner(size: 16)
              : const Icon(Icons.download_outlined, size: 18),
          tooltip: 'Install skill',
          style: _iconActionStyle(
            backgroundColor: VibeHubTheme.slate600,
            foregroundColor: Colors.white,
          ),
        );
      case SkillFeedStatus.outdated:
        return IconButton.filledTonal(
          key: ValueKey('skill-action-update-${item.comparisonKey}'),
          onPressed: isBusy
              ? null
              : () => context.read<SkillsCatalogBloc>().add(
                  SkillsCatalogUpdateRequested(item),
                ),
          icon: isBusy
              ? const _ButtonSpinner(size: 16)
              : const Icon(Icons.system_update_alt_outlined, size: 18),
          tooltip: 'Update skill',
          style: _iconActionStyle(
            backgroundColor: VibeHubTheme.slate100,
            foregroundColor: VibeHubTheme.slate600,
          ),
        );
      case SkillFeedStatus.installed:
        return IconButton.outlined(
          key: ValueKey('skill-action-uninstall-${item.comparisonKey}'),
          onPressed: isBusy
              ? null
              : () => context.read<SkillsCatalogBloc>().add(
                  SkillsCatalogUninstallRequested(item),
                ),
          icon: isBusy
              ? const _ButtonSpinner(size: 16)
              : const Icon(Icons.delete_outline, size: 18),
          tooltip: 'Uninstall skill',
          style: _iconActionStyle(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
        );
    }
  }

  ButtonStyle _iconActionStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    BorderSide? side,
  }) {
    return IconButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      fixedSize: const Size.square(34),
      minimumSize: const Size.square(34),
      padding: EdgeInsets.zero,
      side: side,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner({this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final SkillFeedStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = switch (status) {
      SkillFeedStatus.installed => 'Current',
      SkillFeedStatus.outdated => 'Outdated',
      SkillFeedStatus.notInstalled => 'Missing',
    };
    final foreground = switch (status) {
      SkillFeedStatus.installed => const Color(0xFF047857),
      SkillFeedStatus.outdated => const Color(0xFFEA580C),
      SkillFeedStatus.notInstalled => colors.onSurfaceVariant,
    };
    final background = switch (status) {
      SkillFeedStatus.installed => const Color(0xFFE8FFF5),
      SkillFeedStatus.outdated => Colors.white,
      SkillFeedStatus.notInstalled => colors.surfaceContainerHighest,
    };
    final border = switch (status) {
      SkillFeedStatus.installed => const Color(0xFF047857),
      SkillFeedStatus.outdated => const Color(0xFFEA580C),
      SkillFeedStatus.notInstalled => Colors.transparent,
    };
    final width = switch (status) {
      SkillFeedStatus.installed => 74.0,
      SkillFeedStatus.outdated => 68.0,
      SkillFeedStatus.notInstalled => 58.0,
    };
    final radius = status == SkillFeedStatus.installed ? 999.0 : 4.0;

    return Container(
      width: width,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuietCountText extends StatelessWidget {
  const _QuietCountText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 38,
      child: Opacity(
        opacity: 0.58,
        child: Text(
          label,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: colors.primary),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _shortSha(String sha) {
  return sha.length <= 7 ? sha : sha.substring(0, 7);
}

List<String> _repositoriesForState(SkillsCatalogState state) {
  if (state.selectedOwner != null) {
    return state.index.repositoriesFor(state.selectedOwner);
  }

  final counts = <String, int>{};
  for (final item in state.items) {
    counts[item.repo] = (counts[item.repo] ?? 0) + 1;
  }

  return counts.keys.toList()..sort((first, second) {
    final countCompare = (counts[second] ?? 0).compareTo(counts[first] ?? 0);
    if (countCompare != 0) {
      return countCompare;
    }
    return first.compareTo(second);
  });
}

int _repoSkillCountForState(SkillsCatalogState state, String repo) {
  if (state.selectedOwner != null) {
    return state.index.skillCountForRepository(state.selectedOwner!, repo);
  }

  return state.items.where((item) => item.repo == repo).length;
}

List<SkillFeedItem> _skillsForState(SkillsCatalogState state) {
  return state.items.where((item) {
    final matchesOwner =
        state.selectedOwner == null || item.owner == state.selectedOwner;
    final matchesRepo =
        state.selectedRepo == null || item.repo == state.selectedRepo;
    return matchesOwner && matchesRepo;
  }).toList();
}

(String, String?) _splitVersionedSkillId(String id) {
  final separator = id.lastIndexOf('@');
  if (separator <= 0 || separator == id.length - 1) {
    return (id, null);
  }

  return (id.substring(0, separator), id.substring(separator + 1));
}

List<String> _filterStrings(List<String> values, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return values;
  }

  return values
      .where((value) => value.toLowerCase().contains(normalizedQuery))
      .toList();
}

List<SkillFeedItem> _filterSkills(
  List<SkillFeedItem> skills,
  String query,
  SkillListFilter filter,
) {
  final normalizedQuery = query.trim().toLowerCase();

  return skills.where((skill) {
    final matchesQuery =
        normalizedQuery.isEmpty ||
        skill.id.toLowerCase().contains(normalizedQuery) ||
        skill.sha.toLowerCase().contains(normalizedQuery);
    if (!matchesQuery) {
      return false;
    }

    return switch (filter) {
      SkillListFilter.all => true,
      SkillListFilter.current => skill.status == SkillFeedStatus.installed,
      SkillListFilter.missing => skill.status == SkillFeedStatus.notInstalled,
    };
  }).toList();
}
