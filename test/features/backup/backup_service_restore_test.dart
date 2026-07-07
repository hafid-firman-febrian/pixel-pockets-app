import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pixel_pocket/features/backup/data/backup_serialization.dart';
import 'package:pixel_pocket/features/backup/data/datasources/backup_metadata_store.dart';
import 'package:pixel_pocket/features/backup/data/datasources/google_auth_client.dart';
import 'package:pixel_pocket/features/backup/data/datasources/sheets_data_source.dart';
import 'package:pixel_pocket/features/backup/data/repositories/backup_repository.dart';

GoogleAuthClient _unusedAuth() => GoogleAuthClient(AuthRemoteDataSource());

class _FakeSheets extends SheetsDataSource {
  _FakeSheets() : super(_unusedAuth());

  @override
  Future<List<List<Object?>>> readTab(String spreadsheetId, String tab) async {
    switch (tab) {
      case 'Categories':
        return [categoriesHeader, ['7', 'Food', '#111111', 'expense']];
      case 'SalaryPeriods':
        return [salaryPeriodsHeader, ['3', 'Jul', '2026-07-01', '2026-07-31', '']];
      case 'Transactions':
        return [transactionsHeader, ['99', '2026-07-05', 'expense', '12', '7', 'kopi', '', '']];
      default:
        return [];
    }
  }
}

class _EmptySheets extends SheetsDataSource {
  _EmptySheets() : super(_unusedAuth());

  @override
  Future<List<List<Object?>>> readTab(String spreadsheetId, String tab) async {
    switch (tab) {
      case 'Categories':
        return [categoriesHeader];
      case 'SalaryPeriods':
        return [salaryPeriodsHeader];
      case 'Transactions':
        return [];
      default:
        return [];
    }
  }
}

void main() {
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({'backup_spreadsheet_id': 'sheet123'});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('restore writes sheet rows into drift preserving ids and FK', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = BackupRepository(
      auth: _unusedAuth(),
      sheets: _FakeSheets(),
      db: db,
      meta: BackupMetadataStore(prefs),
    );
    await repo.restore();

    expect((await db.select(db.categories).getSingle()).id, 7);
    final tx = await db.select(db.transactions).getSingle();
    expect(tx.id, 99);
    expect(tx.categoryId, 7);
    expect(tx.description, 'kopi');
    expect((await db.select(db.salaryPeriods).getSingle()).salaryAmount, isNull);
  });

  test('restore from an empty spreadsheet throws and keeps local data intact', () async {
    final prefs = await SharedPreferences.getInstance();
    await db.into(db.categories).insert(
        CategoriesCompanion.insert(id: const Value(1), name: 'Old', color: const Value('#000000'), type: 'expense'));
    final repo = BackupRepository(
      auth: _unusedAuth(),
      sheets: _EmptySheets(),
      db: db,
      meta: BackupMetadataStore(prefs),
    );

    await expectLater(repo.restore(), throwsA(isA<Failure>()));

    final cats = await db.select(db.categories).get();
    expect(cats.map((c) => c.id), [1]);
  });
}
