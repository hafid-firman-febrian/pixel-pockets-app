import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixelarticons/pixel.dart';

class PixelPinPad extends StatelessWidget {
  const PixelPinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;

  final VoidCallback onBackspace;

  final bool enabled;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'back'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s6,
                  ),
                  child: _key(key),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _key(String key) {
    if (key.isEmpty) return const SizedBox(height: 52);
    if (key == 'back') {
      return PixelButton(
        icon: Pixel.delete,
        variant: PixelButtonVariant.danger,
        size: PixelButtonSize.lg,
        isFullWidth: true,
        onPressed: enabled ? onBackspace : null,
      );
    }
    return PixelButton(
      label: key,
      variant: PixelButtonVariant.surface,
      size: PixelButtonSize.lg,
      isFullWidth: true,
      onPressed: enabled ? () => onDigit(key) : null,
    );
  }
}
