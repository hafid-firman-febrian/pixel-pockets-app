import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/chart/data/datasources/chart_dao.dart';

void main() {
  late AppDatabase db;
  late ChartDao dao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ChartDao(db);
    Future<void> add(String type, double amt, String date) =>
      db.into(db.transactions).insert(TransactionsCompanion.insert(
        transactionDate: date, transactionType: type, amount: amt));
    await add('income', 500, '2026-07-10');
    await add('expense', 200, '2026-07-10');
    await add('expense', 50, '2026-07-12');
  });
  tearDown(() => db.close());

  test('month filter returns one label per day with aligned totals', () async {
    final data = await dao.getChart(filter: 'month', today: DateTime(2026, 7, 15));
    expect(data.labels.length, 31);
    final i10 = data.labels.indexOf('2026-07-10');
    expect(i10, greaterThanOrEqualTo(0));
    expect(data.income[i10], 500);
    expect(data.expense[i10], 200);
    final i11 = data.labels.indexOf('2026-07-11');
    expect(data.expense[i11], 0);
  });

  test('year filter returns 12 monthly buckets', () async {
    final data = await dao.getChart(filter: 'year', today: DateTime(2026, 7, 15));
    expect(data.labels.length, 12);
    final jul = data.labels.indexOf('2026-07');
    expect(data.expense[jul], 250);
    expect(data.income[jul], 500);
  });

  test('salary period uses its bounds daily', () async {
    await db.into(db.salaryPeriods).insert(SalaryPeriodsCompanion.insert(
      id: const Value(3), name: 'P', startDate: '2026-07-10', endDate: '2026-07-12'));
    final data = await dao.getChart(salaryPeriodId: 3, today: DateTime(2026, 7, 15));
    expect(data.labels, ['2026-07-10', '2026-07-11', '2026-07-12']);
    expect(data.expense[0], 200);
    expect(data.expense[2], 50);
  });
}
