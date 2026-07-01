import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibehub/ui/bloc/shell/shell_event.dart';
import 'package:vibehub/ui/bloc/shell/shell_state.dart';

class ShellBloc extends Bloc<ShellEvent, ShellState> {
  ShellBloc() : super(const ShellState()) {
    on<ShellSectionSelected>(_onSectionSelected);
    on<ShellSidebarToggled>(_onSidebarToggled);
  }

  void _onSectionSelected(
    ShellSectionSelected event,
    Emitter<ShellState> emit,
  ) {
    emit(state.copyWith(selectedSection: event.section));
  }

  void _onSidebarToggled(ShellSidebarToggled event, Emitter<ShellState> emit) {
    emit(state.copyWith(isSidebarExpanded: !state.isSidebarExpanded));
  }
}
