import 'package:dio/dio.dart';

/// Minimal seam the interceptor needs from the session layer — keeps the
/// interceptor unit-testable without Riverpod.
abstract class SessionGateway {
  Future<String?> currentAccessToken();
  Future<String> refresh();
  Future<void> logout();
}

/// Attaches the backend access token as Bearer. On 401, refreshes once
/// (single-flight lives in the gateway) and retries the original request; if
/// refresh fails, logs out. On 403, passes the error through to the UI.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._gateway, {required this.retry});

  final SessionGateway _gateway;

  /// Re-issues the original request after a refresh. In the app this is
  /// `(o) => dio.fetch(o)`; in tests it is stubbed.
  final Future<Response<dynamic>> Function(RequestOptions options) retry;

  static const _retriedKey = 'auth_retried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _gateway.currentAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    // 403 = email not allowed → surface to UI, never refresh.
    if (status == 401 && !alreadyRetried) {
      try {
        final newToken = await _gateway.refresh();
        final options = err.requestOptions
          ..extra[_retriedKey] = true
          ..headers['Authorization'] = 'Bearer $newToken';
        final response = await retry(options);
        return handler.resolve(response);
      } catch (_) {
        await _gateway.logout();
      }
    }
    handler.next(err);
  }
}
