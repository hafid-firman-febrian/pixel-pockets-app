import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/application/services/dashboard_service.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';
import 'package:pixel_pocket/features/salary_period/domain/model/salary_period_model.dart';

final selectedPeriodProvider = StateProvider<SalaryPeriodModel?>((ref) => null);

final dashboardSummaryProvider = FutureProvider<TransactionSummary>((ref) {
  final period = ref.watch(selectedPeriodProvider);

  return ref.watch(dashboardServiceProvider).summary(period?.id);
});
