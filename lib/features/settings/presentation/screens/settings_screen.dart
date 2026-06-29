import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/pin_controller.dart';
import 'package:pixelarticons/pixel.dart';





class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _resetPin(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset PIN?'),
        content: const Text(
          'Your current PIN will be removed. You\'ll be asked to create a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    
    
    await ref.read(pinControllerProvider.notifier).clearPin();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: Padding(
        padding: AppSpacing.screenAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PIN', style: TextStyle(color: AppColors.textMuted)),
            SizedBox(height: AppSpacing.s8),
            PixelButton(
              label: 'Reset PIN',
              icon: Pixel.lock,
              variant: PixelButtonVariant.danger,
              isFullWidth: true,
              onPressed: () => _resetPin(context, ref),
            ),
            SizedBox(height: AppSpacing.s8),
            const Text(
              'Temporary for testing — clears the PIN, then you\'ll be asked to create a new one.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
