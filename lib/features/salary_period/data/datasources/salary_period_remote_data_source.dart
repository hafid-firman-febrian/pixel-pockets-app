import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/api_client.dart';
import 'package:pixel_pocket/core/api/api_endpoints.dart';
import 'package:pixel_pocket/features/salary_period/data/dtos/salary_period_dto.dart';

class SalaryPeriodRemoteDataSource {
  SalaryPeriodRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SalaryPeriodDto>> getAll() async {
    final response = await _dio.get(ApiEndpoints.salaryPeriods);

    final list = response.data['data'] as List;

    return list
        .map((e) => SalaryPeriodDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final salaryPeriodRemoteDataSourceProvider =
    Provider<SalaryPeriodRemoteDataSource>(
      (ref) => SalaryPeriodRemoteDataSource(ref.watch(dioProvider)),
    );
