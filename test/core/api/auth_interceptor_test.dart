import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/api/auth_interceptor.dart';

class _FakeGateway implements SessionGateway {
  _FakeGateway(this.access);
  String? access;
  int refreshCalls = 0, logoutCalls = 0;
  bool refreshSucceeds = true;
  @override
  Future<String?> currentAccessToken() async => access;
  @override
  Future<String> refresh() async {
    refreshCalls++;
    if (!refreshSucceeds) throw DioException(requestOptions: RequestOptions(path: '/x'));
    access = 'fresh';
    return 'fresh';
  }
  @override
  Future<void> logout() async => logoutCalls++;
}

/// A no-op error handler that swallows next/resolve/reject calls so tests can
/// call [AuthInterceptor.onError] outside a real Dio interceptor chain without
/// [ErrorInterceptorHandler] throwing an unhandled-state error.
class _SinkErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {}
  @override
  void resolve(Response response) {}
  @override
  void reject(DioException err, [bool callFollowingErrorInterceptor = false]) {}
}

/// A no-op request handler for the same reason.
class _SinkRequestHandler extends RequestInterceptorHandler {
  @override
  void next(RequestOptions options) {}
  @override
  void resolve(Response response, [bool callFollowingResponseInterceptor = false]) {}
  @override
  void reject(DioException err, [bool callFollowingErrorInterceptor = false]) {}
}

DioException _err(int code) => DioException(
      requestOptions: RequestOptions(path: '/api/summary'),
      response: Response(requestOptions: RequestOptions(path: '/api/summary'), statusCode: code),
    );

void main() {
  test('attaches Bearer access token on request', () async {
    final i = AuthInterceptor(_FakeGateway('tok'), retry: (o) async => Response(requestOptions: o, statusCode: 200));
    final opts = RequestOptions(path: '/api/summary');
    // onRequest returns void (Dio override), so we pump microtasks instead of
    // awaiting it directly — this lets the async body's awaited token read
    // resolve before we assert the header.
    i.onRequest(opts, _SinkRequestHandler());
    await Future<void>.delayed(Duration.zero);
    expect(opts.headers['Authorization'], 'Bearer tok');
  });

  test('403 does NOT refresh', () async {
    final gw = _FakeGateway('tok');
    final i = AuthInterceptor(gw, retry: (o) async => Response(requestOptions: o, statusCode: 200));
    i.onError(_err(403), _SinkErrorHandler());
    await Future<void>.delayed(Duration.zero);
    expect(gw.refreshCalls, 0);
  });

  test('401 → refresh once → retry; refresh failure → logout', () async {
    final gw = _FakeGateway('tok')..refreshSucceeds = false;
    final i = AuthInterceptor(gw, retry: (o) async => Response(requestOptions: o, statusCode: 200));
    i.onError(_err(401), _SinkErrorHandler());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(gw.refreshCalls, 1);
    expect(gw.logoutCalls, 1);
  });

  test('401 → refresh succeeds → retry called with new Bearer → resolved', () async {
    final gw = _FakeGateway('tok');
    Response<dynamic>? capturedRetryResponse;
    final i = AuthInterceptor(
      gw,
      retry: (o) async {
        expect(o.headers['Authorization'], 'Bearer fresh');
        expect(o.extra['auth_retried'], true);
        return capturedRetryResponse =
            Response(requestOptions: o, statusCode: 200);
      },
    );
    i.onError(_err(401), _SinkErrorHandler());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(gw.refreshCalls, 1);
    expect(gw.logoutCalls, 0);
    expect(capturedRetryResponse, isNotNull);
  });

  test('401 → refresh succeeds but retry fails → error passes through, no logout', () async {
    final gw = _FakeGateway('tok'); // refresh succeeds by default
    final i = AuthInterceptor(
      gw,
      retry: (o) async => throw DioException(requestOptions: o), // retried request fails
    );
    i.onError(_err(401), _SinkErrorHandler());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(gw.refreshCalls, 1);
    expect(gw.logoutCalls, 0); // a failed RETRY must not log the user out
  });
}
