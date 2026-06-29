import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/widgets/pixel_bottom_sheet.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/core/widgets/pixel_field_label.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';
import 'package:pixel_pocket/features/categories/presentation/controllers/category_controller.dart';

/// Bottom-sheet form to create or edit a category (name, type, color).
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, this.existing});

  /// When non-null the form edits this category instead of creating one.
  final CategoryModel? existing;

  bool get isEditing => existing != null;

  /// Opens the sheet. Resolves to `true` when a category was saved.
  static Future<bool?> show(BuildContext context, {CategoryModel? existing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.background.withValues(alpha: 0.72),
      useSafeArea: true,
      builder: (_) => CategoryFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  /// Retro palette the user can pick from (sent to the API as hex).
  static const _palette = [
    '#7D9B76', '#5F8A8B', '#8B6355', '#8C7B6B', '#C4A882', '#6B7C8D',
    '#9B6B8C', '#B5847A', '#CC7358', '#A0856C', '#7B6D8D', '#4A7C8C',
    '#6B8C5F', '#5B7A8C', '#8C7A3D', '#8C5B3D', '#7A8C6B', '#8C8C7B',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late String _type;
  late String _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? 'expense';
    _color = existing?.color ?? _palette.first;
    _nameController.text = existing?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(categoryControllerProvider);
    final name = _nameController.text.trim();
    try {
      final existing = widget.existing;
      if (existing != null) {
        await controller.update(
          id: existing.id,
          name: name,
          color: _color,
          type: _type,
        );
      } else {
        await controller.create(name: name, color: _color, type: _type);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e is Failure ? e.message : 'Failed to save category';
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.expense),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PixelBottomSheetFrame(
      title: widget.isEditing ? 'EDIT CATEGORY' : 'NEW CATEGORY',
      child: SingleChildScrollView(
        padding: AppSpacing.form,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PixelFieldLabel('NAME'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: AppSpacing.section),

              const PixelFieldLabel('TYPE'),
              Row(
                children: [
                  _typeButton('expense', 'EXPENSE', PixelButtonVariant.expense),
                  const SizedBox(width: AppSpacing.s8),
                  _typeButton('income', 'INCOME', PixelButtonVariant.income),
                  const SizedBox(width: AppSpacing.s8),
                  _typeButton('both', 'BOTH', PixelButtonVariant.primary),
                ],
              ),
              const SizedBox(height: AppSpacing.section),

              const PixelFieldLabel('COLOR'),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (final hex in _palette)
                    _ColorSwatch(
                      hex: hex,
                      selected: hex == _color,
                      onTap: () => setState(() => _color = hex),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),

              PixelButton(
                label: widget.isEditing ? 'SAVE CHANGES' : 'SAVE CATEGORY',
                isFullWidth: true,
                isLoading: _saving,
                onPressed: _saving ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.s12),
              PixelButton(
                label: 'CANCEL',
                variant: PixelButtonVariant.secondary,
                isFullWidth: true,
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String value, String label, PixelButtonVariant variant) {
    final selected = _type == value;
    return Expanded(
      child: PixelButton(
        label: label,
        isFullWidth: true,
        variant: selected ? variant : PixelButtonVariant.surface,
        pressed: selected,
        onPressed: () => setState(() => _type = value),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.fromHex(hex),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}
