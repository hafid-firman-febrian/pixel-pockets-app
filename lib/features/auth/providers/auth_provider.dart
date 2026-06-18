import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';
import '../repositories/auth_repository.dart';

/// Authentication state. [AuthUnknown] is the launch state — the router keeps
/// the user on the splash screen until it resolves, avoiding a flicker to the
/// login screen while the silent sign-in is still running.
sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.account);
  final GoogleSignInAccount account;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Owns the auth lifecycle: bootstraps a silent sign-in on launch, mirrors
/// SDK events into [AuthState], and exposes login/logout.
class AuthController extends Notifier<AuthState> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _sub;

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    ref.onDispose(() => _sub?.cancel());
    _bootstrap();
    return const AuthUnknown();
  }

  Future<void> _bootstrap() async {
    try {
      await _repo.initialize();
      _sub = _repo.authEvents.listen(_onEvent);
      final account = await _repo.lightweightAuthentication();
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
    final account = await _repo.signIn();
    // account == null → user batal: biarkan tetap signed-out, bukan error.
    if (account != null) state = AuthSignedIn(account);
  }

  Future<void> logout() async {
    await _repo.signOut();
    state = const AuthSignedOut();
    ref.invalidate(transactionsProvider); // drop the previous user's data
  }
}
