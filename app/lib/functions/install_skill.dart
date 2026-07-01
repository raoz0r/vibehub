import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:vibehub/api/paths.dart';
import 'package:vibehub/api/skills_api.dart';
import 'package:vibehub/api/skills_lock_api.dart';

class InstallAllLogEntry {
  const InstallAllLogEntry({
    required this.skillId,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.duration,
  });

  final String skillId;
  final String status;
  final DateTime startedAt;
  final DateTime finishedAt;
  final Duration duration;
}

/// Installs a skill at project level inside the versioned folder under `~/.vibehub/catalog/<id>`.
/// Executes the skill's installCommand, extracts the files from `.agents/skills/<name>` to the root,
/// deletes the `.agents` directory, and registers the skill in the local SQLite database.
Future<String> installSkill(
  Skill skill,
  SkillsApi skillsApi, {
  SkillsLockApi? skillsLockApi,
}) async {
  final lockApi = skillsLockApi ?? SkillsLockApi();
  if (await lockApi.isLocked(skill.id)) {
    return 'error: Skill is locked and cannot be updated.';
  }

  final startedAt = DateTime.now();
  final totalStopwatch = Stopwatch()..start();

  if (skill.installCommand.startsWith('install ')) {
    skillsApi.writeSkill(_skillWithDescription(skill, skill.description));
    totalStopwatch.stop();
    return 'ok';
  }

  try {
    final setupStopwatch = Stopwatch()..start();
    final catalogDir = Directory(
      p.join(VibeHubPaths.dataDir, 'catalog', skill.id.replaceAll('/', '_')),
    );
    if (!await catalogDir.exists()) {
      await catalogDir.create(recursive: true);
    }
    setupStopwatch.stop();

    final parts = skill.installCommand.split(' ');
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'error: Install command is empty.';
    }

    final executable = parts.first;
    final List<String> arguments = [...parts.sublist(1), '-a', '*', '-y'];

    final processStopwatch = Stopwatch()..start();
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: catalogDir.path,
      runInShell: true,
    );
    processStopwatch.stop();

    final logDir = Directory(p.join(VibeHubPaths.logDir, 'install'));
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    final logFile = File(
      p.join(logDir.path, '${skill.id.replaceAll('/', '_')}.log'),
    );
    var copyCleanupDuration = Duration.zero;
    var dbWriteDuration = Duration.zero;

    if (result.exitCode == 0) {
      final separator = skill.id.lastIndexOf('@');
      final skillName = separator > 0
          ? skill.id.substring(0, separator)
          : skill.id;
      final nameSeparator = skillName.lastIndexOf('/');
      final skillShortName = nameSeparator >= 0
          ? skillName.substring(nameSeparator + 1)
          : skillName;

      final copyCleanupStopwatch = Stopwatch()..start();
      bool copied = false;
      for (final folderName in ['.agents', 'agent']) {
        // Try short name first (e.g. .agents/skills/find-release)
        var sourceDir = Directory(
          p.join(catalogDir.path, folderName, 'skills', skillShortName),
        );
        // Fallback to full namespace path (e.g. .agents/skills/flutter/flutter/find-release)
        if (!await sourceDir.exists()) {
          sourceDir = Directory(
            p.join(catalogDir.path, folderName, 'skills', skillName),
          );
        }

        if (await sourceDir.exists() && !copied) {
          await _copyDirectory(sourceDir, catalogDir);
          copied = true;
        }
      }

      // Clean up all temporary folders to ensure a completely flat structure
      for (final folderName in ['.agents', 'agent']) {
        final dirToClean = Directory(p.join(catalogDir.path, folderName));
        if (await dirToClean.exists()) {
          await dirToClean.delete(recursive: true);
        }
      }
      copyCleanupStopwatch.stop();
      copyCleanupDuration = copyCleanupStopwatch.elapsed;

      final dbStopwatch = Stopwatch()..start();
      final description = await readSkillDescription(catalogDir);
      skillsApi.writeSkill(_skillWithDescription(skill, description));
      dbStopwatch.stop();
      dbWriteDuration = dbStopwatch.elapsed;

      totalStopwatch.stop();
      await logFile.writeAsString(
        formatInstallSkillLog(
          command: '$executable ${arguments.join(' ')}',
          startedAt: startedAt,
          finishedAt: DateTime.now(),
          exitCode: result.exitCode,
          totalDuration: totalStopwatch.elapsed,
          setupDuration: setupStopwatch.elapsed,
          processDuration: processStopwatch.elapsed,
          copyCleanupDuration: copyCleanupDuration,
          dbWriteDuration: dbWriteDuration,
          stdout: result.stdout,
          stderr: result.stderr,
        ),
      );
      return 'ok';
    } else {
      totalStopwatch.stop();
      await logFile.writeAsString(
        formatInstallSkillLog(
          command: '$executable ${arguments.join(' ')}',
          startedAt: startedAt,
          finishedAt: DateTime.now(),
          exitCode: result.exitCode,
          totalDuration: totalStopwatch.elapsed,
          setupDuration: setupStopwatch.elapsed,
          processDuration: processStopwatch.elapsed,
          copyCleanupDuration: copyCleanupDuration,
          dbWriteDuration: dbWriteDuration,
          stdout: result.stdout,
          stderr: result.stderr,
        ),
      );
      return 'error: Command failed with exit code ${result.exitCode}. Stderr: ${result.stderr}';
    }
  } catch (e) {
    return 'error: $e';
  }
}

Future<String> readSkillDescription(Directory skillDir) async {
  final file = File(p.join(skillDir.path, 'SKILL.md'));
  if (!await file.exists()) {
    return '';
  }

  return parseSkillDescription(await file.readAsString());
}

String parseSkillDescription(String content) {
  final lines = content.replaceAll('\r\n', '\n').split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') {
    return '';
  }

  for (var index = 1; index < lines.length; index += 1) {
    final line = lines[index].trim();
    if (line == '---') {
      return '';
    }
    final separator = line.indexOf(':');
    if (separator <= 0) {
      continue;
    }
    if (line.substring(0, separator).trim() != 'description') {
      continue;
    }

    final rawValue = line.substring(separator + 1).trim();
    if (rawValue.length >= 2) {
      final quote = rawValue[0];
      if ((quote == '"' || quote == "'") && rawValue.endsWith(quote)) {
        return rawValue.substring(1, rawValue.length - 1).trim();
      }
    }
    return rawValue;
  }

  return '';
}

Skill _skillWithDescription(Skill skill, String description) {
  return Skill(
    id: skill.id,
    owner: skill.owner,
    repo: skill.repo,
    version: skill.version,
    installCommand: skill.installCommand,
    updateAvailable: skill.updateAvailable,
    inJsonProjects: skill.inJsonProjects,
    metadata: skill.metadata,
    description: description,
  );
}

String formatInstallSkillLog({
  required String command,
  required DateTime startedAt,
  required DateTime finishedAt,
  required int exitCode,
  required Duration totalDuration,
  required Duration setupDuration,
  required Duration processDuration,
  required Duration copyCleanupDuration,
  required Duration dbWriteDuration,
  required Object stdout,
  required Object stderr,
}) {
  return 'Command: $command\n'
      'Started At: ${startedAt.toIso8601String()}\n'
      'Finished At: ${finishedAt.toIso8601String()}\n'
      'Exit Code: $exitCode\n'
      'Durations:\n'
      '  Total: ${_formatDuration(totalDuration)}\n'
      '  Catalog Setup: ${_formatDuration(setupDuration)}\n'
      '  Process Run: ${_formatDuration(processDuration)}\n'
      '  Copy/Cleanup: ${_formatDuration(copyCleanupDuration)}\n'
      '  DB Write: ${_formatDuration(dbWriteDuration)}\n'
      'STDOUT:\n$stdout\n'
      'STDERR:\n$stderr\n';
}

Future<String> writeInstallAllLog({
  required DateTime startedAt,
  required DateTime finishedAt,
  required Duration totalDuration,
  required List<InstallAllLogEntry> entries,
}) async {
  final logDir = Directory(p.join(VibeHubPaths.logDir, 'install'));
  if (!await logDir.exists()) {
    await logDir.create(recursive: true);
  }

  final timestamp = startedAt.toIso8601String().replaceAll(
    RegExp(r'[:.]'),
    '-',
  );
  final logFile = File(p.join(logDir.path, 'install_all_$timestamp.log'));
  await logFile.writeAsString(
    formatInstallAllLog(
      startedAt: startedAt,
      finishedAt: finishedAt,
      totalDuration: totalDuration,
      entries: entries,
    ),
  );
  return logFile.path;
}

String formatInstallAllLog({
  required DateTime startedAt,
  required DateTime finishedAt,
  required Duration totalDuration,
  required List<InstallAllLogEntry> entries,
}) {
  final buffer = StringBuffer()
    ..writeln('Install All Summary')
    ..writeln('Started At: ${startedAt.toIso8601String()}')
    ..writeln('Finished At: ${finishedAt.toIso8601String()}')
    ..writeln('Total Duration: ${_formatDuration(totalDuration)}')
    ..writeln('Skill Count: ${entries.length}')
    ..writeln()
    ..writeln('Skills:');

  for (var index = 0; index < entries.length; index += 1) {
    final entry = entries[index];
    buffer
      ..writeln(
        '${index + 1}. ${entry.skillId} - ${entry.status} - ${_formatDuration(entry.duration)}',
      )
      ..writeln('   Started At: ${entry.startedAt.toIso8601String()}')
      ..writeln('   Finished At: ${entry.finishedAt.toIso8601String()}');
  }

  return buffer.toString();
}

String _formatDuration(Duration duration) {
  final milliseconds = duration.inMilliseconds;
  if (milliseconds < 1000) {
    return '${milliseconds}ms';
  }

  final seconds = milliseconds / 1000;
  return '${seconds.toStringAsFixed(2)}s';
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await for (var entity in source.list(recursive: true)) {
    if (entity is Directory) {
      final newDirectory = Directory(
        p.join(
          destination.absolute.path,
          p.relative(entity.path, from: source.path),
        ),
      );
      await newDirectory.create(recursive: true);
    } else if (entity is File) {
      final newFile = File(
        p.join(
          destination.absolute.path,
          p.relative(entity.path, from: source.path),
        ),
      );
      await newFile.parent.create(recursive: true);
      await entity.copy(newFile.path);
    }
  }
}
