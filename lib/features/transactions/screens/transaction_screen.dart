import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'widgets/transaction_form_sheet.dart';
import 'widgets/transaction_list_item.dart';
import 'widgets/transaction_type_filter.dart';

/// Transactions list. UI only: it watches providers and delegates every
/// write to [TransactionController] via small interaction handlers.
class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => TransactionFormSheet.show(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const TransactionTypeFilter(),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: e is Failure ? e.message : e.toString(),
                onRetry: () => ref.invalidate(transactionsProvider),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const _EmptyView();
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(transactionsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) =>
                        const Divider(indent: 72, height: 1),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return Dismissible(
                        key: ValueKey(tx.id),
                        direction: DismissDirection.endToStart,
                        background: _deleteBackground(),
                        confirmDismiss: (_) => _confirmDelete(context),
                        onDismissed: (_) => _delete(context, ref, tx),
                        child: TransactionListItem(
                          transaction: tx,
                          onTap: () =>
                              TransactionFormSheet.show(context, existing: tx),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      color: AppColors.expense,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(transactionControllerProvider).delete(tx.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaksi dihapus')),
      );
    } on Failure catch (f) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: AppColors.expense,
        ),
      );
      ref.invalidate(transactionsProvider); // restore the row
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.receipt_long_outlined,
            size: 64, color: AppColors.textMuted),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Belum ada transaksi',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
