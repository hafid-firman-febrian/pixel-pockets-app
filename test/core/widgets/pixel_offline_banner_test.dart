import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/network/network_status.dart';
import 'package:pixel_pocket/core/widgets/pixel_offline_banner.dart';

void main() {
  Widget wrap(bool online) => ProviderScope(
    overrides: [
      networkStatusProvider.overrideWith(() {
        final n = _StubStatus(online);
        return n;
      }),
    ],
    child: const MaterialApp(home: Scaffold(body: PixelOfflineBanner())),
  );

  testWidgets('hidden when online', (tester) async {
    await tester.pumpWidget(wrap(true));
    expect(find.textContaining('Offline'), findsNothing);
  });

  testWidgets('shows the strip when offline', (tester) async {
    await tester.pumpWidget(wrap(false));
    expect(find.textContaining('Offline'), findsOneWidget);
  });
}

class _StubStatus extends NetworkStatusNotifier {
  _StubStatus(this._initial);
  final bool _initial;
  @override
  bool build() => _initial;
}
