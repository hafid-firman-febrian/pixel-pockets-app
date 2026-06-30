import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixel_pocket/features/transactions/application/services/transaction_service.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

/// Paginated list of a category's transactions within the effective dashboard
/// period, filtered server-side via the `category_id` query param.
class CategoryTransactionsController
    extends AutoDisposeFamilyAsyncNotifier<List<TransactionModel>, int> {
  static const int pageSize = 20;

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  int? _periodId;

  bool get hasMore => _hasMore;

  @override
  Future<List<TransactionModel>> build(int categoryId) async {
    _page = 1;
    final period = await ref.watch(effectivePeriodProvider.future);
    _periodId = period?.id;
    final items = await _fetch(page: 1);
    _hasMore = items.length == pageSize;
    return items;
  }

  TransactionService get _service => ref.read(transactionServiceProvider);

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || !state.hasValue) return;
    _loadingMore = true;
    try {
      final next = await _fetch(page: _page + 1);
      _page += 1;
      _hasMore = next.length == pageSize;
      state = AsyncData([...?state.valueOrNull, ...next]);
    } catch (_) {
      // Keep the current page on a failed load-more.
    } finally {
      _loadingMore = false;
    }
  }

  Future<List<TransactionModel>> _fetch({required int page}) {
    return _service.list(
      TransactionFilter(
        salaryPeriodId: _periodId,
        categoryId: arg,
        page: page,
        limit: pageSize,
      ),
    );
  }
}

final categoryTransactionsControllerProvider =
    AutoDisposeAsyncNotifierProvider.family<
      CategoryTransactionsController,
      List<TransactionModel>,
      int
    >(CategoryTransactionsController.new);
