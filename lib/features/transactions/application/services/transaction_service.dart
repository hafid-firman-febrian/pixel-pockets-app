import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/transactions/data/repositories/transaction_repository.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

/// Business logic for transactions. Builds domain objects from raw inputs and
/// orchestrates the repository. No Riverpod state, no widgets.
class TransactionService {
  TransactionService(this._repo);

  final TransactionRepository _repo;

  Future<List<TransactionModel>> list(TransactionFilter filter) =>
      _repo.getAll(filter);

  Future<TransactionModel> create({
    required String transactionDate,
    required String transactionType,
    required double amount,
    int? categoryId,
    String? description,
  }) {
    final transaction = TransactionModel(
      id: 0,
      transactionDate: transactionDate,
      transactionType: transactionType,
      amount: amount,
      categoryId: categoryId,
      description: description,
    );
    return _repo.create(transaction);
  }

  Future<TransactionModel> update({
    required int id,
    required String transactionDate,
    required String transactionType,
    required double amount,
    int? categoryId,
    String? description,
  }) {
    final transaction = TransactionModel(
      id: id,
      transactionDate: transactionDate,
      transactionType: transactionType,
      amount: amount,
      categoryId: categoryId,
      description: description,
    );
    return _repo.update(transaction);
  }

  Future<void> delete(int id) => _repo.delete(id);
}

final transactionServiceProvider = Provider<TransactionService>(
  (ref) => TransactionService(ref.watch(transactionRepositoryProvider)),
);
