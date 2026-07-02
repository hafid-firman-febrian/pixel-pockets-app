import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';
import 'package:pixel_pocket/features/chart/presentation/screens/widgets/chart_filter_bar.dart';
import 'package:pixel_pocket/features/chart/presentation/screens/widgets/chart_summary_row.dart';
import 'package:pixel_pocket/features/chart/presentation/screens/widgets/income_expense_chart.dart';
import 'package:pixel_pocket/features/chart/presentation/states/chart_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ChartScreen extends ConsumerWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(chartProvider);

    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.section),
            Padding(
              padding: AppSpacing.card,
              child: Text('CHART', style: AppTextStyles.displayMedium),
            ),
            const SizedBox(height: AppSpacing.section),
            const ChartFilterBar(),
            Padding(
              padding: AppSpacing.card,
              child: Divider(color: AppColors.border, thickness: 1),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  0,
                  AppSpacing.s16,
                  AppSpacing.s24,
                ),
                child: _chartSection(chartAsync),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartSection(AsyncValue<ChartData> chartAsync) {
    if (chartAsync.hasError && !chartAsync.hasValue) {
      return const _CardMessage('Failed to load chart.');
    }
    final data = chartAsync.valueOrNull;
    if (chartAsync.isLoading && data == null) {
      return const _ChartLoading();
    }
    if (data == null || data.isEmpty) {
      return const _CardMessage('No data for this range.');
    }
    return Column(
      children: [
        ChartSummaryRow(data: data),
        const SizedBox(height: AppSpacing.section),
        IncomeExpenseChart(data: data),
      ],
    );
  }
}

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  static const _bars = <double>[40, 70, 30, 85, 55, 75, 45, 60];

  @override
  Widget build(BuildContext context) {
    const placeholder = ChartData(
      labels: ['', '', ''],
      income: [1500000],
      expense: [900000],
    );

    return Skeletonizer(
      child: Column(
        children: [
          ChartSummaryRow(data: placeholder),
          const SizedBox(height: AppSpacing.section),
          PixelCard(
            padding: AppSpacing.card,
            child: SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final h in _bars)
                    Container(
                      width: 18,
                      height: 30 + h * 1.6,
                      color: AppColors.surfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
