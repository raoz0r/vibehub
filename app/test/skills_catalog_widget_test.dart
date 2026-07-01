import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vibehub/api/skills_api.dart';
import 'package:vibehub/api/skills_catalog_api.dart';
import 'package:vibehub/ui/widgets/skills_catalog_widget.dart';

void main() {
  group('Skills catalog preprocessing', () {
    test('parses catalog skills and creates stable identity values', () {
      final skills = parseCatalogSkills(
        jsonEncode({
          'skills': [
            {
              'name': 'alpha',
              'owner': 'owner-a',
              'repo': 'repo-a',
              'version': '2026.27',
              'sha': '9aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
              'repoUrl': 'https://github.com/owner-a/repo-a',
              'installCommand': 'npx skills add alpha',
            },
          ],
        }),
      );

      expect(skills, hasLength(1));
      expect(skills.first.name, 'alpha');
      expect(skills.first.sha, '9aa7c1f3b2182a88bd96748f1798a5d0332a8c76');
      expect(skills.first.repoUrl, 'https://github.com/owner-a/repo-a');
      expect(
        skillIdFor('owner-a', 'repo-a', 'alpha', '2026.27'),
        'owner-a/repo-a/alpha@2026.27',
      );
      expect(
        skillComparisonKey(owner: 'owner-a', repo: 'repo-a', name: 'alpha'),
        'owner-a/repo-a/alpha',
      );
      expect(skillNameFromVersionedId('alpha@2026.27', '2026.27'), 'alpha');
    });

    test('precomputes installed, outdated, and not installed statuses', () {
      const catalogSkills = [
        CatalogSkill(
          name: 'alpha',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.27',
          sha: '9aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-a/repo-a',
          installCommand: 'install alpha',
        ),
        CatalogSkill(
          name: 'beta',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.26',
          sha: '0aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-a/repo-a',
          installCommand: 'install beta',
        ),
        CatalogSkill(
          name: 'gamma',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.26',
          sha: '1aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-a/repo-a',
          installCommand: 'install gamma',
        ),
        CatalogSkill(
          name: 'delta',
          owner: 'owner-b',
          repo: 'repo-b',
          version: '2026.26',
          sha: '2aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-b/repo-b',
          installCommand: 'install delta',
        ),
      ];
      final installedSkills = [
        Skill(
          id: 'owner-a/repo-a/alpha@2026.26',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.26',
          installCommand: 'install alpha old',
          updateAvailable: false,
          inJsonProjects: '{}',
        ),
        Skill(
          id: 'owner-a/repo-a/beta@2026.26',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.26',
          installCommand: 'install beta',
          updateAvailable: false,
          inJsonProjects: '{}',
        ),
      ];

      final feed = buildUnifiedSkillFeed(catalogSkills, installedSkills);
      final alpha = feed.firstWhere((item) => item.name == 'alpha');
      final beta = feed.firstWhere((item) => item.name == 'beta');
      final gamma = feed.firstWhere((item) => item.name == 'gamma');
      final index = buildSkillsCatalogIndex(feed);

      expect(compareSkillVersions('2026.06.30', '2026.06.29'), greaterThan(0));
      expect(alpha.status, SkillFeedStatus.outdated);
      expect(alpha.localVersion, '2026.26');
      expect(beta.status, SkillFeedStatus.installed);
      expect(gamma.status, SkillFeedStatus.notInstalled);
      expect(index.owners, ['owner-a', 'owner-b']);
      expect(index.skillCountForOwner('owner-a'), 3);
      expect(index.skillCountForOwner('owner-b'), 1);
      expect(index.repositoriesFor('owner-a'), ['repo-a']);
      expect(index.skillCountForRepository('owner-a', 'repo-a'), 3);
    });
  });

  group('SkillsCatalogWidget', () {
    late Directory tempDirectory;
    late String databasePath;
    late VibeHubDatabase database;
    late SkillsApi skillsApi;
    late SkillsCatalogApi skillsCatalogApi;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync(
        'skills_catalog_widget_test',
      );
      databasePath = p.join(tempDirectory.path, 'skills.db');
      database = VibeHubDatabase(databasePath: databasePath);
      skillsApi = SkillsApi(database);
      skillsCatalogApi = SkillsCatalogApi();

      skillsCatalogApi.replaceCatalogSkills(const [
        CatalogSkill(
          name: 'alpha',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.27',
          sha: '9aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-a/repo-a',
          installCommand: 'install alpha',
        ),
        CatalogSkill(
          name: 'beta',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.26',
          sha: '0aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-a/repo-a',
          installCommand: 'install beta',
        ),
        CatalogSkill(
          name: 'gamma',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.26',
          sha: '1aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-a/repo-a',
          installCommand: 'install gamma',
        ),
        CatalogSkill(
          name: 'delta',
          owner: 'owner-a',
          repo: 'repo-b',
          version: '2026.26',
          sha: '2aa7c1f3b2182a88bd96748f1798a5d0332a8c76',
          repoUrl: 'https://github.com/owner-a/repo-b',
          installCommand: 'install delta',
        ),
      ]);

      skillsApi.writeSkill(
        Skill(
          id: 'owner-a/repo-a/alpha@2026.26',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.26',
          installCommand: 'install alpha old',
          updateAvailable: false,
          inJsonProjects: '{}',
        ),
      );
      skillsApi.writeSkill(
        Skill(
          id: 'owner-a/repo-a/beta@2026.26',
          owner: 'owner-a',
          repo: 'repo-a',
          version: '2026.26',
          installCommand: 'install beta',
          updateAvailable: false,
          inJsonProjects: '{}',
        ),
      );
    });

    tearDown(() {
      skillsCatalogApi.close();
      database.close();
      try {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      } catch (_) {
        // Ignore folder deletion errors on Windows if SQLite lock is still held
      }
    });

    testWidgets('filters by owner and repo and exposes update action', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCatalogWidget(
        tester,
        skillsApi: skillsApi,
        skillsCatalogApi: skillsCatalogApi,
      );

      expect(find.text('OWNERS'), findsOneWidget);
      expect(find.byKey(const ValueKey('owner-owner-a')), findsOneWidget);
      expect(find.text('alpha@2026.27', findRichText: true), findsOneWidget);
      expect(find.text('beta@2026.26', findRichText: true), findsOneWidget);
      expect(find.text('gamma@2026.26', findRichText: true), findsOneWidget);
      expect(find.text('9aa7c1f'), findsOneWidget);
      expect(find.text('Outdated'), findsOneWidget);
      expect(find.text('Current'), findsWidgets);
      expect(find.text('Missing'), findsWidgets);
      expect(
        find.byKey(const ValueKey('skill-action-update-owner-a/repo-a/alpha')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('skill-action-install-owner-a/repo-a/gamma')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('skill-action-update-owner-a/repo-a/alpha')),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(
          const ValueKey('skill-action-uninstall-owner-a/repo-a/alpha'),
        ),
      );
    });

    testWidgets('install action updates status to installed', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCatalogWidget(
        tester,
        skillsApi: skillsApi,
        skillsCatalogApi: skillsCatalogApi,
      );

      await tester.tap(
        find.byKey(const ValueKey('skill-action-install-owner-a/repo-a/gamma')),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(
          const ValueKey('skill-action-uninstall-owner-a/repo-a/gamma'),
        ),
      );
    });

    testWidgets(
      'install keeps catalog visible and only shows button progress',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final installCompleter = Completer<String>();

        await _pumpCatalogWidget(
          tester,
          skillsApi: skillsApi,
          skillsCatalogApi: skillsCatalogApi,
          installSkillFn: (skill, api) => installCompleter.future.then((val) {
            if (val == 'ok') {
              api.writeSkill(skill);
            }
            return val;
          }),
        );

        await tester.tap(
          find.byKey(
            const ValueKey('skill-action-install-owner-a/repo-a/gamma'),
          ),
        );
        await tester.pump();

        expect(find.text('OWNERS'), findsOneWidget);
        expect(find.text('REPOSITORIES'), findsOneWidget);
        expect(find.text('SKILLS'), findsOneWidget);
        expect(find.text('gamma@2026.26', findRichText: true), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        installCompleter.complete('ok');
        await _pumpUntilFound(
          tester,
          find.byKey(
            const ValueKey('skill-action-uninstall-owner-a/repo-a/gamma'),
          ),
        );
      },
    );

    testWidgets(
      'installSkills installs sequentially, updating statuses in memory',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final completers = <String, Completer<String>>{
          'owner-a/repo-a/gamma@2026.26': Completer<String>(),
          'owner-a/repo-b/delta@2026.26': Completer<String>(),
        };

        await _pumpCatalogWidget(
          tester,
          skillsApi: skillsApi,
          skillsCatalogApi: skillsCatalogApi,
          installSkillFn: (skill, api) {
            final completer = completers[skill.id];
            if (completer != null) {
              return completer.future.then((val) {
                if (val == 'ok') {
                  api.writeSkill(skill);
                }
                return val;
              });
            }
            return Future.value('ok');
          },
        );

        // Tap the owner tile again to clear repo selection and show both repo-a and repo-b skills
        await tester.tap(find.byKey(const ValueKey('owner-owner-a')));
        await tester.pump();

        final installAllButton = find.text('Install All (2)');
        expect(installAllButton, findsOneWidget);

        await tester.tap(installAllButton);
        await tester.pump();
        expect(
          find.textContaining(
            'Install All: installing 1/2 owner-a/repo-a/gamma@2026.26',
          ),
          findsOneWidget,
        );

        // Complete the first skill (gamma)
        completers['owner-a/repo-a/gamma@2026.26']!.complete('ok');
        await _pumpUntilFound(
          tester,
          find.textContaining(
            'Install All: installing 2/2 owner-a/repo-b/delta@2026.26',
          ),
        );

        // Complete the second skill (delta)
        completers['owner-a/repo-b/delta@2026.26']!.complete('ok');
        await _pumpUntilFound(
          tester,
          find.byKey(
            const ValueKey('skill-action-uninstall-owner-a/repo-b/delta'),
          ),
        );

        // Wait for final reload and background async tasks to settle
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        expect(
          find.textContaining('Install All complete: 2 skills'),
          findsOneWidget,
        );
      },
    );

    testWidgets('uninstall action updates status to not installed', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCatalogWidget(
        tester,
        skillsApi: skillsApi,
        skillsCatalogApi: skillsCatalogApi,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('skill-action-uninstall-owner-a/repo-a/beta'),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('skill-action-install-owner-a/repo-a/beta')),
      );
    });
  });
}

Future<void> _pumpCatalogWidget(
  WidgetTester tester, {
  required SkillsApi skillsApi,
  required SkillsCatalogApi skillsCatalogApi,
  Future<String> Function(Skill, SkillsApi)? installSkillFn,
  Future<String> Function(Skill, SkillsApi)? uninstallSkillFn,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SkillsCatalogWidget(
          skillsApi: skillsApi,
          skillsCatalogApi: skillsCatalogApi,
          installSkillFn: installSkillFn,
          uninstallSkillFn: uninstallSkillFn,
        ),
      ),
    ),
  );
  await _pumpUntilFound(tester, find.byKey(const ValueKey('owner-owner-a')));

  expect(find.byKey(const ValueKey('repo-all-repo-a')), findsOneWidget);
  expect(find.byKey(const ValueKey('repo-all-repo-b')), findsOneWidget);
  expect(find.text('alpha@2026.27', findRichText: true), findsOneWidget);
  expect(find.text('delta@2026.26', findRichText: true), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('owner-owner-a')));
  await tester.pump();

  expect(find.byKey(const ValueKey('repo-owner-a-repo-a')), findsOneWidget);
  expect(find.byKey(const ValueKey('repo-owner-a-repo-b')), findsOneWidget);
  expect(find.text('3'), findsWidgets);
  expect(find.text('1'), findsWidgets);

  await tester.tap(find.byKey(const ValueKey('repo-owner-a-repo-a')));
  await tester.pump();
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  fail('Expected widget to appear.');
}
