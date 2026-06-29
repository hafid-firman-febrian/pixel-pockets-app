import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/utils/currency_formatter.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Mask asterisk tetap saat nominal disembunyikan (tidak membocorkan panjang angka).
const _kMask = '******';

class TransactionSummaryCard extends ConsumerWidget {
  const TransactionSummaryCard({super.key, required this.summary});

  final TransactionSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHidden = ref.watch(balanceHiddenProvider);
    final isNegative = summary.balance < 0;
    // Saat hidden, jangan bocorkan status minus lewat warna/tanda.
    final balanceColor = (!isHidden && isNegative)
        ? AppColors.expense
        : AppColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        PixelCard(
          elevated: true,
          child: Padding(
            padding: AppSpacing.card,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.keep(
                    child: Text(
                      'BALANCE',
                      style: AppTextStyles.bodyNormal.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.item),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: (!isHidden && isNegative)
                                    ? '-Rp '
                                    : 'Rp ',
                                style: AppTextStyles.bodyNormal.copyWith(
                                  color: balanceColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: isHidden
                                    ? _kMask
                                    : CurrencyFormatter.formatWhileTyping(
                                        CurrencyFormatter.format(
                                          summary.balance,
                                        ),
                                      ),
                                style: AppTextStyles.numericXl.copyWith(
                                  color: balanceColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Skeleton.keep(
                        child: InkWell(
                          onTap: () => ref
                              .read(balanceHiddenProvider.notifier)
                              .update((hidden) => !hidden),
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.s4),
                            child: Icon(
                              isHidden ? Pixel.eyeclosed : Pixel.eye,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.section),
                  Skeleton.keep(child: Divider(color: AppColors.border)),
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
                      Skeleton.keep(
                        child: Text('SPENT', style: AppTextStyles.overlineSm),
                      ),
                      Text(
                        summary.spentPercentageString,
                        style: AppTextStyles.overlineLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s4),

                  // ✅ Tidak perlu LayoutBuilder sama sekali
                  SizedBox(
                    width: double.infinity,
                    height: 5,
                    child: Stack(
                      children: [
                        // track background
                        Container(
                          decoration: BoxDecoration(color: AppColors.border),
                        ),
                        // filled bar
                        FractionallySizedBox(
                          // alignment: Alignment.centerLeft, // ← mulai dari kiri
                          widthFactor: summary.spentPercentage.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(color: AppColors.expense),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // LayoutBuilder(
                  //   builder: (context, constraints) {
                  //     final percentage = summary.spentPercentage.clamp(
                  //       0.0,
                  //       1.0,
                  //     );
                  //     final spentWidth = constraints.maxWidth * percentage;

                  //     return Container(
                  //       width: double.infinity,
                  //       height: 5,
                  //       decoration: BoxDecoration(color: AppColors.border),
                  //       child: Align(
                  //         alignment: Alignment.centerRight,
                  //         child: Container(
                  //           width: spentWidth,
                  //           height: 10,
                  //           decoration: BoxDecoration(color: AppColors.expense),
                  //         ),
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalTransaction extends ConsumerWidget {
  const _TotalTransaction({required this.summary, required this.isIncome});

  final TransactionSummary summary;
  final bool isIncome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHidden = ref.watch(balanceHiddenProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton.keep(
          child: Row(
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
        ),
        SizedBox(height: AppSpacing.s4),
        Text(
          isHidden
              ? 'Rp $_kMask'
              : CurrencyFormatter.format(
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
