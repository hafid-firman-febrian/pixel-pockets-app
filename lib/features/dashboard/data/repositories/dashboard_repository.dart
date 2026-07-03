import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:pixel_pocket/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/category_summary.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

class DashboardRepository {
  DashboardRepository(this._remote, this._local);

  final DashboardRemoteDataSource _remote;
  final DashboardLocalDataSource _local;

  Future<TransactionSummary> getSummary(int? periodId) async {
    try {
      final dto = await _remote.getSummary(periodId);
      await _local.saveSummary(periodId, dto);
      return dto.toDomain();
    } on DioException catch (e) {
      if (isConnectivityError(e)) {
        final cached = _local.readSummary(periodId);
        if (cached != null) return cached.toDomain();
      }
      throw Failure.fromDio(e);
    }
  }

  Future<List<CategorySummary>> getByCategory(int? periodId) async {
    try {
      final dtos = await _remote.getByCategory(periodId);
      await _local.saveByCategory(periodId, dtos);
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      if (isConnectivityError(e)) {
        final cached = _local.readByCategory(periodId);
        if (cached != null) return cached.map((d) => d.toDomain()).toList();
      }
      throw Failure.fromDio(e);
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(
    ref.watch(dashboardRemoteDataSourceProvider),
    ref.watch(dashboardLocalDataSourceProvider),
  ),
);
