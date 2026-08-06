import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/backup/application/auto_backup_coordinator.dart';
import 'package:pixel_pocket/features/backup/application/services/backup_service.dart';
import 'package:pixel_pocket/features/backup/presentation/states/backup_state.dart';
import 'package:pixel_pocket/features/categories/presentation/states/category_state.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';
import 'package:pixel_pocket/features/transactions/presentation/controllers/transaction_controller.dart';

class BackupController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  BackupService get _service => ref.read(backupServiceProvider);

  Future<bool> connect() => _run(() => _service.connect());
  Future<bool> backup() => _run(() => _service.backup());
  Future<bool> disconnect() => _run(() => _service.disconnect());
  Future<bool> keepLocalData() => _run(() => _service.keepLocalData());

  Future<bool> restore() => _run(() async {
    await _service.restore();
    _invalidateData();
  });

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    ref.invalidate(backupStatusProvider);
    ref.read(autoBackupStatusProvider.notifier).sync();
    return !state.hasError;
  }

  void _invalidateData() {
    ref.invalidate(categoriesProvider);
    ref.invalidate(transactionsControllerProvider);
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(expensesByCategoryProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(salaryPeriodProvider);
  }
}

final backupControllerProvider =
    AutoDisposeAsyncNotifierProvider<BackupController, void>(
      BackupController.new,
    );
