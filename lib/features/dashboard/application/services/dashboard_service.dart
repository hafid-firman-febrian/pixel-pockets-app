import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

/// Business logic for the dashboard.
class DashboardService {
  DashboardService(this._repo);

  final DashboardRepository _repo;

  Future<TransactionSummary> summary() => _repo.getSummary();
}

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(ref.watch(dashboardRepositoryProvider)),
);
