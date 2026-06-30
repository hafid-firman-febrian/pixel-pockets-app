import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/chart/application/services/chart_service.dart';
import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';

enum ChartUnit { week, month, year }

class ChartFilter {
  const ChartFilter({this.unit = ChartUnit.month, this.salaryPeriod});

  final ChartUnit unit;
  final SalaryPeriodModel? salaryPeriod;

  bool get isSalaryPeriod => salaryPeriod != null;

  factory ChartFilter.period(SalaryPeriodModel period) =>
      ChartFilter(salaryPeriod: period);

  @override
  bool operator ==(Object other) =>
      other is ChartFilter &&
      other.unit == unit &&
      other.salaryPeriod?.id == salaryPeriod?.id;

  @override
  int get hashCode => Object.hash(unit, salaryPeriod?.id);
}

final chartFilterProvider = StateProvider<ChartFilter>(
  (ref) => const ChartFilter(),
);

final chartProvider = FutureProvider<ChartData>((ref) {
  final filter = ref.watch(chartFilterProvider);
  final service = ref.watch(chartServiceProvider);
  if (filter.salaryPeriod != null) {
    return service.chart(salaryPeriodId: filter.salaryPeriod!.id);
  }
  return service.chart(filter: filter.unit.name);
});
