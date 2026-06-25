import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/auth/application/services/auth_service.dart';
import 'package:pixel_pocket/features/auth/data/repositories/auth_session_repository.dart';
import 'package:pixel_pocket/features/auth/domain/models/auth_user.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';

/// Pumps a few microtasks so the async `_bootstrap()`/`login()` work settles
/// before assertions (the Notifier kicks off `_bootstrap()` from `build()`).
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.signInResult});

  /// What `signIn()` returns (null == user cancelled the picker).
  AuthUser? signInResult;
  bool signOutCalled = false;

  @override
  Future<void> initialize() => Future<void>.value();

  @override
  Future<AuthUser?> signIn() async => signInResult;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Stream<AuthUser?> get authStateChanges => throw UnimplementedError();

  @override
  Future<AuthUser?> lightweightAuthentication() => throw UnimplementedError();
}

class _FakeSession implements AuthSessionRepository {
  _FakeSession({this.accessToken, this.userName, this.exchangeError});

  String? accessToken;
  String? userName;

  /// If set, `exchangeGoogle` throws it (e.g. a 403 Failure).
  Object? exchangeError;

  String? exchangedIdToken;
  bool logoutCalled = false;

  @override
  Future<String?> currentAccessToken() async => accessToken;

  @override
  Future<String?> currentUserName() async => userName;

  @override
  Future<void> exchangeGoogle(String idToken) async {
    exchangedIdToken = idToken;
    if (exchangeError != null) throw exchangeError!;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<String> refresh() => throw UnimplementedError();
}

ProviderContainer _makeContainer(_FakeAuthService service, _FakeSession session) {
  final container = ProviderContainer(
    overrides: [
      authServiceProvider.overrideWithValue(service),
      authSessionRepositoryProvider.overrideWithValue(session),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('bootstrap restores session as AuthSignedIn when an access token exists',
      () async {
    final service = _FakeAuthService();
    final session = _FakeSession(accessToken: 'access', userName: 'Ammar');
    final container = _makeContainer(service, session);

    container.read(authControllerProvider); // triggers build()/_bootstrap()
    await _settle();

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthSignedIn>());
    expect((state as AuthSignedIn).user.displayName, 'Ammar');
  });

  test('bootstrap with no token settles to AuthSignedOut', () async {
    final service = _FakeAuthService();
    final session = _FakeSession(); // no access token
    final container = _makeContainer(service, session);

    container.read(authControllerProvider);
    await _settle();

    expect(container.read(authControllerProvider), isA<AuthSignedOut>());
  });

  test('login exchanges the Google idToken and signs in on success', () async {
    final service = _FakeAuthService(
      signInResult: const AuthUser(
        id: '1',
        email: 'a@b.com',
        displayName: 'Ammar',
        idToken: 'gid',
      ),
    );
    final session = _FakeSession();
    final container = _makeContainer(service, session);

    container.read(authControllerProvider);
    await _settle();

    await container.read(authControllerProvider.notifier).login();

    expect(session.exchangedIdToken, 'gid');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
  });

  test('login rethrows when exchange fails (403) and stays signed out',
      () async {
    final service = _FakeAuthService(
      signInResult: const AuthUser(
        id: '1',
        email: 'a@b.com',
        displayName: 'Ammar',
        idToken: 'gid',
      ),
    );
    final session = _FakeSession(
      exchangeError: const Failure(message: 'email tidak diizinkan', statusCode: 403),
    );
    final container = _makeContainer(service, session);

    container.read(authControllerProvider);
    await _settle();

    await expectLater(
      () => container.read(authControllerProvider.notifier).login(),
      throwsA(isA<Failure>().having((f) => f.statusCode, 'statusCode', 403)),
    );
    expect(container.read(authControllerProvider), isA<AuthSignedOut>());
  });
}
