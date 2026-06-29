import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/auth_interceptor.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/auth/data/datasources/auth_api.dart';
import 'package:pixel_pocket/features/auth/data/datasources/token_local_data_source.dart';

class AuthSessionRepository implements SessionGateway {
  AuthSessionRepository(this._api, this._store);

  final AuthApi _api;
  final TokenLocalDataSource _store;

  Future<String>? _refreshing;

  Future<void> exchangeGoogle(String idToken) async {
    try {
      final s = await _api.exchangeGoogle(idToken);
      debugPrint('[AUTH] accessToken dari API: ${s.accessToken}');
      await _store.save(
        accessToken: s.accessToken,
        refreshToken: s.refreshToken,
        userName: s.name,
      );
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  @override
  Future<String?> currentAccessToken() => _store.readAccessToken();

  Future<String?> currentUserName() => _store.readUserName();

  @override
  Future<String> refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String> _doRefresh() async {
    final rt = await _store.readRefreshToken();
    if (rt == null) {
      throw const Failure(
        message: 'Session expired. Please sign in again.',
        statusCode: 401,
      );
    }
    try {
      final s = await _api.refresh(rt);
      await _store.save(
        accessToken: s.accessToken,
        refreshToken: s.refreshToken,
      );
      return s.accessToken;
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  @override
  Future<void> logout() async {
    final rt = await _store.readRefreshToken();
    if (rt != null) {
      try {
        await _api.logout(rt);
      } catch (_) {}
    }
    await _store.clear();
  }
}

final authSessionRepositoryProvider = Provider<AuthSessionRepository>(
  (ref) => AuthSessionRepository(
    ref.watch(authApiProvider),
    ref.watch(tokenLocalDataSourceProvider),
  ),
);
