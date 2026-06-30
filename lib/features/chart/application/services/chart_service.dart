import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/chart/data/repositories/chart_repository.dart';
import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';


class ChartService {
  ChartService(this._repo);

  final ChartRepository _repo;

  Future<ChartData> chart({String? filter, int? salaryPeriodId}) =>
      _repo.getChart(filter: filter, salaryPeriodId: salaryPeriodId);
}

final chartServiceProvider = Provider<ChartService>(
  (ref) => ChartService(ref.watch(chartRepositoryProvider)),
);
