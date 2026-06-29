import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/auth/application/services/auth_service.dart';
import 'package:pixel_pocket/features/auth/application/services/pin_service.dart';
import 'package:pixel_pocket/features/auth/data/repositories/auth_session_repository.dart';
import 'package:pixel_pocket/features/auth/domain/models/auth_user.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';
import 'package:pixel_pocket/features/transactions/presentation/controllers/transaction_controller.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
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
      await _service.initialize();
    } catch (_) {}
    try {
      final token = await _session.currentAccessToken();
      if (token != null) {
        final name = await _session.currentUserName();
        final user = _restoredUser(name);

        state = await _hasPin() ? AuthLocked(user) : AuthSignedIn(user);
      } else if (state is AuthUnknown) {
        state = const AuthSignedOut();
      }
    } catch (_) {
      if (state is AuthUnknown) state = const AuthSignedOut();
    }
  }

  Future<bool> _hasPin() async {
    try {
      return await ref.read(pinServiceProvider).hasPin();
    } catch (_) {
      return false;
    }
  }

  void unlock() {
    final current = state;
    if (current is AuthLocked) state = AuthSignedIn(current.user);
  }

  AuthUser _restoredUser(String? name) => AuthUser(
    id: '',
    email: '',
    displayName: name,
    photoUrl: null,
    idToken: null,
  );

  Future<void> login() async {
    if (_signingIn) {
      debugPrint('[AUTH] login() ignored — sign-in already in progress');
      return;
    }
    _signingIn = true;
    try {
      final user = await _service.signIn();
      if (user == null) return;
      final idToken = user.idToken;
      if (idToken == null) {
        throw const Failure(message: 'Google did not return an ID token.');
      }
      await _session.exchangeGoogle(idToken);
      state = AuthSignedIn(_restoredUser(user.displayName));
    } finally {
      _signingIn = false;
    }
  }

  Future<void> logout() async {
    try {
      await _session.logout();
    } finally {
      try {
        await _service.signOut();
      } catch (_) {}
      state = const AuthSignedOut();
      ref.invalidate(transactionsControllerProvider);
    }
  }
}
