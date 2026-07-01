import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vibehub/vibehub.dart';

void main() {
  group('SkillsApi Tests', () {
    late String testDbPath;
    late File testDbFile;
    late VibeHubDatabase database;
    late SkillsApi skillsApi;

    setUp(() {
      final tempDir = Directory.systemTemp.createTempSync('skills_api_test');
      testDbPath = p.join(tempDir.path, 'database');
      testDbFile = File(testDbPath);

      database = VibeHubDatabase(databasePath: testDbPath);
      skillsApi = SkillsApi(database);
    });

    tearDown(() {
      database.close();
      final parentDir = testDbFile.parent;
      if (parentDir.existsSync()) {
        try {
          parentDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('writeSkill inserts a new skill and readSkill retrieves it', () {
      final skill = Skill(
        id: 'applying-brand-guidelines@2026.26',
        owner: 'google-dm',
        repo: 'brand-guidelines',
        version: '2026.26',
        installCommand: 'flutter pub run brand_guidelines:install',
        updateAvailable: true,
        inJsonProjects: json.encode({
          'projects': [
            {
              'id': 'my-project-id',
              'name': 'My Beautiful Project',
              'path': 'E:/projects/my-project',
            },
          ],
        }),
      );

      // Write skill
      skillsApi.writeSkill(skill);

      // Read skill
      final fetched = skillsApi.readSkill(skill.id);
      expect(fetched, isNotNull);
      expect(fetched!.id, skill.id);
      expect(fetched.owner, skill.owner);
      expect(fetched.repo, skill.repo);
      expect(fetched.version, skill.version);
      expect(fetched.installCommand, skill.installCommand);
      expect(fetched.updateAvailable, skill.updateAvailable);
      expect(fetched.inJsonProjects, skill.inJsonProjects);
    });

    test('writeSkill persists skill metadata', () {
      final skill = Skill(
        id: 'metadata-skill@2026.26',
        owner: 'owner',
        repo: 'repo',
        version: '2026.26',
        installCommand: 'install metadata-skill',
        updateAvailable: false,
        inJsonProjects: '{}',
        metadata: {'description': 'Metadata-backed skill description.'},
      );

      skillsApi.writeSkill(skill);

      final fetched = skillsApi.readSkill(skill.id);
      expect(fetched, isNotNull);
      expect(
        fetched!.metadata['description'],
        'Metadata-backed skill description.',
      );
    });

    test('writeSkill persists skill description', () {
      final skill = Skill(
        id: 'described-skill@2026.07.01',
        owner: 'owner',
        repo: 'repo',
        version: '2026.07.01',
        installCommand: 'install described-skill',
        updateAvailable: false,
        inJsonProjects: '{}',
        description: 'Description saved from SKILL.md.',
      );

      skillsApi.writeSkill(skill);

      final fetched = skillsApi.readSkill(skill.id);
      expect(fetched, isNotNull);
      expect(fetched!.description, 'Description saved from SKILL.md.');
    });

    test('writeSkill updates an existing skill (upsert behavior)', () {
      final skill = Skill(
        id: 'brand-guidelines@2026.26',
        owner: 'google-dm',
        repo: 'brand-guidelines',
        version: '2026.26',
        installCommand: 'install cmd',
        updateAvailable: false,
        inJsonProjects: '{}',
      );

      skillsApi.writeSkill(skill);

      final updatedSkill = Skill(
        id: 'brand-guidelines@2026.26',
        owner: 'google-dm-updated',
        repo: 'brand-guidelines-updated',
        version: '2026.27',
        installCommand: 'install cmd updated',
        updateAvailable: true,
        inJsonProjects: json.encode({
          'projects': [
            {
              'id': 'my-project-id',
              'name': 'My Beautiful Project',
              'path': 'E:/projects/my-project',
            },
          ],
        }),
      );

      skillsApi.writeSkill(updatedSkill);

      final fetched = skillsApi.readSkill(skill.id);
      expect(fetched, isNotNull);
      expect(fetched!.owner, 'google-dm-updated');
      expect(fetched.repo, 'brand-guidelines-updated');
      expect(fetched.version, '2026.27');
      expect(fetched.installCommand, 'install cmd updated');
      expect(fetched.updateAvailable, isTrue);
      expect(fetched.inJsonProjects, updatedSkill.inJsonProjects);
    });

    test('readAllSkills returns all skills in the database', () {
      expect(skillsApi.readAllSkills(), isEmpty);

      final skill1 = Skill(
        id: 'skill-1@2026.01',
        owner: 'owner-1',
        repo: 'repo-1',
        version: '2026.01',
        installCommand: 'cmd-1',
        updateAvailable: false,
        inJsonProjects: '{}',
      );

      final skill2 = Skill(
        id: 'skill-2@2026.02',
        owner: 'owner-2',
        repo: 'repo-2',
        version: '2026.02',
        installCommand: 'cmd-2',
        updateAvailable: true,
        inJsonProjects: '{}',
      );

      skillsApi.writeSkill(skill1);
      skillsApi.writeSkill(skill2);

      final all = skillsApi.readAllSkills();
      expect(all, hasLength(2));
      expect(all.any((s) => s.id == 'skill-1@2026.01'), isTrue);
      expect(all.any((s) => s.id == 'skill-2@2026.02'), isTrue);
    });

    test('filter queries (by owner, repo, project) and projects getter', () {
      final skill1 = Skill(
        id: 'brand-guidelines@2026.26',
        owner: 'google-dm',
        repo: 'brand-guidelines',
        version: '2026.26',
        installCommand: 'cmd',
        updateAvailable: false,
        inJsonProjects: json.encode({
          'projects': [
            {'id': 'proj-a', 'name': 'Project A', 'path': '/path/a'},
            {'id': 'proj-b', 'name': 'Project B', 'path': '/path/b'},
          ],
        }),
      );

      final skill2 = Skill(
        id: 'coding-assistant@2026.01',
        owner: 'google-dm',
        repo: 'coding-assistant',
        version: '2026.01',
        installCommand: 'cmd2',
        updateAvailable: true,
        inJsonProjects: json.encode({
          'projects': [
            {'id': 'proj-b', 'name': 'Project B', 'path': '/path/b'},
          ],
        }),
      );

      final skill3 = Skill(
        id: 'other-skill@2026.01',
        owner: 'other-owner',
        repo: 'brand-guidelines', // same repo name but different owner/id
        version: '2026.01',
        installCommand: 'cmd3',
        updateAvailable: false,
        inJsonProjects: '{}',
      );

      skillsApi.writeSkill(skill1);
      skillsApi.writeSkill(skill2);
      skillsApi.writeSkill(skill3);

      // Verify projects getter
      final fetched1 = skillsApi.readSkill(skill1.id)!;
      expect(fetched1.projects, hasLength(2));
      expect(fetched1.projects[0]['id'], 'proj-a');
      expect(fetched1.projects[1]['id'], 'proj-b');

      final fetched3 = skillsApi.readSkill(skill3.id)!;
      expect(fetched3.projects, isEmpty);

      // Query by owner
      final googleDmSkills = skillsApi.readSkillsByOwner('google-dm');
      expect(googleDmSkills, hasLength(2));
      expect(googleDmSkills.any((s) => s.id == skill1.id), isTrue);
      expect(googleDmSkills.any((s) => s.id == skill2.id), isTrue);

      final otherSkills = skillsApi.readSkillsByOwner('other-owner');
      expect(otherSkills, hasLength(1));
      expect(otherSkills.first.id, skill3.id);

      // Query by repo
      final brandGuidelineSkills = skillsApi.readSkillsByRepo(
        'brand-guidelines',
      );
      expect(brandGuidelineSkills, hasLength(2));
      expect(brandGuidelineSkills.any((s) => s.id == skill1.id), isTrue);
      expect(brandGuidelineSkills.any((s) => s.id == skill3.id), isTrue);

      // Query by project
      final projectBSkills = skillsApi.readSkillsByProject('proj-b');
      expect(projectBSkills, hasLength(2));
      expect(projectBSkills.any((s) => s.id == skill1.id), isTrue);
      expect(projectBSkills.any((s) => s.id == skill2.id), isTrue);

      final projectASkills = skillsApi.readSkillsByProject('proj-a');
      expect(projectASkills, hasLength(1));
      expect(projectASkills.first.id, skill1.id);
    });

    test(
      'deleteSkill deletes a skill by ID and returns correct boolean status',
      () {
        final skill = Skill(
          id: 'temp-skill@2026.01',
          owner: 'owner',
          repo: 'repo',
          version: '2026.01',
          installCommand: 'cmd',
          updateAvailable: false,
          inJsonProjects: '{}',
        );

        skillsApi.writeSkill(skill);
        expect(skillsApi.readSkill(skill.id), isNotNull);

        // Delete existing
        final deleted = skillsApi.deleteSkill(skill.id);
        expect(deleted, isTrue);
        expect(skillsApi.readSkill(skill.id), isNull);

        // Delete non-existing
        final deletedAgain = skillsApi.deleteSkill(skill.id);
        expect(deletedAgain, isFalse);
      },
    );
  });
}
