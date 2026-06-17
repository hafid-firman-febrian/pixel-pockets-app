import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/transaction_filter.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(dioProvider)),
);

/// Current list filter. Mutating this re-runs [transactionsProvider].
final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => const TransactionFilter(),
);

/// The filtered transaction list — the screen's primary read.
final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  final filter = ref.watch(transactionFilterProvider);
  return ref.watch(transactionRepositoryProvider).getAll(filter);
});

final transactionControllerProvider = Provider<TransactionController>(
  (ref) => TransactionController(ref, ref.watch(transactionRepositoryProvider)),
);

/// Orchestrates writes and refreshes the list afterwards. Holds the
/// create/update/delete logic so screens stay UI-only.
class TransactionController {
  TransactionController(this._ref, this._repo);

  final Ref _ref;
  final TransactionRepository _repo;

  Future<TransactionModel> create({
    required String transactionDate,
    required String transactionType,
    required double amount,
    int? categoryId,
    String? description,
  }) async {
    final body = TransactionModel(
      id: 0,
      transactionDate: transactionDate,
      transactionType: transactionType,
      amount: amount,
      categoryId: categoryId,
      description: description,
    ).toJson();
    final created = await _repo.create(body);
    _ref.invalidate(transactionsProvider);
    return created;
  }

  Future<TransactionModel> update({
    required int id,
    required String transactionDate,
    required String transactionType,
    required double amount,
    int? categoryId,
    String? description,
  }) async {
    final body = TransactionModel(
      id: id,
      transactionDate: transactionDate,
      transactionType: transactionType,
      amount: amount,
      categoryId: categoryId,
      description: description,
    ).toJson();
    final updated = await _repo.update(id, body);
    _ref.invalidate(transactionsProvider);
    return updated;
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    _ref.invalidate(transactionsProvider);
  }
}
