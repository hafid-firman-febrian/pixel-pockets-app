import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';

import '../../../../core/error/failure.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';
import 'package:pixel_pocket/features/categories/presentation/states/category_state.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';

/// Bottom-sheet form for creating or editing a transaction.
///
/// Form/UI state (controllers, selections) lives here because it is
/// genuinely view state. The actual write goes through
/// [TransactionController]; this widget never touches Dio or JSON.
class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key, this.existing});

  /// When non-null the form is in edit mode.
  final TransactionModel? existing;

  bool get isEditing => existing != null;

  /// Opens the sheet. Resolves to `true` when a transaction was saved.
  static Future<bool?> show(
    BuildContext context, {
    TransactionModel? existing,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

  late String _type; // income | expense
  late DateTime _date;
  int? _categoryId;
  bool _submitting = false;

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

  // A date with no time component, derived without Date.now sensitivity issues.
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
      _showSnack('Pilih kategori terlebih dahulu', isError: true);
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    final controller = ref.read(transactionControllerProvider);

    setState(() => _submitting = true);
    try {
      if (widget.isEditing) {
        await controller.update(
          id: widget.existing!.id,
          transactionDate: _dateFormat.format(_date),
          transactionType: _type,
          amount: amount,
          categoryId: _categoryId,
          description: description.isEmpty ? null : description,
        );
      } else {
        await controller.create(
          transactionDate: _dateFormat.format(_date),
          transactionType: _type,
          amount: amount,
          categoryId: _categoryId,
          description: description.isEmpty ? null : description,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Failure catch (f) {
      if (mounted) {
        setState(() => _submitting = false);
        _showSnack(f.message, isError: true);
      }
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
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: AppSpacing.form,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: AppSpacing.s4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.section),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.isEditing ? 'Edit Transaksi' : 'Transaksi Baru',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.section),

              // Income / Expense toggle
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                  ButtonSegment(value: 'income', label: Text('Pemasukan')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _categoryId = null; // category list depends on type
                }),
              ),
              const SizedBox(height: AppSpacing.section),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  prefixText: 'Rp ',
                ),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null || value <= 0) {
                    return 'Masukkan jumlah yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.section),

              // Category (depends on type)
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Gagal memuat kategori: $e',
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
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: options
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppColors.fromHex(c.color),
                                    shape: BoxShape.circle,
                                  ),
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

              // Date
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                  child: Text(_dateFormat.format(_date)),
                ),
              ),
              const SizedBox(height: AppSpacing.section),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                ),
              ),
              const SizedBox(height: AppSpacing.s24),

              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.isEditing ? 'Simpan Perubahan' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
