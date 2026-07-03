import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/chart/data/datasources/chart_local_data_source.dart';
import 'package:pixel_pocket/features/chart/data/datasources/chart_remote_data_source.dart';
import 'package:pixel_pocket/features/chart/data/dtos/chart_dto.dart';
import 'package:pixel_pocket/features/chart/data/repositories/chart_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemote implements ChartRemoteDataSource {
  _FakeRemote({this.result, this.error});
  final ChartDto? result;
  final Object? error;

  @override
  Future<ChartDto> getChart({String? filter, int? salaryPeriodId}) async {
    if (error != null) throw error!;
    return result!;
  }
}

DioException _offline() => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.connectionError,
);

const _chart = ChartDto(
  labels: ['1', '2'],
  income: [10, 20],
  expense: [5, 8],
);

void main() {
  late ChartLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    local = ChartLocalDataSource(
      CacheStore(await SharedPreferences.getInstance()),
    );
  });

  test('success caches; offline returns cached', () async {
    final ok = ChartRepository(_FakeRemote(result: _chart), local);
    final fresh = await ok.getChart(filter: 'month');
    expect(fresh.labels.length, 2);

    final off = ChartRepository(_FakeRemote(error: _offline()), local);
    final cached = await off.getChart(filter: 'month');
    expect(cached.income, [10, 20]);
  });

  test('offline with empty cache throws', () async {
    final off = ChartRepository(_FakeRemote(error: _offline()), local);
    expect(() => off.getChart(filter: 'month'), throwsA(isA<Failure>()));
  });
}
