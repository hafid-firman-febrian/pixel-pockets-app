import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/utils/currency_formatter.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/core/widgets/pixel_select_chip.dart';
import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';
import 'package:pixel_pocket/features/chart/presentation/states/chart_state.dart';

const double _kPointWidth = 44;
const double _kChartHeight = 220;
const double _kYAxisWidth = 44;
const double _kBottomReserved = 28;

class IncomeExpenseChart extends ConsumerStatefulWidget {
  const IncomeExpenseChart({super.key, required this.data});

  final ChartData data;

  @override
  ConsumerState<IncomeExpenseChart> createState() => _IncomeExpenseChartState();
}

class _IncomeExpenseChartState extends ConsumerState<IncomeExpenseChart> {
  final _scroll = ScrollController();

  ChartData get data => widget.data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void didUpdateWidget(covariant IncomeExpenseChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data.labels.length != data.labels.length ||
        oldWidget.data.labels.lastOrNull != data.labels.lastOrNull) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!_scroll.hasClients) return;
    final labels = data.labels;
    if (labels.isEmpty) return;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var index = labels.indexOf(todayStr);
    if (index < 0) index = labels.length - 1;

    final position = _scroll.position;
    final target =
        index * _kPointWidth +
        _kPointWidth / 2 -
        position.viewportDimension / 2;
    _scroll.jumpTo(target.clamp(0.0, position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(chartViewProvider);
    final maxY = data.maxValue <= 0 ? 1.0 : data.maxValue * 1.2;
    final count = data.labels.length;

    return PixelCard(
      padding: AppSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _Legend(),
              _ViewToggle(
                view: view,
                onChanged: (v) =>
                    ref.read(chartViewProvider.notifier).state = v,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.section),
          SizedBox(
            height: _kChartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: _kYAxisWidth, child: _yAxis(maxY)),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final needed = count * _kPointWidth;
                      final width = needed < constraints.maxWidth
                          ? constraints.maxWidth
                          : needed;
                      return SingleChildScrollView(
                        controller: _scroll,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: width,
                          child: view == ChartView.line
                              ? _buildLineChart(maxY, count)
                              : _buildBarChart(maxY, count),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChart _yAxis(double maxY) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: maxY,
        lineBarsData: const [],
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
              reservedSize: _kBottomReserved,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _kYAxisWidth,
              interval: maxY / 4,
              getTitlesWidget: _leftLabel,
            ),
          ),
        ),
      ),
    );
  }

  LineChart _buildLineChart(double maxY, int count) {
    return LineChart(
      LineChartData(
        
        
        minX: -0.5,
        maxX: (count - 1).clamp(0, double.infinity).toDouble() + 0.5,
        minY: 0,
        maxY: maxY,
        gridData: _gridData(maxY),
        borderData: FlBorderData(show: false),
        titlesData: _plotTitles(count),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceVariant,
            getTooltipItems: _lineTooltipItems,
          ),
        ),
        lineBarsData: [
          _line(data.income, AppColors.income),
          _line(data.expense, AppColors.expense),
        ],
      ),
    );
  }

  BarChart _buildBarChart(double maxY, int count) {
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: _gridData(maxY),
        borderData: FlBorderData(show: false),
        titlesData: _plotTitles(count),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceVariant,
            getTooltipItem: _barTooltipItem,
          ),
        ),
        barGroups: [
          for (var i = 0; i < count; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 2,
              barRods: [
                _rod(data.income[i], AppColors.income),
                _rod(data.expense[i], AppColors.expense),
              ],
            ),
        ],
      ),
    );
  }

  FlGridData _gridData(double maxY) => FlGridData(
    show: true,
    drawVerticalLine: false,
    horizontalInterval: maxY / 4,
    getDrawingHorizontalLine: (_) =>
        const FlLine(color: AppColors.border, strokeWidth: 1),
  );

  FlTitlesData _plotTitles(int count) => FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: _kBottomReserved,
        interval: 1,
        getTitlesWidget: (value, meta) => _bottomLabel(value, count),
      ),
    ),
  );

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

  BarChartRodData _rod(double value, Color color) =>
      BarChartRodData(toY: value, color: color, width: 4);

  List<LineTooltipItem?> _lineTooltipItems(List<LineBarSpot> spots) {
    return spots.map((spot) {
      final color = spot.barIndex == 0 ? AppColors.income : AppColors.expense;
      final label = spot.barIndex == 0 ? 'Income' : 'Expense';
      return LineTooltipItem(
        '$label\n${CurrencyFormatter.format(spot.y)}',
        AppTextStyles.captionSm.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList();
  }

  BarTooltipItem _barTooltipItem(
    BarChartGroupData group,
    int groupIndex,
    BarChartRodData rod,
    int rodIndex,
  ) {
    final color = rodIndex == 0 ? AppColors.income : AppColors.expense;
    final label = rodIndex == 0 ? 'Income' : 'Expense';
    return BarTooltipItem(
      '$label\n${CurrencyFormatter.format(rod.toY)}',
      AppTextStyles.captionSm.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _leftLabel(double value, TitleMeta meta) {
    if (value <= 0) return const SizedBox.shrink();
    final text = CurrencyFormatter.compact(value).replaceFirst('Rp ', '');
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s4),
      child: Text(
        text,
        style: AppTextStyles.captionMd.copyWith(color: AppColors.textMuted),
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
        style: AppTextStyles.captionMd.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final ChartView view;
  final ValueChanged<ChartView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PixelSelectChip(
          label: 'LINE',
          selected: view == ChartView.line,
          onTap: () => onChanged(ChartView.line),
        ),
        const SizedBox(width: AppSpacing.s6),
        PixelSelectChip(
          label: 'BAR',
          selected: view == ChartView.bar,
          onTap: () => onChanged(ChartView.bar),
        ),
      ],
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
