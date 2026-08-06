import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixelarticons/pixel.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

double _labelWidth(WidgetTester tester, String label) =>
    tester.getSize(find.text(label)).width;

void main() {
  group('PixelButton', () {
    testWidgets('renders the label uppercased', (tester) async {
      await tester.pumpWidget(
        _host(PixelButton(label: 'Keep Local', onPressed: () {})),
      );
      expect(find.text('KEEP LOCAL'), findsOneWidget);
    });

    testWidgets('a long label scales down instead of overflowing',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 96,
            child: PixelButton(
              label: 'Keep Local',
              isFullWidth: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('KEEP LOCAL'), findsOneWidget);
    });

    testWidgets('two long labels share a row without overflowing',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 220,
            child: Row(
              children: [
                Expanded(
                  child: PixelButton(
                    label: 'Keep Local',
                    size: PixelButtonSize.sm,
                    isFullWidth: true,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PixelButton(
                    label: 'Restore',
                    size: PixelButtonSize.sm,
                    isFullWidth: true,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('KEEP LOCAL'), findsOneWidget);
      expect(find.text('RESTORE'), findsOneWidget);
    });

    testWidgets('a label that already fits is not scaled down',
        (tester) async {
      await tester.pumpWidget(
        _host(PixelButton(label: 'Keep Local', onPressed: () {})),
      );
      final natural = _labelWidth(tester, 'KEEP LOCAL');

      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 400,
            child: PixelButton(
              label: 'Keep Local',
              isFullWidth: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(_labelWidth(tester, 'KEEP LOCAL'), natural);
    });

    testWidgets('still fires onPressed and shows a loader when loading',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          PixelButton(
            label: 'Restore',
            icon: Pixel.clouddownload,
            onPressed: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('RESTORE'));
      expect(taps, 1);

      await tester.pumpWidget(
        _host(
          PixelButton(
            label: 'Restore',
            icon: Pixel.clouddownload,
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Pixel.clouddownload), findsNothing);
    });
  });
}
