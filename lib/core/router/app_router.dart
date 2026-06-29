import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixel_pocket/core/widgets/pixel_bottom_nav.dart';
import 'package:pixel_pocket/features/chart/presentation/screens/chart_screen.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:pixel_pocket/features/settings/presentation/screens/settings_screen.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/transaction_screen.dart';
import 'package:pixelarticons/pixel.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/controllers/pin_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/set_pin_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/unlock_pin_screen.dart';
import '../../features/auth/presentation/states/auth_state.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const setPin = '/set-pin';
  static const unlock = '/unlock';
  static const String dashboard = '/';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String chart = '/chart';
  static const String settings = '/settings';
  static const String salaryPeriods = '/settings/salary-periods';
}

const _navItems = [
  PixelNavItem(icon: Pixel.home, label: 'HOME', path: AppRoutes.dashboard),
  PixelNavItem(icon: Pixel.list, label: 'TXN', path: AppRoutes.transactions),
  PixelNavItem(icon: Pixel.chartbar, label: 'CHART', path: AppRoutes.chart),
  PixelNavItem(
    icon: Pixel.sliders,
    label: 'SETTINGS',
    path: AppRoutes.settings,
  ),
];

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      if (auth is AuthUnknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (auth is AuthSignedOut) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }

      if (auth is AuthLocked) {
        return location == AppRoutes.unlock ? null : AppRoutes.unlock;
      }

      final hasPin = ref.read(pinControllerProvider);
      if (hasPin == false) {
        return location == AppRoutes.setPin ? null : AppRoutes.setPin;
      }

      if (location == AppRoutes.login ||
          location == AppRoutes.splash ||
          location == AppRoutes.setPin ||
          location == AppRoutes.unlock) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.setPin,
        name: 'setPin',

        builder: (context, state) => const SetPinScreen(),
      ),
      GoRoute(
        path: AppRoutes.unlock,
        name: 'unlock',

        builder: (context, state) => UnlockPinScreen(
          onSuccess: () => ref.read(authControllerProvider.notifier).unlock(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) {
          return AppShell(shell: shell);
        },

        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) => const TransactionScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chart,
                builder: (context, state) => const ChartScreen(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
    ),
  );
});

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());

    ref.listen(pinControllerProvider, (_, _) => notifyListeners());
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: PixelBottomNav(
        items: _navItems,
        currentIndex: shell.currentIndex,
        onTap: _onTap,
      ),
    );
  }

  void _onTap(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }
}
