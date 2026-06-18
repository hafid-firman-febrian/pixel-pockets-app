import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/salary_period/application/salary_period_service.dart';
import 'package:pixel_pocket/features/salary_period/domain/model/salary_period_model.dart';

final salaryPeriodProvider = FutureProvider<List<SalaryPeriodModel>>((ref) {
  return ref.watch(salaryPeriodServiceProvider).list();
});
