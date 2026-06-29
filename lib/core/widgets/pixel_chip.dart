import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixelarticons/pixel.dart';

/// A pixel-style data chip: optional leading color dot, a label, and an
/// optional trailing × delete button. Tapping the body fires [onTap]; tapping
/// the × fires [onDelete] only.
class PixelChip extends StatelessWidget {
  const PixelChip({
    super.key,
    required this.label,
    this.leadingColor,
    this.onTap,
    this.onDelete,
  });

  final String label;
  final Color? leadingColor;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingColor != null) ...[
                    Container(width: 10, height: 10, color: leadingColor),
                    const SizedBox(width: AppSpacing.s8),
                  ],
                  Text(label, style: AppTextStyles.bodyNormal),
                ],
              ),
            ),
          ),
          if (onDelete != null)
            InkWell(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s6,
                ),
                child: Icon(Pixel.close, size: 14, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
