import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheStore {
  CacheStore(this._prefs);

  final SharedPreferences _prefs;

  Future<void> writeJson(String key, Object json) =>
      _prefs.setString(key, jsonEncode(json));

  Map<String, dynamic>? readJson(String key) {
    final raw = _prefs.getString(key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  List<dynamic>? readJsonList(String key) {
    final raw = _prefs.getString(key);
    return raw == null ? null : jsonDecode(raw) as List<dynamic>;
  }

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> removeByPrefix(String prefix) async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  Future<void> clearAll() => _prefs.clear();
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final cacheStoreProvider = Provider<CacheStore>(
  (ref) => CacheStore(ref.watch(sharedPreferencesProvider)),
);
