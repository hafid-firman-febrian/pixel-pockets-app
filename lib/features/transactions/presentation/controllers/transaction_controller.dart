import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/transactions/application/services/transaction_service.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';

class TransactionsController
    extends AutoDisposeAsyncNotifier<List<TransactionModel>> {
  static const int pageSize = 10;

  /// Safety cap when fetching every page in a range for search, so an "ALL"
  /// range can never loop unbounded.
  static const int _maxSearchPages = 50;

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  bool get isLoadingMore => _loadingMore;

  @override
  Future<List<TransactionModel>> build() async {
    final range = ref.watch(rangeFilterProvider);
    final query = ref.watch(transactionSearchProvider).trim();
    _page = 1;

    if (query.isNotEmpty) {
      _hasMore = false;
      final all = await _fetchAllInRange(range);
      return _filter(all, query);
    }

    final items = await _service.list(range.toFilter(page: 1, limit: pageSize));
    _hasMore = items.length == pageSize;
    return items;
  }

  TransactionService get _service => ref.read(transactionServiceProvider);

  /// Loads every transaction in [range] by walking pages until exhausted.
  Future<List<TransactionModel>> _fetchAllInRange(RangeFilter range) async {
    final all = <TransactionModel>[];
    for (var page = 1; page <= _maxSearchPages; page++) {
      final batch = await _service.list(
        range.toFilter(page: page, limit: pageSize),
      );
      all.addAll(batch);
      if (batch.length < pageSize) break;
    }
    return all;
  }

  /// Case-insensitive match against description and category name.
  List<TransactionModel> _filter(List<TransactionModel> items, String query) {
    final q = query.toLowerCase();
    return items.where((t) {
      final desc = t.description?.toLowerCase() ?? '';
      final category = t.categoryName?.toLowerCase() ?? '';
      return desc.contains(q) || category.contains(q);
    }).toList(growable: false);
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || !state.hasValue) return;
    _loadingMore = true;
    try {
      final range = ref.read(rangeFilterProvider);
      final next = await _service.list(
        range.toFilter(page: _page + 1, limit: pageSize),
      );
      _page += 1;
      _hasMore = next.length == pageSize;
      state = AsyncData([...?state.valueOrNull, ...next]);
    } catch (_) {
    } finally {
      _loadingMore = false;
    }
  }

  Future<bool> create({
    required String transactionDate,
    required String transactionType,
    required double amount,
    int? categoryId,
    String? description,
  }) {
    return _mutateThenReload(
      () => _service.create(
        transactionDate: transactionDate,
        transactionType: transactionType,
        amount: amount,
        categoryId: categoryId,
        description: description,
      ),
    );
  }

  Future<bool> edit({
    required int id,
    required String transactionDate,
    required String transactionType,
    required double amount,
    int? categoryId,
    String? description,
  }) {
    return _mutateThenReload(
      () => _service.update(
        id: id,
        transactionDate: transactionDate,
        transactionType: transactionType,
        amount: amount,
        categoryId: categoryId,
        description: description,
      ),
    );
  }

  Future<bool> delete(int id) async {
    state = const AsyncLoading<List<TransactionModel>>().copyWithPrevious(
      state,
    );
    try {
      await _service.delete(id);
    } on Failure catch (e, st) {
      state = AsyncError<List<TransactionModel>>(e, st).copyWithPrevious(state);
      return false;
    }

    final current = state.valueOrNull ?? const [];
    state = AsyncData(current.where((t) => t.id != id).toList(growable: false));
    return true;
  }

  Future<bool> _mutateThenReload(Future<void> Function() action) async {
    state = const AsyncLoading<List<TransactionModel>>().copyWithPrevious(
      state,
    );
    try {
      await action();
    } on Failure catch (e, st) {
      state = AsyncError<List<TransactionModel>>(e, st).copyWithPrevious(state);
      return false;
    }
    final range = ref.read(rangeFilterProvider);
    final query = ref.read(transactionSearchProvider).trim();
    _page = 1;

    if (query.isNotEmpty) {
      _hasMore = false;
      state = await AsyncValue.guard(
        () async => _filter(await _fetchAllInRange(range), query),
      );
      return !state.hasError;
    }

    state = await AsyncValue.guard(
      () => _service.list(range.toFilter(page: 1, limit: pageSize)),
    );
    if (!state.hasError) {
      _hasMore = (state.valueOrNull?.length ?? 0) == pageSize;
    }
    return !state.hasError;
  }
}

final transactionsControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      TransactionsController,
      List<TransactionModel>
    >(TransactionsController.new);
