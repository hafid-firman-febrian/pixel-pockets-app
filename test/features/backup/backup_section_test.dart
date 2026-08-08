import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/features/backup/presentation/screens/widgets/backup_section.dart';
import 'package:pixel_pocket/features/backup/presentation/screens/widgets/restore_decision_dialog.dart';
import 'package:pixel_pocket/features/backup/presentation/states/backup_state.dart';

Future<Widget> _host(
  Map<String, Object> values, {
  BackupAction? running,
}) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (running != null)
        backupRunningActionProvider.overrideWith((ref) => running),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: BackupSection())),
    ),
  );
}

Future<void> _setNarrowSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(320, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Finder _spinnerInsideButton(String label) => find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(PixelButton),
      ),
      matching: find.byType(CircularProgressIndicator),
    );

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

    expect(find.textContaining('142 transactions'), findsOneWidget);
    expect(find.textContaining('Synced'), findsNothing);
    expect(find.text('KEEP LOCAL'), findsOneWidget);
  });

  testWidgets('falls back to generic copy when the remote count is unknown',
      (tester) async {
    await tester.pumpWidget(await _host({
      'backup_spreadsheet_id': 'sheet123',
      'backup_needs_restore_decision': true,
    }));
    await tester.pump();

    expect(find.textContaining('Drive holds a backup'), findsOneWidget);
  });

  testWidgets('keeping local data dismisses the banner', (tester) async {
    await tester.pumpWidget(await _host({
      'backup_spreadsheet_id': 'sheet123',
      'backup_needs_restore_decision': true,
      'backup_remote_tx_count': 142,
    }));
    await tester.pump();

    await tester.tap(find.text('KEEP LOCAL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('142 transactions'), findsNothing);
    expect(find.textContaining('Synced'), findsOneWidget);
  });

  testWidgets('shows the synced row when no decision is pending',
      (tester) async {
    await tester.pumpWidget(await _host({
      'backup_spreadsheet_id': 'sheet123',
      'backup_account_email': 'user@example.com',
    }));
    await tester.pump();

    expect(find.textContaining('Synced'), findsOneWidget);
    expect(find.text('KEEP LOCAL'), findsNothing);
  });

  testWidgets('a running restore spins the Restore button, not Backup Now',
      (tester) async {
    await tester.pumpWidget(await _host(
      {
        'backup_spreadsheet_id': 'sheet123',
        'backup_account_email': 'user@example.com',
      },
      running: BackupAction.restore,
    ));
    await tester.pump();

    expect(_spinnerInsideButton('RESTORE'), findsOneWidget);
    expect(_spinnerInsideButton('BACKUP NOW'), findsNothing);
    expect(_spinnerInsideButton('DISCONNECT'), findsNothing);
  });

  testWidgets('a running backup spins Backup Now, not Restore', (tester) async {
    await tester.pumpWidget(await _host(
      {
        'backup_spreadsheet_id': 'sheet123',
        'backup_account_email': 'user@example.com',
      },
      running: BackupAction.backup,
    ));
    await tester.pump();

    expect(_spinnerInsideButton('BACKUP NOW'), findsOneWidget);
    expect(_spinnerInsideButton('RESTORE'), findsNothing);
  });

  testWidgets('a running keep-local spins the banner Keep Local button',
      (tester) async {
    await tester.pumpWidget(await _host(
      {
        'backup_spreadsheet_id': 'sheet123',
        'backup_needs_restore_decision': true,
        'backup_remote_tx_count': 142,
      },
      running: BackupAction.keepLocal,
    ));
    await tester.pump();

    expect(_spinnerInsideButton('KEEP LOCAL'), findsOneWidget);
    expect(_spinnerInsideButton('BACKUP NOW'), findsNothing);
  });

  testWidgets('banner lays out without overflow on a narrow screen',
      (tester) async {
    await _setNarrowSurface(tester);
    await tester.pumpWidget(await _host({
      'backup_spreadsheet_id': 'sheet123',
      'backup_account_email': 'averylongaccountname@example.com',
      'backup_needs_restore_decision': true,
      'backup_remote_tx_count': 148291,
    }));
    await tester.pump();

    expect(find.text('KEEP LOCAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('decision dialog lays out without overflow on a narrow screen',
      (tester) async {
    await _setNarrowSurface(tester);
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    showRestoreDecisionDialog(ctx, transactionCount: 148291);
    await tester.pumpAndSettle();

    expect(find.text('Backup found'), findsOneWidget);
    expect(find.text('RESTORE'), findsOneWidget);
    expect(find.text('KEEP LOCAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('decision dialog returns keepLocal, restore, or null on dismiss',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final keepLocal = showRestoreDecisionDialog(ctx, transactionCount: 1);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 transaction '), findsOneWidget);
    await tester.tap(find.text('KEEP LOCAL'));
    await tester.pumpAndSettle();
    expect(await keepLocal, RestoreDecision.keepLocal);

    final restore = showRestoreDecisionDialog(ctx, transactionCount: 3);
    await tester.pumpAndSettle();
    await tester.tap(find.text('RESTORE'));
    await tester.pumpAndSettle();
    expect(await restore, RestoreDecision.restore);

    final dismissed = showRestoreDecisionDialog(ctx, transactionCount: 3);
    await tester.pumpAndSettle();
    Navigator.of(ctx).pop();
    await tester.pumpAndSettle();
    expect(await dismissed, isNull);
  });
}
