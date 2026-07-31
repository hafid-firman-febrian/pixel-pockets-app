import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pixel_pocket/features/backup/data/datasources/backup_metadata_store.dart';
import 'package:pixel_pocket/features/backup/data/datasources/google_auth_client.dart';
import 'package:pixel_pocket/features/backup/data/datasources/sheets_data_source.dart';
import 'package:pixel_pocket/features/backup/data/repositories/backup_repository.dart';

/// Simulates a plugin-level failure (e.g. GoogleSignIn credential-clear
/// failure) when disconnecting.
class _ThrowingAuthClient extends GoogleAuthClient {
  _ThrowingAuthClient() : super(AuthRemoteDataSource());

  @override
  Future<void> disconnect() async {
    throw Exception('sign-out failed');
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test(
    'disconnect still clears local metadata when the auth client throws',
    () async {
      SharedPreferences.setMockInitialValues({
        'backup_spreadsheet_id': 'sheet123',
        'backup_account_email': 'user@example.com',
        'backup_auto_enabled': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final meta = BackupMetadataStore(prefs);
      expect(meta.isConnected, true);

      final repo = BackupRepository(
        auth: _ThrowingAuthClient(),
        sheets: SheetsDataSource(_ThrowingAuthClient()),
        db: db,
        meta: meta,
      );

      await expectLater(repo.disconnect(), throwsA(anything));

      expect(meta.isConnected, false);
      expect(meta.spreadsheetId, isNull);
      expect(meta.autoBackupEnabled, true); // resets to default (no pref stored)
    },
  );
}
