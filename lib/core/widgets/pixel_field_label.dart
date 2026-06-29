import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';

/// Small uppercase label shown above a form field (AMOUNT, DATE, …).
class PixelFieldLabel extends StatelessWidget {
  const PixelFieldLabel(this.text, {super.key});

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
