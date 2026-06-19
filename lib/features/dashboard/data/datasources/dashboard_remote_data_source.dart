import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/api_client.dart';
import 'package:pixel_pocket/core/api/api_endpoints.dart';
import 'package:pixel_pocket/features/dashboard/data/dtos/summary_dto.dart';

/// Source of dashboard summary data. Returns stub values for now; wiring the
/// real `GET /api/summary` endpoint is out of scope for this migration.
class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._dio);
  final Dio _dio;

  Future<SummaryDto> getSummary(int? salaryPeriodId) async {
    final response = await _dio.get(
      ApiEndpoints.summary,
      queryParameters: {
        if (salaryPeriodId != null) 'salary_period_id': salaryPeriodId,
      },
    );

    return SummaryDto.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSource(ref.watch(dioProvider)),
);
