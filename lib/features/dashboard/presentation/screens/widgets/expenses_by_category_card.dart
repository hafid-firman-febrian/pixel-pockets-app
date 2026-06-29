import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/utils/currency_formatter.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/category_summary.dart';
import 'package:skeletonizer/skeletonizer.dart';



class ExpensesByCategoryCard extends StatelessWidget {
  const ExpensesByCategoryCard({super.key, required this.items});

  final List<CategorySummary> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: AppSpacing.section),
              _CategoryRow(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item});

  final CategorySummary item;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(item.colorHex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, color: color),
            SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyNormal,
              ),
            ),
            SizedBox(width: AppSpacing.s8),
            Text(
              CurrencyFormatter.format(item.total),
              style: AppTextStyles.bodyNormal.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.s6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: 5,
                child: Stack(
                  children: [
                    Container(color: AppColors.border),
                    FractionallySizedBox(
                      widthFactor: (item.percentage / 100).clamp(0.0, 1.0),
                      child: Container(color: color),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppSpacing.s8),
            Text(
              '${item.percentage.toStringAsFixed(1)}%',
              style: AppTextStyles.overlineSm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class ExpensesByCategoryCardSkeleton extends StatelessWidget {
  const ExpensesByCategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ExpensesByCategoryCard(
        items: const [
          CategorySummary(
            categoryId: 0,
            name: 'Category',
            colorHex: '#8C8C7B',
            type: 'expense',
            total: 100000,
            percentage: 60,
            count: 1,
          ),
          CategorySummary(
            categoryId: 1,
            name: 'Category',
            colorHex: '#8C8C7B',
            type: 'expense',
            total: 50000,
            percentage: 30,
            count: 1,
          ),
        ],
      ),
    );
  }
}
