import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pixel_pocket/features/auth/auth_config.dart';

class AuthRemoteDataSource {
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _initialized = false;

  Stream<GoogleSignInAuthenticationEvent> get authEvents =>
      _google.authenticationEvents;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _google.initialize(
        serverClientId: AuthConfig.serverClientId,
        clientId: AuthConfig.iosClientId,
      );
      debugPrint('[AUTH] initialize() OK');
    } catch (e) {
      debugPrint('[AUTH] initialize() threw (ignored): $e');
    }
    _initialized = true;
  }

  Future<GoogleSignInAccount?> lightweightAuthentication() async {
    final attempt = _google.attemptLightweightAuthentication();
    if (attempt == null) {
      debugPrint(
        '[AUTH] attemptLightweightAuthentication() => null Future '
        '(SDK does not offer silent restore)',
      );
      return null;
    }
    try {
      final account = await attempt;
      debugPrint(
        '[AUTH] lightweight restore => '
        '${account == null ? "null account" : "account ${account.email}, "
                  "idToken=${account.authentication.idToken != null ? "PRESENT" : "null"}"}',
      );
      return account;
    } catch (e) {
      debugPrint('[AUTH] lightweight restore THREW: $e');
      rethrow;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    if (!_google.supportsAuthenticate()) {
      throw UnsupportedError(
        'authenticate() is not supported on this platform',
      );
    }
    try {
      final account = await _google.authenticate();
      debugPrint(
        '[AUTH] authenticate() OK => ${account.email}, '
        'idToken=${account.authentication.idToken != null ? "PRESENT" : "null"}',
      );
      return account;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() => _google.signOut();

  Future<String?> currentIdToken() async {
    final account = await lightweightAuthentication();
    return account?.authentication.idToken;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(),
);
