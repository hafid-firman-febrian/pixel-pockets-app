import 'package:pixel_pocket/features/auth/domain/models/auth_user.dart';

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

/// Session is valid but the app is locked behind the local PIN. The router
/// holds the user on the unlock screen until the PIN is entered.
///
/// NOTE: not emitted yet — the trigger (silent session restore on launch)
/// lands with the session/refresh-token work. The state + routing are in place
/// so that wiring is a one-line change later.
class AuthLocked extends AuthState {
  const AuthLocked(this.user);
  final AuthUser user;
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);
  final AuthUser user;
}
