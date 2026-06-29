import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/auth_session_repository.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  final gateway = ref.watch(authSessionRepositoryProvider);
  client.dio.interceptors.insert(
    0,
    AuthInterceptor(gateway, retry: (options) => client.dio.fetch(options)),
  );
  return client;
});

final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);

class ApiClient {
  ApiClient() : dio = Dio(_baseOptions()) {
    // Body logging is intentionally OFF: printing full request/response bodies
    // through debugPrint (rate-limited) noticeably stalls larger responses like
    // the by-category list in debug builds. Errors are still logged.
    dio.interceptors.add(
      LogInterceptor(
        request: false,
        requestBody: false,
        responseBody: false,
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

  static const bool _useLocalDevServer = false;

  static String _resolveBaseUrl() {
    if (kReleaseMode || !_useLocalDevServer) return ApiEndpoints.prodBaseUrl;

    // Local dev server: pick the right host. Web has no Platform → localhost.
    if (kIsWeb) return ApiEndpoints.iosDevBaseUrl;
    if (Platform.isAndroid) return ApiEndpoints.androidDevBaseUrl;
    return ApiEndpoints.iosDevBaseUrl;
  }
}
