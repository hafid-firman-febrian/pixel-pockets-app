import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('replaceAll wipes then writes preserving ids', () async {
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: const Value(1),
            name: 'Old',
            color: const Value('#000000'),
            type: 'expense',
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            transactionDate: '2020-01-01',
            transactionType: 'expense',
            amount: 1,
          ),
        );

    await db.replaceAll(
      categories: [
        CategoriesCompanion.insert(
          id: const Value(7),
          name: 'Food',
          color: const Value('#111111'),
          type: 'expense',
        ),
      ],
      salaryPeriods: [
        SalaryPeriodsCompanion.insert(
          id: const Value(3),
          name: 'Jul',
          startDate: '2026-07-01',
          endDate: '2026-07-31',
        ),
      ],
      transactions: [
        TransactionsCompanion.insert(
          id: const Value(99),
          transactionDate: '2026-07-05',
          transactionType: 'expense',
          amount: 12,
          categoryId: const Value(7),
        ),
      ],
    );

    final cats = await db.select(db.categories).get();
    expect(cats.map((c) => c.id), [7]);
    final tx = await db.select(db.transactions).getSingle();
    expect(tx.id, 99);
    expect(tx.categoryId, 7);
    expect((await db.select(db.salaryPeriods).getSingle()).id, 3);
  });
}
