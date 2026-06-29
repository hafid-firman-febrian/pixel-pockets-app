import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/category_summary.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';


class DashboardService {
  DashboardService(this._repo);

  final DashboardRepository _repo;

  Future<TransactionSummary> summary(int? periodId) =>
      _repo.getSummary(periodId);

  
  Future<List<CategorySummary>> expensesByCategory(int? periodId) async {
    final all = await _repo.getByCategory(periodId);
    final expenses = all.where((c) => c.type == 'expense').toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return expenses;
  }
}

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(ref.watch(dashboardRepositoryProvider)),
);
