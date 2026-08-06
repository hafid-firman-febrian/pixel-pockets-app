import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/backup/data/backup_serialization.dart';
import 'package:pixel_pocket/features/backup/data/datasources/backup_metadata_store.dart';
import 'package:pixel_pocket/features/backup/data/datasources/google_auth_client.dart';
import 'package:pixel_pocket/features/backup/data/datasources/sheets_data_source.dart';

class BackupRepository {
  BackupRepository({
    required GoogleAuthClient auth,
    required SheetsDataSource sheets,
    required AppDatabase db,
    required BackupMetadataStore meta,
  }) : _auth = auth,
       _sheets = sheets,
       _db = db,
       _meta = meta;

  final GoogleAuthClient _auth;
  final SheetsDataSource _sheets;
  final AppDatabase _db;
  final BackupMetadataStore _meta;

  Future<String> connect() async {
    try {
      final email = await _auth.connect();
      final id = await _sheets.findOrCreateSpreadsheet();
      await _meta.setNeedsRestoreDecision(true);
      await _meta.setSpreadsheetId(id);
      await _meta.setAccountEmail(email);
      await _applyRemoteInspection(id);
      return email;
    } catch (e) {
      throw _asFailure(e);
    }
  }

  Future<RemoteBackupSummary> inspectRemote(String spreadsheetId) async {
    final parsed = remoteSummaryFromMetadataRows(
      await _sheets.readTab(spreadsheetId, 'Metadata'),
    );
    if (parsed != null && !parsed.isEmpty) return parsed;

    final cats = _dropHeader(await _sheets.readTab(spreadsheetId, 'Categories'));
    final periods =
        _dropHeader(await _sheets.readTab(spreadsheetId, 'SalaryPeriods'));
    final txs =
        _dropHeader(await _sheets.readTab(spreadsheetId, 'Transactions'));
    return RemoteBackupSummary(
      transactions: txs.length,
      categories: cats.length,
      salaryPeriods: periods.length,
    );
  }

  Future<void> _applyRemoteInspection(String spreadsheetId) async {
    try {
      final summary = await inspectRemote(spreadsheetId);
      if (summary.isEmpty) {
        await _clearRestoreDecision();
        return;
      }
      await _meta.setNeedsRestoreDecision(true);
      await _meta.setRemoteTransactionCount(
        summary.transactions == 0 ? null : summary.transactions,
      );
    } catch (_) {
      await _meta.setNeedsRestoreDecision(true);
      await _meta.setRemoteTransactionCount(null);
    }
  }

  Future<void> _clearRestoreDecision() async {
    await _meta.setNeedsRestoreDecision(false);
    await _meta.setRemoteTransactionCount(null);
  }

  Future<void> disconnect() async {
    try {
      await _auth.disconnect();
    } finally {
      await _meta.clear();
    }
  }

  Future<void> keepLocalData() => _clearRestoreDecision();

  Future<DateTime> backup() async {
    try {
      final id = _meta.spreadsheetId ?? await _sheets.findOrCreateSpreadsheet();
      await _meta.setSpreadsheetId(id);

      final cats = await _db.select(_db.categories).get();
      final periods = await _db.select(_db.salaryPeriods).get();
      final txs = await _db.select(_db.transactions).get();

      await _sheets.writeTab(id, 'Categories', [
        categoriesHeader,
        ...cats.map(categoryToRow),
      ]);
      await _sheets.writeTab(id, 'SalaryPeriods', [
        salaryPeriodsHeader,
        ...periods.map(salaryPeriodToRow),
      ]);
      await _sheets.writeTab(id, 'Transactions', [
        transactionsHeader,
        ...txs.map(transactionToRow),
      ]);
      final now = DateTime.now();
      await _sheets.writeTab(id, 'Metadata', [
        ['key', 'value'],
        ['schema_version', '1'],
        ['last_backup_at', now.toIso8601String()],
        ['categories', '${cats.length}'],
        ['salary_periods', '${periods.length}'],
        ['transactions', '${txs.length}'],
      ]);
      await _meta.setLastBackupAt(now);
      await _meta.setPendingBackup(false);
      await _clearRestoreDecision();
      return now;
    } catch (e) {
      throw _asFailure(e);
    }
  }

  Future<void> restore() async {
    try {
      final id = _meta.spreadsheetId ?? await _sheets.findOrCreateSpreadsheet();
      final cats = _dropHeader(await _sheets.readTab(id, 'Categories'));
      final periods = _dropHeader(await _sheets.readTab(id, 'SalaryPeriods'));
      final txs = _dropHeader(await _sheets.readTab(id, 'Transactions'));
      if (cats.isEmpty && periods.isEmpty && txs.isEmpty) {
        throw const Failure(message: 'Tidak ada backup ditemukan untuk direstore.');
      }
      await _db.replaceAll(
        categories: cats
            .map((r) => categoryFromRow(padRow(r, categoriesHeader.length)))
            .toList(),
        salaryPeriods: periods
            .map((r) => salaryPeriodFromRow(padRow(r, salaryPeriodsHeader.length)))
            .toList(),
        transactions: txs
            .map((r) => transactionFromRow(padRow(r, transactionsHeader.length)))
            .toList(),
      );
      await _clearRestoreDecision();
    } catch (e) {
      throw _asFailure(e);
    }
  }

  List<List<Object?>> _dropHeader(List<List<Object?>> rows) =>
      rows.length <= 1 ? const [] : rows.sublist(1);

  Failure _asFailure(Object e) {
    if (e is Failure) return e;
    if (e is SheetsAuthException) {
      return Failure(message: e.message, type: FailureType.unauthorized);
    }
    return Failure(message: e.toString());
  }
}

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepository(
    auth: ref.watch(googleAuthClientProvider),
    sheets: ref.watch(sheetsDataSourceProvider),
    db: ref.watch(appDatabaseProvider),
    meta: ref.watch(backupMetadataStoreProvider),
  ),
);
