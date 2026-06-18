import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/salary_period/data/datasources/salary_period_remote_data_source.dart';
import 'package:pixel_pocket/features/salary_period/domain/model/salary_period_model.dart';

class SalaryPeriodRepository {
  SalaryPeriodRepository(this._remote);

  final SalaryPeriodRemoteDataSource _remote;

  Future<List<SalaryPeriodModel>> getAll() async {
    try {
      final dtos = await _remote.getAll();
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final salaryPeriodRepositoryProvider = Provider<SalaryPeriodRepository>(
  (ref) =>
      SalaryPeriodRepository(ref.watch(salaryPeriodRemoteDataSourceProvider)),
);
