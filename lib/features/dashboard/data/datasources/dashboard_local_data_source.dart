import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/cache/cache_keys.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/features/dashboard/data/dtos/category_summary_dto.dart';
import 'package:pixel_pocket/features/dashboard/data/dtos/summary_dto.dart';

class DashboardLocalDataSource {
  DashboardLocalDataSource(this._cache);

  final CacheStore _cache;

  Future<void> saveSummary(int? periodId, SummaryDto dto) =>
      _cache.writeJson(_summaryKey(periodId), dto.toCacheJson());

  SummaryDto? readSummary(int? periodId) {
    final raw = _cache.readJson(_summaryKey(periodId));
    return raw == null ? null : SummaryDto.fromJson(raw);
  }

  Future<void> saveByCategory(int? periodId, List<CategorySummaryDto> dtos) =>
      _cache.writeJson(
        _byCategoryKey(periodId),
        dtos.map((d) => d.toCacheJson()).toList(),
      );

  List<CategorySummaryDto>? readByCategory(int? periodId) {
    final raw = _cache.readJsonList(_byCategoryKey(periodId));
    return raw
        ?.map((e) => CategorySummaryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _summaryKey(int? periodId) =>
      '${CacheKeys.dashboardSummary}:$periodId';
  String _byCategoryKey(int? periodId) =>
      '${CacheKeys.dashboardByCategory}:$periodId';
}

final dashboardLocalDataSourceProvider = Provider<DashboardLocalDataSource>(
  (ref) => DashboardLocalDataSource(ref.watch(cacheStoreProvider)),
);
