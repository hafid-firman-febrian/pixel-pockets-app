import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/transactions/data/datasources/transaction_dao.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

void main() {
  late AppDatabase db;
  late TransactionDao dao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = TransactionDao(db);
    await db.into(db.categories).insert(
      CategoriesCompanion.insert(
        id: const Value(1), name: 'Food', color: const Value('#abcdef'), type: 'expense',
      ),
    );
  });
  tearDown(() => db.close());

  TransactionModel tx({
    String date = '2026-07-01',
    String type = 'expense',
    double amount = 10,
    int? categoryId = 1,
  }) => TransactionModel(
        id: 0, transactionDate: date, transactionType: type,
        amount: amount, categoryId: categoryId,
      );

  test('create returns row with id and getAll joins category name/color', () async {
    final created = await dao.create(tx());
    expect(created.id, greaterThan(0));
    final all = await dao.getAll(const TransactionFilter(limit: 20));
    expect(all.length, 1);
    expect(all.first.categoryName, 'Food');
    expect(all.first.categoryColor, '#abcdef');
  });

  test('filters by transaction_type', () async {
    await dao.create(tx(type: 'expense'));
    await dao.create(tx(type: 'income', categoryId: null));
    final expenses = await dao.getAll(const TransactionFilter(transactionType: 'expense', limit: 20));
    expect(expenses.length, 1);
    expect(expenses.first.transactionType, 'expense');
  });

  test('filters by custom date range', () async {
    await dao.create(tx(date: '2026-07-01'));
    await dao.create(tx(date: '2026-07-20'));
    final inRange = await dao.getAll(const TransactionFilter(
      filter: 'custom', startDate: '2026-07-10', endDate: '2026-07-31', limit: 20,
    ));
    expect(inRange.length, 1);
    expect(inRange.first.transactionDate, '2026-07-20');
  });

  test('paginates by page/limit', () async {
    for (var i = 1; i <= 5; i++) {
      await dao.create(tx(date: '2026-07-0$i'));
    }
    final page1 = await dao.getAll(const TransactionFilter(page: 1, limit: 2));
    final page2 = await dao.getAll(const TransactionFilter(page: 2, limit: 2));
    expect(page1.length, 2);
    expect(page2.length, 2);
    expect(page1.map((t) => t.id).toSet().intersection(page2.map((t) => t.id).toSet()), isEmpty);
  });

  test('salary period filter overrides date and uses period bounds', () async {
    await db.into(db.salaryPeriods).insert(SalaryPeriodsCompanion.insert(
      id: const Value(9), name: 'Jul', startDate: '2026-07-01', endDate: '2026-07-15',
    ));
    await dao.create(tx(date: '2026-07-05'));
    await dao.create(tx(date: '2026-07-25'));
    final inPeriod = await dao.getAll(const TransactionFilter(salaryPeriodId: 9, limit: 20));
    expect(inPeriod.length, 1);
    expect(inPeriod.first.transactionDate, '2026-07-05');
  });

  test('update and delete', () async {
    final c = await dao.create(tx(amount: 10));
    final u = await dao.update(TransactionModel(
      id: c.id, transactionDate: c.transactionDate, transactionType: 'expense',
      amount: 99, categoryId: 1,
    ));
    expect(u.amount, 99);
    await dao.delete(c.id);
    expect(await dao.getAll(const TransactionFilter(limit: 20)), isEmpty);
  });
}
