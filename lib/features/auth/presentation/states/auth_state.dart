import 'package:google_sign_in/google_sign_in.dart';

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
