import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/salary_period/application/services/salary_period_service.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';

/// Glue between the salary-period form and the service: creates a period, then
/// invalidates [salaryPeriodProvider] so the picker/filters refetch. Throws
/// [Failure] on error for the caller (the form) to surface.
class SalaryPeriodController {
  SalaryPeriodController(this._ref);

  final Ref _ref;

  Future<void> create({
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) async {
    await _ref.read(salaryPeriodServiceProvider).create(
          name: name,
          startDate: startDate,
          endDate: endDate,
          salaryAmount: salaryAmount,
        );
    _ref.invalidate(salaryPeriodProvider);
  }

  Future<void> update({
    required int id,
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) async {
    await _ref.read(salaryPeriodServiceProvider).update(
          id: id,
          name: name,
          startDate: startDate,
          endDate: endDate,
          salaryAmount: salaryAmount,
        );
    _ref.invalidate(salaryPeriodProvider);
  }

  Future<void> delete(int id) async {
    await _ref.read(salaryPeriodServiceProvider).delete(id);
    _ref.invalidate(salaryPeriodProvider);
  }
}

final salaryPeriodControllerProvider = Provider<SalaryPeriodController>(
  (ref) => SalaryPeriodController(ref),
);
