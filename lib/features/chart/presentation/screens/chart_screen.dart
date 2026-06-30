import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';
import 'package:pixel_pocket/features/chart/presentation/screens/widgets/chart_filter_bar.dart';
import 'package:pixel_pocket/features/chart/presentation/screens/widgets/income_expense_chart.dart';
import 'package:pixel_pocket/features/chart/presentation/states/chart_state.dart';

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
            const SizedBox(height: AppSpacing.section),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screen,
                child: _content(chartAsync),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(AsyncValue<ChartData> chartAsync) {
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
    return IncomeExpenseChart(data: data);
  }
}

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  @override
  Widget build(BuildContext context) {
    return const PixelCard(
      padding: AppSpacing.card,
      child: SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
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
