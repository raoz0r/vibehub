import 'package:flutter/widgets.dart';
import 'package:vibehub/ui/shell/vibehub_section.dart';
import 'package:vibehub/ui/views/placeholder_section_view.dart';

class BlueprintsView extends StatelessWidget {
  const BlueprintsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderSectionView(section: VibeHubSection.blueprints);
  }
}
