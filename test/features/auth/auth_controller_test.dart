import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/application/services/auth_service.dart';
import 'package:pixel_pocket/features/auth/application/services/pin_service.dart';
import 'package:pixel_pocket/features/auth/data/datasources/pin_local_data_source.dart';
import 'package:pixel_pocket/features/auth/data/repositories/pin_repository.dart';
import 'package:pixel_pocket/features/auth/domain/models/auth_user.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';

/// Pumps a few microtasks so the async `_bootstrap()` work settles before
/// assertions (the Notifier kicks off `_bootstrap()` from `build()`).
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _FakeAuthService implements AuthService {
  bool signOutCalled = false;

  @override
  Future<void> initialize() => Future<void>.value();

  @override
  Future<AuthUser?> signIn() async => null;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Stream<AuthUser?> get authStateChanges => throw UnimplementedError();

  @override
  Future<AuthUser?> lightweightAuthentication() => throw UnimplementedError();
}

/// Fake PinService whose `hasPin()` is fixed. The super repo is never touched
/// because `hasPin` is overridden, so the dummy data source is never called.
class _FakePinService extends PinService {
  _FakePinService(this._hasPin) : super(PinRepository(PinLocalDataSource()));

  final bool _hasPin;

  @override
  Future<bool> hasPin() async => _hasPin;
}

ProviderContainer _makeContainer(
  _FakeAuthService service, {
  bool hasPin = false,
}) {
  final container = ProviderContainer(
    overrides: [
      authServiceProvider.overrideWithValue(service),
      pinServiceProvider.overrideWithValue(_FakePinService(hasPin)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('bootstrap with no pin settles to AuthSignedIn(null)', () async {
    final container = _makeContainer(_FakeAuthService());

    container.read(authControllerProvider); // triggers build()/_bootstrap()
    await _settle();

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthSignedIn>());
    expect((state as AuthSignedIn).user, isNull);
  });

  test('bootstrap locks behind PIN when a PIN exists', () async {
    final container = _makeContainer(_FakeAuthService(), hasPin: true);

    container.read(authControllerProvider);
    await _settle();

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthLocked>());
    expect((state as AuthLocked).user, isNull);
  });

  test('unlock promotes a locked session to signed-in', () async {
    final container = _makeContainer(_FakeAuthService(), hasPin: true);

    container.read(authControllerProvider);
    await _settle();
    expect(container.read(authControllerProvider), isA<AuthLocked>());

    container.read(authControllerProvider.notifier).unlock();

    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
  });
}
