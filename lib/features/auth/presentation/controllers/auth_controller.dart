import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/auth/application/services/auth_service.dart';
import 'package:pixel_pocket/features/auth/data/repositories/auth_session_repository.dart';
import 'package:pixel_pocket/features/auth/domain/models/auth_user.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';
import 'package:pixel_pocket/features/transactions/presentation/controllers/transaction_controller.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Owns the auth lifecycle. The signed-in state is driven by *possession of a
/// backend access token*, not by the Google account stream — Google sign-in is
/// a one-shot used only to obtain the ID token for the backend exchange.
class AuthController extends Notifier<AuthState> {
  /// Guards against a second interactive sign-in while one is already running
  /// (e.g. a double tap), which would open two Google account pickers at once.
  bool _signingIn = false;

  AuthService get _service => ref.read(authServiceProvider);
  AuthSessionRepository get _session => ref.read(authSessionRepositoryProvider);

  @override
  AuthState build() {
    _bootstrap();
    return const AuthUnknown();
  }

  Future<void> _bootstrap() async {
    try {
      await _service.initialize(); // Google SDK ready for a later interactive login
    } catch (_) {
      // SDK may already be initialized after hot restart — ignore.
    }
    try {
      final token = await _session.currentAccessToken();
      if (token != null) {
        final name = await _session.currentUserName();
        state = AuthSignedIn(_restoredUser(name));
      } else if (state is AuthUnknown) {
        state = const AuthSignedOut();
      }
    } catch (_) {
      if (state is AuthUnknown) state = const AuthSignedOut();
    }
  }

  /// Identity for a token-restored session: backend identity isn't re-fetched
  /// here (Fase 1), so we surface the cached display name only.
  AuthUser _restoredUser(String? name) =>
      AuthUser(id: '', email: '', displayName: name, photoUrl: null, idToken: null);

  /// Interactive sign-in: Google picker → ID token → backend exchange. A 403
  /// (or any other [Failure]) from the exchange propagates to the UI so the
  /// LoginScreen can show it; state stays signed-out because [AuthSignedIn] is
  /// only set after a successful exchange.
  Future<void> login() async {
    if (_signingIn) {
      debugPrint('[AUTH] login() ignored — sign-in already in progress');
      return;
    }
    _signingIn = true;
    try {
      final user = await _service.signIn(); // Google picker → AuthUser? with idToken
      if (user == null) return; // user cancelled → stay signed out
      final idToken = user.idToken;
      if (idToken == null) {
        throw const Failure(message: 'Google tidak mengembalikan ID token.');
      }
      await _session.exchangeGoogle(idToken); // throws Failure on 403/400/etc.
      state = AuthSignedIn(user);
    } finally {
      _signingIn = false;
    }
  }

  /// Sign-out: clear backend tokens, best-effort Google sign-out, then mark the
  /// app signed-out and drop the previous user's data. PIN is kept across logout.
  Future<void> logout() async {
    await _session.logout(); // clears backend tokens (best-effort API call)
    try {
      await _service.signOut();
    } catch (_) {
      // Google sign-out is best-effort.
    }
    state = const AuthSignedOut();
    ref.invalidate(transactionsControllerProvider); // drop previous user's data
    // PIN is intentionally kept across logout.
  }
}
