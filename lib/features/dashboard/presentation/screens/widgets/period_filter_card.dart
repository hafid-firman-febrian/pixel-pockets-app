import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_sizing.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';
import 'package:pixelarticons/pixelarticons.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PeriodFilterCard extends ConsumerStatefulWidget {
  const PeriodFilterCard({super.key});

  @override
  ConsumerState<PeriodFilterCard> createState() => _PeriodFilterCardState();
}

class _PeriodFilterCardState extends ConsumerState<PeriodFilterCard> {
  bool _sheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedPeriodProvider);
    final effective = ref.watch(effectivePeriodProvider);

    final label = effective.hasError
        ? '-'
        : switch (selection) {
            AutoPeriod() =>
              effective.valueOrNull?.name ??
                  (effective.isLoading ? 'Juni 2026' : 'Periode Saat Ini'),
            AllPeriods() => 'Semua Periode',
            SpecificPeriod() => effective.valueOrNull?.name ?? '...',
          };

    return InkWell(
      onTap: _openPicker,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PERIOD', style: AppTextStyles.bodyNormal),
              Skeletonizer(
                enabled: effective.isLoading && !effective.hasValue,
                child: Row(
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyNormal.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: AppSpacing.s6),
                    AnimatedRotation(
                      turns: _sheetOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Pixel.chevrondown,
                        size: AppSizing.iconMd,
                        color: AppColors.primary,
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

  Future<void> _openPicker() async {
    setState(() => _sheetOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.background.withValues(alpha: 0.72),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return const PixelBottomSheetFrame(
          title: 'SELECT PERIOD',
          child: _PeriodPickerSheet(),
        );
      },
    );
    if (mounted) setState(() => _sheetOpen = false);
  }
}

class PixelBottomSheetFrame extends StatelessWidget {
  const PixelBottomSheetFrame({
    super.key,
    required this.child,
    required this.title,
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        child: Container(
          width: size.width,
          constraints: BoxConstraints(maxHeight: size.height * 0.62),

          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.border,
                offset: Offset(0, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PixelSheetHeader(title: title),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _PixelSheetHeader extends StatelessWidget {
  const _PixelSheetHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s8,
        AppSpacing.s12,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headingSmall,
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.s4),
              child: Icon(
                Pixel.close,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodPickerSheet extends ConsumerStatefulWidget {
  const _PeriodPickerSheet();

  @override
  ConsumerState<_PeriodPickerSheet> createState() => _PeriodPickerSheetState();
}

class _PeriodPickerSheetState extends ConsumerState<_PeriodPickerSheet> {
  int _selectedYear = DateTime.now().year;

  int _yearOf(SalaryPeriodModel period) {
    return DateTime.parse(period.startDate).year;
  }

  bool _isCurrentPeriod(SalaryPeriodModel period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime.parse(period.startDate);
    final end = DateTime.parse(period.endDate);
    return !today.isBefore(start) && !today.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(salaryPeriodProvider);
    final selection = ref.watch(selectedPeriodProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.s12,
          bottom: AppSpacing.s12,
        ),
        child: periodsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load periods',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyNormal.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyNormal.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                TextButton(
                  onPressed: () => ref.invalidate(salaryPeriodProvider),
                  child: Text(
                    'Try Again',
                    style: AppTextStyles.bodyNormal.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          data: (periods) {
            final years = periods.map(_yearOf).toSet().toList()
              ..sort((a, b) => a.compareTo(b));

            final filtered = periods
                .where((period) => _yearOf(period) == _selectedYear)
                .toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.s12),
                if (years.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                    ),
                    child: Row(
                      children: [
                        for (final year in years)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.s6,
                            ),
                            child: _YearChip(
                              year: year,
                              selected: year == _selectedYear,
                              onTap: () => setState(() => _selectedYear = year),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.s8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s12,
                      0,
                      AppSpacing.s12,
                      AppSpacing.s12,
                    ),
                    children: [
                      _TerminalPeriodTile(
                        icon: Pixel.calendartoday,
                        title: 'Current Period',
                        subtitle: 'Auto according to today\'s date',
                        selected: selection is AutoPeriod,
                        onTap: () {
                          ref.read(selectedPeriodProvider.notifier).state =
                              const AutoPeriod();
                          Navigator.of(context).pop();
                        },
                      ),
                      _TerminalPeriodTile(
                        icon: Pixel.list,
                        title: 'All Periods',
                        selected: selection is AllPeriods,
                        onTap: () {
                          ref.read(selectedPeriodProvider.notifier).state =
                              const AllPeriods();
                          Navigator.of(context).pop();
                        },
                      ),
                      for (final period in filtered)
                        _TerminalPeriodTile(
                          title: period.name,
                          subtitle: '${period.startDate} → ${period.endDate}',
                          isCurrent: _isCurrentPeriod(period),
                          selected:
                              selection is SpecificPeriod &&
                              selection.period.id == period.id,
                          onTap: () {
                            ref.read(selectedPeriodProvider.notifier).state =
                                SpecificPeriod(period);
                            Navigator.of(context).pop();
                          },
                        ),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.s24),
                          child: Text(
                            'Tidak ada periode untuk tahun $_selectedYear',
                            style: AppTextStyles.bodyNormal.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        border: Border.all(color: AppColors.primary),
      ),
      child: Text(
        'CURRENT',
        style: AppTextStyles.overlineSm.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({
    required this.year,
    required this.selected,
    required this.onTap,
  });

  final int year;
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
          color: selected
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          '$year',
          style: AppTextStyles.bodyNormal.copyWith(
            color: selected ? AppColors.primary : AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TerminalPeriodTile extends StatelessWidget {
  const _TerminalPeriodTile({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.selected = false,
    this.isCurrent = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;

  final bool selected;

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizing.iconMd, color: AppColors.primary),
                const SizedBox(width: AppSpacing.s10),
              ] else ...[
                Text(
                  '>',
                  style: AppTextStyles.bodyNormal.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: AppSpacing.s10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyNormal.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: AppSpacing.s6),
                          const _CurrentBadge(),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodyNormal.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: AppSpacing.s10),
                const Icon(
                  Pixel.check,
                  size: AppSizing.iconMd,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
