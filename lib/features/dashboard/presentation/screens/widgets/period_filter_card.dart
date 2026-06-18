import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_sizing.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixel_pocket/features/salary_period/domain/model/salary_period_model.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';
import 'package:pixelarticons/pixelarticons.dart';

class PeriodFilterCard extends ConsumerWidget {
  const PeriodFilterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref
        .watch(effectivePeriodProvider)
        .maybeWhen(
          data: (data) => data?.name ?? 'All Periode',
          orElse: () => '...',
        );

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
              Row(
                children: [
                  Text(
                    label.toString(),
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
            ],
          ),
        ),
      ),
    );
  }

  void _openPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (_) => const _PeriodPickerSheet(),
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

  int _yearOf(SalaryPeriodModel p) => DateTime.parse(p.startDate).year;

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(salaryPeriodProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.section),
        child: periodsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gagal memuat periode: $e', textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.section),
                TextButton(
                  onPressed: () => ref.invalidate(salaryPeriodProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
          data: (periods) {
            // Tahun unik dari semua period (terbaru dulu).
            final years = periods.map(_yearOf).toSet().toList()
              ..sort((a, b) => b.compareTo(a));
            // Filter client-side: hanya period di tahun terpilih.
            final filtered = periods
                .where((p) => _yearOf(p) == _selectedYear)
                .toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (years.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: AppSpacing.card,
                    child: Row(
                      children: [
                        for (final year in years)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.s4,
                            ),
                            child: ChoiceChip(
                              label: Text('$year'),
                              selected: year == _selectedYear,
                              onSelected: (_) =>
                                  setState(() => _selectedYear = year),
                            ),
                          ),
                      ],
                    ),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text('Semua Periode'),
                        onTap: () {
                          ref.read(selectedPeriodProvider.notifier).state =
                              const AllPeriods();
                          Navigator.of(context).pop();
                        },
                      ),
                      for (final period in filtered)
                        ListTile(
                          title: Text(period.name),
                          subtitle: Text(
                            '${period.startDate} → ${period.endDate}',
                          ),
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
                            style: const TextStyle(color: AppColors.textMuted),
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
