import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';

/// The time window the transactions list is scoped to.
enum RangeUnit { day, week, month, year, all }

/// Selected time-range filter for the transactions list: a [unit] plus an
/// [anchor] date that prev/next shifts. Pure value object — maps itself to a
/// [TransactionFilter] (`custom` + start/end) so prev/next works for any window.
class RangeFilter {
  const RangeFilter({required this.unit, required this.anchor, this.salaryPeriod});

  final RangeUnit unit;
  final DateTime anchor;

  /// When set, filters by this salary period instead of the time window —
  /// `salary_period_id` overrides the date filter on the backend.
  final SalaryPeriodModel? salaryPeriod;

  bool get isSalaryPeriod => salaryPeriod != null;

  /// Today's window — the default for a freshly selected unit.
  factory RangeFilter.now(RangeUnit unit) {
    final now = DateTime.now();
    return RangeFilter(unit: unit, anchor: DateTime(now.year, now.month, now.day));
  }

  /// Filter scoped to a specific salary period.
  factory RangeFilter.period(SalaryPeriodModel period) =>
      RangeFilter(unit: RangeUnit.all, anchor: DateTime(2000), salaryPeriod: period);

  TransactionFilter toFilter({required int page, required int limit}) {
    if (salaryPeriod != null) {
      return TransactionFilter(
        salaryPeriodId: salaryPeriod!.id,
        page: page,
        limit: limit,
      );
    }
    if (unit == RangeUnit.all) {
      return TransactionFilter(page: page, limit: limit);
    }
    final (start, end) = bounds;
    return TransactionFilter(
      filter: 'custom',
      startDate: _fmt(start),
      endDate: _fmt(end),
      page: page,
      limit: limit,
    );
  }

  /// Inclusive [start, end] of the current window.
  (DateTime, DateTime) get bounds {
    final a = DateTime(anchor.year, anchor.month, anchor.day);
    switch (unit) {
      case RangeUnit.day:
        return (a, a);
      case RangeUnit.week:
        final start = a.subtract(Duration(days: a.weekday - 1)); // Monday
        return (start, start.add(const Duration(days: 6)));
      case RangeUnit.month:
        return (DateTime(a.year, a.month, 1), DateTime(a.year, a.month + 1, 0));
      case RangeUnit.year:
        return (DateTime(a.year, 1, 1), DateTime(a.year, 12, 31));
      case RangeUnit.all:
        return (a, a);
    }
  }

  /// Shift the window by [delta] units (e.g. previous/next day, week, …).
  RangeFilter shifted(int delta) {
    switch (unit) {
      case RangeUnit.day:
        return RangeFilter(
          unit: unit,
          anchor: DateTime(anchor.year, anchor.month, anchor.day + delta),
        );
      case RangeUnit.week:
        return RangeFilter(
          unit: unit,
          anchor: DateTime(anchor.year, anchor.month, anchor.day + 7 * delta),
        );
      case RangeUnit.month:
        return RangeFilter(
          unit: unit,
          anchor: DateTime(anchor.year, anchor.month + delta, 1),
        );
      case RangeUnit.year:
        return RangeFilter(unit: unit, anchor: DateTime(anchor.year + delta, 1, 1));
      case RangeUnit.all:
        return this;
    }
  }

  /// Human label for the navigator (e.g. "17 Jun 2026", "Jun 2026", "2026").
  String get label {
    if (salaryPeriod != null) return salaryPeriod!.name;
    final (start, end) = bounds;
    switch (unit) {
      case RangeUnit.day:
        return DateFormat('d MMM yyyy').format(start);
      case RangeUnit.week:
        return '${DateFormat('d MMM').format(start)} – '
            '${DateFormat('d MMM').format(end)}';
      case RangeUnit.month:
        return DateFormat('MMM yyyy').format(start);
      case RangeUnit.year:
        return DateFormat('yyyy').format(start);
      case RangeUnit.all:
        return 'All time';
    }
  }

  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  bool operator ==(Object other) =>
      other is RangeFilter &&
      other.unit == unit &&
      other.anchor == anchor &&
      other.salaryPeriod?.id == salaryPeriod?.id;

  @override
  int get hashCode => Object.hash(unit, anchor, salaryPeriod?.id);
}

/// Selected range for the transactions list. Changing it re-runs
/// [TransactionsController.build], which refetches page 1.
final rangeFilterProvider = StateProvider<RangeFilter>(
  (ref) => RangeFilter.now(RangeUnit.day),
);
