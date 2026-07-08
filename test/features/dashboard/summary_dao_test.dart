import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/dashboard/data/datasources/summary_dao.dart';

void main() {
  late AppDatabase db;
  late SummaryDao dao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SummaryDao(db);
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: const Value(1), name: 'Food', color: const Value('#111111'), type: 'expense'));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: const Value(2), name: 'Transport', color: const Value('#222222'), type: 'expense'));
    Future<void> add(String type, double amt, int? cat, String date) =>
        db.into(db.transactions).insert(TransactionsCompanion.insert(
            transactionDate: date, transactionType: type, amount: amt, categoryId: Value(cat)));
    await add('income', 1000, null, '2026-07-01');
    await add('expense', 300, 1, '2026-07-02');
    await add('expense', 100, 2, '2026-07-03');
  });
  tearDown(() => db.close());

  test('summary aggregates income/expense/balance/count', () async {
    final s = await dao.getSummary(null);
    expect(s.totalIncome, 1000);
    expect(s.totalExpense, 400);
    expect(s.balance, 600);
    expect(s.transactionCount, 3);
  });

  test('by-category totals with percentage relative to same type', () async {
    final rows = await dao.getByCategory(null);
    final food = rows.firstWhere((r) => r.categoryId == 1);
    expect(food.total, 300);
    expect(food.percentage, closeTo(75, 0.001));
    expect(food.count, 1);
  });

  test('summary respects salary period bounds', () async {
    await db.into(db.salaryPeriods).insert(SalaryPeriodsCompanion.insert(
        id: const Value(5), name: 'P', startDate: '2026-07-02', endDate: '2026-07-02'));
    final s = await dao.getSummary(5);
    expect(s.totalExpense, 300);
    expect(s.totalIncome, 0);
    expect(s.transactionCount, 1);
  });
}
