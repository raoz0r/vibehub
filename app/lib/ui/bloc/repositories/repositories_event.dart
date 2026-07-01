import 'package:vibehub/api/skills_api.dart';

sealed class RepositoriesEvent {
  const RepositoriesEvent();
}

class RepositoriesStarted extends RepositoriesEvent {
  const RepositoriesStarted();
}

class RepositoryLinkSkillRequested extends RepositoriesEvent {
  final String repositoryId;
  final String repositoryName;
  final String repositoryPath;
  final String skillId;

  const RepositoryLinkSkillRequested({
    required this.repositoryId,
    required this.repositoryName,
    required this.repositoryPath,
    required this.skillId,
  });
}

class RepositoryUnlinkSkillRequested extends RepositoriesEvent {
  final String repositoryId;
  final String repositoryPath;
  final String skillId;

  const RepositoryUnlinkSkillRequested({
    required this.repositoryId,
    required this.repositoryPath,
    required this.skillId,
  });
}

class RepositoryInstallSkillRequested extends RepositoriesEvent {
  final String repositoryId;
  final String repositoryName;
  final String repositoryPath;
  final Skill skill;
  final bool linkAfterInstall;

  const RepositoryInstallSkillRequested({
    required this.repositoryId,
    required this.repositoryName,
    required this.repositoryPath,
    required this.skill,
    this.linkAfterInstall = true,
  });
}

class RepositoryDeleteRequested extends RepositoriesEvent {
  final String repositoryId;
  final String repositoryPath;

  const RepositoryDeleteRequested({
    required this.repositoryId,
    required this.repositoryPath,
  });
}

class RepositorySkillLockToggled extends RepositoriesEvent {
  final String skillId;

  const RepositorySkillLockToggled({required this.skillId});
}

class RepositoriesSearchQueryChanged extends RepositoriesEvent {
  final String query;

  const RepositoriesSearchQueryChanged(this.query);
}

class RepositoryRegisterRequested extends RepositoriesEvent {
  final String path;
  final String name;

  const RepositoryRegisterRequested({
    required this.path,
    required this.name,
  });
}
