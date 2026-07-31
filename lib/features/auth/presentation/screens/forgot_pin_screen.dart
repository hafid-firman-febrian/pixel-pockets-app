import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/core/widgets/pixel_field_label.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/pin_controller.dart';
import 'package:pixelarticons/pixel.dart';

class ForgotPinScreen extends ConsumerStatefulWidget {
  const ForgotPinScreen({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  ConsumerState<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends ConsumerState<ForgotPinScreen> {
  static const _confirmWord = 'DELETE';

  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  bool get _canSubmit => _controller.text == _confirmWord && !_submitting;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(pinControllerProvider.notifier).resetForgottenPin();
      if (!mounted) return;
      widget.onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      debugPrint('resetForgottenPin failed: $e');
      setState(() => _error = "Couldn't erase your data. Please try again.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Pixel.arrowleft),
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screenAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Pixel.warningbox,
                  size: 48,
                  color: AppColors.expense,
                ),
                SizedBox(height: AppSpacing.s16),
                Text(
                  'Forgot PIN?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLg,
                ),
                SizedBox(height: AppSpacing.s8),
                PixelCard(
                  padding: AppSpacing.card,
                  child: Text(
                    'This will permanently erase all transactions, categories, '
                    'and salary periods on this device, and reset your PIN. '
                    'If Google Sheets backup is connected, it will be '
                    'disconnected too. This cannot be undone.',
                    style: AppTextStyles.bodyNormal.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.section),
                const PixelFieldLabel('TYPE DELETE TO CONFIRM'),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_submitting,
                  onChanged: (_) => setState(() {}),
                ),
                if (_error != null) ...[
                  SizedBox(height: AppSpacing.s8),
                  Text(
                    _error!,
                    style: AppTextStyles.bodyNormal.copyWith(
                      color: AppColors.expense,
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.section),
                PixelButton(
                  label: 'Erase & Reset PIN',
                  variant: PixelButtonVariant.danger,
                  isFullWidth: true,
                  isLoading: _submitting,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
