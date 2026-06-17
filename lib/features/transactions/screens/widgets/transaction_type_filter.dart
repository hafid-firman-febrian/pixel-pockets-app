import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/transaction_provider.dart';

/// Segmented "All / Income / Expense" filter. Reads and updates the shared
/// [transactionFilterProvider]; the list re-fetches automatically.
class TransactionTypeFilter extends ConsumerWidget {
  const TransactionTypeFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(
      transactionFilterProvider.select((f) => f.transactionType),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SegmentedButton<String?>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: null, label: Text('Semua')),
          ButtonSegment(value: 'income', label: Text('Masuk')),
          ButtonSegment(value: 'expense', label: Text('Keluar')),
        ],
        selected: {current},
        onSelectionChanged: (selection) {
          final value = selection.first;
          final notifier = ref.read(transactionFilterProvider.notifier);
          notifier.update(
            (f) => value == null
                ? f.copyWith(clearTransactionType: true, page: 1)
                : f.copyWith(transactionType: value, page: 1),
          );
        },
      ),
    );
  }
}
