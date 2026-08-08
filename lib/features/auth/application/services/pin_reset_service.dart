import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/data/repositories/pin_reset_repository.dart';
import 'package:pixel_pocket/features/backup/application/services/backup_service.dart';

/// Business logic for "forgot PIN" recovery: wipes local data, then
/// best-effort disconnects Google Sheets backup so auto-backup can't
/// silently overwrite the cloud copy with the now-empty local state.
class PinResetService {
  PinResetService(this._repo, this._backupService);

  final PinResetRepository _repo;
  final BackupService _backupService;

  Future<void> resetForgottenPin() async {
    await _repo.wipeAll();
    try {
      await _backupService.disconnect();
    } catch (_) {
      // Best-effort — a failed Google sign-out must not block PIN recovery.
    }
  }
}

final pinResetServiceProvider = Provider<PinResetService>(
  (ref) => PinResetService(
    ref.watch(pinResetRepositoryProvider),
    ref.watch(backupServiceProvider),
  ),
);
