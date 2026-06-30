import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/application/services/dashboard_service.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/category_summary.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';
import 'package:pixel_pocket/features/transactions/application/services/transaction_service.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

sealed class PeriodSelection {
  const PeriodSelection();
}

class AutoPeriod extends PeriodSelection {
  const AutoPeriod();
}

class AllPeriods extends PeriodSelection {
  const AllPeriods();
}

class SpecificPeriod extends PeriodSelection {
  const SpecificPeriod(this.period);
  final SalaryPeriodModel period;
}

final selectedPeriodProvider = StateProvider<PeriodSelection>(
  (ref) => const AutoPeriod(),
);

final balanceHiddenProvider = StateProvider<bool>((ref) => true);

final effectivePeriodProvider = FutureProvider<SalaryPeriodModel?>((ref) async {
  final selection = ref.watch(selectedPeriodProvider);
  switch (selection) {
    case AllPeriods():
      return null;
    case SpecificPeriod(:final period):
      return period;
    case AutoPeriod():
      final periods = await ref.watch(salaryPeriodProvider.future);
      return _periodForToday(periods, _todayFloor());
  }
});

final dashboardSummaryProvider = FutureProvider<TransactionSummary>((
  ref,
) async {
  final period = await ref.watch(effectivePeriodProvider.future);
  return ref.watch(dashboardServiceProvider).summary(period?.id);
});

final expensesByCategoryProvider = FutureProvider<List<CategorySummary>>((
  ref,
) async {
  final period = await ref.watch(effectivePeriodProvider.future);
  return ref.watch(dashboardServiceProvider).expensesByCategory(period?.id);
});

/// The latest few transactions for the effective period (dashboard preview).
final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final period = await ref.watch(effectivePeriodProvider.future);
  return ref
      .watch(transactionServiceProvider)
      .list(TransactionFilter(salaryPeriodId: period?.id, limit: 5));
});


DateTime _todayFloor() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

SalaryPeriodModel? _periodForToday(
  List<SalaryPeriodModel> periods,
  DateTime today,
) {
  for (final p in periods) {
    final start = DateTime.parse(p.startDate);
    final end = DateTime.parse(p.endDate);
    if (!today.isBefore(start) && !today.isAfter(end)) return p;
  }
  return null;
}
