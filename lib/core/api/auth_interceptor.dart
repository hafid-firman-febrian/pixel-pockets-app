import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/states/auth_state.dart';

/// Attaches the Google ID token as a Bearer header on every request.
///
/// 401 handling is intentionally a pass-through for now. A 401 currently means
/// the backend has not yet accepted the Google ID token (backend token-exchange
/// work pending) — NOT that the session expired. Auto-logout belongs to the
/// "30-day session expired" case (backend refresh token exhausted), which only
/// exists once the backend issues its own tokens.
///
/// The previous 401 handler re-fetched a token via `lightweightAuthentication()`
/// and logged out; that popped a Google sign-in sheet on every failed request,
/// which — colliding with the login picker — produced a sign-in loop.
///
/// TODO(session): once backend refresh tokens land, log out here when a refresh
/// genuinely fails (the real "session expired" signal).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final auth = _ref.read(authControllerProvider);
    if (auth is AuthSignedIn) {
      final token = auth.user.idToken;

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
