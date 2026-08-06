import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/features/backup/presentation/screens/widgets/backup_section.dart';

Future<Widget> _host(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: BackupSection())),
    ),
  );
}

void main() {
  testWidgets('shows the restore-decision banner instead of the synced row',
      (tester) async {
    await tester.pumpWidget(await _host({
      'backup_spreadsheet_id': 'sheet123',
      'backup_account_email': 'user@example.com',
      'backup_needs_restore_decision': true,
      'backup_remote_tx_count': 142,
    }));
    await tester.pump();

    expect(find.textContaining('142 transaksi di Drive'), findsOneWidget);
    expect(find.textContaining('Tersinkron'), findsNothing);
    expect(find.text('PAKAI DATA LOKAL'), findsOneWidget);
  });

  testWidgets('falls back to generic copy when the remote count is unknown',
      (tester) async {
    await tester.pumpWidget(await _host({
      'backup_spreadsheet_id': 'sheet123',
      'backup_needs_restore_decision': true,
    }));
    await tester.pump();

    expect(find.textContaining('Backup di Drive'), findsOneWidget);
  });

  testWidgets('keeping local data dismisses the banner', (tester) async {
    await tester.pumpWidget(await _host({
      'backup_spreadsheet_id': 'sheet123',
      'backup_needs_restore_decision': true,
      'backup_remote_tx_count': 142,
    }));
    await tester.pump();

    await tester.tap(find.text('PAKAI DATA LOKAL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('142 transaksi di Drive'), findsNothing);
    expect(find.textContaining('Tersinkron'), findsOneWidget);
  });

  testWidgets('shows the synced row when no decision is pending',
      (tester) async {
    await tester.pumpWidget(await _host({
      'backup_spreadsheet_id': 'sheet123',
      'backup_account_email': 'user@example.com',
    }));
    await tester.pump();

    expect(find.textContaining('Tersinkron'), findsOneWidget);
    expect(find.text('PAKAI DATA LOKAL'), findsNothing);
  });
}
