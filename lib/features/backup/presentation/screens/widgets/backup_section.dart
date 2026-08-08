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
import 'package:pixel_pocket/core/widgets/pixel_snack_bar.dart';
import 'package:pixel_pocket/features/backup/application/auto_backup_coordinator.dart';
import 'package:pixel_pocket/features/backup/presentation/controllers/backup_controller.dart';
import 'package:pixel_pocket/features/backup/presentation/screens/widgets/restore_decision_dialog.dart';
import 'package:pixel_pocket/features/backup/presentation/states/backup_state.dart';
import 'package:pixelarticons/pixel.dart';

class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backupStatusProvider);
    final autoBackupStatus = ref.watch(autoBackupStatusProvider);
    final isLoading = ref.watch(backupControllerProvider).isLoading;
    final running = ref.watch(backupRunningActionProvider);
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
                onChanged: (value) =>
                    ref.read(autoBackupCoordinatorProvider).setEnabled(value),
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                inactiveThumbColor: AppColors.textMuted,
                inactiveTrackColor: AppColors.surfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          if (status.needsRestoreDecision)
            _RestoreDecisionBanner(
              transactionCount: status.remoteTransactionCount,
              busy: busy,
              restoring: running == BackupAction.restore,
              keepingLocal: running == BackupAction.keepLocal,
              onRestore: () => _runRestore(context, ref),
              onKeepLocal: () => _keepLocal(context, ref),
            )
          else
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
            isLoading:
                running == BackupAction.backup || autoBackupStatus.running,
            onPressed: busy ? null : () => _backup(context, ref),
          ),
          const SizedBox(height: AppSpacing.s8),
          PixelButton(
            label: 'Restore',
            icon: Pixel.clouddownload,
            variant: PixelButtonVariant.secondary,
            isFullWidth: true,
            isLoading: running == BackupAction.restore,
            onPressed: busy ? null : () => _restore(context, ref),
          ),
          const SizedBox(height: AppSpacing.s8),
          PixelButton(
            label: 'Disconnect',
            icon: Pixel.unlink,
            variant: PixelButtonVariant.danger,
            isFullWidth: true,
            isLoading: running == BackupAction.disconnect,
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
    if (!ok || !context.mounted) return;
    if (!ref.read(backupStatusProvider).needsRestoreDecision) return;
    await _askRestoreDecision(context, ref);
  }

  Future<void> _askRestoreDecision(BuildContext context, WidgetRef ref) async {
    final decision = await showRestoreDecisionDialog(
      context,
      transactionCount: ref.read(backupStatusProvider).remoteTransactionCount,
    );
    if (decision == null || !context.mounted) return;
    switch (decision) {
      case RestoreDecision.restore:
        await _runRestore(context, ref);
      case RestoreDecision.keepLocal:
        await _keepLocal(context, ref);
    }
  }

  Future<void> _keepLocal(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(backupControllerProvider.notifier)
        .keepLocalData();
    _notify(
      messenger,
      ok,
      ref,
      success: 'Using local data — the cloud backup will be overwritten',
    );
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(backupControllerProvider.notifier).backup();
    _notify(messenger, ok, ref, success: 'Backup complete');
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showPixelConfirm(
      context,
      title: 'Restore data?',
      message:
          'Your local data will be replaced with the data from Google Sheets. '
          'This cannot be undone.',
      confirmLabel: 'Restore',
      confirmVariant: PixelButtonVariant.danger,
      icon: Pixel.clouddownload,
    );
    if (!confirmed || !context.mounted) return;
    await _runRestore(context, ref);
  }

  Future<void> _runRestore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
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
      messenger.showPixelSnackBar(success);
      return;
    }
    final error = ref.read(backupControllerProvider).error;
    messenger.showPixelSnackBar(asFailure(error).toString(), isError: true);
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
        'Backing up…',
        style: AppTextStyles.bodyNormal.copyWith(color: AppColors.textMuted),
      );
    }

    if (autoBackupStatus.pending) {
      return Text(
        '⚠ Changes not backed up yet',
        style: AppTextStyles.bodyNormal.copyWith(color: AppColors.secondary),
      );
    }

    return Text(
      'Synced — last backup: ${_lastBackupLabel(lastBackupAt)}',
      style: AppTextStyles.bodyNormal.copyWith(color: AppColors.textMuted),
    );
  }

  String _lastBackupLabel(DateTime? value) {
    if (value == null) return 'Never';
    return DateFormat('d MMM yyyy, HH:mm').format(value);
  }
}

class _RestoreDecisionBanner extends StatelessWidget {
  const _RestoreDecisionBanner({
    required this.transactionCount,
    required this.busy,
    required this.restoring,
    required this.keepingLocal,
    required this.onRestore,
    required this.onKeepLocal,
  });

  final int? transactionCount;
  final bool busy;
  final bool restoring;
  final bool keepingLocal;
  final VoidCallback onRestore;
  final VoidCallback onKeepLocal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardSm,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠ Cloud backup not restored',
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            restoreDecisionBannerMessage(transactionCount),
            style: AppTextStyles.bodyNormal.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: PixelButton(
                  label: 'Keep Local',
                  variant: PixelButtonVariant.secondary,
                  size: PixelButtonSize.sm,
                  isFullWidth: true,

                  isLoading: keepingLocal,
                  onPressed: busy ? null : onKeepLocal,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: PixelButton(
                  label: 'Restore',
                  size: PixelButtonSize.sm,
                  isFullWidth: true,
                  isLoading: restoring,
                  onPressed: busy ? null : onRestore,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
