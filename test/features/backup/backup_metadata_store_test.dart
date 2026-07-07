import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixel_pocket/features/backup/data/datasources/backup_metadata_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('stores and clears backup metadata', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = BackupMetadataStore(prefs);
    expect(store.isConnected, false);

    await store.setSpreadsheetId('sheet123');
    await store.setAccountEmail('a@b.com');
    await store.setLastBackupAt(DateTime.parse('2026-07-07T10:00:00Z'));

    expect(store.isConnected, true);
    expect(store.spreadsheetId, 'sheet123');
    expect(store.accountEmail, 'a@b.com');
    expect(store.lastBackupAt, DateTime.parse('2026-07-07T10:00:00Z'));

    await store.clear();
    expect(store.isConnected, false);
    expect(store.spreadsheetId, isNull);
    expect(store.lastBackupAt, isNull);
  });
}
