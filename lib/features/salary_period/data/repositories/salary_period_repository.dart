import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/salary_period/data/datasources/salary_period_dao.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';

class SalaryPeriodRepository {
  SalaryPeriodRepository(this._dao);

  final SalaryPeriodDao _dao;

  Future<List<SalaryPeriodModel>> getAll() => _dao.getAll();

  Future<SalaryPeriodModel> create({
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) => _dao.create(name: name, startDate: startDate, endDate: endDate, salaryAmount: salaryAmount);

  Future<SalaryPeriodModel> update({
    required int id,
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) => _dao.update(id: id, name: name, startDate: startDate, endDate: endDate, salaryAmount: salaryAmount);

  Future<void> delete(int id) => _dao.delete(id);
}

final salaryPeriodRepositoryProvider = Provider<SalaryPeriodRepository>(
  (ref) => SalaryPeriodRepository(ref.watch(salaryPeriodDaoProvider)),
);
