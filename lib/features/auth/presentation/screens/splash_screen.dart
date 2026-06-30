import 'package:flutter/material.dart';

import '../../../../core/theme/app_color.dart';

/// Shown while the silent sign-in resolves. The router redirects away as soon
/// as [AuthState] becomes signed-in or signed-out.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/app_icon.png',
              width: 120,
              height: 120,
              filterQuality: FilterQuality.none, // keep pixel-art crisp
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
