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

  test('pendingBackup defaults false, persists, and clears', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = BackupMetadataStore(prefs);
    expect(store.pendingBackup, false);
    await store.setPendingBackup(true);
    expect(store.pendingBackup, true);
    await store.clear();
    expect(store.pendingBackup, false);
  });

  test('autoBackupEnabled defaults true, persists, and clears back to true', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = BackupMetadataStore(prefs);
    expect(store.autoBackupEnabled, true);
    await store.setAutoBackupEnabled(false);
    expect(store.autoBackupEnabled, false);
    await store.clear();
    expect(store.autoBackupEnabled, true);
  });

  test('needsRestoreDecision defaults false, persists, and clears', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = BackupMetadataStore(prefs);
    expect(store.needsRestoreDecision, false);
    await store.setNeedsRestoreDecision(true);
    expect(store.needsRestoreDecision, true);
    await store.clear();
    expect(store.needsRestoreDecision, false);
  });

  test('remoteTransactionCount persists, resets to null, and clears', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = BackupMetadataStore(prefs);
    expect(store.remoteTransactionCount, isNull);
    await store.setRemoteTransactionCount(142);
    expect(store.remoteTransactionCount, 142);
    await store.setRemoteTransactionCount(null);
    expect(store.remoteTransactionCount, isNull);
    await store.setRemoteTransactionCount(7);
    await store.clear();
    expect(store.remoteTransactionCount, isNull);
  });
}
