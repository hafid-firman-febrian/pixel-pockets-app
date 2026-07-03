import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/cache/cache_keys.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/features/chart/data/dtos/chart_dto.dart';

class ChartLocalDataSource {
  ChartLocalDataSource(this._cache);

  final CacheStore _cache;

  Future<void> save({
    String? filter,
    int? salaryPeriodId,
    required ChartDto dto,
  }) => _cache.writeJson(_keyFor(filter, salaryPeriodId), dto.toCacheJson());

  ChartDto? read({String? filter, int? salaryPeriodId}) {
    final raw = _cache.readJson(_keyFor(filter, salaryPeriodId));
    return raw == null ? null : ChartDto.fromJson(raw);
  }

  String _keyFor(String? filter, int? salaryPeriodId) =>
      '${CacheKeys.chart}:f=$filter:sp=$salaryPeriodId';
}

final chartLocalDataSourceProvider = Provider<ChartLocalDataSource>(
  (ref) => ChartLocalDataSource(ref.watch(cacheStoreProvider)),
);
