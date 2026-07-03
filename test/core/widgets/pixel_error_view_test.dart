import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/core/widgets/pixel_error_view.dart';
import 'package:pixelarticons/pixel.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PixelErrorView', () {
    testWidgets('shows the failure message', (tester) async {
      await tester.pumpWidget(_host(PixelErrorView(
        failure: const Failure(message: 'Failed to load summary.'),
        onRetry: () {},
      )));
      expect(find.text('Failed to load summary.'), findsOneWidget);
      expect(find.text('TRY AGAIN'), findsOneWidget);
    });

    testWidgets('fires onRetry when Try Again is tapped', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_host(PixelErrorView(
        failure: const Failure(message: 'boom'),
        onRetry: () => tapped++,
      )));
      await tester.tap(find.text('TRY AGAIN'));
      expect(tapped, 1);
    });

    testWidgets('renders the no-connection icon for noConnection type',
        (tester) async {
      await tester.pumpWidget(_host(PixelErrorView(
        failure: const Failure(
          message: 'offline',
          type: FailureType.noConnection,
        ),
        onRetry: () {},
      )));
      expect(find.byIcon(Pixel.downasaur), findsOneWidget);
    });

    testWidgets('renders the server icon for server type', (tester) async {
      await tester.pumpWidget(_host(PixelErrorView(
        failure: const Failure(message: '500', type: FailureType.server),
        onRetry: () {},
      )));
      expect(find.byIcon(Pixel.server), findsOneWidget);
    });

    testWidgets('compact mode still shows message and fires onRetry',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_host(PixelErrorView(
        failure: const Failure(message: 'card error'),
        onRetry: () => tapped++,
        compact: true,
      )));
      expect(find.text('card error'), findsOneWidget);
      await tester.tap(find.text('TRY AGAIN'));
      expect(tapped, 1);
    });
  });
}
