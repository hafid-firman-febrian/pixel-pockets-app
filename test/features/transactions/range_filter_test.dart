import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';

void main() {
  final today = DateTime(2026, 7, 19);

  RangeFilter on(RangeUnit unit, DateTime anchor) =>
      RangeFilter(unit: unit, anchor: anchor);

  RangeFilter period(String start, String end) => RangeFilter.period(
    SalaryPeriodModel(id: 1, name: 'Period', startDate: start, endDate: end),
  );

  group('day', () {
    test('today stays today', () {
      expect(
        on(RangeUnit.day, DateTime(2026, 7, 19)).entryDateFor(today),
        DateTime(2026, 7, 19),
      );
    });

    test('yesterday defaults to yesterday', () {
      expect(
        on(RangeUnit.day, DateTime(2026, 7, 18)).entryDateFor(today),
        DateTime(2026, 7, 18),
      );
    });

    test('tomorrow defaults to tomorrow', () {
      expect(
        on(RangeUnit.day, DateTime(2026, 7, 20)).entryDateFor(today),
        DateTime(2026, 7, 20),
      );
    });
  });

  group('week', () {
    test('current week keeps today', () {
      expect(
        on(RangeUnit.week, DateTime(2026, 7, 19)).entryDateFor(today),
        DateTime(2026, 7, 19),
      );
    });

    test('previous week clamps to its last day', () {
      expect(
        on(RangeUnit.week, DateTime(2026, 7, 12)).entryDateFor(today),
        DateTime(2026, 7, 12),
      );
    });

    test('next week clamps to its first day', () {
      expect(
        on(RangeUnit.week, DateTime(2026, 7, 26)).entryDateFor(today),
        DateTime(2026, 7, 20),
      );
    });
  });

  group('month', () {
    test('current month keeps today', () {
      expect(
        on(RangeUnit.month, DateTime(2026, 7, 1)).entryDateFor(today),
        DateTime(2026, 7, 19),
      );
    });

    test('previous month clamps to its last day', () {
      expect(
        on(RangeUnit.month, DateTime(2026, 6, 1)).entryDateFor(today),
        DateTime(2026, 6, 30),
      );
    });

    test('next month clamps to its first day', () {
      expect(
        on(RangeUnit.month, DateTime(2026, 8, 1)).entryDateFor(today),
        DateTime(2026, 8, 1),
      );
    });

    test('leap february clamps to the 29th', () {
      expect(
        on(RangeUnit.month, DateTime(2024, 2, 1)).entryDateFor(today),
        DateTime(2024, 2, 29),
      );
    });
  });

  group('year', () {
    test('current year keeps today', () {
      expect(
        on(RangeUnit.year, DateTime(2026, 1, 1)).entryDateFor(today),
        DateTime(2026, 7, 19),
      );
    });

    test('previous year clamps to 31 december', () {
      expect(
        on(RangeUnit.year, DateTime(2025, 1, 1)).entryDateFor(today),
        DateTime(2025, 12, 31),
      );
    });
  });

  group('all', () {
    test('returns today', () {
      expect(
        RangeFilter.now(RangeUnit.all).entryDateFor(today),
        DateTime(2026, 7, 19),
      );
    });

    test('returns today even when the anchor is stale', () {
      expect(
        on(RangeUnit.all, DateTime(2026, 7, 18)).entryDateFor(today),
        DateTime(2026, 7, 19),
      );
    });
  });

  group('salary period', () {
    test('period containing today keeps today', () {
      expect(
        period('2026-06-25', '2026-07-24').entryDateFor(today),
        DateTime(2026, 7, 19),
      );
    });

    test('past period clamps to its end date', () {
      expect(
        period('2026-05-25', '2026-06-24').entryDateFor(today),
        DateTime(2026, 6, 24),
      );
    });

    test('future period clamps to its start date', () {
      expect(
        period('2026-07-25', '2026-08-24').entryDateFor(today),
        DateTime(2026, 7, 25),
      );
    });

    test('unparseable dates fall back to today', () {
      expect(period('not-a-date', 'nope').entryDateFor(today), today);
    });
  });

  group('picker window', () {
    test('a year before the window clamps to entryDateMin', () {
      expect(
        on(RangeUnit.year, DateTime(2019, 1, 1)).entryDateFor(today),
        RangeFilter.entryDateMin,
      );
    });

    test('never returns a date the picker would assert on', () {
      final filter = on(RangeUnit.year, DateTime(2019, 1, 1));
      final result = filter.entryDateFor(today);
      expect(result.isBefore(RangeFilter.entryDateMin), isFalse);
      expect(result.isAfter(RangeFilter.entryDateMax), isFalse);
    });
  });

  test('ignores the time component of today', () {
    expect(
      on(RangeUnit.day, DateTime(2026, 7, 19)).entryDateFor(
        DateTime(2026, 7, 19, 23, 59, 59),
      ),
      DateTime(2026, 7, 19),
    );
  });
}
