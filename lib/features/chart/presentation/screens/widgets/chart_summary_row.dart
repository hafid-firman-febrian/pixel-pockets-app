import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/utils/currency_formatter.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';

class ChartSummaryRow extends StatelessWidget {
  const ChartSummaryRow({super.key, required this.data});

  final ChartData data;

  double get _income => data.income.fold(0, (sum, v) => sum + v);
  double get _expense => data.expense.fold(0, (sum, v) => sum + v);

  @override
  Widget build(BuildContext context) {
    final net = _income - _expense;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'INCOME',
            value: _income,
            color: AppColors.income,
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: _StatCard(
            label: 'EXPENSE',
            value: _expense,
            color: AppColors.expense,
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: _StatCard(
            label: 'NET',
            value: net,
            color: net < 0 ? AppColors.expense : AppColors.textPrimary,
            signed: true,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.signed = false,
  });

  final String label;
  final double value;
  final Color color;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final prefix = signed && value < 0 ? '-' : '';
    return PixelCard(
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.overlineSm),
          const SizedBox(height: AppSpacing.s6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$prefix${CurrencyFormatter.format(value)}',
              style: AppTextStyles.numericMd.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
