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

class _WritableSheets extends _StubSheets {
  _WritableSheets(super.tabs);

  final written = <String>[];

  @override
  Future<void> writeTab(
    String spreadsheetId,
    String tab,
    List<List<Object?>> valuesWithHeader,
  ) async {
    written.add(tab);
  }
}

class _WriteThrowingSheets extends _StubSheets {
  _WriteThrowingSheets(super.tabs);

  @override
  Future<void> writeTab(
    String spreadsheetId,
    String tab,
    List<List<Object?>> valuesWithHeader,
  ) async {
    throw Exception('write failed');
  }
}

class _AssertingSheets extends _StubSheets {
  _AssertingSheets(super.tabs, this.meta);

  final BackupMetadataStore meta;
  Object? assertionFailure;

  @override
  Future<List<List<Object?>>> readTab(String spreadsheetId, String tab) async {
    try {
      expect(meta.needsRestoreDecision, true);
      expect(meta.isConnected, true);
    } catch (e) {
      assertionFailure ??= e;
    }
    return super.readTab(spreadsheetId, tab);
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

  test('the flag is already up and the app already counts as connected before the inspection network calls run', () async {
    final sheets = _AssertingSheets(_populatedTabs(), meta);
    final repo = _repo(db, meta, sheets);

    await repo.connect();

    if (sheets.assertionFailure != null) throw sheets.assertionFailure!;
  });

  test('an all-zero Metadata summary falls through to counting the data tabs', () async {
    final repo = _repo(
      db,
      meta,
      _StubSheets({
        'Metadata': [
          ['key', 'value'],
          ['categories', '0'],
          ['salary_periods', '0'],
          ['transactions', '0'],
        ],
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

  test('connect stores a zero transaction count as null', () async {
    final repo = _repo(
      db,
      meta,
      _StubSheets({
        'Metadata': [
          ['key', 'value'],
          ['categories', '18'],
          ['salary_periods', '0'],
          ['transactions', '0'],
        ],
      }),
    );

    await repo.connect();

    expect(meta.needsRestoreDecision, true);
    expect(meta.remoteTransactionCount, isNull);
  });

  group('clearing the restore decision', () {
    setUp(() async {
      await meta.setSpreadsheetId('sheet123');
      await meta.setNeedsRestoreDecision(true);
      await meta.setRemoteTransactionCount(142);
    });

    test('keepLocalData clears the flag without touching the sheet', () async {
      final sheets = _WritableSheets(_populatedTabs());
      await _repo(db, meta, sheets).keepLocalData();

      expect(meta.needsRestoreDecision, false);
      expect(meta.remoteTransactionCount, isNull);
      expect(sheets.written, isEmpty);
    });

    test('a successful backup clears the flag', () async {
      final sheets = _WritableSheets(_populatedTabs());
      await _repo(db, meta, sheets).backup();

      expect(meta.needsRestoreDecision, false);
      expect(meta.remoteTransactionCount, isNull);
      expect(sheets.written, contains('Transactions'));
    });

    test('a successful restore clears the flag', () async {
      final sheets = _WritableSheets({
        'Categories': [categoriesHeader, ['7', 'Food', '#111111', 'expense']],
        'SalaryPeriods': [salaryPeriodsHeader],
        'Transactions': [
          transactionsHeader,
          ['99', '2026-07-05', 'expense', '12', '7', 'kopi', '', ''],
        ],
      });
      await _repo(db, meta, sheets).restore();

      expect(meta.needsRestoreDecision, false);
      expect(meta.remoteTransactionCount, isNull);
      expect((await db.select(db.transactions).getSingle()).id, 99);
    });

    test('a failed restore keeps the flag set', () async {
      final repo = _repo(db, meta, _StubSheets(_emptyTabs()));

      await expectLater(repo.restore(), throwsA(anything));

      expect(meta.needsRestoreDecision, true);
      expect(meta.remoteTransactionCount, 142);
    });

    test('a failed backup keeps the flag set', () async {
      final repo = _repo(db, meta, _WriteThrowingSheets(_populatedTabs()));

      await expectLater(repo.backup(), throwsA(anything));

      expect(meta.needsRestoreDecision, true);
      expect(meta.remoteTransactionCount, 142);
    });
  });
}
