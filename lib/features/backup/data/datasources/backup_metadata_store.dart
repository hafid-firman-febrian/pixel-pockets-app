import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';

class BackupMetadataStore {
  BackupMetadataStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kSpreadsheetId = 'backup_spreadsheet_id';
  static const _kEmail = 'backup_account_email';
  static const _kLastBackup = 'backup_last_at';

  String? get spreadsheetId => _prefs.getString(_kSpreadsheetId);
  String? get accountEmail => _prefs.getString(_kEmail);
  DateTime? get lastBackupAt {
    final s = _prefs.getString(_kLastBackup);
    return s == null ? null : DateTime.tryParse(s);
  }

  bool get isConnected => spreadsheetId != null;

  Future<void> setSpreadsheetId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kSpreadsheetId);
    } else {
      await _prefs.setString(_kSpreadsheetId, id);
    }
  }

  Future<void> setAccountEmail(String? email) async {
    if (email == null) {
      await _prefs.remove(_kEmail);
    } else {
      await _prefs.setString(_kEmail, email);
    }
  }

  Future<void> setLastBackupAt(DateTime at) =>
      _prefs.setString(_kLastBackup, at.toIso8601String());

  Future<void> clear() async {
    await _prefs.remove(_kSpreadsheetId);
    await _prefs.remove(_kEmail);
    await _prefs.remove(_kLastBackup);
  }
}

final backupMetadataStoreProvider = Provider<BackupMetadataStore>(
  (ref) => BackupMetadataStore(ref.watch(sharedPreferencesProvider)),
);
