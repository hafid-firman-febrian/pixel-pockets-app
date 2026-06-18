// Smoke test: with no Google session the app gates to the login screen.
//
// We override the auth controller so the real google_sign_in plugin is never
// touched (it isn't available under flutter test). A signed-out state drives
// the router guard to /login.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixel_pocket/features/auth/providers/auth_provider.dart';
import 'package:pixel_pocket/main.dart';

/// Auth controller that resolves immediately to signed-out, with no SDK calls.
class _SignedOutAuthController extends AuthController {
  @override
  AuthState build() => const AuthSignedOut();
}

void main() {
  testWidgets('Gates to login when there is no session', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_SignedOutAuthController.new),
        ],
        child: const PixelPocketApp(),
      ),
    );

    await tester.pumpAndSettle();

    // PixelButton meng-uppercase label-nya.
    expect(find.text('SIGN IN WITH GOOGLE'), findsOneWidget);
    expect(find.text('Pixel Pocket'), findsOneWidget);
  });
}
