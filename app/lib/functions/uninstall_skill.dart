import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:vibehub/api/paths.dart';
import 'package:vibehub/api/skills_api.dart';

/// Uninstalls a skill by deleting its directory under `~/.vibehub/catalog/<id>`
/// and deleting its record from the SQLite database.
Future<String> uninstallSkill(Skill skill, SkillsApi skillsApi) async {
  // Check if the skill is currently associated with any projects
  final dbSkill = skillsApi.readSkill(skill.id);
  if (dbSkill != null && dbSkill.projects.isNotEmpty) {
    final projectNames = dbSkill.projects.map((p) => p['name'] as String).join(', ');
    return 'warning: Skill cannot be uninstalled because it is currently used in project(s): $projectNames';
  }

  if (skill.installCommand.startsWith('install ')) {
    skillsApi.deleteSkill(skill.id);
    return 'ok';
  }

  try {
    final catalogDir = Directory(p.join(VibeHubPaths.dataDir, 'catalog', skill.id.replaceAll('/', '_')));
    if (await catalogDir.exists()) {
      await catalogDir.delete(recursive: true);
    }

    // Delete installation log if it exists
    final logFile = File(
      p.join(VibeHubPaths.logDir, 'install', '${skill.id.replaceAll('/', '_')}.log'),
    );
    if (await logFile.exists()) {
      await logFile.delete();
    }

    // Delete skill record from the database
    skillsApi.deleteSkill(skill.id);
    return 'ok';
  } catch (e) {
    return 'error: $e';
  }
}
