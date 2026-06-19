import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/salary_period/data/repositories/salary_period_repository.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';

class SalaryPeriodService {
  SalaryPeriodService(this._repo);
  final SalaryPeriodRepository _repo;

  Future<List<SalaryPeriodModel>> list() => _repo.getAll();
}

final salaryPeriodServiceProvider = Provider<SalaryPeriodService>(
  (ref) => SalaryPeriodService(ref.watch(salaryPeriodRepositoryProvider)),
);
