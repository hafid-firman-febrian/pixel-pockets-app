import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/application/services/auth_service.dart';
import 'package:pixel_pocket/features/auth/application/services/pin_service.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  AuthState build() {
    _bootstrap();
    return const AuthUnknown();
  }

  Future<void> _bootstrap() async {
    try {
      await _service.initialize();
    } catch (_) {}
    state = await _hasPin() ? const AuthLocked(null) : const AuthSignedIn(null);
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

  void lock() {
    final current = state;
    if (current is AuthSignedIn) state = AuthLocked(current.user);
  }
}
