import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/features/backup/data/datasources/backup_metadata_store.dart';
import 'package:pixel_pocket/features/backup/presentation/states/backup_state.dart';

Future<ProviderContainer> _container(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  test('backupStatusProvider exposes the restore decision', () async {
    final container = await _container({
      'backup_spreadsheet_id': 'sheet123',
      'backup_account_email': 'user@example.com',
      'backup_needs_restore_decision': true,
      'backup_remote_tx_count': 142,
    });
    addTearDown(container.dispose);

    final status = container.read(backupStatusProvider);
    expect(status.connected, true);
    expect(status.needsRestoreDecision, true);
    expect(status.remoteTransactionCount, 142);
  });

  test('backupStatusProvider defaults the restore decision to false', () async {
    final container = await _container({'backup_spreadsheet_id': 'sheet123'});
    addTearDown(container.dispose);

    final status = container.read(backupStatusProvider);
    expect(status.needsRestoreDecision, false);
    expect(status.remoteTransactionCount, isNull);
  });

  test('BackupMetadataStore drives the flag through the provider', () async {
    final container = await _container({'backup_spreadsheet_id': 'sheet123'});
    addTearDown(container.dispose);

    await container
        .read(backupMetadataStoreProvider)
        .setNeedsRestoreDecision(true);
    container.invalidate(backupStatusProvider);

    expect(container.read(backupStatusProvider).needsRestoreDecision, true);
  });
}
