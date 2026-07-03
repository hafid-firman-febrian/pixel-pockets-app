import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/salary_period/data/datasources/salary_period_local_data_source.dart';
import 'package:pixel_pocket/features/salary_period/data/datasources/salary_period_remote_data_source.dart';
import 'package:pixel_pocket/features/salary_period/data/dtos/salary_period_dto.dart';
import 'package:pixel_pocket/features/salary_period/data/repositories/salary_period_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemote implements SalaryPeriodRemoteDataSource {
  _FakeRemote({this.result, this.error});
  final List<SalaryPeriodDto>? result;
  final Object? error;

  @override
  Future<List<SalaryPeriodDto>> getAll() async {
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<SalaryPeriodDto> create({
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) async => throw UnimplementedError();
  @override
  Future<SalaryPeriodDto> update({
    required int id,
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) async => throw UnimplementedError();
  @override
  Future<void> delete(int id) async {}
}

DioException _offline() => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.connectionError,
);

const _period = SalaryPeriodDto(
  id: 1,
  name: 'July',
  startDate: '2026-07-01',
  endDate: '2026-07-31',
  salaryAmount: 5000000,
);

void main() {
  late SalaryPeriodLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    local = SalaryPeriodLocalDataSource(
      CacheStore(await SharedPreferences.getInstance()),
    );
  });

  test('success caches; offline returns cached', () async {
    final ok = SalaryPeriodRepository(_FakeRemote(result: [_period]), local);
    final fresh = await ok.getAll();
    expect(fresh.single.name, 'July');

    final off = SalaryPeriodRepository(_FakeRemote(error: _offline()), local);
    final cached = await off.getAll();
    expect(cached.single.id, 1);
  });

  test('offline with empty cache throws', () async {
    final off = SalaryPeriodRepository(_FakeRemote(error: _offline()), local);
    expect(() => off.getAll(), throwsA(isA<Failure>()));
  });
}
