import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/core/router/app_router.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/widgets/transaction_form_sheet.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/widgets/transaction_list_item.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/widgets/transaction_type_filter.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';
import 'package:pixelarticons/pixel.dart';

/// Transactions list. UI only: it watches providers and delegates every
/// write to [TransactionController] via small interaction handlers.
class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final router = GoRouter.of(context);

    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   title: Text('~\$ Pixel-Pocket', style: AppTextStyles.headingLarge),

        //   actions: [
        //     PixelButton(
        //       onPressed: () =>
        //           ref.read(authControllerProvider.notifier).logout(),
        //       variant: PixelButtonVariant.danger,
        //       icon: Pixel.logout,
        //       label: '',
        //     ),
        //   ],
        // ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => TransactionFormSheet.show(context),
          child: const Icon(Icons.add),
        ),

        body: Padding(
          padding: EdgeInsets.all(AppSpacing.section),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('~\$ Pixel-Pocket', style: AppTextStyles.titleLg),
                  PixelButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                    variant: PixelButtonVariant.danger,
                    icon: Pixel.logout,
                    size: PixelButtonSize.sm,
                  ),
                ],
              ),
              const TransactionTypeFilter(),
              Expanded(
                child: transactionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) {
                    final failure = e is Failure ? e : null;
                    return _ErrorView(
                      message: failure?.message ?? e.toString(),
                      type: failure?.type ?? FailureType.unknown,
                      onRetry: () => ref.invalidate(transactionsProvider),
                    );
                  },
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
                              onTap: () => TransactionFormSheet.show(
                                context,
                                existing: tx,
                              ),
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
        ),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      color: AppColors.expense,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.s24),
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
        SnackBar(content: Text(f.message), backgroundColor: AppColors.expense),
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
        Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted),
        SizedBox(height: AppSpacing.section),
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
  const _ErrorView({
    required this.message,
    required this.type,
    required this.onRetry,
  });

  final String message;
  final FailureType type;
  final VoidCallback onRetry;

  /// Ikon per kategori error. Dio tidak bisa membedakan "tidak ada sinyal"
  /// vs "sinyal lemah", jadi cellularsignaloff dipakai sebagai fallback umum.
  IconData get _icon {
    switch (type) {
      case FailureType.noConnection:
        return Pixel.downasaur;
      case FailureType.timeout:
        return Pixel.hourglass;
      case FailureType.server:
        return Pixel.server;
      case FailureType.notFound:
      case FailureType.unauthorized:
      case FailureType.cancelled:
      case FailureType.unknown:
        return Pixel.cellularsignaloff;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.s12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.section),
            PixelButton(
              onPressed: onRetry,
              icon: Pixel.reload,
              label: 'Coba Lagi',
            ),
          ],
        ),
      ),
    );
  }
}
