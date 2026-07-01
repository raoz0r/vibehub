import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibehub/api/skills_catalog_api.dart';
import 'package:vibehub/main.dart';

void main() {
  testWidgets('renders the VibeHub shell with all sidebar sections', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());

    expect(find.text('VibeHub'), findsOneWidget);
    expect(find.text('Overview'), findsNWidgets(2));
    expect(find.text('Repositories'), findsNWidgets(2));
    expect(find.text('Skills'), findsOneWidget);
    expect(find.text('MCP'), findsOneWidget);
    expect(find.text('Secret Manager'), findsWidgets);
    expect(find.text('Blueprints'), findsWidgets);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('selecting a menu changes the main content title', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());

    await tester.tap(find.text('Repositories').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('page-title-repositories')),
      findsOneWidget,
    );
    expect(find.textContaining('REGISTERED DIRECTORIES'), findsOneWidget);
    expect(find.byTooltip('Open package'), findsNothing);
  });

  testWidgets('sidebar can collapse and expand again', (tester) async {
    await tester.pumpWidget(_buildApp());
    final sidebarSecretManager = find.descendant(
      of: find.byType(VibeHubSidebar),
      matching: find.text('Secret Manager'),
    );

    expect(find.text('Hide'), findsOneWidget);
    expect(sidebarSecretManager, findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sidebar-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Hide'), findsNothing);
    expect(sidebarSecretManager, findsNothing);

    await tester.tap(find.byKey(const ValueKey('sidebar-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Hide'), findsOneWidget);
    expect(sidebarSecretManager, findsOneWidget);
  });
}

Widget _buildApp() {
  return VibeHubApp(skillsCatalogApi: SkillsCatalogApi());
}
