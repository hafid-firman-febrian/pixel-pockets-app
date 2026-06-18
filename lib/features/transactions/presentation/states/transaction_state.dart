import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/transactions/application/services/transaction_service.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

/// Current list filter. Mutating this re-runs [transactionsProvider].
final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => const TransactionFilter(),
);

/// The filtered transaction list — the screen's primary read.
final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  final filter = ref.watch(transactionFilterProvider);
  return ref.watch(transactionServiceProvider).list(filter);
});
