import 'package:vibehub/api/skills_api.dart';

enum SkillFeedStatus { installed, outdated, notInstalled }

enum SkillListFilter { all, current, missing }

class SkillFeedItem {
  const SkillFeedItem({
    required this.id,
    required this.comparisonKey,
    required this.name,
    required this.owner,
    required this.repo,
    required this.catalogVersion,
    required this.sha,
    required this.repoUrl,
    required this.localVersion,
    required this.installCommand,
    required this.isInstalled,
    required this.isOutdated,
    this.metadata = const {},
    this.installedVersions = const [],
  });

  final String id;
  final String comparisonKey;
  final String name;
  final String owner;
  final String repo;
  final String catalogVersion;
  final String sha;
  final String repoUrl;
  final String? localVersion;
  final String installCommand;
  final bool isInstalled;
  final bool isOutdated;
  final Map<String, dynamic> metadata;
  final List<Skill> installedVersions;

  SkillFeedStatus get status {
    if (!isInstalled) {
      return SkillFeedStatus.notInstalled;
    }
    return isOutdated ? SkillFeedStatus.outdated : SkillFeedStatus.installed;
  }
}

class SkillsCatalogIndex {
  const SkillsCatalogIndex({
    required this.owners,
    required this.ownerSkillCounts,
    required this.repositorySkillCounts,
    required this.repositoriesByOwner,
    required this.skillsByOwnerRepo,
  });

  final List<String> owners;
  final Map<String, int> ownerSkillCounts;
  final Map<String, int> repositorySkillCounts;
  final Map<String, List<String>> repositoriesByOwner;
  final Map<String, List<SkillFeedItem>> skillsByOwnerRepo;

  static const empty = SkillsCatalogIndex(
    owners: [],
    ownerSkillCounts: {},
    repositorySkillCounts: {},
    repositoriesByOwner: {},
    skillsByOwnerRepo: {},
  );

  int skillCountForOwner(String owner) {
    return ownerSkillCounts[owner] ?? 0;
  }

  int skillCountForRepository(String owner, String repo) {
    return repositorySkillCounts[_ownerRepoKey(owner, repo)] ?? 0;
  }

  List<String> repositoriesFor(String? owner) {
    if (owner == null) {
      return const [];
    }
    return repositoriesByOwner[owner] ?? const [];
  }

  List<SkillFeedItem> skillsFor(String? owner, String? repo) {
    if (owner == null || repo == null) {
      return const [];
    }
    return skillsByOwnerRepo[_ownerRepoKey(owner, repo)] ?? const [];
  }
}

class SkillsCatalogState {
  const SkillsCatalogState({
    required this.isLoading,
    required this.isBulkInstalling,
    required this.busySkillIds,
    required this.items,
    required this.index,
    this.selectedOwner,
    this.selectedRepo,
    this.ownerQuery = '',
    this.repoQuery = '',
    this.skillQuery = '',
    this.skillFilter = SkillListFilter.all,
    this.errorMessage,
    this.actionStatus,
  });

  final bool isLoading;
  final bool isBulkInstalling;
  final Set<String> busySkillIds;
  final List<SkillFeedItem> items;
  final SkillsCatalogIndex index;
  final String? selectedOwner;
  final String? selectedRepo;
  final String ownerQuery;
  final String repoQuery;
  final String skillQuery;
  final SkillListFilter skillFilter;
  final String? errorMessage;
  final String? actionStatus;

  const SkillsCatalogState.initial()
    : isLoading = true,
      isBulkInstalling = false,
      busySkillIds = const {},
      items = const [],
      index = SkillsCatalogIndex.empty,
      selectedOwner = null,
      selectedRepo = null,
      ownerQuery = '',
      repoQuery = '',
      skillQuery = '',
      skillFilter = SkillListFilter.all,
      errorMessage = null,
      actionStatus = null;

  SkillsCatalogState copyWith({
    bool? isLoading,
    bool? isBulkInstalling,
    Set<String>? busySkillIds,
    List<SkillFeedItem>? items,
    SkillsCatalogIndex? index,
    Object? selectedOwner = _unset,
    Object? selectedRepo = _unset,
    String? ownerQuery,
    String? repoQuery,
    String? skillQuery,
    SkillListFilter? skillFilter,
    Object? errorMessage = _unset,
    Object? actionStatus = _unset,
  }) {
    return SkillsCatalogState(
      isLoading: isLoading ?? this.isLoading,
      isBulkInstalling: isBulkInstalling ?? this.isBulkInstalling,
      busySkillIds: busySkillIds ?? this.busySkillIds,
      items: items ?? this.items,
      index: index ?? this.index,
      selectedOwner: selectedOwner == _unset
          ? this.selectedOwner
          : selectedOwner as String?,
      selectedRepo: selectedRepo == _unset
          ? this.selectedRepo
          : selectedRepo as String?,
      ownerQuery: ownerQuery ?? this.ownerQuery,
      repoQuery: repoQuery ?? this.repoQuery,
      skillQuery: skillQuery ?? this.skillQuery,
      skillFilter: skillFilter ?? this.skillFilter,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      actionStatus: actionStatus == _unset
          ? this.actionStatus
          : actionStatus as String?,
    );
  }
}

String _ownerRepoKey(String owner, String repo) {
  return '$owner/$repo';
}

const Object _unset = Object();
