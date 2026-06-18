import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixelarticons/pixel.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';

/// Login entry point. UI only — delegates the actual sign-in to
/// [AuthController]. Local [_loading] is pure view state.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed to sign in: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppSpacing.screenAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Pixel.coin, size: 72, color: AppColors.primary),
              SizedBox(height: AppSpacing.s14),
              const Text(
                'Pixel Pocket',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: AppSpacing.s14),

              const Text(
                'Track the money. Spot the pattern.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              SizedBox(height: AppSpacing.s14),

              PixelButton(
                label: 'Sign in with Google',
                onPressed: _loading ? null : _signIn,
                isLoading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
