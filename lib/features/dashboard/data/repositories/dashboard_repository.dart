import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/data/datasources/summary_dao.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/category_summary.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

class DashboardRepository {
  DashboardRepository(this._dao);

  final SummaryDao _dao;

  Future<TransactionSummary> getSummary(int? periodId) => _dao.getSummary(periodId);

  Future<List<CategorySummary>> getByCategory(int? periodId) =>
      _dao.getByCategory(periodId);
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(summaryDaoProvider)),
);
