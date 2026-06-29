import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/category_summary.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

/// Maps the summary DTO to the domain model.
class DashboardRepository {
  DashboardRepository(this._remote);

  final DashboardRemoteDataSource _remote;

  Future<TransactionSummary> getSummary(int? periodId) async {
    try {
      final dto = await _remote.getSummary(periodId);
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<List<CategorySummary>> getByCategory(int? periodId) async {
    try {
      final dtos = await _remote.getByCategory(periodId);
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dashboardRemoteDataSourceProvider)),
);
