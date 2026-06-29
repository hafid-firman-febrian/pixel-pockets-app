import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/widgets/pixel_bottom_sheet.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/core/widgets/pixel_field_label.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';
import 'package:pixel_pocket/features/salary_period/presentation/controllers/salary_period_controller.dart';
import 'package:pixelarticons/pixel.dart';

/// Bottom-sheet form to create or edit a salary period.
class SalaryPeriodFormSheet extends ConsumerStatefulWidget {
  const SalaryPeriodFormSheet({super.key, this.existing});

  /// When non-null the form edits this period instead of creating one.
  final SalaryPeriodModel? existing;

  bool get isEditing => existing != null;

  /// Opens the sheet. Resolves to `true` when a period was saved.
  static Future<bool?> show(BuildContext context, {SalaryPeriodModel? existing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.background.withValues(alpha: 0.72),
      useSafeArea: true,
      builder: (_) => SalaryPeriodFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<SalaryPeriodFormSheet> createState() =>
      _SalaryPeriodFormSheetState();
}

class _SalaryPeriodFormSheetState extends ConsumerState<SalaryPeriodFormSheet> {
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  late DateTime _start;
  late DateTime _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final today = _todayFloor();
    _start = existing != null ? DateTime.parse(existing.startDate) : today;
    _end = existing != null ? DateTime.parse(existing.endDate) : today;
    _nameController.text = existing?.name ?? '';
    if (existing?.salaryAmount != null) {
      _amountController.text = existing!.salaryAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  DateTime _todayFloor() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(salaryPeriodControllerProvider);
    final amountText = _amountController.text.trim();
    final name = _nameController.text.trim();
    final startDate = _dateFormat.format(_start);
    final endDate = _dateFormat.format(_end);
    final salaryAmount = amountText.isEmpty ? null : double.parse(amountText);
    try {
      final existing = widget.existing;
      if (existing != null) {
        await controller.update(
          id: existing.id,
          name: name,
          startDate: startDate,
          endDate: endDate,
          salaryAmount: salaryAmount,
        );
      } else {
        await controller.create(
          name: name,
          startDate: startDate,
          endDate: endDate,
          salaryAmount: salaryAmount,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e is Failure ? e.message : 'Failed to save period';
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.expense),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PixelBottomSheetFrame(
      title: widget.isEditing ? 'EDIT SALARY PERIOD' : 'NEW SALARY PERIOD',
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

              const PixelFieldLabel('START DATE'),
              _DateField(
                value: _dateFormat.format(_start),
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: AppSpacing.section),

              const PixelFieldLabel('END DATE'),
              _DateField(
                value: _dateFormat.format(_end),
                onTap: () => _pickDate(isStart: false),
              ),
              const SizedBox(height: AppSpacing.section),

              const PixelFieldLabel('SALARY AMOUNT (OPTIONAL)'),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(prefixText: 'Rp '),
              ),
              const SizedBox(height: AppSpacing.s24),

              PixelButton(
                label: widget.isEditing ? 'SAVE CHANGES' : 'SAVE PERIOD',
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
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Pixel.calendar, size: 18),
        ),
        child: Text(value),
      ),
    );
  }
}
