import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:vibehub/api/paths.dart';
import 'package:vibehub/api/skills_api.dart';
import 'package:vibehub/api/skills_lock_api.dart';
import 'package:vibehub/api/repositories_registry_api.dart';
import 'package:vibehub/functions/install_skill.dart' as fns;
import 'repositories_event.dart';
import 'repositories_state.dart';

class RepositoriesBloc extends Bloc<RepositoriesEvent, RepositoriesState> {
  RepositoriesBloc({
    SkillsApi? skillsApi,
    SkillsLockApi? skillsLockApi,
    RepositoriesRegistryApi? repositoriesRegistryApi,
  }) : _skillsApi = skillsApi ?? SkillsApi(),
       _skillsLockApi = skillsLockApi ?? SkillsLockApi(),
       _repositoriesRegistryApi =
           repositoriesRegistryApi ?? RepositoriesRegistryApi(),
       super(const RepositoriesState.initial()) {
    on<RepositoriesStarted>(_onStarted);
    on<RepositoryLinkSkillRequested>(_onLinkSkill);
    on<RepositoryInstallSkillRequested>(_onInstallSkill);
    on<RepositoryUnlinkSkillRequested>(_onUnlinkSkill);
    on<RepositoryDeleteRequested>(_onDeleteRepository);
    on<RepositorySkillLockToggled>(_onSkillLockToggled);
    on<RepositoriesSearchQueryChanged>(_onSearchQueryChanged);
    on<RepositoryRegisterRequested>(_onRegisterRepository);
  }

  final SkillsApi _skillsApi;
  final SkillsLockApi _skillsLockApi;
  final RepositoriesRegistryApi _repositoriesRegistryApi;

  Future<void> _linkInstalledSkill({
    required String repositoryId,
    required String repositoryName,
    required String repositoryPath,
    required String skillId,
  }) async {
    final skill = _skillsApi.readSkill(skillId);
    if (skill == null) {
      throw StateError('Skill $skillId is not installed/found in database.');
    }

    final skillShortName = _skillShortName(skill);

    final linkPath = p.join(
      repositoryPath,
      '.agents',
      'skills',
      skillShortName,
    );
    final targetPath = p.join(
      VibeHubPaths.dataDir,
      'catalog',
      skill.id.replaceAll('/', '_'),
    );

    final currentProjects = List<Map<String, dynamic>>.from(skill.projects);
    final alreadyLinked = currentProjects.any((p) => p['id'] == repositoryId);
    if (!alreadyLinked) {
      currentProjects.add({
        'id': repositoryId,
        'name': repositoryName,
        'path': repositoryPath,
      });
      final updatedSkill = Skill(
        id: skill.id,
        owner: skill.owner,
        repo: skill.repo,
        version: skill.version,
        installCommand: skill.installCommand,
        updateAvailable: skill.updateAvailable,
        inJsonProjects: json.encode({'projects': currentProjects}),
        metadata: skill.metadata,
        description: skill.description,
      );
      _skillsApi.writeSkill(updatedSkill);
    }

    final link = Link(linkPath);
    if (await FileSystemEntity.type(linkPath) !=
        FileSystemEntityType.notFound) {
      await Directory(linkPath).delete(recursive: true);
    }
    await Directory(p.dirname(linkPath)).create(recursive: true);
    await link.create(targetPath);
    await _writeRepositorySkillLockEntry(
      repositoryPath: repositoryPath,
      skill: skill,
      targetPath: targetPath,
    );
  }

  Future<void> _onStarted(
    RepositoriesStarted event,
    Emitter<RepositoriesState> emit,
  ) async {
    emit(
      state.copyWith(isLoading: true, errorMessage: null, actionStatus: null),
    );
    try {
      final data = await _fetchData();
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load repositories: $e',
        ),
      );
    }
  }

  Future<
    ({
      List<RepositoryEntry> repos,
      List<Skill> installedSkills,
      Set<String> locks,
    })
  >
  _fetchData() async {
    final registered = await _repositoriesRegistryApi
        .getRegisteredRepositories();
    final allSkills = _skillsApi.readAllSkills();
    final reposMap = <String, RepositoryEntry>{};

    for (final reg in registered) {
      final regId = reg['id']!;
      final regName = reg['name']!;
      final regPath = reg['path']!;
      reposMap[regId] = RepositoryEntry(
        id: regId,
        name: regName,
        path: regPath,
        skills: [],
      );
    }

    for (final skill in allSkills) {
      for (final proj in skill.projects) {
        final projId = proj['id'] as String;
        final projName = proj['name'] as String;
        final projPath = proj['path'] as String;

        var existing = reposMap[projId];
        if (existing == null) {
          existing = RepositoryEntry(
            id: projId,
            name: projName,
            path: projPath,
            skills: [],
          );
          reposMap[projId] = existing;
          await _repositoriesRegistryApi.registerRepository(
            id: projId,
            name: projName,
            path: projPath,
          );
        }
        existing.skills.add(skill);
      }
    }

    final lockedSkillIds = await _skillsLockApi.getLockedSkills();
    return (
      repos: reposMap.values.toList(),
      installedSkills: allSkills,
      locks: lockedSkillIds,
    );
  }

  Future<void> _onLinkSkill(
    RepositoryLinkSkillRequested event,
    Emitter<RepositoriesState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        actionStatus: 'Linking skill...',
      ),
    );
    try {
      await _linkInstalledSkill(
        repositoryId: event.repositoryId,
        repositoryName: event.repositoryName,
        repositoryPath: event.repositoryPath,
        skillId: event.skillId,
      );

      final data = await _fetchData();
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          actionStatus: 'Successfully linked skill and created symlink.',
        ),
      );
    } catch (e) {
      final data = await _fetchData().catchError(
        (_) => (
          repos: <RepositoryEntry>[],
          installedSkills: <Skill>[],
          locks: <String>{},
        ),
      );
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          errorMessage: 'Failed to link skill: $e',
        ),
      );
    }
  }

  Future<void> _onInstallSkill(
    RepositoryInstallSkillRequested event,
    Emitter<RepositoriesState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        actionStatus: 'Installing skill...',
      ),
    );
    try {
      final status = await fns.installSkill(
        event.skill,
        _skillsApi,
        skillsLockApi: _skillsLockApi,
      );
      if (status != 'ok') {
        throw StateError(status);
      }

      if (event.linkAfterInstall) {
        await _linkInstalledSkill(
          repositoryId: event.repositoryId,
          repositoryName: event.repositoryName,
          repositoryPath: event.repositoryPath,
          skillId: event.skill.id,
        );
      }

      final data = await _fetchData();
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          actionStatus: event.linkAfterInstall
              ? 'Successfully installed and linked skill.'
              : 'Successfully installed skill.',
        ),
      );
    } catch (e) {
      final data = await _fetchData().catchError(
        (_) => (
          repos: <RepositoryEntry>[],
          installedSkills: <Skill>[],
          locks: <String>{},
        ),
      );
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          errorMessage: 'Failed to install skill: $e',
        ),
      );
    }
  }

  Future<void> _onUnlinkSkill(
    RepositoryUnlinkSkillRequested event,
    Emitter<RepositoriesState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        actionStatus: 'Unlinking skill...',
      ),
    );
    try {
      final skill = _skillsApi.readSkill(event.skillId);
      if (skill != null) {
        final skillShortName = _skillShortName(skill);

        final linkPath = p.join(
          event.repositoryPath,
          '.agents',
          'skills',
          skillShortName,
        );

        // Update database association first
        final currentProjects = List<Map<String, dynamic>>.from(skill.projects);
        currentProjects.removeWhere((p) => p['id'] == event.repositoryId);
        final updatedSkill = Skill(
          id: skill.id,
          owner: skill.owner,
          repo: skill.repo,
          version: skill.version,
          installCommand: skill.installCommand,
          updateAvailable: skill.updateAvailable,
          inJsonProjects: json.encode({'projects': currentProjects}),
          metadata: skill.metadata,
          description: skill.description,
        );
        _skillsApi.writeSkill(updatedSkill);

        // Delete symlink
        final link = Link(linkPath);
        if (await link.exists()) {
          await link.delete();
        }
        await _removeRepositorySkillLockEntry(
          repositoryPath: event.repositoryPath,
          skill: skill,
        );

        // Clean up empty parent directories
        final skillsDir = Directory(
          p.join(event.repositoryPath, '.agents', 'skills'),
        );
        if (await skillsDir.exists()) {
          final list = await skillsDir.list().toList();
          if (list.isEmpty) {
            await skillsDir.delete();
          }
        }

        final agentsDir = Directory(p.join(event.repositoryPath, '.agents'));
        if (await agentsDir.exists()) {
          final list = await agentsDir.list().toList();
          if (list.isEmpty) {
            await agentsDir.delete();
          }
        }
      }

      final data = await _fetchData();
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          actionStatus: 'Successfully unlinked skill and deleted symlink.',
        ),
      );
    } catch (e) {
      final data = await _fetchData().catchError(
        (_) => (
          repos: <RepositoryEntry>[],
          installedSkills: <Skill>[],
          locks: <String>{},
        ),
      );
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          errorMessage: 'Failed to unlink skill: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteRepository(
    RepositoryDeleteRequested event,
    Emitter<RepositoriesState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        actionStatus: 'Deleting repository...',
      ),
    );
    try {
      final allSkills = _skillsApi.readAllSkills();

      for (final skill in allSkills) {
        final projects = List<Map<String, dynamic>>.from(skill.projects);
        final hasProject = projects.any((p) => p['id'] == event.repositoryId);
        if (hasProject) {
          // Remove from database association
          projects.removeWhere((p) => p['id'] == event.repositoryId);
          final updatedSkill = Skill(
            id: skill.id,
            owner: skill.owner,
            repo: skill.repo,
            version: skill.version,
            installCommand: skill.installCommand,
            updateAvailable: skill.updateAvailable,
            inJsonProjects: json.encode({'projects': projects}),
            metadata: skill.metadata,
            description: skill.description,
          );
          _skillsApi.writeSkill(updatedSkill);

          // Delete corresponding symlink
          final skillShortName = _skillShortName(skill);

          final linkPath = p.join(
            event.repositoryPath,
            '.agents',
            'skills',
            skillShortName,
          );
          final link = Link(linkPath);
          if (await link.exists()) {
            await link.delete();
          }
          await _removeRepositorySkillLockEntry(
            repositoryPath: event.repositoryPath,
            skill: skill,
          );
        }
      }

      // Clean up empty parent directories in the repository
      final skillsDir = Directory(
        p.join(event.repositoryPath, '.agents', 'skills'),
      );
      if (await skillsDir.exists()) {
        final list = await skillsDir.list().toList();
        if (list.isEmpty) {
          await skillsDir.delete();
        }
      }

      final agentsDir = Directory(p.join(event.repositoryPath, '.agents'));
      if (await agentsDir.exists()) {
        final list = await agentsDir.list().toList();
        if (list.isEmpty) {
          await agentsDir.delete();
        }
      }

      await _repositoriesRegistryApi.unregisterRepository(event.repositoryId);

      final data = await _fetchData();
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          actionStatus:
              'Successfully deleted repository from VibeHub and cleaned up files.',
        ),
      );
    } catch (e) {
      final data = await _fetchData().catchError(
        (_) => (
          repos: <RepositoryEntry>[],
          installedSkills: <Skill>[],
          locks: <String>{},
        ),
      );
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          errorMessage: 'Failed to delete repository: $e',
        ),
      );
    }
  }

  Future<void> _onSkillLockToggled(
    RepositorySkillLockToggled event,
    Emitter<RepositoriesState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        actionStatus: 'Toggling lock...',
      ),
    );
    try {
      final isLocked = await _skillsLockApi.isLocked(event.skillId);
      if (isLocked) {
        await _skillsLockApi.unlockSkill(event.skillId);
      } else {
        await _skillsLockApi.lockSkill(event.skillId);
      }

      final data = await _fetchData();
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          actionStatus: isLocked
              ? 'Unlocked skill ${event.skillId}.'
              : 'Locked skill ${event.skillId} from updates.',
        ),
      );
    } catch (e) {
      final data = await _fetchData().catchError(
        (_) => (
          repos: <RepositoryEntry>[],
          installedSkills: <Skill>[],
          locks: <String>{},
        ),
      );
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          errorMessage: 'Failed to toggle lock: $e',
        ),
      );
    }
  }

  Future<void> _onSearchQueryChanged(
    RepositoriesSearchQueryChanged event,
    Emitter<RepositoriesState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onRegisterRepository(
    RepositoryRegisterRequested event,
    Emitter<RepositoriesState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        actionStatus: 'Registering repository...',
      ),
    );
    try {
      final sanitizedName = event.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
          .toLowerCase();
      final id = '${sanitizedName}_${event.path.hashCode.abs().toString()}';

      await _repositoriesRegistryApi.registerRepository(
        id: id,
        name: event.name,
        path: event.path,
      );

      final data = await _fetchData();
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          actionStatus: 'Successfully registered repository.',
        ),
      );
    } catch (e) {
      final data = await _fetchData().catchError(
        (_) => (
          repos: <RepositoryEntry>[],
          installedSkills: <Skill>[],
          locks: <String>{},
        ),
      );
      emit(
        state.copyWith(
          isLoading: false,
          repositories: data.repos,
          installedSkills: data.installedSkills,
          lockedSkillIds: data.locks,
          errorMessage: 'Failed to register repository: $e',
        ),
      );
    }
  }
}

String _skillNameWithoutVersion(Skill skill) {
  final separator = skill.id.lastIndexOf('@');
  return separator > 0 ? skill.id.substring(0, separator) : skill.id;
}

String _skillShortName(Skill skill) {
  final skillName = _skillNameWithoutVersion(skill);
  final nameSeparator = skillName.lastIndexOf('/');
  return nameSeparator >= 0
      ? skillName.substring(nameSeparator + 1)
      : skillName;
}

Future<void> _writeRepositorySkillLockEntry({
  required String repositoryPath,
  required Skill skill,
  required String targetPath,
}) async {
  final lockFile = File(p.join(repositoryPath, '.agents', 'skills-lock.json'));
  final lockJson = await _readRepositorySkillsLock(lockFile);
  final skills = Map<String, dynamic>.from(lockJson['skills'] as Map);
  final shortName = _skillShortName(skill);

  skills[shortName] = {
    'source':
        _metadataString(skill, 'source') ?? '${skill.owner}/${skill.repo}',
    'sourceType': _metadataString(skill, 'sourceType') ?? 'github',
    'skillPath':
        _metadataString(skill, 'skillPath') ?? 'skills/$shortName/SKILL.md',
    'computedHash': await _computedSkillHash(skill, targetPath),
  };

  lockJson['skills'] = skills;
  await lockFile.parent.create(recursive: true);
  await lockFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(lockJson),
  );
}

Future<void> _removeRepositorySkillLockEntry({
  required String repositoryPath,
  required Skill skill,
}) async {
  final lockFile = File(p.join(repositoryPath, '.agents', 'skills-lock.json'));
  if (!await lockFile.exists()) {
    return;
  }

  final lockJson = await _readRepositorySkillsLock(lockFile);
  final skills = Map<String, dynamic>.from(lockJson['skills'] as Map);
  skills.remove(_skillShortName(skill));
  lockJson['skills'] = skills;

  if (skills.isEmpty) {
    await lockFile.delete();
    return;
  }

  await lockFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(lockJson),
  );
}

Future<Map<String, dynamic>> _readRepositorySkillsLock(File lockFile) async {
  if (!await lockFile.exists()) {
    return {'version': 1, 'skills': <String, dynamic>{}};
  }

  final decoded = json.decode(await lockFile.readAsString());
  if (decoded is Map) {
    return {
      'version': decoded['version'] is int ? decoded['version'] : 1,
      'skills': decoded['skills'] is Map
          ? Map<String, dynamic>.from(decoded['skills'] as Map)
          : <String, dynamic>{},
    };
  }
  return {'version': 1, 'skills': <String, dynamic>{}};
}

String? _metadataString(Skill skill, String key) {
  final value = skill.metadata[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

Future<String> _computedSkillHash(Skill skill, String targetPath) async {
  final metadataHash =
      _metadataString(skill, 'computedHash') ?? _metadataString(skill, 'sha');
  if (metadataHash != null) {
    return metadataHash;
  }

  final skillFile = File(p.join(targetPath, 'SKILL.md'));
  if (!await skillFile.exists()) {
    return '';
  }

  return sha256.convert(await skillFile.readAsBytes()).toString();
}
