import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/auth/data/datasources/pin_local_data_source.dart';

/// Whole-database wipe for the forgot-PIN recovery flow. Touches
/// [AppDatabase] directly (like `backup_repository.dart` does for
/// backup/restore) because this is a snapshot-level reset, not business-
/// entity CRUD.
class PinResetRepository {
  PinResetRepository({required AppDatabase db, required PinLocalDataSource pinLocal})
      : _db = db,
        _pinLocal = pinLocal;

  final AppDatabase _db;
  final PinLocalDataSource _pinLocal;

  Future<void> wipeAll() async {
    await _db.wipeAllData();
    await _pinLocal.clear();
  }
}

final pinResetRepositoryProvider = Provider<PinResetRepository>(
  (ref) => PinResetRepository(
    db: ref.watch(appDatabaseProvider),
    pinLocal: ref.watch(pinLocalDataSourceProvider),
  ),
);
