import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/period_filter_card.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/transaction_summary_card.dart';
import 'package:pixelarticons/pixel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    return SafeArea(
      child: Scaffold(
        body: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (summary) => Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.section),
            child: Column(
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
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).logout(),
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
                      TransactionSummaryCard(summary: summary),
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
      ),
    );
  }
}
