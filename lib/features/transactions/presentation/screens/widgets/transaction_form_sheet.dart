import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_bottom_sheet.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';
import 'package:pixel_pocket/features/categories/presentation/states/category_state.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/controllers/transaction_controller.dart';






class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key, this.existing});

  
  final TransactionModel? existing;

  bool get isEditing => existing != null;

  
  static Future<bool?> show(
    BuildContext context, {
    TransactionModel? existing,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.background.withValues(alpha: 0.72),
      useSafeArea: true,
      builder: (_) => TransactionFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late String _type; 
  late DateTime _date;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.transactionType ?? 'expense';
    _date = existing != null
        ? (DateTime.tryParse(existing.transactionDate) ?? _todayFloor())
        : _todayFloor();
    _categoryId = existing?.categoryId;
    _amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '',
    );
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
  }

  
  DateTime _todayFloor() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  List<CategoryModel> _categoriesForType(List<CategoryModel> all) =>
      all.where((c) => c.type == _type).toList();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      _showSnack('Please select a category first', isError: true);
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    final controller = ref.read(transactionsControllerProvider.notifier);

    
    final ok = widget.isEditing
        ? await controller.edit(
            id: widget.existing!.id,
            transactionDate: _dateFormat.format(_date),
            transactionType: _type,
            amount: amount,
            categoryId: _categoryId,
            description: description.isEmpty ? null : description,
          )
        : await controller.create(
            transactionDate: _dateFormat.format(_date),
            transactionType: _type,
            amount: amount,
            categoryId: _categoryId,
            description: description.isEmpty ? null : description,
          );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final error = ref.read(transactionsControllerProvider).error;
      _showSnack(
        error is Failure ? error.message : 'Failed to save transaction',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.expense : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isSubmitting = ref.watch(transactionsControllerProvider).isLoading;

    return PixelBottomSheetFrame(
      title: widget.isEditing ? 'EDIT TRANSACTION' : 'NEW TRANSACTION',
      child: SingleChildScrollView(
        padding: AppSpacing.form,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Expense / Income toggle (pixel buttons).
              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'EXPENSE',
                      isFullWidth: true,
                      // Active → colored & flat (pressed-in); inactive → grey
                      // with the normal raised shadow.
                      variant: _type == 'expense'
                          ? PixelButtonVariant.expense
                          : PixelButtonVariant.surface,
                      pressed: _type == 'expense',
                      onPressed: () => _setType('expense'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: PixelButton(
                      label: 'INCOME',
                      isFullWidth: true,
                      variant: _type == 'income'
                          ? PixelButtonVariant.income
                          : PixelButtonVariant.surface,
                      pressed: _type == 'income',
                      onPressed: () => _setType('income'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),

              const _FieldLabel('AMOUNT'),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.numericMd,
                decoration: const InputDecoration(prefixText: 'Rp '),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null || value <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.section),

              const _FieldLabel('DATE'),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                  child: Text(_dateFormat.format(_date)),
                ),
              ),
              const SizedBox(height: AppSpacing.section),

              const _FieldLabel('CATEGORY'),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Failed to load categories: $e',
                  style: const TextStyle(color: AppColors.expense),
                ),
                data: (all) {
                  final options = _categoriesForType(all);
                  final validIds = options.map((c) => c.id).toSet();
                  final value = validIds.contains(_categoryId)
                      ? _categoryId
                      : null;
                  return DropdownButtonFormField<int>(
                    initialValue: value,
                    isExpanded: true,
                    items: options
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  color: AppColors.fromHex(c.color),
                                ),
                                const SizedBox(width: 10),
                                Text(c.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) => setState(() => _categoryId = id),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.section),

              const _FieldLabel('DESCRIPTION (OPTIONAL)'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.s24),

              PixelButton(
                label: widget.isEditing ? 'SAVE CHANGES' : 'SAVE TRANSACTION',
                isFullWidth: true,
                isLoading: isSubmitting,
                onPressed: isSubmitting ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.s12),
              PixelButton(
                label: 'CANCEL',
                variant: PixelButtonVariant.secondary,
                isFullWidth: true,
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setType(String type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _categoryId = null; // category list depends on type
    });
  }
}

/// Small uppercase field label shown above each input, per the design system.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
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
