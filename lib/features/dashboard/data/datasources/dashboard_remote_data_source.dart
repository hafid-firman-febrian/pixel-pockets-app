import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/data/dtos/summary_dto.dart';

/// Source of dashboard summary data. Returns stub values for now; wiring the
/// real `GET /api/summary` endpoint is out of scope for this migration.
class DashboardRemoteDataSource {
  Future<SummaryDto> getSummary() async => const SummaryDto(
        totalIncome: 10000000,
        totalExpense: 5000000,
        balance: 5000000,
        transactionCount: 10,
      );
}

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSource(),
);
