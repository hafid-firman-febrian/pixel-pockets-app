import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/features/backup/application/auto_backup_coordinator.dart';
import 'package:pixel_pocket/features/backup/data/datasources/backup_metadata_store.dart';

const _fast = Duration(milliseconds: 20);

Future<BackupMetadataStore> _store({bool connected = true}) async {
  SharedPreferences.setMockInitialValues(
    connected ? {'backup_spreadsheet_id': 'sheet1'} : {},
  );
  return BackupMetadataStore(await SharedPreferences.getInstance());
}

void main() {
  test('markDirty sets pending and, after debounce, backs up once (coalesced)', () async {
    final meta = await _store();
    var calls = 0;
    final c = AutoBackupCoordinator(
      runBackup: () async => calls++, meta: meta, debounce: _fast);
    await c.markDirty();
    await c.markDirty();
    await c.markDirty();
    expect(meta.pendingBackup, true);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(calls, 1);
    expect(meta.pendingBackup, false);
    c.dispose();
  });

  test('failed backup keeps pending and does not throw', () async {
    final meta = await _store();
    final c = AutoBackupCoordinator(
      runBackup: () async => throw Exception('offline'), meta: meta, debounce: _fast);
    await c.markDirty();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(meta.pendingBackup, true);
    c.dispose();
  });

  test('does not back up when disabled', () async {
    final meta = await _store();
    await meta.setAutoBackupEnabled(false);
    var calls = 0;
    final c = AutoBackupCoordinator(
      runBackup: () async => calls++, meta: meta, debounce: _fast);
    await c.markDirty();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(calls, 0);
    expect(meta.pendingBackup, true);
    c.dispose();
  });

  test('does not back up when not connected', () async {
    final meta = await _store(connected: false);
    var calls = 0;
    final c = AutoBackupCoordinator(
      runBackup: () async => calls++, meta: meta, debounce: _fast);
    await c.markDirty();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(calls, 0);
    c.dispose();
  });

  test('flush backs up immediately without waiting for debounce', () async {
    final meta = await _store();
    var calls = 0;
    final c = AutoBackupCoordinator(
      runBackup: () async => calls++, meta: meta, debounce: const Duration(seconds: 30));
    await meta.setPendingBackup(true);
    await c.flush();
    expect(calls, 1);
    expect(meta.pendingBackup, false);
    c.dispose();
  });

  test('onResume retries when pending', () async {
    final meta = await _store();
    var calls = 0;
    final c = AutoBackupCoordinator(
      runBackup: () async => calls++, meta: meta, debounce: const Duration(seconds: 30));
    await meta.setPendingBackup(true);
    await c.onResume();
    expect(calls, 1);
    c.dispose();
  });

  test('autoBackupStatusProvider notifies listeners when enabled toggles', () async {
    SharedPreferences.setMockInitialValues({'backup_spreadsheet_id': 'sheet1'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final seen = <bool>[];
    container.listen(
      autoBackupStatusProvider,
      (_, next) => seen.add(next.enabled),
      fireImmediately: true,
    );

    expect(container.read(autoBackupStatusProvider).enabled, true);
    await container.read(autoBackupCoordinatorProvider).setEnabled(false);
    expect(container.read(autoBackupStatusProvider).enabled, false);
    expect(seen, [true, false]);
  });
}
