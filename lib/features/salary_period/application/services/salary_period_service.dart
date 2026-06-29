import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/salary_period/data/repositories/salary_period_repository.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';

class SalaryPeriodService {
  SalaryPeriodService(this._repo);
  final SalaryPeriodRepository _repo;

  Future<List<SalaryPeriodModel>> list() => _repo.getAll();

  Future<SalaryPeriodModel> create({
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) => _repo.create(
    name: name,
    startDate: startDate,
    endDate: endDate,
    salaryAmount: salaryAmount,
  );

  Future<SalaryPeriodModel> update({
    required int id,
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) => _repo.update(
    id: id,
    name: name,
    startDate: startDate,
    endDate: endDate,
    salaryAmount: salaryAmount,
  );

  Future<void> delete(int id) => _repo.delete(id);
}

final salaryPeriodServiceProvider = Provider<SalaryPeriodService>(
  (ref) => SalaryPeriodService(ref.watch(salaryPeriodRepositoryProvider)),
);
