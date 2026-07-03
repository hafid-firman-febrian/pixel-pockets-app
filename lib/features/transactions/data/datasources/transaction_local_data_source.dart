import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/cache/cache_keys.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/features/transactions/data/dtos/transaction_dto.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';

class TransactionLocalDataSource {
  TransactionLocalDataSource(this._cache);

  final CacheStore _cache;

  Future<void> save(TransactionFilter filter, List<TransactionDto> dtos) =>
      _cache.writeJson(
        _keyFor(filter),
        dtos.map((d) => d.toCacheJson()).toList(),
      );

  List<TransactionDto>? read(TransactionFilter filter) {
    final raw = _cache.readJsonList(_keyFor(filter));
    return raw
        ?.map((e) => TransactionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> invalidateAfterMutation() async {
    await _cache.removeByPrefix(CacheKeys.transactions);
    await _cache.removeByPrefix(CacheKeys.dashboard);
  }

  String _keyFor(TransactionFilter f) =>
      '${CacheKeys.transactions}'
      ':sp=${f.salaryPeriodId}:f=${f.filter}:s=${f.startDate}:e=${f.endDate}'
      ':t=${f.transactionType}:c=${f.categoryId}:p=${f.page}:l=${f.limit}';
}

final transactionLocalDataSourceProvider = Provider<TransactionLocalDataSource>(
  (ref) => TransactionLocalDataSource(ref.watch(cacheStoreProvider)),
);
