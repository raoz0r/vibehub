import 'package:vibehub/api/skills_api.dart';

class RepositoryEntry {
  final String id;
  final String name;
  final String path;
  final List<Skill> skills;

  const RepositoryEntry({
    required this.id,
    required this.name,
    required this.path,
    required this.skills,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepositoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          path == other.path;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ path.hashCode;
}

class RepositoriesState {
  final bool isLoading;
  final List<RepositoryEntry> repositories;
  final List<Skill> installedSkills;
  final Set<String> lockedSkillIds;
  final String searchQuery;
  final String? errorMessage;
  final String? actionStatus;

  const RepositoriesState({
    required this.isLoading,
    required this.repositories,
    required this.installedSkills,
    required this.lockedSkillIds,
    required this.searchQuery,
    this.errorMessage,
    this.actionStatus,
  });

  const RepositoriesState.initial()
    : isLoading = true,
      repositories = const [],
      installedSkills = const [],
      lockedSkillIds = const {},
      searchQuery = '',
      errorMessage = null,
      actionStatus = null;

  RepositoriesState copyWith({
    bool? isLoading,
    List<RepositoryEntry>? repositories,
    List<Skill>? installedSkills,
    Set<String>? lockedSkillIds,
    String? searchQuery,
    Object? errorMessage = _unset,
    Object? actionStatus = _unset,
  }) {
    return RepositoriesState(
      isLoading: isLoading ?? this.isLoading,
      repositories: repositories ?? this.repositories,
      installedSkills: installedSkills ?? this.installedSkills,
      lockedSkillIds: lockedSkillIds ?? this.lockedSkillIds,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      actionStatus: actionStatus == _unset
          ? this.actionStatus
          : actionStatus as String?,
    );
  }
}

const Object _unset = Object();
