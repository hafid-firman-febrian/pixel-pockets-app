import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('wipeAllData clears transactions, salary periods and categories, '
      'then reseeds the 18 default categories', () async {
    await db.seedDefaultCategoriesIfEmpty();
    await db.into(db.salaryPeriods).insert(
          SalaryPeriodsCompanion.insert(
            name: 'Jul',
            startDate: '2026-07-01',
            endDate: '2026-07-31',
          ),
        );
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            transactionDate: '2026-07-05',
            transactionType: 'expense',
            amount: 12,
          ),
        );

    await db.wipeAllData();

    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.salaryPeriods).get(), isEmpty);
    final cats = await db.select(db.categories).get();
    expect(cats.length, 18);
  });

  test('wipeAllData works even when called on an already-empty database', () async {
    await db.wipeAllData();

    final cats = await db.select(db.categories).get();
    expect(cats.length, 18);
  });
}
