import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/chart/data/datasources/chart_local_data_source.dart';
import 'package:pixel_pocket/features/chart/data/datasources/chart_remote_data_source.dart';
import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';

class ChartRepository {
  ChartRepository(this._remote, this._local);

  final ChartRemoteDataSource _remote;
  final ChartLocalDataSource _local;

  Future<ChartData> getChart({String? filter, int? salaryPeriodId}) async {
    try {
      final dto = await _remote.getChart(
        filter: filter,
        salaryPeriodId: salaryPeriodId,
      );
      await _local.save(
        filter: filter,
        salaryPeriodId: salaryPeriodId,
        dto: dto,
      );
      return dto.toDomain();
    } on DioException catch (e) {
      if (isConnectivityError(e)) {
        final cached = _local.read(
          filter: filter,
          salaryPeriodId: salaryPeriodId,
        );
        if (cached != null) return cached.toDomain();
      }
      throw Failure.fromDio(e);
    }
  }
}

final chartRepositoryProvider = Provider<ChartRepository>(
  (ref) => ChartRepository(
    ref.watch(chartRemoteDataSourceProvider),
    ref.watch(chartLocalDataSourceProvider),
  ),
);
