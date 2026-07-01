import 'package:vibehub/ui/shell/vibehub_section.dart';

class ShellState {
  const ShellState({
    this.selectedSection = VibeHubSection.overview,
    this.isSidebarExpanded = true,
  });

  final VibeHubSection selectedSection;
  final bool isSidebarExpanded;

  ShellState copyWith({
    VibeHubSection? selectedSection,
    bool? isSidebarExpanded,
  }) {
    return ShellState(
      selectedSection: selectedSection ?? this.selectedSection,
      isSidebarExpanded: isSidebarExpanded ?? this.isSidebarExpanded,
    );
  }
}
