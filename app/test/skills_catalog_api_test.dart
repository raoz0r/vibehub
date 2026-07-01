import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vibehub/api/skills_catalog_api.dart';

void main() {
  group('SkillsCatalogApi', () {
    late Directory tempDirectory;
    late SkillsCatalogApi api;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync(
        'skills_catalog_api_test',
      );
      api = SkillsCatalogApi();
    });

    tearDown(() {
      api.close();
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('replaceCatalogSkills creates schema and reads rows from memory', () {
      api.replaceCatalogSkills(const [
        CatalogSkill(
          name: 'alpha',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.27',
          sha: '9aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-a/repo-a',
          installCommand: 'install alpha',
        ),
      ]);

      final skills = api.readAllCatalogSkills();

      expect(skills, hasLength(1));
      expect(skills.first.name, 'alpha');
      expect(skills.first.owner, 'owner-a');
      expect(skills.first.repoUrl, 'https://github.com/owner-a/repo-a');
    });

    test('hydrateFromFile loads valid catalog JSON once into memory', () async {
      final catalogPath = p.join(tempDirectory.path, 'skills.json');
      File(catalogPath).writeAsStringSync(
        jsonEncode({
          'skills': [
            {
              'name': 'alpha',
              'owner': 'owner-a',
              'repo': 'repo-a',
              'version': '2026.27',
              'sha': '9aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
              'repoUrl': 'https://github.com/owner-a/repo-a',
              'installCommand': 'install alpha',
            },
          ],
        }),
      );

      await api.hydrateFromFile(catalogPath);
      File(catalogPath).deleteSync();

      final skills = api.readAllCatalogSkills();
      expect(skills, hasLength(1));
      expect(skills.first.name, 'alpha');
    });

    test('parseCatalogSkills preserves metadata description', () {
      final skills = parseCatalogSkills(
        jsonEncode({
          'skills': [
            {
              'name': 'alpha',
              'owner': 'owner-a',
              'repo': 'repo-a',
              'version': '2026.27',
              'metadata': {'description': 'Use this for alpha work.'},
            },
          ],
        }),
      );

      expect(skills, hasLength(1));
      expect(skills.first.metadata['description'], 'Use this for alpha work.');
    });

    test('hydrateFromFile ignores invalid skill rows consistently', () async {
      final catalogPath = p.join(tempDirectory.path, 'skills.json');
      File(catalogPath).writeAsStringSync(
        jsonEncode({
          'skills': [
            {
              'name': '',
              'owner': 'owner-a',
              'repo': 'repo-a',
              'version': '2026.27',
            },
            {
              'name': 'beta',
              'owner': 'owner-a',
              'repo': 'repo-a',
              'version': '2026.26',
              'sha': '0aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
              'repoUrl': 'https://github.com/owner-a/repo-a',
              'installCommand': 'install beta',
            },
          ],
        }),
      );

      await api.hydrateFromFile(catalogPath);

      final skills = api.readAllCatalogSkills();
      expect(skills, hasLength(1));
      expect(skills.first.name, 'beta');
    });

    test('replaceCatalogSkills replaces previous in-memory rows', () {
      api.replaceCatalogSkills(const [
        CatalogSkill(
          name: 'alpha',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.27',
          sha: '9aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-a/repo-a',
          installCommand: 'install alpha',
        ),
      ]);

      api.replaceCatalogSkills(const [
        CatalogSkill(
          name: 'beta',
          owner: 'owner-b',
          repo: 'repo-b',
          version: '2026.28',
          sha: '0aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-b/repo-b',
          installCommand: 'install beta',
        ),
      ]);

      final skills = api.readAllCatalogSkills();
      expect(skills, hasLength(1));
      expect(skills.first.name, 'beta');
    });

    test('hydrateFromFile stores load errors for catalog reads', () async {
      await api.hydrateFromFile(p.join(tempDirectory.path, 'missing.json'));

      expect(api.readAllCatalogSkills, throwsStateError);
    });

    test('close releases memory database and can reopen empty', () {
      api.replaceCatalogSkills(const [
        CatalogSkill(
          name: 'alpha',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.27',
          sha: '9aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-a/repo-a',
          installCommand: 'install alpha',
        ),
      ]);

      api.close();

      expect(api.readAllCatalogSkills(), isEmpty);
    });
  });
}
