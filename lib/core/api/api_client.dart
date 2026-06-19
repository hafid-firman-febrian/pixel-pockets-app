import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_endpoints.dart';
import 'auth_interceptor.dart';

/// App-wide [ApiClient] singleton, with the auth interceptor installed first
/// so the Bearer header is attached before logging.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  client.dio.interceptors.insert(0, AuthInterceptor(ref));
  return client;
});

/// Convenience provider exposing the configured [Dio] instance.
/// Repositories depend on this rather than constructing their own Dio.
final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);

/// Owns the single configured [Dio] instance for the whole app.
///
/// Base URL resolution:
/// - Release builds always point at production.
/// - Debug/profile builds also point at production for now, because there is
///   no local dev server yet. Flip [_useLocalDevServer] to `true` once one is
///   running to route debug builds to the per-platform local hosts.
class ApiClient {
  ApiClient() : dio = Dio(_baseOptions()) {
    dio.interceptors.add(
      LogInterceptor(
        request: false,
        requestBody: kDebugMode,
        responseBody: kDebugMode,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  final Dio dio;

  static BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: _resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
  }

  /// Set to `true` to route debug/profile builds at the local dev server.
  /// Left `false` while the API only lives on Vercel (no local server yet).
  static const bool _useLocalDevServer = false;

  static String _resolveBaseUrl() {
    if (kReleaseMode || !_useLocalDevServer) return ApiEndpoints.prodBaseUrl;

    // Local dev server: pick the right host. Web has no Platform → localhost.
    if (kIsWeb) return ApiEndpoints.iosDevBaseUrl;
    if (Platform.isAndroid) return ApiEndpoints.androidDevBaseUrl;
    return ApiEndpoints.iosDevBaseUrl;
  }
}
