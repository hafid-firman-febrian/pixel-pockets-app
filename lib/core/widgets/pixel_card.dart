import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';

class PixelCard extends StatelessWidget {
  const PixelCard({
    super.key,
    required this.child,
    this.padding,
    this.elevated = false,
    this.color,
    this.onTap,
  });

  final Widget child;

  final EdgeInsetsGeometry? padding;

  final bool elevated;

  final Color? color;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        border: Border.all(color: AppColors.border),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: AppColors.border,
                  offset: Offset(0, 5),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    if (onTap != null) {
      content = InkWell(onTap: onTap, child: content);
    }
    return content;
  }
}
