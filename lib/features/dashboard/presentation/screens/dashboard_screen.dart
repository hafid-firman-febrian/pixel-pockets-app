import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/core/widgets/pixel_confirm_dialog.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/period_filter_card.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/transaction_summary_card.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _placeholderSummary = TransactionSummary(
  totalIncome: 0000000,
  totalExpense: 0000000,
  balance: 0000000,
  transactionCount: 12,
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    return SafeArea(
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: ListView(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.section),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: AppSpacing.card,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '~\$ Pixel-Pocket',
                      style: AppTextStyles.displayMedium,
                    ),
                    PixelButton(
                      onPressed: () => _confirmLogout(context, ref),
                      variant: PixelButtonVariant.danger,
                      icon: Pixel.logout,
                      size: PixelButtonSize.sm,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.section),
              const PeriodFilterCard(),
              SizedBox(height: AppSpacing.section),
              Padding(
                padding: AppSpacing.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (summaryAsync.hasError && !summaryAsync.hasValue)
                      Padding(
                        padding: AppSpacing.card,
                        child: const Text('Failed to load summary.'),
                      )
                    else
                      Skeletonizer(
                        enabled:
                            summaryAsync.isLoading && !summaryAsync.hasValue,
                        child: TransactionSummaryCard(
                          summary:
                              summaryAsync.valueOrNull ?? _placeholderSummary,
                        ),
                      ),
                    SizedBox(height: AppSpacing.section),
                    Text(
                      'EXPENSES BY CATEGORY',
                      style: AppTextStyles.bodyNormal,
                    ),
                    SizedBox(height: AppSpacing.section),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showPixelConfirm(
      context,
      title: 'Logout?',
      message: 'Sesi akan diakhiri dan kamu perlu login lagi untuk masuk.',
      confirmLabel: 'Logout',
      confirmVariant: PixelButtonVariant.danger,
      icon: Pixel.logout,
    );
    if (!confirmed) return;
    await ref.read(authControllerProvider.notifier).logout();
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(salaryPeriodProvider);
    ref.invalidate(dashboardSummaryProvider);
    await ref.read(dashboardSummaryProvider.future);
  }
}
