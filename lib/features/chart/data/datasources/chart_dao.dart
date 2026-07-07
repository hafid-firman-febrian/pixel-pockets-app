import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';

class ChartDao {
  ChartDao(this._db);

  final AppDatabase _db;

  static final _day = DateFormat('yyyy-MM-dd');
  static final _month = DateFormat('yyyy-MM');

  Future<ChartData> getChart({
    String? filter,
    int? salaryPeriodId,
    DateTime? today,
  }) async {
    final now = today ?? DateTime.now();
    final anchor = DateTime(now.year, now.month, now.day);

    if (salaryPeriodId != null) {
      final p = await (_db.select(_db.salaryPeriods)
            ..where((r) => r.id.equals(salaryPeriodId)))
          .getSingleOrNull();
      if (p != null) {
        return _daily(DateTime.parse(p.startDate), DateTime.parse(p.endDate));
      }
    }

    switch (filter ?? 'month') {
      case 'week':
        final start = anchor.subtract(Duration(days: anchor.weekday - 1));
        return _daily(start, start.add(const Duration(days: 6)));
      case 'year':
        return _monthly(anchor.year);
      case 'month':
      default:
        final start = DateTime(anchor.year, anchor.month, 1);
        final end = DateTime(anchor.year, anchor.month + 1, 0);
        return _daily(start, end);
    }
  }

  Future<ChartData> _daily(DateTime start, DateTime end) async {
    final rows = await _rowsBetween(_day.format(start), _day.format(end));
    final labels = <String>[];
    final incomeByKey = <String, double>{};
    final expenseByKey = <String, double>{};
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      labels.add(_day.format(d));
    }
    for (final r in rows) {
      final key = r.transactionDate;
      if (r.transactionType == 'income') {
        incomeByKey[key] = (incomeByKey[key] ?? 0) + r.amount;
      } else if (r.transactionType == 'expense') {
        expenseByKey[key] = (expenseByKey[key] ?? 0) + r.amount;
      }
    }
    return ChartData(
      labels: labels,
      income: labels.map((k) => incomeByKey[k] ?? 0).toList(),
      expense: labels.map((k) => expenseByKey[k] ?? 0).toList(),
    );
  }

  Future<ChartData> _monthly(int year) async {
    final rows = await _rowsBetween('$year-01-01', '$year-12-31');
    final labels = [for (var m = 1; m <= 12; m++) _month.format(DateTime(year, m))];
    final incomeByKey = <String, double>{};
    final expenseByKey = <String, double>{};
    for (final r in rows) {
      final key = r.transactionDate.substring(0, 7);
      if (r.transactionType == 'income') {
        incomeByKey[key] = (incomeByKey[key] ?? 0) + r.amount;
      } else if (r.transactionType == 'expense') {
        expenseByKey[key] = (expenseByKey[key] ?? 0) + r.amount;
      }
    }
    return ChartData(
      labels: labels,
      income: labels.map((k) => incomeByKey[k] ?? 0).toList(),
      expense: labels.map((k) => expenseByKey[k] ?? 0).toList(),
    );
  }

  Future<List<Transaction>> _rowsBetween(String start, String end) {
    return (_db.select(_db.transactions)
          ..where((t) => t.transactionDate.isBiggerOrEqualValue(start))
          ..where((t) => t.transactionDate.isSmallerOrEqualValue(end)))
        .get();
  }
}

final chartDaoProvider = Provider<ChartDao>(
  (ref) => ChartDao(ref.watch(appDatabaseProvider)),
);
