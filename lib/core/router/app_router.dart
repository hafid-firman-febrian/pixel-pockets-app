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

/// App route paths. As features land, register their screens below.
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

/// The app router. Lives in a provider so its [GoRouter.redirect] can read the
/// current [AuthState] and so it can refresh when auth changes.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      // Still resolving the silent sign-in — hold on the splash screen.
      if (auth is AuthUnknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Signed out — force the login screen.
      if (auth is AuthSignedOut) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }

      // Session valid but PIN-locked — hold on the unlock screen.
      // (Not emitted yet; activates with the session-restore work.)
      if (auth is AuthLocked) {
        return location == AppRoutes.unlock ? null : AppRoutes.unlock;
      }

      // Signed in. First-time users (no PIN yet) must create one.
      final hasPin = ref.read(pinControllerProvider);
      if (hasPin == false) {
        return location == AppRoutes.setPin ? null : AppRoutes.setPin;
      }

      // Has PIN (or still resolving) — keep the user out of the entry screens.
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
        // On save, pin status flips to true and the redirect moves the user on.
        builder: (context, state) => const SetPinScreen(),
      ),
      GoRoute(
        path: AppRoutes.unlock,
        name: 'unlock',
        builder: (context, state) =>
            UnlockPinScreen(onSuccess: () => context.go(AppRoutes.dashboard)),
      ),
      StatefulShellRoute.indexedStack(
        // AppShell = wrapper Scaffold yang berisi bottom nav
        builder: (context, state, shell) {
          return AppShell(shell: shell);
        },

        branches: [
          // ── Tab 0: Dashboard ──────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // ── Tab 1: Transactions ───────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) => const TransactionScreen(),
                // routes: [
                //   // Sub-route: add — TIDAK tampilkan bottom nav
                //   GoRoute(
                //     path: 'add',
                //     builder: (context, state) => const AddTransactionScreen(),
                //   ),
                // ],
              ),
            ],
          ),

          // ── Tab 2: Chart (placeholder) ────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chart,
                builder: (context, state) => const ChartScreen(),
              ),
            ],
          ),

          // ── Tab 3: Settings ───────────────────
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
    // routes: [
    //   GoRoute(
    //     path: AppRoutes.splash,
    //     name: 'splash',
    //     builder: (context, state) => const SplashScreen(),
    //   ),
    //   GoRoute(
    //     path: AppRoutes.login,
    //     name: 'login',
    //     builder: (context, state) => const LoginScreen(),
    //   ),
    //   GoRoute(
    //     path: AppRoutes.transactions,
    //     name: 'transactions',
    //     builder: (context, state) => const TransactionScreen(),
    //   ),
    //   GoRoute(
    //     path: AppRoutes.chart,
    //     name: 'categories',
    //     builder: (context, state) => const CategoryScreen(),
    //   ),
    // ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
    ),
  );
});

/// Bridges [authControllerProvider] changes to go_router so the redirect
/// re-runs whenever the auth state changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    // Re-run redirect when the PIN status resolves (null → true/false) so a
    // freshly signed-in first-time user is sent to the set-PIN screen.
    ref.listen(pinControllerProvider, (_, _) => notifyListeners());
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // shell.currentIndex otomatis berubah saat navigasi
      body: shell,
      bottomNavigationBar: PixelBottomNav(
        items: _navItems,
        currentIndex: shell.currentIndex,
        onTap: _onTap,
      ),
    );
  }

  void _onTap(int index) {
    shell.goBranch(
      index,
      // Tap tab yang sudah aktif → kembali ke root tab tersebut
      // Contoh: di /transactions/add, tap tab TXN → balik ke /transactions
      initialLocation: index == shell.currentIndex,
    );
  }
}
