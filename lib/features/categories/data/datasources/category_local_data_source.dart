import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/cache/cache_keys.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/features/categories/data/dtos/category_dto.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this._cache);

  final CacheStore _cache;

  Future<void> save(List<CategoryDto> dtos) => _cache.writeJson(
        CacheKeys.categories,
        dtos.map((d) => d.toCacheJson()).toList(),
      );

  List<CategoryDto>? read() {
    final raw = _cache.readJsonList(CacheKeys.categories);
    return raw
        ?.map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> invalidate() => _cache.remove(CacheKeys.categories);
}

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>(
  (ref) => CategoryLocalDataSource(ref.watch(cacheStoreProvider)),
);
