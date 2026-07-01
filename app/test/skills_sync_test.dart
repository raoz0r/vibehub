import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibehub/api/skills_sync.dart';

void main() {
  group('SkillsSyncApi Tests', () {
    late String testFilePath;
    late File testFile;

    setUp(() {
      testFilePath = SkillsSyncApi.getLocalFilePath();
      testFile = File(testFilePath);
      // Clean up before test runs
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
    });

    tearDown(() {
      // Clean up after test runs
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
    });

    test('Status reports correct state when file does not exist', () {
      final status = SkillsSyncApi.checkStatus();
      expect(status.exists, isFalse);
      expect(status.needsUpdate, isTrue);
      expect(status.path, testFilePath);
    });

    test('Sync triggers download when file is missing', () async {
      // 1. Verify missing
      expect(testFile.existsSync(), isFalse);

      // 2. Perform sync
      final result = await SkillsSyncApi.sync();
      expect(result.success, isTrue);
      expect(result.downloaded, isTrue);
      expect(testFile.existsSync(), isTrue);

      // 3. Verify content was written
      final content = testFile.readAsStringSync();
      expect(content, contains('skills'));
    });

    test('Sync skips download when file is fresh (< 7 days)', () async {
      // 1. Download it first
      final result1 = await SkillsSyncApi.sync();
      expect(result1.downloaded, isTrue);

      // 2. Run sync again
      final result2 = await SkillsSyncApi.sync();
      expect(result2.success, isTrue);
      expect(result2.downloaded, isFalse); // Should skip downloading
      expect(result2.reason, contains('File is up to date'));
    });

    test('Sync triggers download when file is older than 7 days', () async {
      // 1. Download it first
      final result1 = await SkillsSyncApi.sync();
      expect(result1.downloaded, isTrue);

      // 2. Set file date to 8 days ago
      final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
      testFile.setLastModifiedSync(eightDaysAgo);

      // 3. Check status
      final status = SkillsSyncApi.checkStatus();
      expect(status.exists, isTrue);
      expect(status.needsUpdate, isTrue);
      expect(status.ageDays, isNotNull);
      expect(status.ageDays!, greaterThanOrEqualTo(8.0));

      // 4. Run sync again
      final result2 = await SkillsSyncApi.sync();
      expect(result2.success, isTrue);
      expect(result2.downloaded, isTrue); // Should download again
      expect(result2.reason, contains('File is older than 7 days'));
    });
  });
}
