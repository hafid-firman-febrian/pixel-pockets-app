import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/core/router/app_router.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_sizing.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/core/widgets/pixel_confirm_dialog.dart';
import 'package:pixel_pocket/core/widgets/pixel_error_view.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/category_summary.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/period_filter_card.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/expenses_by_category_card.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/recent_transactions_card.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/transaction_summary_card.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
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
    final byCategoryAsync = ref.watch(expensesByCategoryProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    // Every section failed (typically offline): collapse the three inline
    // errors into one centered error with a single retry.
    final allFailed =
        summaryAsync.hasError &&
        !summaryAsync.hasValue &&
        byCategoryAsync.hasError &&
        !byCategoryAsync.hasValue &&
        recentAsync.hasError &&
        !recentAsync.hasValue;

    return SafeArea(
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: allFailed
              ? _OfflineBody(
                  onLogout: () => _confirmLogout(context, ref),
                  failure: asFailure(summaryAsync.error),
                  onRetry: () => _refresh(ref),
                )
              : ListView(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.section),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _DashboardHeader(
                      onLogout: () => _confirmLogout(context, ref),
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
                            PixelErrorView(
                              failure: asFailure(summaryAsync.error),
                              onRetry: () =>
                                  ref.invalidate(dashboardSummaryProvider),
                              compact: true,
                            )
                          else
                            Skeletonizer(
                              enabled:
                                  summaryAsync.isLoading &&
                                  !summaryAsync.hasValue,
                              child: TransactionSummaryCard(
                                summary:
                                    summaryAsync.valueOrNull ??
                                    _placeholderSummary,
                              ),
                            ),
                          SizedBox(height: AppSpacing.section),
                          Text(
                            'EXPENSES BY CATEGORY',
                            style: AppTextStyles.bodyNormal,
                          ),
                          SizedBox(height: AppSpacing.section),
                          _ExpensesByCategorySection(
                            byCategoryAsync: byCategoryAsync,
                            onRetry: () =>
                                ref.invalidate(expensesByCategoryProvider),
                          ),
                          SizedBox(height: AppSpacing.section),
                          _RecentTransactionsSection(
                            recentAsync: recentAsync,
                            onRetry: () =>
                                ref.invalidate(recentTransactionsProvider),
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
      message: 'Your session will end and you\'ll need to sign in again.',
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
    ref.invalidate(expensesByCategoryProvider);
    ref.invalidate(recentTransactionsProvider);
    await ref.read(dashboardSummaryProvider.future);
  }
}

/// App title + logout button. Shared between the normal and offline layouts so
/// the header stays identical in both.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.card,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('~\$ Pixel-Pocket', style: AppTextStyles.displayMedium),
          PixelButton(
            onPressed: onLogout,
            variant: PixelButtonVariant.danger,
            icon: Pixel.logout,
            size: PixelButtonSize.sm,
          ),
        ],
      ),
    );
  }
}

/// Shown when every dashboard section failed (typically offline): keeps the
/// header + period filter, then one centered error with a single retry that
/// refreshes all sections at once.
class _OfflineBody extends StatelessWidget {
  const _OfflineBody({
    required this.onLogout,
    required this.failure,
    required this.onRetry,
  });

  final VoidCallback onLogout;
  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: AppSpacing.section),
        _DashboardHeader(onLogout: onLogout),
        SizedBox(height: AppSpacing.section),
        const PeriodFilterCard(),
        Expanded(
          child: PixelErrorView(failure: failure, onRetry: onRetry, fill: true),
        ),
      ],
    );
  }
}

/// Header row ("RECENT" + Show all) plus the recent-transactions list with
/// loading / error / empty states. "Show all" switches to the Transactions tab.
class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({
    required this.recentAsync,
    required this.onRetry,
  });

  final AsyncValue<List<TransactionModel>> recentAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RECENT', style: AppTextStyles.bodyNormal),
            InkWell(
              onTap: () => context.go(AppRoutes.transactions),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Row(
                  children: [
                    Text(
                      'SEE ALL',
                      style: AppTextStyles.overlineLg.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    const Icon(
                      Pixel.chevronright,
                      size: AppSizing.iconSm,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.s8),
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    if (recentAsync.hasError && !recentAsync.hasValue) {
      return PixelErrorView(
        failure: asFailure(recentAsync.error),
        onRetry: onRetry,
        compact: true,
      );
    }
    final items = recentAsync.valueOrNull;
    if (recentAsync.isLoading && items == null) {
      return const RecentTransactionsCardSkeleton();
    }
    if (items == null || items.isEmpty) {
      return const _CardMessage('No transactions for this period.');
    }
    return RecentTransactionsCard(items: items);
  }
}

class _ExpensesByCategorySection extends StatelessWidget {
  const _ExpensesByCategorySection({
    required this.byCategoryAsync,
    required this.onRetry,
  });

  final AsyncValue<List<CategorySummary>> byCategoryAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (byCategoryAsync.hasError && !byCategoryAsync.hasValue) {
      return PixelErrorView(
        failure: asFailure(byCategoryAsync.error),
        onRetry: onRetry,
        compact: true,
      );
    }

    final items = byCategoryAsync.valueOrNull;
    if (byCategoryAsync.isLoading && items == null) {
      return const ExpensesByCategoryCardSkeleton();
    }
    if (items == null || items.isEmpty) {
      return const _CardMessage('No expenses for this period.');
    }
    return ExpensesByCategoryCard(items: items);
  }
}

/// Empty/error message kept inside a card so the section looks the same whether
/// it has data or not.
class _CardMessage extends StatelessWidget {
  const _CardMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      padding: AppSpacing.card,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppTextStyles.bodyNormal.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
