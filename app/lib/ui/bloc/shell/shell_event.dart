import 'package:vibehub/ui/shell/vibehub_section.dart';

sealed class ShellEvent {
  const ShellEvent();
}

class ShellSectionSelected extends ShellEvent {
  const ShellSectionSelected(this.section);

  final VibeHubSection section;
}

class ShellSidebarToggled extends ShellEvent {
  const ShellSidebarToggled();
}
