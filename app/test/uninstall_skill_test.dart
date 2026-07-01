import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vibehub/vibehub.dart';
import 'package:vibehub/functions/uninstall_skill.dart';

void main() {
  group('uninstallSkill Tests', () {
    late String testDbPath;
    late File testDbFile;
    late VibeHubDatabase database;
    late SkillsApi skillsApi;

    setUp(() {
      final tempDir = Directory.systemTemp.createTempSync('uninstall_skill_test');
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

    test('uninstallSkill returns warning when skill is used in a project', () async {
      final skill = Skill(
        id: 'brand-guidelines@2026.26',
        owner: 'google-dm',
        repo: 'brand-guidelines',
        version: '2026.26',
        installCommand: 'install cmd',
        updateAvailable: false,
        inJsonProjects: json.encode({
          'projects': [
            {
              'id': 'proj-1',
              'name': 'My Super Project',
              'path': 'E:/projects/super'
            }
          ]
        }),
      );

      // Write skill and associate it with a project
      skillsApi.writeSkill(skill);

      // Attempt to uninstall
      final status = await uninstallSkill(skill, skillsApi);

      expect(status, contains('warning: Skill cannot be uninstalled because it is currently used in project(s): My Super Project'));
      
      // Verify skill was NOT deleted from database
      expect(skillsApi.readSkill(skill.id), isNotNull);
    });

    test('uninstallSkill successfully uninstalls when not used in any project', () async {
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

      final status = await uninstallSkill(skill, skillsApi);

      expect(status, equals('ok'));
      
      // Verify skill WAS deleted from database
      expect(skillsApi.readSkill(skill.id), isNull);
    });
  });
}
