import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/backup/data/backup_serialization.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('transaction row round-trips including nulls', () async {
    final id = await db.into(db.transactions).insert(TransactionsCompanion.insert(
        transactionDate: '2026-07-05', transactionType: 'expense', amount: 12.5,
        categoryId: const Value(7), description: const Value('kopi')));
    final row = await (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingle();

    final cells = transactionToRow(row);
    expect(cells.first.toString(), id.toString());

    final companion = transactionFromRow(cells);
    expect(companion.amount.value, 12.5);
    expect(companion.categoryId.value, 7);
    expect(companion.description.value, 'kopi');
    expect(companion.id.value, id);
  });

  test('null category and description serialize to empty and back to null', () async {
    final id = await db.into(db.transactions).insert(TransactionsCompanion.insert(
        transactionDate: '2026-07-06', transactionType: 'income', amount: 100));
    final row = await (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingle();
    final cells = transactionToRow(row);
    expect(cells[4], '');
    final c = transactionFromRow(cells);
    expect(c.categoryId.value, isNull);
    expect(c.description.value, isNull);
  });

  test('category and salary period round-trip', () async {
    final cid = await db.into(db.categories).insert(
        CategoriesCompanion.insert(name: 'Food', color: const Value('#111111'), type: 'expense'));
    final crow = await (db.select(db.categories)..where((c) => c.id.equals(cid))).getSingle();
    final cc = categoryFromRow(categoryToRow(crow));
    expect(cc.name.value, 'Food');
    expect(cc.color.value, '#111111');
    expect(cc.type.value, 'expense');

    final pid = await db.into(db.salaryPeriods).insert(
        SalaryPeriodsCompanion.insert(name: 'Jul', startDate: '2026-07-01', endDate: '2026-07-31', salaryAmount: const Value(5000)));
    final prow = await (db.select(db.salaryPeriods)..where((p) => p.id.equals(pid))).getSingle();
    final pc = salaryPeriodFromRow(salaryPeriodToRow(prow));
    expect(pc.salaryAmount.value, 5000);
    expect(pc.name.value, 'Jul');
  });

  test('padRow pads a short salary period row from trimmed sheet values', () {
    final row = padRow(['3', 'Jul', '2026-07-01', '2026-07-31'], salaryPeriodsHeader.length);
    final companion = salaryPeriodFromRow(row);
    expect(companion.salaryAmount.value, isNull);
    expect(companion.name.value, 'Jul');
  });

  test('padRow pads a short transaction row from trimmed sheet values', () {
    final row = padRow(
        ['99', '2026-07-05', 'expense', '12', '7', 'kopi'], transactionsHeader.length);
    final companion = transactionFromRow(row);
    expect(companion.createdAt.value, isNull);
    expect(companion.updatedAt.value, isNull);
  });
}
