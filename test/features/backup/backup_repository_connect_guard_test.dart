import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pixel_pocket/features/backup/data/backup_serialization.dart';
import 'package:pixel_pocket/features/backup/data/datasources/backup_metadata_store.dart';
import 'package:pixel_pocket/features/backup/data/datasources/google_auth_client.dart';
import 'package:pixel_pocket/features/backup/data/datasources/sheets_data_source.dart';
import 'package:pixel_pocket/features/backup/data/repositories/backup_repository.dart';

class _FakeAuth extends GoogleAuthClient {
  _FakeAuth() : super(AuthRemoteDataSource());

  @override
  Future<String> connect() async => 'user@example.com';
}

class _StubSheets extends SheetsDataSource {
  _StubSheets(this.tabs) : super(_FakeAuth());

  final Map<String, List<List<Object?>>> tabs;

  @override
  Future<String> findOrCreateSpreadsheet() async => 'sheet123';

  @override
  Future<List<List<Object?>>> readTab(String spreadsheetId, String tab) async =>
      tabs[tab] ?? const [];
}

class _ThrowingSheets extends SheetsDataSource {
  _ThrowingSheets() : super(_FakeAuth());

  @override
  Future<String> findOrCreateSpreadsheet() async => 'sheet123';

  @override
  Future<List<List<Object?>>> readTab(String spreadsheetId, String tab) async {
    throw Exception('offline');
  }
}

BackupRepository _repo(AppDatabase db, BackupMetadataStore meta, SheetsDataSource sheets) =>
    BackupRepository(auth: _FakeAuth(), sheets: sheets, db: db, meta: meta);

Map<String, List<List<Object?>>> _populatedTabs() => {
      'Metadata': [
        ['key', 'value'],
        ['schema_version', '1'],
        ['last_backup_at', '2026-08-05T21:10:00.000'],
        ['categories', '20'],
        ['salary_periods', '3'],
        ['transactions', '142'],
      ],
    };

Map<String, List<List<Object?>>> _emptyTabs() => {
      'Metadata': const [],
      'Categories': [categoriesHeader],
      'SalaryPeriods': [salaryPeriodsHeader],
      'Transactions': [transactionsHeader],
    };

void main() {
  late AppDatabase db;
  late BackupMetadataStore meta;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    meta = BackupMetadataStore(await SharedPreferences.getInstance());
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('connect flags a restore decision when the sheet already has data', () async {
    final repo = _repo(db, meta, _StubSheets(_populatedTabs()));

    expect(await repo.connect(), 'user@example.com');

    expect(meta.needsRestoreDecision, true);
    expect(meta.remoteTransactionCount, 142);
    expect(meta.spreadsheetId, 'sheet123');
  });

  test('connect leaves the flag off when the sheet is empty', () async {
    final repo = _repo(db, meta, _StubSheets(_emptyTabs()));

    await repo.connect();

    expect(meta.needsRestoreDecision, false);
    expect(meta.remoteTransactionCount, isNull);
  });

  test('connect counts data tabs when the Metadata tab is unusable', () async {
    final repo = _repo(
      db,
      meta,
      _StubSheets({
        'Metadata': const [],
        'Categories': [categoriesHeader, ['7', 'Food', '#111111', 'expense']],
        'SalaryPeriods': [salaryPeriodsHeader],
        'Transactions': [
          transactionsHeader,
          ['99', '2026-07-05', 'expense', '12', '7', 'kopi', '', ''],
          ['100', '2026-07-06', 'expense', '15', '7', 'teh', '', ''],
        ],
      }),
    );

    await repo.connect();

    expect(meta.needsRestoreDecision, true);
    expect(meta.remoteTransactionCount, 2);
  });

  test('connect fails safe: inspection error still flags a restore decision', () async {
    final repo = _repo(db, meta, _ThrowingSheets());

    expect(await repo.connect(), 'user@example.com');

    expect(meta.needsRestoreDecision, true);
    expect(meta.remoteTransactionCount, isNull);
  });

  test('reconnecting to an emptied sheet clears a stale flag', () async {
    await meta.setNeedsRestoreDecision(true);
    await meta.setRemoteTransactionCount(9);
    final repo = _repo(db, meta, _StubSheets(_emptyTabs()));

    await repo.connect();

    expect(meta.needsRestoreDecision, false);
    expect(meta.remoteTransactionCount, isNull);
  });
}
