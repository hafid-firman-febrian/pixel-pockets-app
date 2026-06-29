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

  Future<SalaryPeriodDto> create({
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.salaryPeriods,
      data: {
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'salary_amount': ?salaryAmount,
      },
    );
    return SalaryPeriodDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<SalaryPeriodDto> update({
    required int id,
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.salaryPeriodById(id),
      data: {
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'salary_amount': ?salaryAmount,
      },
    );
    return SalaryPeriodDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiEndpoints.salaryPeriodById(id));
  }
}

final salaryPeriodRemoteDataSourceProvider =
    Provider<SalaryPeriodRemoteDataSource>(
      (ref) => SalaryPeriodRemoteDataSource(ref.watch(dioProvider)),
    );
