import 'package:flutter/material.dart';

/// Shown while the silent sign-in resolves. The router redirects away as soon
/// as [AuthState] becomes signed-in or signed-out.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
