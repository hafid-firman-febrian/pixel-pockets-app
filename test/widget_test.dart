// Smoke test: the app boots and renders the Transaksi screen shell.
//
// The transaction list itself makes a network call, so here we only verify
// the app builds and the AppBar title is shown — no backend required.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixel_pocket/core/router/app_router.dart';
import 'package:pixel_pocket/core/theme/app_theme.dart';
import 'package:pixel_pocket/features/transactions/providers/transaction_provider.dart';

void main() {
  testWidgets('App boots to the Transaksi screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Stub the list so no real network call (and no Dio timer) fires.
          transactionsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: appRouter,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('Belum ada transaksi'), findsOneWidget);
  });
}
