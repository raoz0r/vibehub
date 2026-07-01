import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'paths.dart';

class SkillsLockApi {
  SkillsLockApi({String? lockFilePath}) : _customLockFilePath = lockFilePath;

  final String? _customLockFilePath;

  String get _lockFilePath => _customLockFilePath ?? p.join(VibeHubPaths.configDir, 'locked_skills.json');

  /// Reads the set of locked skill IDs/names from the lock file.
  Future<Set<String>> getLockedSkills() async {
    final file = File(_lockFilePath);
    if (!await file.exists()) {
      return {};
    }
    try {
      final content = await file.readAsString();
      final decoded = json.decode(content);
      if (decoded is Map && decoded['locked_skills'] is List) {
        return Set<String>.from(decoded['locked_skills'] as List);
      }
    } catch (_) {}
    return {};
  }

  /// Locks a skill by adding its ID/name to the lock file.
  Future<void> lockSkill(String skillId) async {
    final file = File(_lockFilePath);
    await file.parent.create(recursive: true);
    final locks = await getLockedSkills();
    if (locks.add(skillId)) {
      await file.writeAsString(json.encode({'locked_skills': locks.toList()}));
    }
  }

  /// Unlocks a skill by removing its ID/name from the lock file.
  Future<void> unlockSkill(String skillId) async {
    final file = File(_lockFilePath);
    final locks = await getLockedSkills();
    if (locks.remove(skillId)) {
      await file.parent.create(recursive: true);
      await file.writeAsString(json.encode({'locked_skills': locks.toList()}));
    }
  }

  /// Checks if a skill is currently locked.
  /// This checks both the full skill ID (e.g. `owner/repo/name@version`) and the parent skill ID (e.g. `owner/repo/name`).
  Future<bool> isLocked(String skillId) async {
    final locks = await getLockedSkills();
    if (locks.contains(skillId)) {
      return true;
    }
    // Check by name/parent skill ID (without version)
    final separator = skillId.lastIndexOf('@');
    if (separator > 0) {
      final parentId = skillId.substring(0, separator);
      if (locks.contains(parentId)) {
        return true;
      }
    }
    return false;
  }
}
