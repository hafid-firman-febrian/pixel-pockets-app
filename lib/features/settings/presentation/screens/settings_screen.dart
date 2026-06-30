import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/core/widgets/pixel_chip.dart';
import 'package:pixel_pocket/core/widgets/pixel_confirm_dialog.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/pin_controller.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';
import 'package:pixel_pocket/features/categories/presentation/controllers/category_controller.dart';
import 'package:pixel_pocket/features/categories/presentation/screens/widgets/category_form_sheet.dart';
import 'package:pixel_pocket/features/categories/presentation/states/category_state.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';
import 'package:pixel_pocket/features/salary_period/presentation/controllers/salary_period_controller.dart';
import 'package:pixel_pocket/features/salary_period/presentation/screens/widgets/salary_period_form_sheet.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        padding: AppSpacing.screenAll,
        children: [
          const _SectionLabel('DATA'),
          const _SalaryPeriodSection(),
          const SizedBox(height: AppSpacing.section),
          const _CategorySection(),
          const SizedBox(height: AppSpacing.section),
          const _SectionLabel('SECURITY'),
          _ResetPinTile(onTap: () => _resetPin(context, ref)),
        ],
      ),
    );
  }

  Future<void> _resetPin(BuildContext context, WidgetRef ref) async {
    final confirmed = await showPixelConfirm(
      context,
      title: 'Reset PIN?',
      message:
          'Your current PIN will be removed. '
          'You\'ll be asked to create a new one.',
      confirmLabel: 'Reset',
      confirmVariant: PixelButtonVariant.danger,
      icon: Pixel.lock,
    );
    if (!confirmed) return;
    await ref.read(pinControllerProvider.notifier).clearPin();
  }
}

class _SalaryPeriodSection extends ConsumerWidget {
  const _SalaryPeriodSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(salaryPeriodProvider);
    return _DataCard(
      label: 'SALARY PERIOD',
      addLabel: 'Add Salary Period',
      onAdd: () => _open(context),
      child: async.when(
        loading: () => const _ChipsLoading(),
        error: (e, _) => const _LoadError(),
        data: (periods) => periods.isEmpty
            ? const _EmptyHint('No salary periods yet')
            : _grouped(context, ref, periods),
      ),
    );
  }

  Widget _grouped(
    BuildContext context,
    WidgetRef ref,
    List<SalaryPeriodModel> periods,
  ) {
    final byYear = <String, List<SalaryPeriodModel>>{};
    for (final p in periods) {
      final year = p.endDate.length >= 4 ? p.endDate.substring(0, 4) : '—';
      byYear.putIfAbsent(year, () => []).add(p);
    }
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

    final sections = <Widget>[];
    for (final year in years) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: AppSpacing.s12));
      }
      sections.add(_SectionLabel(year));
      sections.add(
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final p in byYear[year]!)
              PixelChip(
                label: p.name,
                onTap: () => _open(context, existing: p),
                onDelete: () => _delete(context, ref, p),
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Future<void> _open(
    BuildContext context, {
    SalaryPeriodModel? existing,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await SalaryPeriodFormSheet.show(context, existing: existing);
    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Period created' : 'Period updated'),
        ),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SalaryPeriodModel period,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showPixelConfirm(
      context,
      title: 'Delete period?',
      message: '"${period.name}" will be removed.',
      confirmLabel: 'Delete',
      confirmVariant: PixelButtonVariant.danger,
      icon: Pixel.trash,
    );
    if (!confirmed) return;
    try {
      await ref.read(salaryPeriodControllerProvider).delete(period.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Salary period deleted')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to delete'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesProvider);
    return _DataCard(
      label: 'CATEGORIES',
      addLabel: 'Add Category',
      onAdd: () => _open(context),
      child: async.when(
        loading: () => const _ChipsLoading(),
        error: (e, _) => const _LoadError(),
        data: (categories) => categories.isEmpty
            ? const _EmptyHint('No categories yet')
            : _grouped(context, ref, categories),
      ),
    );
  }

  Widget _grouped(
    BuildContext context,
    WidgetRef ref,
    List<CategoryModel> categories,
  ) {
    const groups = [
      ('expense', 'EXPENSE'),
      ('income', 'INCOME'),
      ('both', 'BOTH'),
    ];
    final sections = <Widget>[];
    for (final (type, label) in groups) {
      final items = categories.where((c) => c.type == type).toList();
      if (items.isEmpty) continue;
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: AppSpacing.s12));
      }
      sections.add(_SectionLabel(label));
      sections.add(
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final c in items)
              PixelChip(
                label: c.name,
                leadingColor: AppColors.fromHex(c.color),
                onTap: () => _open(context, existing: c),
                onDelete: () => _delete(context, ref, c),
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Future<void> _open(BuildContext context, {CategoryModel? existing}) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await CategoryFormSheet.show(context, existing: existing);
    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Category created' : 'Category updated',
          ),
        ),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showPixelConfirm(
      context,
      title: 'Delete category?',
      message: '"${category.name}" will be removed.',
      confirmLabel: 'Delete',
      confirmVariant: PixelButtonVariant.danger,
      icon: Pixel.trash,
    );
    if (!confirmed) return;
    try {
      await ref.read(categoryControllerProvider).delete(category.id);
      messenger.showSnackBar(const SnackBar(content: Text('Category deleted')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to delete'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.label,
    required this.child,
    required this.addLabel,
    required this.onAdd,
  });

  final String label;
  final Widget child;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      padding: AppSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyBold),
          const SizedBox(height: AppSpacing.s12),
          child,
          const SizedBox(height: AppSpacing.section),
          PixelButton(
            label: addLabel,
            icon: Pixel.plus,
            isFullWidth: true,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _ChipsLoading extends StatelessWidget {
  const _ChipsLoading();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Wrap(
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s8,
        children: const [
          PixelChip(label: 'Placeholder'),
          PixelChip(label: 'Category'),
          PixelChip(label: 'Item'),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) => const _EmptyHint('Failed to load');
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTextStyles.bodyNormal.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Text(
        text,
        style: AppTextStyles.overlineSm.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _ResetPinTile extends StatelessWidget {
  const _ResetPinTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      onTap: onTap,
      padding: AppSpacing.card,
      child: Row(
        children: [
          const Icon(Pixel.lock, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: Text('Reset PIN', style: AppTextStyles.bodyNormal)),
          const Icon(Pixel.chevronright, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
