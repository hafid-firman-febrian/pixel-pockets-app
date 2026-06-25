import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/data/repositories/pin_repository.dart';

/// Business logic for the local PIN lock: sets, verifies, and clears the PIN.
/// The raw PIN is hashed with a per-PIN random salt (SHA-256) and never
/// persisted in plaintext.
class PinService {
  PinService(this._repo);

  final PinRepository _repo;

  Future<bool> hasPin() => _repo.hasPin();

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    await _repo.save(hash: _hash(pin, salt), salt: salt);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _repo.read();
    if (stored == null) return false;
    return _hash(pin, stored.salt) == stored.hash;
  }

  Future<void> clearPin() => _repo.clear();

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }
}

final pinServiceProvider = Provider<PinService>(
  (ref) => PinService(ref.watch(pinRepositoryProvider)),
);
