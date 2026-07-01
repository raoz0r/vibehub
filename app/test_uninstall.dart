import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:vibehub/api/paths.dart';
import 'package:vibehub/api/skills_api.dart';
import 'package:vibehub/functions/uninstall_skill.dart';

void main() async {
  final dbPath = p.join(Directory.systemTemp.path, 'vibehub_test_install.db');
  final db = VibeHubDatabase(databasePath: dbPath);
  final api = SkillsApi(db);

  final skill = Skill(
    id: 'anthropics/anthropic-cookbook/analyzing-financial-statements@2026.26',
    owner: 'anthropics',
    repo: 'anthropic-cookbook',
    version: '2026.26',
    installCommand: 'npx skills add https://github.com/anthropics/anthropic-cookbook --skill analyzing-financial-statements',
    updateAvailable: false,
    inJsonProjects: '{}',
  );

  print('--- Starting Skill Uninstallation ---');
  final result = await uninstallSkill(skill, api);
  print('Uninstall Output Status: $result');

  // Verify paths
  final expectedDirName = 'anthropics_anthropic-cookbook_analyzing-financial-statements@2026.26';
  final expectedDir = Directory(p.join(VibeHubPaths.dataDir, 'catalog', expectedDirName));
  print('Flat Directory Exists: ${await expectedDir.exists()}');

  db.close();
}
