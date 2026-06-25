import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';

/// Row of square pixel dots showing PIN entry progress: [filled] of [length]
/// are solid. Turns red when [error] is true (e.g. a wrong/mismatched PIN).
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.error = false,
  });

  final int length;
  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final activeColor = error ? AppColors.expense : AppColors.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isFilled ? activeColor : Colors.transparent,
            border: Border.all(
              color: isFilled ? activeColor : AppColors.border,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}
