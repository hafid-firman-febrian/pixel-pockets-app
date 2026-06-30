import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/utils/currency_formatter.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';

class IncomeExpenseChart extends StatelessWidget {
  const IncomeExpenseChart({super.key, required this.data});

  final ChartData data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.maxValue <= 0 ? 1.0 : data.maxValue * 1.2;
    final count = data.labels.length;

    final step = count <= 6 ? 1 : (count / 6).ceil();

    return PixelCard(
      padding: AppSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Legend(),
          const SizedBox(height: AppSpacing.section),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (count - 1).clamp(0, double.infinity).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: maxY / 4,
                      getTitlesWidget: _leftLabel,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: step.toDouble(),
                      getTitlesWidget: (value, meta) =>
                          _bottomLabel(value, count),
                    ),
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: true),
                lineBarsData: [
                  _line(data.income, AppColors.income),
                  _line(data.expense, AppColors.expense),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(List<double> values, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
      ],
      isCurved: false,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
  }

  Widget _leftLabel(double value, TitleMeta meta) {
    if (value <= 0) return const SizedBox.shrink();
    final text = CurrencyFormatter.compact(value).replaceFirst('Rp ', '');
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s4),
      child: Text(
        text,
        style: AppTextStyles.captionSm.copyWith(color: AppColors.textMuted),
      ),
    );
  }

  Widget _bottomLabel(double value, int count) {
    final index = value.round();
    if (index < 0 || index >= count) return const SizedBox.shrink();
    final raw = data.labels[index];
    final parsed = DateTime.tryParse(raw);
    final text = parsed != null ? DateFormat('d/M').format(parsed) : raw;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s6),
      child: Text(
        text,
        style: AppTextStyles.captionSm.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendItem(color: AppColors.income, label: 'INCOME'),
        SizedBox(width: AppSpacing.s16),
        _LegendItem(color: AppColors.expense, label: 'EXPENSE'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: AppSpacing.s6),
        Text(label, style: AppTextStyles.overlineSm),
      ],
    );
  }
}
