import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixel_pocket/core/widgets/pixel_bottom_nav.dart';
import 'package:pixel_pocket/features/dashboard/presentation/dashboard_screen.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/transaction_screen.dart';
import 'package:pixelarticons/pixel.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';

/// App route paths. As features land, register their screens below.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
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

      // Signed in — keep the user out of the splash/login screens.
      if (location == AppRoutes.login || location == AppRoutes.splash) {
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

          // ── Tab 2: Chart ──────────────────────
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       path: AppRoutes.chart,
          //       builder: (context, state) => const ChartScreen(),
          //     ),
          //   ],
          // ),

          // ── Tab 3: Settings ───────────────────
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       path: AppRoutes.settings,
          //       builder: (context, state) => const SettingsScreen(),
          //     ),
          //   ],
          // ),
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
