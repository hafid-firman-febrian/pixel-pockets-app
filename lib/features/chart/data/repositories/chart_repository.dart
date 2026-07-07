import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/chart/data/datasources/chart_dao.dart';
import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';

class ChartRepository {
  ChartRepository(this._dao);

  final ChartDao _dao;

  Future<ChartData> getChart({String? filter, int? salaryPeriodId}) =>
      _dao.getChart(filter: filter, salaryPeriodId: salaryPeriodId);
}

final chartRepositoryProvider = Provider<ChartRepository>(
  (ref) => ChartRepository(ref.watch(chartDaoProvider)),
);
