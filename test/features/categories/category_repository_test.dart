import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/categories/data/datasources/category_local_data_source.dart';
import 'package:pixel_pocket/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:pixel_pocket/features/categories/data/dtos/category_dto.dart';
import 'package:pixel_pocket/features/categories/data/repositories/category_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemote implements CategoryRemoteDataSource {
  _FakeRemote({this.result, this.error});
  final List<CategoryDto>? result;
  final Object? error;

  @override
  Future<List<CategoryDto>> getAll() async {
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<List<CategoryDto>> seed() async => throw UnimplementedError();
  @override
  Future<CategoryDto> create({
    required String name,
    required String color,
    required String type,
  }) async => throw UnimplementedError();
  @override
  Future<CategoryDto> update({
    required int id,
    required String name,
    required String color,
    required String type,
  }) async => throw UnimplementedError();
  @override
  Future<void> delete(int id) async {}
}

DioException _offline() => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.connectionError,
);

const _cat = CategoryDto(id: 1, name: 'Coffee', color: '#8B6355', type: 'expense');

void main() {
  late CategoryLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    local = CategoryLocalDataSource(
      CacheStore(await SharedPreferences.getInstance()),
    );
  });

  test('success caches; offline returns cached', () async {
    final ok = CategoryRepository(_FakeRemote(result: [_cat]), local);
    final fresh = await ok.getAll();
    expect(fresh.single.name, 'Coffee');

    final off = CategoryRepository(_FakeRemote(error: _offline()), local);
    final cached = await off.getAll();
    expect(cached.single.id, 1);
  });

  test('offline with empty cache throws', () async {
    final off = CategoryRepository(_FakeRemote(error: _offline()), local);
    expect(() => off.getAll(), throwsA(isA<Failure>()));
  });
}
