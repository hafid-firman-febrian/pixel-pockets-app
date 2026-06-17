import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/transactions/screens/transaction_screen.dart';

/// App route table. As features land, register their screens here.
class AppRoutes {
  AppRoutes._();

  static const transactions = '/';
  // Reserved for upcoming features:
  // static const dashboard = '/dashboard';
  // static const categories = '/categories';
  // static const salaryPeriods = '/salary-periods';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.transactions,
  routes: [
    GoRoute(
      path: AppRoutes.transactions,
      name: 'transactions',
      builder: (context, state) => const TransactionScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
  ),
);
