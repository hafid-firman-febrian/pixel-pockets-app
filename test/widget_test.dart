import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/pin_controller.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';
import 'package:pixel_pocket/main.dart';

class _SignedInAuthController extends AuthController {
  @override
  AuthState build() => const AuthSignedIn(null);
}

class _NoPinController extends PinController {
  @override
  bool? build() => false;
}

void main() {
  testWidgets('Gates to set-pin when there is no pin yet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_SignedInAuthController.new),
          pinControllerProvider.overrideWith(_NoPinController.new),
        ],
        child: const PixelPocketApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Create PIN'), findsOneWidget);
  });
}
