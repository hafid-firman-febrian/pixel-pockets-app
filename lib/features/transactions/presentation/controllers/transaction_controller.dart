import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/transactions/application/services/transaction_service.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';

/// Single source of truth for the transactions list AND its mutations — the
/// presentation-layer controller per the project's architecture diagram
/// (Widgets → States → Controllers → Services). Widgets only ever watch this.
///
/// [build] loads the list for the current [transactionFilterProvider] and
/// re-runs automatically whenever the filter changes. create/edit/delete write
/// through the service and refresh this same state. Loading/error are exposed
/// through the `AsyncValue` itself; previous data is preserved across a
/// mutation so the list never blanks out — callers read the returned `bool` to
/// decide what to do next (close a sheet, show an error snackbar, …).
class TransactionsController
    extends AutoDisposeAsyncNotifier<List<TransactionModel>> {
  /// Items fetched per page (infinite scroll).
  static const int pageSize = 10;

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  /// Whether another page may exist (last page returned a full [pageSize]).
  bool get hasMore => _hasMore;

  /// Whether a `loadMore()` fetch is in flight.
  bool get isLoadingMore => _loadingMore;

  @override
  Future<List<TransactionModel>> build() async {
    final range = ref.watch(rangeFilterProvider);
    _page = 1;
    final items = await _service.list(
      range.toFilter(page: 1, limit: pageSize),
    );
    _hasMore = items.length == pageSize;
    return items;
  }

  TransactionService get _service => ref.read(transactionServiceProvider);

  /// Fetch the next page and append it to the current list. No-op when already
  /// loading, when no more pages exist, or while the first page is still loading.
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
      // Keep the current page; scrolling again retries.
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
    state = const AsyncLoading<List<TransactionModel>>().copyWithPrevious(state);
    try {
      await _service.delete(id);
    } on Failure catch (e, st) {
      state = AsyncError<List<TransactionModel>>(e, st).copyWithPrevious(state);
      return false;
    }
    // Optimistic prune (no refetch) so the row doesn't flicker back behind the
    // dismiss animation. The next filter change / refresh re-syncs from server.
    final current = state.valueOrNull ?? const [];
    state = AsyncData(current.where((t) => t.id != id).toList(growable: false));
    return true;
  }

  /// Runs a write, then reloads so widgets see server-authoritative data
  /// (new ids, joined category name/color, …). Keeps previous data visible
  /// while in flight. Returns `true` when the write and reload both succeed.
  Future<bool> _mutateThenReload(Future<void> Function() action) async {
    state = const AsyncLoading<List<TransactionModel>>().copyWithPrevious(state);
    try {
      await action();
    } on Failure catch (e, st) {
      state = AsyncError<List<TransactionModel>>(e, st).copyWithPrevious(state);
      return false;
    }
    final range = ref.read(rangeFilterProvider);
    _page = 1;
    state = await AsyncValue.guard(
      () => _service.list(range.toFilter(page: 1, limit: pageSize)),
    );
    if (!state.hasError) {
      _hasMore = (state.valueOrNull?.length ?? 0) == pageSize;
    }
    return !state.hasError;
  }
}

final transactionsControllerProvider = AutoDisposeAsyncNotifierProvider<
    TransactionsController, List<TransactionModel>>(TransactionsController.new);
