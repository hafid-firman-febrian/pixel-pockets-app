import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/backup/application/services/backup_service.dart';
import 'package:pixel_pocket/features/backup/data/datasources/backup_metadata_store.dart';
import 'package:pixel_pocket/features/backup/presentation/states/backup_state.dart';

class AutoBackupStatus {
  const AutoBackupStatus({
    required this.enabled,
    required this.pending,
    required this.running,
  });

  final bool enabled;
  final bool pending;
  final bool running;
}

class AutoBackupCoordinator {
  AutoBackupCoordinator({
    required Future<void> Function() runBackup,
    required BackupMetadataStore meta,
    required Duration debounce,
    void Function()? onChanged,
  })  : _runBackup = runBackup,
        _meta = meta,
        _debounce = debounce,
        _onChanged = onChanged;

  final Future<void> Function() _runBackup;
  final BackupMetadataStore _meta;
  final Duration _debounce;
  final void Function()? _onChanged;

  Timer? _timer;
  bool _running = false;

  bool get enabled => _meta.autoBackupEnabled;
  bool get pending => _meta.pendingBackup;
  bool get running => _running;

  Future<void> markDirty() async {
    await _meta.setPendingBackup(true);
    _onChanged?.call();
    _timer?.cancel();
    if (_meta.autoBackupEnabled) {
      _timer = Timer(_debounce, _attempt);
    }
  }

  Future<void> flush() async {
    _timer?.cancel();
    await _attempt();
  }

  Future<void> onResume() async {
    if (_meta.pendingBackup) await _attempt();
  }

  Future<void> setEnabled(bool value) async {
    await _meta.setAutoBackupEnabled(value);
    _onChanged?.call();
    if (!value) {
      _timer?.cancel();
    } else if (_meta.pendingBackup) {
      await _attempt();
    }
  }

  Future<void> _attempt() async {
    if (_running) return;
    if (!_meta.autoBackupEnabled || !_meta.isConnected) return;
    _running = true;
    _onChanged?.call();
    try {
      await _runBackup();
      await _meta.setPendingBackup(false);
    } catch (_) {
    } finally {
      _running = false;
      _onChanged?.call();
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}

final Provider<AutoBackupCoordinator> autoBackupCoordinatorProvider =
    Provider<AutoBackupCoordinator>((ref) {
  final coordinator = AutoBackupCoordinator(
    runBackup: () => ref.read(backupServiceProvider).backup(),
    meta: ref.read(backupMetadataStoreProvider),
    debounce: const Duration(seconds: 10),
    onChanged: () {
      ref.invalidate(autoBackupStatusProvider);
      ref.invalidate(backupStatusProvider);
    },
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

final Provider<AutoBackupStatus> autoBackupStatusProvider =
    Provider<AutoBackupStatus>((ref) {
  final c = ref.watch(autoBackupCoordinatorProvider);
  return AutoBackupStatus(
    enabled: c.enabled,
    pending: c.pending,
    running: c.running,
  );
});
