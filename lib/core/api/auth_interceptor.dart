import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/states/auth_state.dart';
import 'api_client.dart';

/// Attaches the Google ID token as a Bearer header on every request, and on a
/// `401` tries once with a freshly fetched token before logging the user out.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;

  static const _retriedKey = 'auth_retried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final auth = _ref.read(authControllerProvider);
    if (auth is AuthSignedIn) {
      final token = auth.account.authentication.idToken;

      if (token != null) {
        // TODO Hapus Jika sudah selesai testing
        print('${auth.account.authentication.idToken}');
        Clipboard.setData(ClipboardData(text: token));
        print('TOKEN length=${token.length} (sudah disalin ke clipboard)');
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    if (is401 && !alreadyRetried) {
      final repo = _ref.read(authRepositoryProvider);
      String? token;
      try {
        token = await repo.currentIdToken();
      } catch (_) {
        token = null;
      }

      if (token != null) {
        final options = err.requestOptions
          ..extra[_retriedKey] = true
          ..headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _ref.read(dioProvider).fetch(options);
          return handler.resolve(response);
        } catch (_) {
          // fall through to logout
        }
      }

      // Could not recover — treat the session as expired.
      await _ref.read(authControllerProvider.notifier).logout();
    }

    handler.next(err);
  }
}
