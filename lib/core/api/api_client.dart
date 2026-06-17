import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_endpoints.dart';

/// App-wide [ApiClient] singleton.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Convenience provider exposing the configured [Dio] instance.
/// Repositories depend on this rather than constructing their own Dio.
final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);

/// Owns the single configured [Dio] instance for the whole app.
///
/// Base URL resolution:
/// - In release builds it always points at production.
/// - In debug builds it points at the local dev server, choosing the
///   right host for the Android emulator vs. the iOS simulator.
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

  static String _resolveBaseUrl() {
    if (kReleaseMode) return ApiEndpoints.prodBaseUrl;

    // Debug / profile: talk to the local dev server.
    // Web has no Platform; fall back to localhost there.
    if (kIsWeb) return ApiEndpoints.iosDevBaseUrl;
    if (Platform.isAndroid) return ApiEndpoints.androidDevBaseUrl;
    return ApiEndpoints.iosDevBaseUrl;
  }
}
