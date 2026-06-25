import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the backend session tokens (+ cached display name) in the platform
/// secure store. The Google ID token is NOT stored here — it lives only in
/// memory during the initial exchange.
class TokenLocalDataSource {
  TokenLocalDataSource([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userNameKey = 'user_name';

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    String? userName,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    if (userName != null) {
      await _storage.write(key: _userNameKey, value: userName);
    }
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);
  Future<String?> readUserName() => _storage.read(key: _userNameKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userNameKey);
  }
}

final tokenLocalDataSourceProvider = Provider<TokenLocalDataSource>(
  (ref) => TokenLocalDataSource(),
);
