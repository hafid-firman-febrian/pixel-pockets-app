import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixelarticons/pixel.dart';

enum RestoreDecision { restore, keepLocal }

String _remoteSubject(int? transactionCount) {
  if (transactionCount == null) return 'a backup';
  if (transactionCount == 1) return '1 transaction';
  return '$transactionCount transactions';
}

String restoreDecisionMessage(int? transactionCount) =>
    'Google Drive holds ${_remoteSubject(transactionCount)} not yet on this '
    'phone.\n\nRestore replaces your local data. Keeping local data '
    'overwrites the backup in Drive.';

String restoreDecisionBannerMessage(int? transactionCount) =>
    'Drive holds ${_remoteSubject(transactionCount)} not yet on this phone. '
    'Auto-backup is on hold so it will not be overwritten.';

Future<RestoreDecision?> showRestoreDecisionDialog(
  BuildContext context, {
  required int? transactionCount,
}) {
  return showDialog<RestoreDecision>(
    context: context,
    barrierColor: AppColors.background.withValues(alpha: 0.72),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: PixelCard(
        elevated: true,
        padding: AppSpacing.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Pixel.clouddownload,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    'Backup found',
                    style: AppTextStyles.headingSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              restoreDecisionMessage(transactionCount),
              style: AppTextStyles.bodyNormal.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: PixelButton(
                    label: 'Keep Local',
                    variant: PixelButtonVariant.secondary,
                    size: PixelButtonSize.sm,
                    isFullWidth: true,
                    onPressed: () =>
                        Navigator.pop(ctx, RestoreDecision.keepLocal),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: PixelButton(
                    label: 'Restore',
                    size: PixelButtonSize.sm,
                    isFullWidth: true,
                    onPressed: () =>
                        Navigator.pop(ctx, RestoreDecision.restore),
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
