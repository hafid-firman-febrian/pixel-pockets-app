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

class PeriodFilterCard extends ConsumerWidget {
  const PeriodFilterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectedPeriodProvider);
    final effective = ref.watch(effectivePeriodProvider);

    final label = switch (selection) {
      AutoPeriod() =>
        effective.valueOrNull?.name ??
            (effective.isLoading ? 'Juni 2026' : 'Periode Saat Ini'),
      AllPeriods() => 'Semua Periode',
      SpecificPeriod() => effective.valueOrNull?.name ?? '...',
    };

    return InkWell(
      onTap: () => _openPicker(context, ref),
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
                enabled: effective.isLoading,
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
                    Icon(
                      Pixel.chevrondown,
                      size: AppSizing.iconMd,
                      color: AppColors.primary,
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

  void _openPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.background.withOpacity(0.72),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return const PixelBottomSheetFrame(
          title: 'period_filter',
          child: _PeriodPickerSheet(),
        );
      },
    );
  }
}

class PixelBottomSheetFrame extends StatelessWidget {
  const PixelBottomSheetFrame({required this.child, required this.title});

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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border.withOpacity(0.75),
              width: 1.4,
            ),
            // boxShadow: [
            //   BoxShadow(
            //     color: AppColors.primary.withOpacity(0.18),
            //     blurRadius: 24,
            //     spreadRadius: 1,
            //     offset: const Offset(0, -2),
            //   ),
            // ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TerminalSheetTopBar(title),
                Flexible(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                    ),
                    child: child,
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

class _TerminalSheetTopBar extends StatelessWidget {
  const _TerminalSheetTopBar(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.45),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _windowDot(const Color(0xFFFF5F56)),
          const SizedBox(width: AppSpacing.s6),
          _windowDot(const Color(0xFFFFBD2E)),
          const SizedBox(width: AppSpacing.s6),
          _windowDot(const Color(0xFF27C93F)),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyNormal.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Text(
            '▂',
            style: AppTextStyles.bodyNormal.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowDot(Color color) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(salaryPeriodProvider);

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
              ..sort((a, b) => b.compareTo(a));

            final filtered = periods
                .where((period) => _yearOf(period) == _selectedYear)
                .toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: AppSpacing.card,
                  child: Text(
                    '> SELECT PERIOD',
                    style: AppTextStyles.bodyNormal.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
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
                            child: ChoiceChip(
                              label: Text('$year'),
                              selected: year == _selectedYear,
                              onSelected: (_) {
                                setState(() => _selectedYear = year);
                              },
                              backgroundColor: AppColors.surface,
                              selectedColor: AppColors.primary.withOpacity(
                                0.18,
                              ),
                              side: BorderSide(
                                color: year == _selectedYear
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                              labelStyle: AppTextStyles.bodyNormal.copyWith(
                                color: year == _selectedYear
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              showCheckmark: false,
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
                        onTap: () {
                          ref.read(selectedPeriodProvider.notifier).state =
                              const AutoPeriod();
                          Navigator.of(context).pop();
                        },
                      ),
                      _TerminalPeriodTile(
                        icon: Pixel.list,
                        title: 'All Periods',
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

class _TerminalPeriodTile extends StatelessWidget {
  const _TerminalPeriodTile({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
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
                    Text(
                      title,
                      style: AppTextStyles.bodyNormal.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}
