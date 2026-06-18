import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pixel_pocket/features/auth/auth_config.dart';

/// Thin wrapper over the `google_sign_in` v7 SDK. No widgets, no Riverpod
/// state — just the auth operations the rest of the app needs.
///
/// In v7 the source of truth for sign-in changes is [authEvents]; the
/// controller listens to it. Token retrieval re-reads the active account so
/// it always returns the freshest available ID token.
class AuthRemoteDataSource {
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _initialized = false;

  /// Stream of sign-in / sign-out events emitted by the SDK.
  Stream<GoogleSignInAuthenticationEvent> get authEvents =>
      _google.authenticationEvents;

  /// Must be called once before any other method.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _google.initialize(
        serverClientId: AuthConfig.serverClientId,
        clientId: AuthConfig.iosClientId,
      );
    } catch (_) {
      // Native SDK bisa SUDAH ter-inisialisasi (umum setelah hot restart,
      // karena singleton native bertahan walau state Dart direset). Aman
      // diabaikan — sesi tetap bisa dipulihkan lewat lightweight auth.
    }
    _initialized = true;
  }

  /// Non-interactive restore of a previous session. Returns the account when
  /// one is available, otherwise null.
  Future<GoogleSignInAccount?> lightweightAuthentication() async {
    final attempt = _google.attemptLightweightAuthentication();
    return attempt == null ? null : await attempt;
  }

  /// Interactive sign-in (shows the Google account picker).
  /// Returns the account, or null when the user cancels the picker.
  Future<GoogleSignInAccount?> signIn() async {
    if (!_google.supportsAuthenticate()) {
      throw UnsupportedError('authenticate() tidak didukung di platform ini');
    }
    try {
      return await _google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow; // kegagalan nyata tetap dilempar
    }
  }

  Future<void> signOut() => _google.signOut();

  /// Fetches a fresh ID token from the active session, or null if signed out.
  Future<String?> currentIdToken() async {
    final account = await lightweightAuthentication();
    return account?.authentication.idToken;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(),
);
