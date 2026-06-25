import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/features/auth/application/services/pin_service.dart';
import 'package:pixel_pocket/features/auth/data/repositories/pin_repository.dart';

/// In-memory stand-in for [PinRepository] so the service logic is tested
/// without touching platform secure storage.
class _FakePinRepository implements PinRepository {
  ({String hash, String salt})? stored;

  @override
  Future<bool> hasPin() async => stored != null;

  @override
  Future<void> save({required String hash, required String salt}) async =>
      stored = (hash: hash, salt: salt);

  @override
  Future<({String hash, String salt})?> read() async => stored;

  @override
  Future<void> clear() async => stored = null;
}

void main() {
  late _FakePinRepository repo;
  late PinService service;

  setUp(() {
    repo = _FakePinRepository();
    service = PinService(repo);
  });

  test('verifyPin returns true for the PIN that was set', () async {
    await service.setPin('1234');
    expect(await service.verifyPin('1234'), isTrue);
  });

  test('verifyPin returns false for a wrong PIN', () async {
    await service.setPin('1234');
    expect(await service.verifyPin('0000'), isFalse);
  });

  test('verifyPin returns false when no PIN has been set', () async {
    expect(await service.verifyPin('1234'), isFalse);
  });

  test('the PIN is never stored in plaintext', () async {
    await service.setPin('1234');
    expect(repo.stored!.hash, isNot(contains('1234')));
  });

  test('each setPin uses a fresh salt, so hashes differ for the same PIN',
      () async {
    await service.setPin('1234');
    final first = repo.stored!;
    await service.setPin('1234');
    final second = repo.stored!;
    expect(second.salt, isNot(first.salt));
    expect(second.hash, isNot(first.hash));
  });

  test('hasPin reflects whether a PIN was set', () async {
    expect(await service.hasPin(), isFalse);
    await service.setPin('1234');
    expect(await service.hasPin(), isTrue);
  });

  test('clearPin removes the stored PIN', () async {
    await service.setPin('1234');
    await service.clearPin();
    expect(await service.hasPin(), isFalse);
    expect(await service.verifyPin('1234'), isFalse);
  });
}
