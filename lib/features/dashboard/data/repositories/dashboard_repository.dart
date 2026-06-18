import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

/// Maps the summary DTO to the domain model.
class DashboardRepository {
  DashboardRepository(this._remote);

  final DashboardRemoteDataSource _remote;

  Future<TransactionSummary> getSummary() async {
    final dto = await _remote.getSummary();
    return dto.toDomain();
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dashboardRemoteDataSourceProvider)),
);
