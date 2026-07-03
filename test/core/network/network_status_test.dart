import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/network/network_status.dart';

void main() {
  test('starts online, flips offline then back online', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(networkStatusProvider), isTrue);

    container.read(networkStatusProvider.notifier).setOffline();
    expect(container.read(networkStatusProvider), isFalse);

    container.read(networkStatusProvider.notifier).setOnline();
    expect(container.read(networkStatusProvider), isTrue);
  });
}
