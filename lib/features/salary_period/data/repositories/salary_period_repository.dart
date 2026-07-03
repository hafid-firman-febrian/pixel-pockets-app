import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/salary_period/data/datasources/salary_period_local_data_source.dart';
import 'package:pixel_pocket/features/salary_period/data/datasources/salary_period_remote_data_source.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';

class SalaryPeriodRepository {
  SalaryPeriodRepository(this._remote, this._local);

  final SalaryPeriodRemoteDataSource _remote;
  final SalaryPeriodLocalDataSource _local;

  Future<List<SalaryPeriodModel>> getAll() async {
    try {
      final dtos = await _remote.getAll();
      await _local.save(dtos);
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      if (isConnectivityError(e)) {
        final cached = _local.read();
        if (cached != null) return cached.map((d) => d.toDomain()).toList();
      }
      throw Failure.fromDio(e);
    }
  }

  Future<SalaryPeriodModel> create({
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) async {
    try {
      final dto = await _remote.create(
        name: name,
        startDate: startDate,
        endDate: endDate,
        salaryAmount: salaryAmount,
      );
      await _local.invalidate();
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<SalaryPeriodModel> update({
    required int id,
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) async {
    try {
      final dto = await _remote.update(
        id: id,
        name: name,
        startDate: startDate,
        endDate: endDate,
        salaryAmount: salaryAmount,
      );
      await _local.invalidate();
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _remote.delete(id);
      await _local.invalidate();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final salaryPeriodRepositoryProvider = Provider<SalaryPeriodRepository>(
  (ref) => SalaryPeriodRepository(
    ref.watch(salaryPeriodRemoteDataSourceProvider),
    ref.watch(salaryPeriodLocalDataSourceProvider),
  ),
);
