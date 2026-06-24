import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/application/services/auth_service.dart';
import 'package:pixel_pocket/features/auth/domain/models/auth_user.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';
import 'package:pixel_pocket/features/transactions/presentation/controllers/transaction_controller.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Owns the auth lifecycle: bootstraps a silent sign-in on launch, mirrors
/// auth-state changes into [AuthState], and exposes login/logout.
class AuthController extends Notifier<AuthState> {
  StreamSubscription<AuthUser?>? _sub;

  AuthService get _service => ref.read(authServiceProvider);

  @override
  AuthState build() {
    ref.onDispose(() => _sub?.cancel());
    _bootstrap();
    return const AuthUnknown();
  }

  Future<void> _bootstrap() async {
    try {
      await _service.initialize();
      _sub = _service.authStateChanges.listen(_onUserChanged);
      final user = await _service.lightweightAuthentication();
      if (user != null) {
        state = AuthSignedIn(user);
      } else if (state is AuthUnknown) {
        state = const AuthSignedOut();
      }
    } catch (_) {
      // SDK belum tersedia / init gagal → tampilkan login, jangan crash.
      if (state is AuthUnknown) state = const AuthSignedOut();
    }
  }

  /// THE single writer of the runtime auth state. Driven by the SDK's
  /// authentication event stream so sign-in/out always reflect the SDK's own
  /// causal order — no imperative write from [login]/[logout] can race a
  /// late-delivered event and bounce the user back to the login screen.
  void _onUserChanged(AuthUser? user) {
    debugPrint('[AUTH] stream event => ${user != null ? "SignedIn(${user.email})" : "SignedOut"}');
    state = user != null ? AuthSignedIn(user) : const AuthSignedOut();
  }

  /// Triggers interactive sign-in. State is NOT set here — the resulting
  /// SignIn event flows through [_onUserChanged]. (Cancel → null → no event,
  /// state stays signed-out.)
  Future<void> login() async {
    debugPrint('[AUTH] login() trigger');
    await _service.signIn();
  }

  /// Triggers sign-out. State is NOT set here — the SignOut event flows through
  /// [_onUserChanged].
  Future<void> logout() async {
    debugPrint('[AUTH] logout() trigger');
    await _service.signOut();
    ref.invalidate(
      transactionsControllerProvider,
    ); // drop the previous user's data
  }
}
