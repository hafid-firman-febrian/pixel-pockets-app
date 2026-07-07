import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/backup/data/datasources/backup_metadata_store.dart';

class BackupStatus {
  const BackupStatus({required this.connected, this.email, this.lastBackupAt});

  final bool connected;
  final String? email;
  final DateTime? lastBackupAt;
}

final backupStatusProvider = Provider<BackupStatus>((ref) {
  final meta = ref.watch(backupMetadataStoreProvider);
  return BackupStatus(
    connected: meta.isConnected,
    email: meta.accountEmail,
    lastBackupAt: meta.lastBackupAt,
  );
});
