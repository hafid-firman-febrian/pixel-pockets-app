import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/features/auth/presentation/widgets/pin_dots.dart';
import 'package:pixel_pocket/features/auth/presentation/widgets/pixel_pin_pad.dart';
import 'package:pixelarticons/pixel.dart';

/// Shared layout for the PIN screens: header icon + title + subtitle, the
/// progress dots, and the keypad. Owns only the error-shake animation; the
/// entry logic lives in the screens that use it.
class PinScaffold extends StatefulWidget {
  const PinScaffold({
    super.key,
    required this.title,
    required this.length,
    required this.filled,
    required this.onDigit,
    required this.onBackspace,
    this.subtitle,
    this.icon = Pixel.lock,
    this.error = false,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final int length;
  final int filled;

  /// Drives the shake + red dots. Toggle false→true to replay the animation.
  final bool error;

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// When set, shows a back button in the app bar.
  final VoidCallback? onBack;

  @override
  State<PinScaffold> createState() => _PinScaffoldState();
}

class _PinScaffoldState extends State<PinScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void didUpdateWidget(PinScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error && !oldWidget.error) {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// Damped horizontal oscillation: a few swings that decay to zero.
  double _shakeOffset(double t) => sin(t * pi * 4) * 12 * (1 - t);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.onBack == null
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Pixel.arrowleft),
                onPressed: widget.onBack,
              ),
            ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenAll,
          child: Column(
            children: [
              const Spacer(),
              Icon(widget.icon, size: 56, color: AppColors.primary),
              SizedBox(height: AppSpacing.s24),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (widget.subtitle != null) ...[
                SizedBox(height: AppSpacing.s8),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
              SizedBox(height: AppSpacing.s32),
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_shakeOffset(_shake.value), 0),
                  child: child,
                ),
                child: PinDots(
                  length: widget.length,
                  filled: widget.filled,
                  error: widget.error,
                ),
              ),
              const Spacer(),
              PixelPinPad(
                onDigit: widget.onDigit,
                onBackspace: widget.onBackspace,
              ),
              SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ),
    );
  }
}
