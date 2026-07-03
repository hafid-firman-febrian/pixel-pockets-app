import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:pixel_pocket/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:pixel_pocket/features/dashboard/data/dtos/category_summary_dto.dart';
import 'package:pixel_pocket/features/dashboard/data/dtos/summary_dto.dart';
import 'package:pixel_pocket/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemote implements DashboardRemoteDataSource {
  _FakeRemote({this.summary, this.byCategory, this.error});
  final SummaryDto? summary;
  final List<CategorySummaryDto>? byCategory;
  final Object? error;

  @override
  Future<SummaryDto> getSummary(int? id) async {
    if (error != null) throw error!;
    return summary!;
  }

  @override
  Future<List<CategorySummaryDto>> getByCategory(int? id) async {
    if (error != null) throw error!;
    return byCategory!;
  }
}

DioException _offline() => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.connectionError,
);

const _summary = SummaryDto(
  totalIncome: 100,
  totalExpense: 40,
  balance: 60,
  transactionCount: 3,
);

const _byCategory = [
  CategorySummaryDto(
    categoryId: 1,
    name: 'Groceries',
    color: '#7D9B76',
    type: 'expense',
    total: 40,
    percentage: 100,
    count: 2,
  ),
];

void main() {
  late DashboardLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    local = DashboardLocalDataSource(
      CacheStore(await SharedPreferences.getInstance()),
    );
  });

  test('summary: success caches; offline returns cached', () async {
    final ok = DashboardRepository(_FakeRemote(summary: _summary), local);
    final fresh = await ok.getSummary(null);
    expect(fresh.balance, 60);

    final off = DashboardRepository(_FakeRemote(error: _offline()), local);
    final cached = await off.getSummary(null);
    expect(cached.balance, 60);
  });

  test('summary: offline with empty cache throws', () async {
    final off = DashboardRepository(_FakeRemote(error: _offline()), local);
    expect(() => off.getSummary(null), throwsA(isA<Failure>()));
  });

  test('byCategory: success caches; offline returns cached', () async {
    final ok = DashboardRepository(
      _FakeRemote(byCategory: _byCategory),
      local,
    );
    final fresh = await ok.getByCategory(null);
    expect(fresh.single.name, 'Groceries');

    final off = DashboardRepository(_FakeRemote(error: _offline()), local);
    final cached = await off.getByCategory(null);
    expect(cached.single.name, 'Groceries');
  });

  test('byCategory: offline with empty cache throws', () async {
    final off = DashboardRepository(_FakeRemote(error: _offline()), local);
    expect(() => off.getByCategory(null), throwsA(isA<Failure>()));
  });
}
