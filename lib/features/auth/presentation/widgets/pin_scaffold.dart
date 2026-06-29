import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/features/auth/presentation/widgets/pin_dots.dart';
import 'package:pixel_pocket/features/auth/presentation/widgets/pixel_pin_pad.dart';
import 'package:pixelarticons/pixel.dart';

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
    this.keypadEnabled = true,
    this.subtitleError = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final int length;
  final int filled;

  final bool error;

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  final VoidCallback? onBack;

  final bool keypadEnabled;

  final bool subtitleError;

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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (widget.subtitle != null) ...[
                SizedBox(height: AppSpacing.s8),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.subtitleError
                        ? AppColors.expense
                        : AppColors.textMuted,
                    fontWeight: widget.subtitleError
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
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
              AnimatedOpacity(
                opacity: widget.keypadEnabled ? 1 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: PixelPinPad(
                  onDigit: widget.onDigit,
                  onBackspace: widget.onBackspace,
                  enabled: widget.keypadEnabled,
                ),
              ),
              SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ),
    );
  }
}
