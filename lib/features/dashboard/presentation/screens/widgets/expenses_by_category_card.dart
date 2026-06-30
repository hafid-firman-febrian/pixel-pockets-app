import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_sizing.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/utils/currency_formatter.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/category_summary.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/category_transactions_sheet.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ExpensesByCategoryCard extends StatefulWidget {
  const ExpensesByCategoryCard({super.key, required this.items});

  final List<CategorySummary> items;

  @override
  State<ExpensesByCategoryCard> createState() => _ExpensesByCategoryCardState();
}

class _ExpensesByCategoryCardState extends State<ExpensesByCategoryCard> {
  static const _collapsedCount = 3;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final hidden = items.length - _collapsedCount;
    final visible = _expanded ? items : items.take(_collapsedCount).toList();

    return SizedBox(
      width: double.infinity,
      child: PixelCard(
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) SizedBox(height: AppSpacing.section),
                _CategoryRow(
                  item: visible[i],
                  onTap: () => CategoryTransactionsSheet.show(
                    context,
                    categoryId: visible[i].categoryId,
                    categoryName: visible[i].name,
                  ),
                ),
              ],
              if (hidden > 0) ...[
                SizedBox(height: AppSpacing.section),
                _MoreButton(
                  label: _expanded ? 'Show less' : 'Show $hidden more',
                  expanded: _expanded,
                  onTap: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.overlineLg.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            Icon(
              expanded ? Pixel.chevronup : Pixel.chevrondown,
              size: AppSizing.iconSm,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item, this.onTap});

  final CategorySummary item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(item.colorHex);
    return InkWell(
      onTap: onTap,
      child: _content(color),
    );
  }

  Widget _content(Color color) {
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
