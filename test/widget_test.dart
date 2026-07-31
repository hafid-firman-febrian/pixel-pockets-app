import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pixel_pocket/core/router/app_router.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/pin_controller.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';
import 'package:pixel_pocket/main.dart';

class _SignedInAuthController extends AuthController {
  @override
  AuthState build() => const AuthSignedIn(null);
}

class _LockedAuthController extends AuthController {
  @override
  AuthState build() => const AuthLocked(null);
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

  testWidgets('Shows unlock screen when auth is locked', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_LockedAuthController.new),
          pinControllerProvider.overrideWith(_NoPinController.new),
        ],
        child: const PixelPocketApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Enter PIN'), findsOneWidget);
  });

  testWidgets(
    '/reset-pin renders ForgotPinScreen while locked, but other locations '
    'still bounce to unlock',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_LockedAuthController.new),
            pinControllerProvider.overrideWith(_NoPinController.new),
          ],
          child: const PixelPocketApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate straight to /reset-pin while still locked.
      final router = GoRouter.of(tester.element(find.text('Enter PIN')));
      router.go(AppRoutes.resetPin);
      await tester.pumpAndSettle();
      expect(find.text('Forgot PIN?'), findsOneWidget);

      // A different arbitrary in-app location is not exempted — it still
      // bounces back to unlock, proving the redirect exception is scoped to
      // exactly /unlock and /reset-pin.
      final forgotPinContext = tester.element(find.text('Forgot PIN?'));
      GoRouter.of(forgotPinContext).go(AppRoutes.settings);
      await tester.pumpAndSettle();
      expect(find.text('Enter PIN'), findsOneWidget);
    },
  );
}
