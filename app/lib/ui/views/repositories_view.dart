import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibehub/ui/bloc/repositories/repositories_bloc.dart';
import 'package:vibehub/ui/bloc/repositories/repositories_event.dart';
import 'package:vibehub/ui/bloc/repositories/repositories_state.dart';
import 'package:vibehub/ui/theme/vibehub_theme.dart';
import 'package:vibehub/ui/widgets/registered_directory_card.dart';
import 'package:vibehub/ui/widgets/repository_search_header.dart';

class RepositoriesView extends StatelessWidget {
  const RepositoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RepositoriesBloc()..add(const RepositoriesStarted()),
      child: const _RepositoriesViewBody(),
    );
  }
}

class _RepositoriesViewBody extends StatefulWidget {
  const _RepositoriesViewBody({super.key});

  @override
  State<_RepositoriesViewBody> createState() => _RepositoriesViewBodyState();
}

class _RepositoriesViewBodyState extends State<_RepositoriesViewBody> {
  final Set<String> _expandedRepositoryIds = {};

  void _toggleExpansion(String repoId) {
    setState(() {
      if (_expandedRepositoryIds.contains(repoId)) {
        _expandedRepositoryIds.remove(repoId);
      } else {
        _expandedRepositoryIds.add(repoId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RepositoriesBloc, RepositoriesState>(
      builder: (context, state) {
        final query = state.searchQuery.toLowerCase();
        final filteredRepos = state.repositories.where((repo) {
          return repo.name.toLowerCase().contains(query) ||
              repo.path.toLowerCase().contains(query);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RepositorySearchHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: DecoratedBox(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RepositoriesHeader(count: filteredRepos.length),
                      if (state.isLoading && filteredRepos.isEmpty)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: VibeHubTheme.slate600,
                            ),
                          ),
                        )
                      else if (filteredRepos.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No registered repositories found.',
                              style: TextStyle(
                                color: VibeHubTheme.slate400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 760;
                              return ListView.builder(
                                itemCount: filteredRepos.length,
                                itemBuilder: (context, index) {
                                  final repo = filteredRepos[index];
                                  final isExpanded = _expandedRepositoryIds
                                      .contains(repo.id);
                                  return RegisteredDirectoryCard(
                                    repo: repo,
                                    isExpanded: isExpanded,
                                    isCompact: isCompact,
                                    lockedSkillIds: state.lockedSkillIds,
                                    onToggleExpand: () =>
                                        _toggleExpansion(repo.id),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RepositoriesHeader extends StatelessWidget {
  const _RepositoriesHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showScanBadge = constraints.maxWidth >= 560;

        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFFCFDFF),
            border: Border(bottom: BorderSide(color: VibeHubTheme.slate100)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'REGISTERED DIRECTORIES ($count)',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: VibeHubTheme.slate700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
