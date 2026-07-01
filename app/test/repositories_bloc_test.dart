import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vibehub/api/skills_api.dart';
import 'package:vibehub/api/skills_lock_api.dart';
import 'package:vibehub/api/repositories_registry_api.dart';
import 'package:vibehub/functions/install_skill.dart';
import 'package:vibehub/ui/bloc/repositories/repositories_bloc.dart';
import 'package:vibehub/ui/bloc/repositories/repositories_event.dart';
import 'package:vibehub/ui/bloc/repositories/repositories_state.dart';

void main() {
  group('RepositoriesBloc & Symlink & Lock Tests', () {
    late Directory tempDir;
    late String testDbPath;
    late String testLockFilePath;
    late String testRegistryFilePath;
    late String testRepoPath;
    late VibeHubDatabase database;
    late SkillsApi skillsApi;
    late SkillsLockApi skillsLockApi;
    late RepositoriesRegistryApi repositoriesRegistryApi;
    late RepositoriesBloc repositoriesBloc;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('repositories_bloc_test');
      testDbPath = p.join(tempDir.path, 'database');
      testLockFilePath = p.join(tempDir.path, 'locked_skills.json');
      testRegistryFilePath = p.join(tempDir.path, 'registered_repositories.json');
      testRepoPath = p.join(tempDir.path, 'my_test_repo');

      // Create dummy repo directory
      await Directory(testRepoPath).create(recursive: true);

      database = VibeHubDatabase(databasePath: testDbPath);
      skillsApi = SkillsApi(database);
      skillsLockApi = SkillsLockApi(lockFilePath: testLockFilePath);
      repositoriesRegistryApi = RepositoriesRegistryApi(registryFilePath: testRegistryFilePath);

      repositoriesBloc = RepositoriesBloc(
        skillsApi: skillsApi,
        skillsLockApi: skillsLockApi,
        repositoriesRegistryApi: repositoriesRegistryApi,
      );
    });

    tearDown(() async {
      repositoriesBloc.close();
      database.close();
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('Initial state is loading', () {
      expect(repositoriesBloc.state.isLoading, isTrue);
      expect(repositoriesBloc.state.repositories, isEmpty);
      expect(repositoriesBloc.state.lockedSkillIds, isEmpty);
    });

    test(
      'RepositoriesStarted loads repository entries and lock list',
      () async {
        final skill = Skill(
          id: 'accessibility-review@2026.28',
          owner: 'owner',
          repo: 'repo',
          version: '2026.28',
          installCommand: 'cmd',
          updateAvailable: false,
          inJsonProjects: json.encode({
            'projects': [
              {'id': 'my-repo-id', 'name': 'My Repo', 'path': testRepoPath},
            ],
          }),
        );
        skillsApi.writeSkill(skill);
        await skillsLockApi.lockSkill('accessibility-review@2026.28');

        repositoriesBloc.add(const RepositoriesStarted());

        await expectLater(
          repositoriesBloc.stream,
          emitsInOrder([
            predicate<RepositoriesState>((state) => state.isLoading),
            predicate<RepositoriesState>((state) {
              if (state.isLoading) return false;
              if (state.repositories.length != 1) return false;
              final entry = state.repositories.first;
              return entry.id == 'my-repo-id' &&
                  entry.name == 'My Repo' &&
                  entry.path == testRepoPath &&
                  entry.skills.first.id == 'accessibility-review@2026.28' &&
                  state.lockedSkillIds.contains('accessibility-review@2026.28');
            }),
          ]),
        );
      },
    );

    test(
      'RepositoryLinkSkillRequested links skill, updates database, and creates symlink',
      () async {
        // First, write the skill to db (simulating it being installed/saved in catalog)
        final skill = Skill(
          id: 'accessibility-review@2026.28',
          owner: 'owner',
          repo: 'repo',
          version: '2026.28',
          installCommand: 'cmd',
          updateAvailable: false,
          inJsonProjects: '{}',
        );
        skillsApi.writeSkill(skill);

        repositoriesBloc.add(const RepositoriesStarted());
        await repositoriesBloc.stream.firstWhere((state) => !state.isLoading);

        repositoriesBloc.add(
          RepositoryLinkSkillRequested(
            repositoryId: 'my-repo-id',
            repositoryName: 'My Repo',
            repositoryPath: testRepoPath,
            skillId: 'accessibility-review@2026.28',
          ),
        );

        await expectLater(
          repositoriesBloc.stream,
          emitsInOrder([
            // starts loading
            predicate<RepositoriesState>(
              (state) =>
                  state.isLoading && state.actionStatus == 'Linking skill...',
            ),
            // ends loading, loads repositories, sets success status
            predicate<RepositoriesState>((state) {
              if (state.isLoading) return false;
              if (state.repositories.length != 1) return false;
              final entry = state.repositories.first;
              return entry.id == 'my-repo-id' &&
                  entry.skills.first.id == 'accessibility-review@2026.28' &&
                  state.actionStatus ==
                      'Successfully linked skill and created symlink.';
            }),
          ]),
        );

        // Verify the symlink file exists
        final linkPath = p.join(
          testRepoPath,
          '.agents',
          'skills',
          'accessibility-review',
        );
        final link = Link(linkPath);
        expect(await link.exists(), isTrue);

        // Verify DB contains project_skills association
        final updatedSkill = skillsApi.readSkill(
          'accessibility-review@2026.28',
        );
        expect(updatedSkill, isNotNull);
        expect(updatedSkill!.projects, hasLength(1));
        expect(updatedSkill.projects.first['id'], 'my-repo-id');
      },
    );

    test(
      'RepositoryInstallSkillRequested installs skill and links repository',
      () async {
        final skill = Skill(
          id: 'accessibility-review@2026.28',
          owner: 'owner',
          repo: 'repo',
          version: '2026.28',
          installCommand: 'install accessibility-review',
          updateAvailable: false,
          inJsonProjects: '{}',
        );

        repositoriesBloc.add(const RepositoriesStarted());
        await repositoriesBloc.stream.firstWhere((state) => !state.isLoading);

        repositoriesBloc.add(
          RepositoryInstallSkillRequested(
            repositoryId: 'my-repo-id',
            repositoryName: 'My Repo',
            repositoryPath: testRepoPath,
            skill: skill,
          ),
        );

        await expectLater(
          repositoriesBloc.stream,
          emitsInOrder([
            predicate<RepositoriesState>(
              (state) =>
                  state.isLoading &&
                  state.actionStatus == 'Installing skill...',
            ),
            predicate<RepositoriesState>((state) {
              if (state.isLoading) return false;
              if (state.repositories.length != 1) return false;
              final entry = state.repositories.first;
              return entry.id == 'my-repo-id' &&
                  entry.skills.first.id == 'accessibility-review@2026.28' &&
                  state.actionStatus ==
                      'Successfully installed and linked skill.';
            }),
          ]),
        );

        final linkPath = p.join(
          testRepoPath,
          '.agents',
          'skills',
          'accessibility-review',
        );
        expect(await Link(linkPath).exists(), isTrue);

        final installedSkill = skillsApi.readSkill(
          'accessibility-review@2026.28',
        );
        expect(installedSkill, isNotNull);
        expect(installedSkill!.projects.first['id'], 'my-repo-id');
      },
    );

    test(
      'RepositoryUnlinkSkillRequested removes database association, deletes symlink and cleans up directories',
      () async {
        // Setup initial linked skill
        final skill = Skill(
          id: 'accessibility-review@2026.28',
          owner: 'owner',
          repo: 'repo',
          version: '2026.28',
          installCommand: 'cmd',
          updateAvailable: false,
          inJsonProjects: json.encode({
            'projects': [
              {'id': 'my-repo-id', 'name': 'My Repo', 'path': testRepoPath},
            ],
          }),
        );
        skillsApi.writeSkill(skill);

        // Create physical symlink to delete
        final linkPath = p.join(
          testRepoPath,
          '.agents',
          'skills',
          'accessibility-review',
        );
        await Directory(p.dirname(linkPath)).create(recursive: true);
        await Link(
          linkPath,
        ).create(testRepoPath); // Target doesn't matter for deletion test

        repositoriesBloc.add(const RepositoriesStarted());
        await repositoriesBloc.stream.firstWhere((state) => !state.isLoading);

        repositoriesBloc.add(
          RepositoryUnlinkSkillRequested(
            repositoryId: 'my-repo-id',
            repositoryPath: testRepoPath,
            skillId: 'accessibility-review@2026.28',
          ),
        );

        await expectLater(
          repositoriesBloc.stream,
          emitsInOrder([
            predicate<RepositoriesState>(
              (state) =>
                  state.isLoading && state.actionStatus == 'Unlinking skill...',
            ),
            predicate<RepositoriesState>((state) {
              if (state.isLoading) return false;
              return state.repositories.length == 1 &&
                  state.repositories.first.skills.isEmpty &&
                  state.actionStatus ==
                      'Successfully unlinked skill and deleted symlink.';
            }),
          ]),
        );

        // Verify the symlink and parent directories are deleted
        expect(await Link(linkPath).exists(), isFalse);
        expect(
          await Directory(p.join(testRepoPath, '.agents')).exists(),
          isFalse,
        );

        // Verify DB is updated
        final updatedSkill = skillsApi.readSkill(
          'accessibility-review@2026.28',
        );
        expect(updatedSkill, isNotNull);
        expect(updatedSkill!.projects, isEmpty);
      },
    );

    test(
      'RepositoryDeleteRequested cleans up all associated symlinks and database records for repo',
      () async {
        // Setup multiple skills linked to the repository
        final skill1 = Skill(
          id: 'accessibility-review@2026.28',
          owner: 'owner',
          repo: 'repo',
          version: '2026.28',
          installCommand: 'cmd',
          updateAvailable: false,
          inJsonProjects: json.encode({
            'projects': [
              {'id': 'my-repo-id', 'name': 'My Repo', 'path': testRepoPath},
            ],
          }),
        );
        final skill2 = Skill(
          id: 'flutter-add-widget-test@2026.28',
          owner: 'owner',
          repo: 'repo2',
          version: '2026.28',
          installCommand: 'cmd2',
          updateAvailable: false,
          inJsonProjects: json.encode({
            'projects': [
              {'id': 'my-repo-id', 'name': 'My Repo', 'path': testRepoPath},
            ],
          }),
        );
        skillsApi.writeSkill(skill1);
        skillsApi.writeSkill(skill2);

        // Create physical symlinks
        final link1Path = p.join(
          testRepoPath,
          '.agents',
          'skills',
          'accessibility-review',
        );
        final link2Path = p.join(
          testRepoPath,
          '.agents',
          'skills',
          'flutter-add-widget-test',
        );
        await Directory(p.dirname(link1Path)).create(recursive: true);
        await Link(link1Path).create(testRepoPath);
        await Link(link2Path).create(testRepoPath);

        repositoriesBloc.add(const RepositoriesStarted());
        await repositoriesBloc.stream.firstWhere((state) => !state.isLoading);

        repositoriesBloc.add(
          RepositoryDeleteRequested(
            repositoryId: 'my-repo-id',
            repositoryPath: testRepoPath,
          ),
        );

        await expectLater(
          repositoriesBloc.stream,
          emitsInOrder([
            predicate<RepositoriesState>(
              (state) =>
                  state.isLoading &&
                  state.actionStatus == 'Deleting repository...',
            ),
            predicate<RepositoriesState>((state) {
              if (state.isLoading) return false;
              return state.repositories.isEmpty &&
                  state.actionStatus ==
                      'Successfully deleted repository from VibeHub and cleaned up files.';
            }),
          ]),
        );

        // Verify symlinks and parent directories are deleted
        expect(await Link(link1Path).exists(), isFalse);
        expect(await Link(link2Path).exists(), isFalse);
        expect(
          await Directory(p.join(testRepoPath, '.agents')).exists(),
          isFalse,
        );

        // Verify DB records are updated
        expect(
          skillsApi.readSkill('accessibility-review@2026.28')!.projects,
          isEmpty,
        );
        expect(
          skillsApi.readSkill('flutter-add-widget-test@2026.28')!.projects,
          isEmpty,
        );
      },
    );

    test(
      'RepositorySkillLockToggled locks/unlocks a skill and updates list',
      () async {
        repositoriesBloc.add(const RepositoriesStarted());
        await repositoriesBloc.stream.firstWhere((state) => !state.isLoading);

        // Lock skill
        repositoriesBloc.add(
          const RepositorySkillLockToggled(skillId: 'my-locked-skill'),
        );
        await expectLater(
          repositoriesBloc.stream,
          emitsInOrder([
            predicate<RepositoriesState>(
              (state) =>
                  state.isLoading && state.actionStatus == 'Toggling lock...',
            ),
            predicate<RepositoriesState>((state) {
              if (state.isLoading) return false;
              return state.lockedSkillIds.contains('my-locked-skill') &&
                  state.actionStatus ==
                      'Locked skill my-locked-skill from updates.';
            }),
          ]),
        );

        // Unlock skill
        repositoriesBloc.add(
          const RepositorySkillLockToggled(skillId: 'my-locked-skill'),
        );
        await expectLater(
          repositoriesBloc.stream,
          emitsInOrder([
            predicate<RepositoriesState>(
              (state) =>
                  state.isLoading && state.actionStatus == 'Toggling lock...',
            ),
            predicate<RepositoriesState>((state) {
              if (state.isLoading) return false;
              return !state.lockedSkillIds.contains('my-locked-skill') &&
                  state.actionStatus == 'Unlocked skill my-locked-skill.';
            }),
          ]),
        );
      },
    );

    test('installSkill checks lock and fails if locked', () async {
      final skill = Skill(
        id: 'accessibility-review@2026.28',
        owner: 'owner',
        repo: 'repo',
        version: '2026.28',
        installCommand: 'cmd',
        updateAvailable: false,
        inJsonProjects: '{}',
      );

      // Lock the skill
      await skillsLockApi.lockSkill('accessibility-review@2026.28');

      // Attempt to run installSkill
      final result = await installSkill(
        skill,
        skillsApi,
        skillsLockApi: skillsLockApi,
      );
      expect(result, 'error: Skill is locked and cannot be updated.');
    });

    test('RepositoriesSearchQueryChanged updates query in state', () async {
      repositoriesBloc.add(const RepositoriesStarted());
      await repositoriesBloc.stream.firstWhere((state) => !state.isLoading);

      repositoriesBloc.add(const RepositoriesSearchQueryChanged('hello-sandbox'));

      await expectLater(
        repositoriesBloc.stream,
        emits(predicate<RepositoriesState>((state) => state.searchQuery == 'hello-sandbox')),
      );
    });

    test('RepositoryRegisterRequested registers new repository path persistently', () async {
      repositoriesBloc.add(const RepositoriesStarted());
      await repositoriesBloc.stream.firstWhere((state) => !state.isLoading);

      repositoriesBloc.add(RepositoryRegisterRequested(
        path: testRepoPath,
        name: 'My New Sandbox',
      ));

      await expectLater(
        repositoriesBloc.stream,
        emitsInOrder([
          predicate<RepositoriesState>((state) => state.isLoading && state.actionStatus == 'Registering repository...'),
            predicate<RepositoriesState>((state) {
              if (state.isLoading) return false;
              if (state.repositories.length != 1) return false;
              final entry = state.repositories.first;
              return entry.name == 'My New Sandbox' &&
                  entry.path == testRepoPath.replaceAll('\\', '/') &&
                  state.actionStatus == 'Successfully registered repository.';
            }),
        ]),
      );

      // Verify it's persisted in the JSON registry file
      final registered = await repositoriesRegistryApi.getRegisteredRepositories();
      expect(registered, hasLength(1));
      expect(registered.first['name'], 'My New Sandbox');
      expect(registered.first['path'], testRepoPath.replaceAll('\\', '/'));
    });
  });
}
