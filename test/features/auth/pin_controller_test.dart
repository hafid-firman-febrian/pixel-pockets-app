import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/application/services/pin_reset_service.dart';
import 'package:pixel_pocket/features/auth/application/services/pin_service.dart';
import 'package:pixel_pocket/features/auth/data/datasources/pin_local_data_source.dart';
import 'package:pixel_pocket/features/auth/data/repositories/pin_repository.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/pin_controller.dart';
import 'package:pixel_pocket/features/categories/presentation/states/category_state.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';
import 'package:pixel_pocket/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Fake PinService whose `hasPin()` is fixed to true, so the controller
/// bootstraps into "has a PIN" without touching secure storage.
class _FakePinService extends PinService {
  _FakePinService() : super(PinRepository(PinLocalDataSource()));

  @override
  Future<bool> hasPin() async => true;
}

class _FakePinResetService implements PinResetService {
  bool called = false;
  Object? failWith;

  @override
  Future<void> resetForgottenPin() async {
    called = true;
    if (failWith != null) throw failWith!;
  }
}

// Fake notifier for testing that returns empty list without database access
class _FakeTransactionsController extends TransactionsController {
  @override
  Future<List<TransactionModel>> build() async => [];
}

ProviderContainer _makeContainer(_FakePinResetService resetService) {
  final container = ProviderContainer(
    overrides: [
      pinServiceProvider.overrideWithValue(_FakePinService()),
      pinResetServiceProvider.overrideWithValue(resetService),
      // Override providers that depend on database to prevent binding issues during invalidation
      categoriesProvider.overrideWith((ref) => Future.value([])),
      transactionsControllerProvider.overrideWith(_FakeTransactionsController.new),
      dashboardSummaryProvider.overrideWith(
        (ref) => Future.value(
          const TransactionSummary(
            totalIncome: 0,
            totalExpense: 0,
            balance: 0,
            transactionCount: 0,
          ),
        ),
      ),
      expensesByCategoryProvider.overrideWith((ref) => Future.value([])),
      recentTransactionsProvider.overrideWith((ref) => Future.value([])),
      salaryPeriodProvider.overrideWith((ref) => Future.value([])),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('resetForgottenPin clears the pin flag on success', () async {
    final resetService = _FakePinResetService();
    final container = _makeContainer(resetService);

    container.read(pinControllerProvider);
    await _settle();
    expect(container.read(pinControllerProvider), isTrue);

    await container.read(pinControllerProvider.notifier).resetForgottenPin();

    expect(resetService.called, isTrue);
    expect(container.read(pinControllerProvider), isFalse);
  });

  test('a failed reset leaves the pin flag untouched', () async {
    final resetService = _FakePinResetService()
      ..failWith = Exception('wipe failed');
    final container = _makeContainer(resetService);

    container.read(pinControllerProvider);
    await _settle();
    expect(container.read(pinControllerProvider), isTrue);

    await expectLater(
      container.read(pinControllerProvider.notifier).resetForgottenPin(),
      throwsException,
    );

    expect(container.read(pinControllerProvider), isTrue);
  });
}
