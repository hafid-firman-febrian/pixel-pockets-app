import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/api_client.dart';
import 'package:pixel_pocket/core/api/api_endpoints.dart';
import 'package:pixel_pocket/features/chart/data/dtos/chart_dto.dart';



class ChartRemoteDataSource {
  ChartRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ChartDto> getChart({String? filter, int? salaryPeriodId}) async {
    final response = await _dio.get(
      ApiEndpoints.summaryChart,
      queryParameters: {
        'filter': ?filter,
        'salary_period_id': ?salaryPeriodId,
      },
    );
    return ChartDto.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}

final chartRemoteDataSourceProvider = Provider<ChartRemoteDataSource>(
  (ref) => ChartRemoteDataSource(ref.watch(dioProvider)),
);
