import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/application/services/dashboard_service.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

final dashboardSummaryProvider = FutureProvider<TransactionSummary>(
  (ref) => ref.watch(dashboardServiceProvider).summary(),
);
