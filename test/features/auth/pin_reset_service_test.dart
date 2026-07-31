import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/features/auth/application/services/pin_reset_service.dart';
import 'package:pixel_pocket/features/auth/data/repositories/pin_reset_repository.dart';
import 'package:pixel_pocket/features/backup/application/services/backup_service.dart';

class _FakePinResetRepository implements PinResetRepository {
  bool wipeAllCalled = false;
  Object? failWith;

  @override
  Future<void> wipeAll() async {
    wipeAllCalled = true;
    if (failWith != null) throw failWith!;
  }
}

class _FakeBackupService implements BackupService {
  bool disconnectCalled = false;
  Object? failWith;

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
    if (failWith != null) throw failWith!;
  }

  @override
  Future<DateTime> backup() => throw UnimplementedError();

  @override
  Future<String> connect() => throw UnimplementedError();

  @override
  Future<void> restore() => throw UnimplementedError();
}

void main() {
  test('resetForgottenPin wipes data then disconnects backup', () async {
    final repo = _FakePinResetRepository();
    final backup = _FakeBackupService();
    final service = PinResetService(repo, backup);

    await service.resetForgottenPin();

    expect(repo.wipeAllCalled, isTrue);
    expect(backup.disconnectCalled, isTrue);
  });

  test('a failed wipe aborts before touching backup', () async {
    final repo = _FakePinResetRepository()..failWith = Exception('db error');
    final backup = _FakeBackupService();
    final service = PinResetService(repo, backup);

    await expectLater(service.resetForgottenPin(), throwsException);

    expect(backup.disconnectCalled, isFalse);
  });

  test('a failed backup disconnect does not fail the reset', () async {
    final repo = _FakePinResetRepository();
    final backup = _FakeBackupService()..failWith = Exception('network error');
    final service = PinResetService(repo, backup);

    await service.resetForgottenPin(); // must not throw

    expect(repo.wipeAllCalled, isTrue);
    expect(backup.disconnectCalled, isTrue);
  });
}
