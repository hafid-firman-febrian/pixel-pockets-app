import 'package:pixel_pocket/features/auth/domain/models/auth_user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthLocked extends AuthState {
  const AuthLocked(this.user);
  final AuthUser user;
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);
  final AuthUser user;
}
