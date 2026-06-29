import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';
import 'package:pixelarticons/pixel.dart';

class TransactionRangeFilter extends ConsumerWidget {
  const TransactionRangeFilter({super.key});

  static const _units = [
    (RangeUnit.day, 'DAY'),
    (RangeUnit.week, 'WEEK'),
    (RangeUnit.month, 'MONTH'),
    (RangeUnit.year, 'YEAR'),
    (RangeUnit.all, 'ALL'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(rangeFilterProvider);
    void set(RangeFilter r) => ref.read(rangeFilterProvider.notifier).state = r;

    VoidCallback? onPrev;
    VoidCallback? onNext;
    bool showNav = false;
    if (range.isSalaryPeriod) {
      showNav = true;
      final periods = _sortedPeriods(ref);
      final idx = periods.indexWhere((p) => p.id == range.salaryPeriod!.id);
      if (idx > 0) onPrev = () => set(RangeFilter.period(periods[idx - 1]));
      if (idx >= 0 && idx < periods.length - 1) {
        onNext = () => set(RangeFilter.period(periods[idx + 1]));
      }
    } else if (range.unit != RangeUnit.all) {
      showNav = true;
      onPrev = () => set(range.shifted(-1));
      onNext = () => set(range.shifted(1));
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
                  child: _RangeChip(
                    label: label,
                    selected: !range.isSalaryPeriod && range.unit == unit,
                    onTap: () => set(RangeFilter.now(unit)),
                  ),
                ),
              _RangeChip(
                label: 'PERIOD',
                selected: range.isSalaryPeriod,
                onTap: () => _selectCurrentPeriod(ref),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.section),
        if (showNav) ...[
          _RangeNavigator(label: range.label, onPrev: onPrev, onNext: onNext),
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

    ref.read(rangeFilterProvider.notifier).state = RangeFilter.period(current);
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s6,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.overlineLg.copyWith(
            color: selected ? AppColors.textDark : AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RangeNavigator extends StatelessWidget {
  const _RangeNavigator({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardSm,
        child: Row(
          children: [
            _NavArrow(icon: Pixel.chevronleft, onTap: onPrev),
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
            _NavArrow(icon: Pixel.chevronright, onTap: onNext),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}
