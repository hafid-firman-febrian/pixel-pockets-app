import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/category_summary.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

class SummaryDao {
  SummaryDao(this._db);

  final AppDatabase _db;

  Future<(String?, String?)> _bounds(int? salaryPeriodId) async {
    if (salaryPeriodId == null) return (null, null);
    final p = await (_db.select(_db.salaryPeriods)
          ..where((r) => r.id.equals(salaryPeriodId)))
        .getSingleOrNull();
    return (p?.startDate, p?.endDate);
  }

  Future<List<Transaction>> _rows(int? salaryPeriodId) async {
    final (start, end) = await _bounds(salaryPeriodId);
    final q = _db.select(_db.transactions);
    if (start != null) q.where((t) => t.transactionDate.isBiggerOrEqualValue(start));
    if (end != null) q.where((t) => t.transactionDate.isSmallerOrEqualValue(end));
    return q.get();
  }

  Future<TransactionSummary> getSummary(int? salaryPeriodId) async {
    final rows = await _rows(salaryPeriodId);
    var income = 0.0;
    var expense = 0.0;
    for (final r in rows) {
      if (r.transactionType == 'income') income += r.amount;
      if (r.transactionType == 'expense') expense += r.amount;
    }
    return TransactionSummary(
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      transactionCount: rows.length,
    );
  }

  Future<List<CategorySummary>> getByCategory(int? salaryPeriodId) async {
    final rows = await _rows(salaryPeriodId);
    final cats = await _db.select(_db.categories).get();
    final catById = {for (final c in cats) c.id: c};

    final agg = <int, ({double total, int count, String type})>{};
    for (final r in rows) {
      final id = r.categoryId;
      if (id == null) continue;
      final prev = agg[id];
      agg[id] = (
        total: (prev?.total ?? 0) + r.amount,
        count: (prev?.count ?? 0) + 1,
        type: r.transactionType,
      );
    }

    final typeTotals = <String, double>{};
    for (final e in agg.entries) {
      typeTotals[e.value.type] = (typeTotals[e.value.type] ?? 0) + e.value.total;
    }

    return agg.entries.map((e) {
      final cat = catById[e.key];
      final denom = typeTotals[e.value.type] ?? 0;
      return CategorySummary(
        categoryId: e.key,
        name: cat?.name ?? 'Unknown',
        colorHex: cat?.color,
        type: e.value.type,
        total: e.value.total,
        percentage: denom == 0 ? 0 : e.value.total / denom * 100,
        count: e.value.count,
      );
    }).toList();
  }
}

final summaryDaoProvider = Provider<SummaryDao>(
  (ref) => SummaryDao(ref.watch(appDatabaseProvider)),
);
