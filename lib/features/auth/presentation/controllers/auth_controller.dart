import 'dart:async';

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

  void _onUserChanged(AuthUser? user) {
    state = user != null ? AuthSignedIn(user) : const AuthSignedOut();
  }

  Future<void> login() async {
    final user = await _service.signIn();
    // user == null → user batal: biarkan tetap signed-out, bukan error.
    if (user != null) state = AuthSignedIn(user);
  }

  Future<void> logout() async {
    await _service.signOut();
    state = const AuthSignedOut();
    ref.invalidate(
      transactionsControllerProvider,
    ); // drop the previous user's data
  }
}
