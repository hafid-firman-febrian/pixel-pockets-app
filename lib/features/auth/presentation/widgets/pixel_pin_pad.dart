import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixelarticons/pixel.dart';

/// On-screen numeric keypad in the retro pixel style. Reuses [PixelButton] for
/// digits and [PixelIconButton] for backspace — no system keyboard.
///
/// Layout is a 3-column grid: 1-9, then an empty slot, 0, and backspace.
class PixelPinPad extends StatelessWidget {
  const PixelPinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  /// Called with the tapped digit ('0'-'9').
  final ValueChanged<String> onDigit;

  /// Called when backspace is tapped.
  final VoidCallback onBackspace;

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
      return Center(
        child: PixelIconButton(
          icon: Pixel.delete,
          variant: PixelButtonVariant.surface,
          size: PixelButtonSize.lg,
          onPressed: onBackspace,
        ),
      );
    }
    return PixelButton(
      label: key,
      variant: PixelButtonVariant.surface,
      size: PixelButtonSize.lg,
      isFullWidth: true,
      onPressed: () => onDigit(key),
    );
  }
}
