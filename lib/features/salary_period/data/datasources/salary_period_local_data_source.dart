import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/cache/cache_keys.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/features/salary_period/data/dtos/salary_period_dto.dart';

class SalaryPeriodLocalDataSource {
  SalaryPeriodLocalDataSource(this._cache);

  final CacheStore _cache;

  Future<void> save(List<SalaryPeriodDto> dtos) => _cache.writeJson(
    CacheKeys.salaryPeriods,
    dtos.map((d) => d.toCacheJson()).toList(),
  );

  List<SalaryPeriodDto>? read() {
    final raw = _cache.readJsonList(CacheKeys.salaryPeriods);
    return raw
        ?.map((e) => SalaryPeriodDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> invalidate() => _cache.remove(CacheKeys.salaryPeriods);
}

final salaryPeriodLocalDataSourceProvider =
    Provider<SalaryPeriodLocalDataSource>(
      (ref) => SalaryPeriodLocalDataSource(ref.watch(cacheStoreProvider)),
    );
