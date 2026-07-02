import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/core/widgets/pixel_select_chip.dart';
import 'package:pixel_pocket/features/chart/presentation/states/chart_state.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';
import 'package:pixelarticons/pixel.dart';

class ChartFilterBar extends ConsumerWidget {
  const ChartFilterBar({super.key});

  static const _units = [
    (ChartUnit.week, 'WEEK'),
    (ChartUnit.month, 'MONTH'),
    (ChartUnit.year, 'YEAR'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(chartFilterProvider);
    void set(ChartFilter f) => ref.read(chartFilterProvider.notifier).state = f;

    VoidCallback? onPrev;
    VoidCallback? onNext;
    if (filter.isSalaryPeriod) {
      final periods = _sortedPeriods(ref);
      final idx = periods.indexWhere((p) => p.id == filter.salaryPeriod!.id);
      if (idx > 0) onPrev = () => set(ChartFilter.period(periods[idx - 1]));
      if (idx >= 0 && idx < periods.length - 1) {
        onNext = () => set(ChartFilter.period(periods[idx + 1]));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Row(
            children: [
              for (final (unit, label) in _units)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s6),
                  child: PixelSelectChip(
                    label: label,
                    selected: !filter.isSalaryPeriod && filter.unit == unit,
                    onTap: () => set(ChartFilter(unit: unit)),
                  ),
                ),
              PixelSelectChip(
                label: 'PERIOD',
                selected: filter.isSalaryPeriod,
                onTap: () => _selectCurrentPeriod(ref),
              ),
            ],
          ),
        ),
        if (filter.isSalaryPeriod) ...[
          const SizedBox(height: AppSpacing.s8),
          _PeriodNavigator(
            label: filter.salaryPeriod!.name,
            onPrev: onPrev,
            onNext: onNext,
          ),
        ],
      ],
    );
  }

  List<SalaryPeriodModel> _sortedPeriods(WidgetRef ref) {
    final list = ref.read(salaryPeriodProvider).valueOrNull ?? const [];
    return [...list]..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Future<void> _selectCurrentPeriod(WidgetRef ref) async {
    final List<SalaryPeriodModel> periods;
    try {
      periods = await ref.read(salaryPeriodProvider.future);
    } catch (_) {
      return;
    }
    if (periods.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    SalaryPeriodModel? current;
    for (final p in periods) {
      final start = DateTime.parse(p.startDate);
      final end = DateTime.parse(p.endDate);
      if (!today.isBefore(start) && !today.isAfter(end)) {
        current = p;
        break;
      }
    }
    current ??= ([
      ...periods,
    ]..sort((a, b) => b.startDate.compareTo(a.startDate))).first;

    ref.read(chartFilterProvider.notifier).state = ChartFilter.period(current);
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Row(
        children: [
          PixelButton(
            onPressed: onPrev,
            icon: Pixel.chevronleft,
            variant: PixelButtonVariant.ghost,
            size: PixelButtonSize.sm,
            foregroundColor: AppColors.primary,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyNormal.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          PixelButton(
            onPressed: onNext,
            icon: Pixel.chevronright,
            variant: PixelButtonVariant.ghost,
            size: PixelButtonSize.sm,
            foregroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

