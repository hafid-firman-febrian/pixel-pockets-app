import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/transactions/application/services/transaction_service.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';

/// Riverpod glue for writes. Delegates business logic to [TransactionService]
/// and refreshes the list afterwards. Screens call this; it holds no UI.
class TransactionController {
  TransactionController(this._ref, this._service);

  final Ref _ref;
  final TransactionService _service;

  Future<TransactionModel> create({
    required String transactionDate,
    required String transactionType,
    required double amount,
    int? categoryId,
    String? description,
  }) async {
    final created = await _service.create(
      transactionDate: transactionDate,
      transactionType: transactionType,
      amount: amount,
      categoryId: categoryId,
      description: description,
    );
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
    final updated = await _service.update(
      id: id,
      transactionDate: transactionDate,
      transactionType: transactionType,
      amount: amount,
      categoryId: categoryId,
      description: description,
    );
    _ref.invalidate(transactionsProvider);
    return updated;
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _ref.invalidate(transactionsProvider);
  }
}

final transactionControllerProvider = Provider<TransactionController>(
  (ref) => TransactionController(ref, ref.watch(transactionServiceProvider)),
);
