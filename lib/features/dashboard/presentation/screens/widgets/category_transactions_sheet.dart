import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_bottom_sheet.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/features/dashboard/presentation/controllers/category_transactions_controller.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/widgets/transaction_list_item.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Bottom sheet listing a category's transactions within the effective
/// dashboard period. Read-only, paginated via a "Load more" button.
class CategoryTransactionsSheet extends ConsumerStatefulWidget {
  const CategoryTransactionsSheet({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final int categoryId;
  final String categoryName;

  static Future<void> show(
    BuildContext context, {
    required int categoryId,
    required String categoryName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.background.withValues(alpha: 0.72),
      useSafeArea: true,
      builder: (_) => CategoryTransactionsSheet(
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    );
  }

  @override
  ConsumerState<CategoryTransactionsSheet> createState() =>
      _CategoryTransactionsSheetState();
}

class _CategoryTransactionsSheetState
    extends ConsumerState<CategoryTransactionsSheet> {
  bool _loadingMore = false;

  CategoryTransactionsController get _notifier => ref.read(
    categoryTransactionsControllerProvider(widget.categoryId).notifier,
  );

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      await _notifier.loadMore();
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      categoryTransactionsControllerProvider(widget.categoryId),
    );

    return PixelBottomSheetFrame(
      title: widget.categoryName.toUpperCase(),
      child: switch (async) {
        AsyncValue(:final error?) when !async.hasValue => _Message(
          'Failed to load transactions.\n$error',
        ),
        AsyncValue(:final value?) => _buildList(value),
        _ => const _LoadingList(),
      },
    );
  }

  Widget _buildList(List<TransactionModel> items) {
    if (items.isEmpty) {
      return const _Message('No transactions in this category.');
    }

    final showLoadMore = _notifier.hasMore;

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      itemCount: items.length + (showLoadMore ? 1 : 0),
      separatorBuilder: (_, i) => i >= items.length - 1
          ? const SizedBox.shrink()
          : const Divider(height: 1, color: AppColors.border),
      itemBuilder: (_, i) {
        if (i >= items.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s12,
              AppSpacing.s16,
              AppSpacing.s8,
            ),
            child: PixelButton(
              label: 'LOAD MORE',
              icon: Pixel.chevrondown,
              variant: PixelButtonVariant.secondary,
              isFullWidth: true,
              isLoading: _loadingMore,
              onPressed: _loadingMore ? null : _loadMore,
            ),
          );
        }
        return TransactionListItem(transaction: items[i]);
      },
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    const placeholder = TransactionModel(
      id: 0,
      transactionDate: '2026-06-17',
      transactionType: 'expense',
      amount: 50000,
      categoryName: 'Category',
      description: 'Placeholder note',
    );

    return Skeletonizer(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        itemCount: 4,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, _) =>
            const TransactionListItem(transaction: placeholder),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      child: Row(
        children: [
          const Icon(Pixel.reciept, size: 20, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyNormal.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
