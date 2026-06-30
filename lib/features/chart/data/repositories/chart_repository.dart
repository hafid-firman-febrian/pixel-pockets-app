import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/chart/data/datasources/chart_remote_data_source.dart';
import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';

/// Maps the chart DTO to the domain model and transport errors to [Failure].
class ChartRepository {
  ChartRepository(this._remote);

  final ChartRemoteDataSource _remote;

  Future<ChartData> getChart({String? filter, int? salaryPeriodId}) async {
    try {
      final dto = await _remote.getChart(
        filter: filter,
        salaryPeriodId: salaryPeriodId,
      );
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final chartRepositoryProvider = Provider<ChartRepository>(
  (ref) => ChartRepository(ref.watch(chartRemoteDataSourceProvider)),
);
