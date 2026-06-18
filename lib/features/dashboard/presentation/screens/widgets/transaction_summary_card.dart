import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/utils/currency_formatter.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

class TransactionSummaryCard extends StatelessWidget {
  const TransactionSummaryCard({super.key, required this.summary});

  final TransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.border,
                offset: Offset(0, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: AppSpacing.card,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BALANCE',
                    style: AppTextStyles.bodyNormal.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.item),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Rp ',
                          style: AppTextStyles.bodyNormal.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: CurrencyFormatter.formatWhileTyping(
                            summary.balance.toString(),
                          ),
                          style: AppTextStyles.numericXl.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.section),
                  Divider(color: AppColors.border),
                  SizedBox(height: AppSpacing.section),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TotalTransaction(summary: summary, isIncome: true),
                      SizedBox(width: AppSpacing.s24),
                      _TotalTransaction(summary: summary, isIncome: false),
                    ],
                  ),
                  SizedBox(height: AppSpacing.section),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('SPENT', style: AppTextStyles.overlineSm),
                      Text(
                        summary.spentPercentageString,
                        style: AppTextStyles.overlineLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s4),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final percentage = summary.spentPercentage.clamp(
                        0.0,
                        1.0,
                      );
                      final spentWidth = constraints.maxWidth * percentage;

                      return Container(
                        width: double.infinity,
                        height: 5,
                        decoration: BoxDecoration(color: AppColors.border),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: spentWidth,
                            height: 10,
                            decoration: BoxDecoration(color: AppColors.expense),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalTransaction extends StatelessWidget {
  const _TotalTransaction({
    super.key,
    required this.summary,
    required this.isIncome,
  });

  final TransactionSummary summary;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isIncome ? AppColors.income : AppColors.expense,
              ),
            ),
            SizedBox(width: AppSpacing.s4),
            Text(
              isIncome ? 'INCOME' : 'EXPENSE',
              style: AppTextStyles.overlineSm,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.s4),
        Text(
          CurrencyFormatter.format(
            isIncome ? summary.totalIncome : summary.totalExpense,
          ),
          style: AppTextStyles.bodyNormal.copyWith(
            color: isIncome ? AppColors.income : AppColors.expense,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
