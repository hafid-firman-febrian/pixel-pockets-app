import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixelarticons/pixel.dart';

enum RestoreDecision { restore, keepLocal }

String restoreDecisionMessage(int? transactionCount) {
  final subject = transactionCount == null
      ? 'Google Drive berisi backup'
      : 'Google Drive berisi $transactionCount transaksi';
  return '$subject yang belum ada di HP ini.\n\n'
      'Restore akan mengganti data lokal. Pakai data lokal akan menimpa '
      'backup di Drive.';
}

String restoreDecisionBannerMessage(int? transactionCount) {
  final subject = transactionCount == null
      ? 'Backup di Drive'
      : '$transactionCount transaksi di Drive';
  return '$subject belum ada di HP ini. Auto-backup ditahan agar tidak '
      'menimpanya.';
}

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
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
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
                    'Backup ditemukan',
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
              children: [
                Expanded(
                  child: PixelButton(
                    label: 'Pakai data lokal',
                    variant: PixelButtonVariant.secondary,
                    isFullWidth: true,
                    onPressed: () =>
                        Navigator.pop(ctx, RestoreDecision.keepLocal),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: PixelButton(
                    label: 'Restore',
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
