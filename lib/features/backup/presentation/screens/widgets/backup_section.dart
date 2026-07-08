import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/core/widgets/pixel_confirm_dialog.dart';
import 'package:pixel_pocket/features/backup/application/auto_backup_coordinator.dart';
import 'package:pixel_pocket/features/backup/presentation/controllers/backup_controller.dart';
import 'package:pixel_pocket/features/backup/presentation/states/backup_state.dart';
import 'package:pixelarticons/pixel.dart';

class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backupStatusProvider);
    final autoBackupStatus = ref.watch(autoBackupStatusProvider);
    final isLoading = ref.watch(backupControllerProvider).isLoading;
    final busy = isLoading || autoBackupStatus.running;

    if (!status.connected) {
      return PixelCard(
        onTap: isLoading ? null : () => _connect(context, ref),
        padding: AppSpacing.card,
        child: Row(
          children: [
            const Icon(Pixel.cloud, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                'Connect Google Sheets',
                style: AppTextStyles.bodyNormal,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                Pixel.chevronright,
                size: 18,
                color: AppColors.textMuted,
              ),
          ],
        ),
      );
    }

    return PixelCard(
      padding: AppSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Pixel.clouddone, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  status.email ?? 'Connected',
                  style: AppTextStyles.bodyBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: Text('Auto-backup', style: AppTextStyles.bodyNormal),
              ),
              Switch(
                value: autoBackupStatus.enabled,
                onChanged: (value) => ref
                    .read(autoBackupCoordinatorProvider)
                    .setEnabled(value),
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                inactiveThumbColor: AppColors.textMuted,
                inactiveTrackColor: AppColors.surfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          _AutoBackupStatusRow(
            autoBackupStatus: autoBackupStatus,
            lastBackupAt: status.lastBackupAt,
            isBackingUp: busy,
          ),
          const SizedBox(height: AppSpacing.section),
          PixelButton(
            label: 'Backup Now',
            icon: Pixel.cloudupload,
            isFullWidth: true,
            isLoading: busy,
            onPressed: busy ? null : () => _backup(context, ref),
          ),
          const SizedBox(height: AppSpacing.s8),
          PixelButton(
            label: 'Restore',
            icon: Pixel.clouddownload,
            variant: PixelButtonVariant.secondary,
            isFullWidth: true,
            onPressed: busy ? null : () => _restore(context, ref),
          ),
          const SizedBox(height: AppSpacing.s8),
          PixelButton(
            label: 'Disconnect',
            icon: Pixel.unlink,
            variant: PixelButtonVariant.danger,
            isFullWidth: true,
            onPressed: busy ? null : () => _disconnect(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(backupControllerProvider.notifier).connect();
    _notify(messenger, ok, ref, success: 'Connected to Google Sheets');
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(backupControllerProvider.notifier).backup();
    _notify(messenger, ok, ref, success: 'Backup complete');
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showPixelConfirm(
      context,
      title: 'Restore data?',
      message:
          'Data lokal akan diganti dengan data dari Google Sheets. '
          'Tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'Restore',
      confirmVariant: PixelButtonVariant.danger,
      icon: Pixel.clouddownload,
    );
    if (!confirmed) return;
    final ok = await ref.read(backupControllerProvider.notifier).restore();
    _notify(messenger, ok, ref, success: 'Data restored');
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(backupControllerProvider.notifier).disconnect();
    _notify(messenger, ok, ref, success: 'Disconnected');
  }

  void _notify(
    ScaffoldMessengerState messenger,
    bool ok,
    WidgetRef ref, {
    required String success,
  }) {
    if (ok) {
      messenger.showSnackBar(SnackBar(content: Text(success)));
      return;
    }
    final error = ref.read(backupControllerProvider).error;
    messenger.showSnackBar(
      SnackBar(
        content: Text(asFailure(error).toString()),
        backgroundColor: AppColors.expense,
      ),
    );
  }
}

class _AutoBackupStatusRow extends StatelessWidget {
  const _AutoBackupStatusRow({
    required this.autoBackupStatus,
    required this.lastBackupAt,
    required this.isBackingUp,
  });

  final AutoBackupStatus autoBackupStatus;
  final DateTime? lastBackupAt;
  final bool isBackingUp;

  @override
  Widget build(BuildContext context) {
    if (isBackingUp) {
      return Text(
        'Sedang backup…',
        style: AppTextStyles.bodyNormal.copyWith(color: AppColors.textMuted),
      );
    }

    if (autoBackupStatus.pending) {
      return Text(
        '⚠ Perubahan belum ter-backup',
        style: AppTextStyles.bodyNormal.copyWith(color: AppColors.secondary),
      );
    }

    return Text(
      'Tersinkron — backup terakhir: ${_lastBackupLabel(lastBackupAt)}',
      style: AppTextStyles.bodyNormal.copyWith(color: AppColors.textMuted),
    );
  }

  String _lastBackupLabel(DateTime? value) {
    if (value == null) return 'Belum pernah';
    return DateFormat('d MMM yyyy, HH:mm').format(value);
  }
}
