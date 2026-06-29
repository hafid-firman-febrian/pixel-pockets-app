import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/widgets/transaction_list_item.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Compact list of the latest transactions shown on the dashboard. Display-only
/// (no tap) — the full list lives behind the "Show all" header action.
class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key, required this.items});

  final List<TransactionModel> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PixelCard(
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              TransactionListItem(transaction: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder rows for the loading skeleton.
class RecentTransactionsCardSkeleton extends StatelessWidget {
  const RecentTransactionsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: RecentTransactionsCard(
        items: List.generate(
          3,
          (i) => TransactionModel(
            id: i,
            transactionDate: '2026-06-29',
            transactionType: 'expense',
            amount: 50000,
            categoryName: 'Category',
            description: 'Placeholder',
          ),
        ),
      ),
    );
  }
}
