import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/application/services/dashboard_service.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';
import 'package:pixel_pocket/features/salary_period/domain/model/salary_period_model.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';

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

/// Dashboard summary, difilter oleh period efektif.
final dashboardSummaryProvider = FutureProvider<TransactionSummary>((
  ref,
) async {
  final period = await ref.watch(effectivePeriodProvider.future);
  return ref.watch(dashboardServiceProvider).summary(period?.id);
});

/// Tanggal hari ini tanpa komponen jam (untuk perbandingan inklusif).
DateTime _todayFloor() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Period pertama yang rentang [startDate, endDate]-nya memuat [today]
/// (inklusif), atau null bila tidak ada.
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
