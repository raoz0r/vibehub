import 'package:flutter_test/flutter_test.dart';
import 'package:vibehub/functions/install_skill.dart';

void main() {
  group('install skill logging', () {
    test('formats phase timings for a single install log', () {
      final startedAt = DateTime.utc(2026, 6, 27, 10);
      final finishedAt = DateTime.utc(2026, 6, 27, 10, 1);

      final log = formatInstallSkillLog(
        command: 'npx skills add repo --skill alpha -a * -y',
        startedAt: startedAt,
        finishedAt: finishedAt,
        exitCode: 0,
        totalDuration: const Duration(seconds: 60),
        setupDuration: const Duration(milliseconds: 12),
        processDuration: const Duration(seconds: 58),
        copyCleanupDuration: const Duration(milliseconds: 300),
        dbWriteDuration: const Duration(milliseconds: 4),
        stdout: 'done',
        stderr: '',
      );

      expect(
        log,
        contains('Command: npx skills add repo --skill alpha -a * -y'),
      );
      expect(log, contains('Started At: 2026-06-27T10:00:00.000Z'));
      expect(log, contains('Total: 60.00s'));
      expect(log, contains('Catalog Setup: 12ms'));
      expect(log, contains('Process Run: 58.00s'));
      expect(log, contains('Copy/Cleanup: 300ms'));
      expect(log, contains('DB Write: 4ms'));
    });

    test('formats install all summary entries from memory', () {
      final startedAt = DateTime.utc(2026, 6, 27, 10);
      final finishedAt = DateTime.utc(2026, 6, 27, 10, 2);

      final log = formatInstallAllLog(
        startedAt: startedAt,
        finishedAt: finishedAt,
        totalDuration: const Duration(minutes: 2),
        entries: [
          InstallAllLogEntry(
            skillId: 'alpha@2026.27',
            status: 'Install status: ok',
            startedAt: startedAt,
            finishedAt: DateTime.utc(2026, 6, 27, 10, 1),
            duration: const Duration(minutes: 1),
          ),
          InstallAllLogEntry(
            skillId: 'beta@2026.27',
            status: 'Install status: ok',
            startedAt: DateTime.utc(2026, 6, 27, 10, 1),
            finishedAt: finishedAt,
            duration: const Duration(minutes: 1),
          ),
        ],
      );

      expect(log, contains('Install All Summary'));
      expect(log, contains('Total Duration: 120.00s'));
      expect(log, contains('Skill Count: 2'));
      expect(log, contains('1. alpha@2026.27 - Install status: ok - 60.00s'));
      expect(log, contains('2. beta@2026.27 - Install status: ok - 60.00s'));
    });

    test('parses description from SKILL.md metadata', () {
      final description = parseSkillDescription('''---
name: alpha
description: "Helps with alpha project workflows."
---

# Alpha
''');

      expect(description, 'Helps with alpha project workflows.');
    });
  });
}
