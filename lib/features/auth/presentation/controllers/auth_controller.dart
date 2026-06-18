import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pixel_pocket/features/auth/application/services/auth_service.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Owns the auth lifecycle: bootstraps a silent sign-in on launch, mirrors
/// SDK events into [AuthState], and exposes login/logout.
class AuthController extends Notifier<AuthState> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _sub;

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
      _sub = _service.authEvents.listen(_onEvent);
      final account = await _service.lightweightAuthentication();
      if (account != null) {
        state = AuthSignedIn(account);
      } else if (state is AuthUnknown) {
        state = const AuthSignedOut();
      }
    } catch (_) {
      // SDK belum tersedia / init gagal → tampilkan login, jangan crash.
      if (state is AuthUnknown) state = const AuthSignedOut();
    }
  }

  void _onEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        state = AuthSignedIn(user);
      case GoogleSignInAuthenticationEventSignOut():
        state = const AuthSignedOut();
    }
  }

  Future<void> login() async {
    final account = await _service.signIn();
    // account == null → user batal: biarkan tetap signed-out, bukan error.
    if (account != null) state = AuthSignedIn(account);
  }

  Future<void> logout() async {
    await _service.signOut();
    state = const AuthSignedOut();
    ref.invalidate(transactionsProvider); // drop the previous user's data
  }
}
