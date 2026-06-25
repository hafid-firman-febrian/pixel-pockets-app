import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the local PIN credential (hash + salt) in the platform secure
/// store (Keychain on iOS, Keystore on Android). Stores only the hash — never
/// the raw PIN. Pure IO; hashing/verification lives in the service layer.
class PinLocalDataSource {
  PinLocalDataSource([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _hashKey = 'pin_hash';
  static const _saltKey = 'pin_salt';

  Future<bool> hasPin() async => (await _storage.read(key: _hashKey)) != null;

  Future<void> save({required String hash, required String salt}) async {
    await _storage.write(key: _hashKey, value: hash);
    await _storage.write(key: _saltKey, value: salt);
  }

  Future<({String hash, String salt})?> read() async {
    final hash = await _storage.read(key: _hashKey);
    final salt = await _storage.read(key: _saltKey);
    if (hash == null || salt == null) return null;
    return (hash: hash, salt: salt);
  }

  Future<void> clear() async {
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _saltKey);
  }
}

final pinLocalDataSourceProvider = Provider<PinLocalDataSource>(
  (ref) => PinLocalDataSource(),
);
