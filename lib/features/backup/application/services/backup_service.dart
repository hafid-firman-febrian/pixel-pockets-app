import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/backup/data/repositories/backup_repository.dart';

class BackupService {
  BackupService(this._repo);
  final BackupRepository _repo;

  Future<String> connect() => _repo.connect();
  Future<void> disconnect() => _repo.disconnect();
  Future<DateTime> backup() => _repo.backup();
  Future<void> restore() => _repo.restore();
  Future<void> keepLocalData() => _repo.keepLocalData();
}

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(backupRepositoryProvider)),
);
