import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';

/// Current list filter (ephemeral UI state). Mutating this re-runs
/// [TransactionsController.build], which refetches the list.
final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => const TransactionFilter(),
);
