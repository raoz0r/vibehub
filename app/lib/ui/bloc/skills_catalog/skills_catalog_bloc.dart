import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibehub/api/skills_api.dart';
import 'package:vibehub/api/skills_catalog_api.dart';
import 'package:vibehub/functions/install_skill.dart' as fns;
import 'package:vibehub/functions/uninstall_skill.dart' as ufns;
import 'package:vibehub/ui/bloc/skills_catalog/skills_catalog_data.dart';
import 'package:vibehub/ui/bloc/skills_catalog/skills_catalog_event.dart';
import 'package:vibehub/ui/bloc/skills_catalog/skills_catalog_state.dart';

class SkillsCatalogBloc extends Bloc<SkillsCatalogEvent, SkillsCatalogState> {
  SkillsCatalogBloc({
    SkillsApi? skillsApi,
    SkillsCatalogApi? skillsCatalogApi,
    Future<String> Function(Skill, SkillsApi)? installSkillFn,
    Future<String> Function(Skill, SkillsApi)? uninstallSkillFn,
  }) : _skillsApi = skillsApi ?? SkillsApi(),
       _skillsCatalogApi = skillsCatalogApi ?? SkillsCatalogApi(),
       _installSkillFn = installSkillFn ?? fns.installSkill,
       _uninstallSkillFn = uninstallSkillFn ?? ufns.uninstallSkill,
       super(const SkillsCatalogState.initial()) {
    on<SkillsCatalogStarted>(_onStarted);
    on<SkillsCatalogOwnerSelected>(_onOwnerSelected);
    on<SkillsCatalogRepoSelected>(_onRepoSelected);
    on<SkillsCatalogOwnerQueryChanged>(_onOwnerQueryChanged);
    on<SkillsCatalogRepoQueryChanged>(_onRepoQueryChanged);
    on<SkillsCatalogSkillQueryChanged>(_onSkillQueryChanged);
    on<SkillsCatalogSkillFilterChanged>(_onSkillFilterChanged);
    on<SkillsCatalogInstallAllRequested>(_onInstallAllRequested);
    on<SkillsCatalogInstallRequested>(_onInstallRequested);
    on<SkillsCatalogUpdateRequested>(_onUpdateRequested);
    on<SkillsCatalogUninstallRequested>(_onUninstallRequested);
    on<SkillsCatalogUninstallVersionRequested>(_onUninstallVersionRequested);
  }

  final SkillsApi _skillsApi;
  final SkillsCatalogApi _skillsCatalogApi;
  final Future<String> Function(Skill, SkillsApi) _installSkillFn;
  final Future<String> Function(Skill, SkillsApi) _uninstallSkillFn;

  Future<void> _onStarted(
    SkillsCatalogStarted event,
    Emitter<SkillsCatalogState> emit,
  ) async {
    await _loadCatalog(emit, showPageLoading: true);
  }

  Future<void> _loadCatalog(
    Emitter<SkillsCatalogState> emit, {
    required bool showPageLoading,
  }) async {
    if (showPageLoading) {
      emit(
        state.copyWith(isLoading: true, errorMessage: null, actionStatus: null),
      );
    }

    try {
      final catalogSkills = _skillsCatalogApi.readAllCatalogSkills();
      final installedSkills = _skillsApi.readAllSkills();
      final items = buildUnifiedSkillFeed(catalogSkills, installedSkills);
      final index = buildSkillsCatalogIndex(items);

      emit(
        SkillsCatalogState(
          isLoading: false,
          isBulkInstalling: state.isBulkInstalling,
          busySkillIds: state.busySkillIds,
          items: items,
          index: index,
          selectedOwner: state.selectedOwner,
          selectedRepo: state.selectedRepo,
          ownerQuery: state.ownerQuery,
          repoQuery: state.repoQuery,
          skillQuery: state.skillQuery,
          skillFilter: state.skillFilter,
          actionStatus: state.actionStatus,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
          actionStatus: null,
        ),
      );
    }
  }

  void _onOwnerSelected(
    SkillsCatalogOwnerSelected event,
    Emitter<SkillsCatalogState> emit,
  ) {
    emit(
      state.copyWith(
        selectedOwner: event.owner,
        selectedRepo: null,
        repoQuery: '',
        skillQuery: '',
        actionStatus: null,
      ),
    );
  }

  void _onRepoSelected(
    SkillsCatalogRepoSelected event,
    Emitter<SkillsCatalogState> emit,
  ) {
    emit(
      state.copyWith(
        selectedRepo: event.repo,
        skillQuery: '',
        actionStatus: null,
      ),
    );
  }

  void _onOwnerQueryChanged(
    SkillsCatalogOwnerQueryChanged event,
    Emitter<SkillsCatalogState> emit,
  ) {
    emit(state.copyWith(ownerQuery: event.query, actionStatus: null));
  }

  void _onRepoQueryChanged(
    SkillsCatalogRepoQueryChanged event,
    Emitter<SkillsCatalogState> emit,
  ) {
    emit(state.copyWith(repoQuery: event.query, actionStatus: null));
  }

  void _onSkillQueryChanged(
    SkillsCatalogSkillQueryChanged event,
    Emitter<SkillsCatalogState> emit,
  ) {
    emit(state.copyWith(skillQuery: event.query, actionStatus: null));
  }

  void _onSkillFilterChanged(
    SkillsCatalogSkillFilterChanged event,
    Emitter<SkillsCatalogState> emit,
  ) {
    emit(state.copyWith(skillFilter: event.filter, actionStatus: null));
  }

  Future<void> _onInstallAllRequested(
    SkillsCatalogInstallAllRequested event,
    Emitter<SkillsCatalogState> emit,
  ) async {
    final installable = event.items
        .where((item) => item.status == SkillFeedStatus.notInstalled)
        .where((item) => !state.busySkillIds.contains(item.id))
        .toList();
    if (installable.isEmpty) {
      return;
    }

    final startedAt = DateTime.now();
    final totalStopwatch = Stopwatch()..start();
    final logEntries = <fns.InstallAllLogEntry>[];
    emit(
      state.copyWith(
        isBulkInstalling: true,
        actionStatus: 'Install All: starting ${installable.length} skills',
      ),
    );

    for (var index = 0; index < installable.length; index += 1) {
      final item = installable[index];
      emit(
        state.copyWith(
          actionStatus:
              'Install All: installing ${index + 1}/${installable.length} ${item.id}',
        ),
      );
      final itemStartedAt = DateTime.now();
      final itemStopwatch = Stopwatch()..start();
      await _installSkill(item, emit);
      itemStopwatch.stop();
      logEntries.add(
        fns.InstallAllLogEntry(
          skillId: item.id,
          status: state.actionStatus ?? 'Install status unavailable',
          startedAt: itemStartedAt,
          finishedAt: DateTime.now(),
          duration: itemStopwatch.elapsed,
        ),
      );
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    totalStopwatch.stop();
    var finalStatus =
        'Install All complete: ${installable.length} skills in ${_formatStatusDuration(totalStopwatch.elapsed)}';
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        final logPath = await fns.writeInstallAllLog(
          startedAt: startedAt,
          finishedAt: DateTime.now(),
          totalDuration: totalStopwatch.elapsed,
          entries: logEntries,
        );
        finalStatus = '$finalStatus. Log: $logPath';
      } catch (error) {
        finalStatus = '$finalStatus. Summary log failed: $error';
      }
    }

    emit(state.copyWith(isBulkInstalling: false, actionStatus: finalStatus));
  }

  Future<void> _onInstallRequested(
    SkillsCatalogInstallRequested event,
    Emitter<SkillsCatalogState> emit,
  ) async {
    await _installSkill(event.item, emit);
  }

  Future<void> _installSkill(
    SkillFeedItem item,
    Emitter<SkillsCatalogState> emit,
  ) async {
    if (state.busySkillIds.contains(item.id)) {
      return;
    }

    emit(
      state.copyWith(
        busySkillIds: {...state.busySkillIds, item.id},
        actionStatus: state.isBulkInstalling ? state.actionStatus : null,
      ),
    );

    try {
      final status = await _installSkillFn(skillFromFeedItem(item), _skillsApi);
      await _loadCatalog(emit, showPageLoading: false);
      emit(
        state.copyWith(
          busySkillIds: {...state.busySkillIds}..remove(item.id),
          actionStatus: 'Install status: $status',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          busySkillIds: {...state.busySkillIds}..remove(item.id),
          actionStatus: 'Install status: error: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateRequested(
    SkillsCatalogUpdateRequested event,
    Emitter<SkillsCatalogState> emit,
  ) async {
    final item = event.item;
    if (state.busySkillIds.contains(item.id)) {
      return;
    }

    emit(
      state.copyWith(
        busySkillIds: {...state.busySkillIds, item.id},
        actionStatus: null,
      ),
    );

    try {
      final status = await _installSkillFn(skillFromFeedItem(item), _skillsApi);
      await _loadCatalog(emit, showPageLoading: false);
      emit(
        state.copyWith(
          busySkillIds: {...state.busySkillIds}..remove(item.id),
          actionStatus: 'Update status: $status',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          busySkillIds: {...state.busySkillIds}..remove(item.id),
          actionStatus: 'Update status: error: $e',
        ),
      );
    }
  }

  Future<void> _onUninstallRequested(
    SkillsCatalogUninstallRequested event,
    Emitter<SkillsCatalogState> emit,
  ) async {
    await _uninstallSkillVersion(skillFromFeedItem(event.item), emit);
  }

  Future<void> _onUninstallVersionRequested(
    SkillsCatalogUninstallVersionRequested event,
    Emitter<SkillsCatalogState> emit,
  ) async {
    await _uninstallSkillVersion(event.skill, emit);
  }

  Future<void> _uninstallSkillVersion(
    Skill skill,
    Emitter<SkillsCatalogState> emit,
  ) async {
    if (state.busySkillIds.contains(skill.id)) {
      return;
    }

    emit(
      state.copyWith(
        busySkillIds: {...state.busySkillIds, skill.id},
        actionStatus: null,
      ),
    );

    try {
      final status = await _uninstallSkillFn(skill, _skillsApi);
      await _loadCatalog(emit, showPageLoading: false);
      emit(
        state.copyWith(
          busySkillIds: {...state.busySkillIds}..remove(skill.id),
          actionStatus: 'Uninstall status: $status',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          busySkillIds: {...state.busySkillIds}..remove(skill.id),
          actionStatus: 'Uninstall status: error: $e',
        ),
      );
    }
  }
}

String _formatStatusDuration(Duration duration) {
  final milliseconds = duration.inMilliseconds;
  if (milliseconds < 1000) {
    return '${milliseconds}ms';
  }

  return '${(milliseconds / 1000).toStringAsFixed(2)}s';
}
