import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixelarticons/pixel.dart';

class PixelErrorView extends StatelessWidget {
  const PixelErrorView({
    required this.failure,
    required this.onRetry,
    this.compact = false,
    this.fill = false,
    super.key,
  });

  final Failure failure;
  final VoidCallback onRetry;
  final bool compact;
  final bool fill;

  IconData get _icon {
    switch (failure.type) {
      case FailureType.noConnection:
        return Pixel.downasaur;
      case FailureType.timeout:
        return Pixel.hourglass;
      case FailureType.server:
        return Pixel.server;
      case FailureType.notFound:
      case FailureType.unauthorized:
      case FailureType.cancelled:
      case FailureType.unknown:
        return Pixel.cellularsignaloff;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),

        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 28, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.s12),
              Text(failure.message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s12),
              PixelButton(
                onPressed: onRetry,
                icon: Pixel.reload,
                label: 'Try Again',
                variant: PixelButtonVariant.ghost,
                size: PixelButtonSize.sm,
              ),
            ],
          ),
        ),
      );
    }

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.s12),
            Text(failure.message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.section),
            PixelButton(
              onPressed: onRetry,
              icon: Pixel.reload,
              label: 'Try Again',
            ),
          ],
        ),
      ),
    );

    if (!fill) return content;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: content,
        ),
      ),
    );
  }
}
