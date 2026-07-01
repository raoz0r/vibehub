import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibehub/api/skills_catalog_api.dart';
import 'package:vibehub/api/skills_sync.dart';
import 'package:vibehub/ui/bloc/shell/shell_bloc.dart';
import 'package:vibehub/ui/shell/vibehub_shell.dart';
import 'package:vibehub/ui/theme/vibehub_theme.dart';

export 'package:vibehub/ui/shell/vibehub_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final skillsCatalogApi = SkillsCatalogApi();
  await SkillsSyncApi.sync();
  await skillsCatalogApi.hydrateFromFile(SkillsSyncApi.getLocalFilePath());
  runApp(VibeHubApp(skillsCatalogApi: skillsCatalogApi));
}

class VibeHubApp extends StatelessWidget {
  const VibeHubApp({super.key, required this.skillsCatalogApi});

  final SkillsCatalogApi skillsCatalogApi;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SkillsCatalogApi>.value(value: skillsCatalogApi),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VibeHub',
        theme: VibeHubTheme.light,
        home: BlocProvider(
          create: (_) => ShellBloc(),
          child: const VibeHubShell(),
        ),
      ),
    );
  }
}
