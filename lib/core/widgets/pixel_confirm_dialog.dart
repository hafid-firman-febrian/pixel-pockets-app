import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';


Future<bool> showPixelConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'OK',
  String cancelLabel = 'Batal',
  PixelButtonVariant confirmVariant = PixelButtonVariant.primary,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.background.withValues(alpha: 0.72),
    builder: (ctx) => _PixelConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      confirmVariant: confirmVariant,
      icon: icon,
    ),
  );
  return result ?? false;
}

class _PixelConfirmDialog extends StatelessWidget {
  const _PixelConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmVariant,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final PixelButtonVariant confirmVariant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
      child: Container(
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
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.s8),
                  ],
                  Expanded(
                    child: Text(title, style: AppTextStyles.headingSmall),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                message,
                style: AppTextStyles.bodyNormal.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: cancelLabel,
                      variant: PixelButtonVariant.secondary,
                      isFullWidth: true,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: PixelButton(
                      label: confirmLabel,
                      variant: confirmVariant,
                      isFullWidth: true,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
