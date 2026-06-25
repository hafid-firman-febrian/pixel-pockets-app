import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/auth_interceptor.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/auth/data/datasources/auth_api.dart';
import 'package:pixel_pocket/features/auth/data/datasources/token_local_data_source.dart';

/// Owns the backend session: exchanges the Google ID token for backend tokens,
/// refreshes them (single-flight), and clears them on logout. Token rotation is
/// handled here — every refresh persists the new access+refresh pair.
class AuthSessionRepository implements SessionGateway {
  AuthSessionRepository(this._api, this._store);

  final AuthApi _api;
  final TokenLocalDataSource _store;

  /// In-flight refresh, shared by concurrent callers (single-flight).
  Future<String>? _refreshing;

  Future<void> exchangeGoogle(String idToken) async {
    try {
      final s = await _api.exchangeGoogle(idToken);
      await _store.save(
        accessToken: s.accessToken,
        refreshToken: s.refreshToken,
        userName: s.name,
      );
    } on DioException catch (e) {
      // Timeout / no connection / 4xx-5xx → friendly, UI-safe message.
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
      throw const Failure(message: 'Sesi habis. Silakan login lagi.', statusCode: 401);
    }
    try {
      final s = await _api.refresh(rt);
      await _store.save(accessToken: s.accessToken, refreshToken: s.refreshToken);
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
      } catch (_) {
        // best-effort; clear locally regardless
      }
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
