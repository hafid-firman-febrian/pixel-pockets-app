import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';

// =============================================================================
// ENUMS
// =============================================================================

enum PixelButtonVariant {
  primary,
  secondary,
  danger,
  ghost,
  income,
  expense,
  surface, // filled neutral dark — e.g. PIN keypad keys
}

enum PixelButtonSize { sm, md, lg }

// =============================================================================
// PIXEL BUTTON
// =============================================================================

/// Retro pixelated button dengan efek tekan 3D.
///
/// Efek pixel: shadow offset ke bawah saat idle, shift ke bawah + shadow hilang
/// saat ditekan — menyimulasikan tombol fisik yang ditekan.
///
/// ```dart
/// // Basic
/// PixelButton(label: 'Save', onPressed: () {})
///
/// // Dengan icon
/// PixelButton(
///   label: 'Add Transaction',
///   icon: Icons.add,
///   onPressed: () {},
/// )
///
/// // Variant & size
/// PixelButton(
///   label: 'Delete',
///   variant: PixelButtonVariant.danger,
///   size: PixelButtonSize.sm,
///   onPressed: () {},
/// )
///
/// // Loading state
/// PixelButton(
///   label: 'Saving...',
///   isLoading: true,
///   onPressed: null,
/// )
///
/// // Full width
/// PixelButton(
///   label: 'Confirm',
///   isFullWidth: true,
///   onPressed: () {},
/// )
/// ```
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = PixelButtonVariant.primary,
    this.size = PixelButtonSize.md,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : assert(
         label != null || icon != null,
         'PixelButton butuh minimal label atau icon',
       );

  /// Label tombol. Boleh null → tombol jadi icon-only (kotak persegi).
  final String? label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final PixelButtonVariant variant;
  final PixelButtonSize size;
  final bool isLoading;
  final bool isFullWidth;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  /// True saat tidak ada label tapi ada icon → render kotak icon-only.
  bool get _iconOnly =>
      (widget.label == null || widget.label!.isEmpty) && widget.icon != null;

  // ── Shadow depth berdasarkan size ─────────────────────────────────────────
  double get _shadowDepth {
    switch (widget.size) {
      case PixelButtonSize.sm:
        return 3;
      case PixelButtonSize.md:
        return 4;
      case PixelButtonSize.lg:
        return 5;
    }
  }

  // ── Dimensi berdasarkan size ───────────────────────────────────────────────
  double get _height {
    switch (widget.size) {
      case PixelButtonSize.sm:
        return 34;
      case PixelButtonSize.md:
        return 44;
      case PixelButtonSize.lg:
        return 52;
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case PixelButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12);
      case PixelButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 16);
      case PixelButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 20);
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case PixelButtonSize.sm:
        return 11;
      case PixelButtonSize.md:
        return 13;
      case PixelButtonSize.lg:
        return 15;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case PixelButtonSize.sm:
        return 14;
      case PixelButtonSize.md:
        return 16;
      case PixelButtonSize.lg:
        return 18;
    }
  }

  double get _loaderSize {
    switch (widget.size) {
      case PixelButtonSize.sm:
        return 12;
      case PixelButtonSize.md:
        return 14;
      case PixelButtonSize.lg:
        return 16;
    }
  }

  // ── Warna berdasarkan variant ──────────────────────────────────────────────
  _PixelButtonColors get _colors {
    if (_disabled) {
      return _PixelButtonColors(
        face: AppColors.surfaceVariant,
        shadow: AppColors.border,
        label: AppColors.textMuted,
        border: AppColors.border,
      );
    }

    switch (widget.variant) {
      case PixelButtonVariant.primary:
        return _PixelButtonColors(
          face: AppColors.primary,
          shadow: const Color(0xFFB8922A), // darker yellow
          label: AppColors.textDark,
          border: const Color(0xFFB8922A),
        );
      case PixelButtonVariant.secondary:
        return _PixelButtonColors(
          face: AppColors.secondary,
          shadow: const Color(0xFFB86A10), // darker orange
          label: Colors.white,
          border: const Color(0xFFB86A10),
        );
      case PixelButtonVariant.danger:
        return _PixelButtonColors(
          face: AppColors.expense,
          shadow: const Color(0xFFA83232), // darker red
          label: Colors.white,
          border: const Color(0xFFA83232),
        );
      case PixelButtonVariant.income:
        return _PixelButtonColors(
          face: AppColors.income,
          shadow: const Color(0xFF3A5424), // darker green
          label: Colors.white,
          border: const Color(0xFF3A5424),
        );
      case PixelButtonVariant.expense:
        return _PixelButtonColors(
          face: AppColors.expense,
          shadow: const Color(0xFFA83232),
          label: Colors.white,
          border: const Color(0xFFA83232),
        );
      case PixelButtonVariant.ghost:
        return _PixelButtonColors(
          face: Colors.transparent,
          shadow: AppColors.border,
          label: AppColors.textPrimary,
          border: AppColors.border,
        );
      case PixelButtonVariant.surface:
        return _PixelButtonColors(
          face: AppColors.surfaceVariant,
          shadow: AppColors.border,
          label: AppColors.textPrimary,
          border: AppColors.border,
        );
    }
  }

  void _onTapDown(TapDownDetails _) {
    if (_disabled) return;
    HapticFeedback.lightImpact();
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (_disabled) return;
    setState(() => _pressed = false);
    widget.onPressed?.call();
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final depth = _pressed || _disabled ? 0.0 : _shadowDepth;
    final translateY = _pressed && !_disabled ? _shadowDepth : 0.0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        // Shift ke bawah saat ditekan
        transform: Matrix4.translationValues(0, translateY, 0),
        width: _iconOnly
            ? _height // kotak persegi untuk mode icon-only
            : (widget.isFullWidth ? double.infinity : null),
        height: _height,
        decoration: BoxDecoration(
          color: colors.face,
          // Border semua sisi
          border: Border.all(color: colors.border, width: 1.5),
          // Shadow hanya di bawah — efek pixel 3D
          boxShadow: depth > 0
              ? [
                  BoxShadow(
                    color: colors.shadow,
                    offset: Offset(0, depth),
                    blurRadius: 0, // blur=0 agar terlihat pixel
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: _iconOnly
            ? Center(child: _iconOnlyChild(colors))
            : Padding(
                padding: _padding,
                child: Row(
                  mainAxisSize: widget.isFullWidth
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Leading icon
                    if (widget.icon != null && !widget.isLoading) ...[
                      Icon(widget.icon, size: _iconSize, color: colors.label),
                      SizedBox(
                        width: widget.size == PixelButtonSize.sm ? 4 : 6,
                      ),
                    ],

                    // Loading spinner
                    if (widget.isLoading) ...[
                      SizedBox(
                        width: _loaderSize,
                        height: _loaderSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: colors.label,
                        ),
                      ),
                      SizedBox(
                        width: widget.size == PixelButtonSize.sm ? 4 : 6,
                      ),
                    ],

                    // Label
                    Text(
                      (widget.label ?? '').toUpperCase(),
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w700,
                        color: colors.label,
                        letterSpacing: 1.0,
                        height: 1,
                      ),
                    ),

                    // Trailing icon
                    if (widget.trailingIcon != null && !widget.isLoading) ...[
                      SizedBox(
                        width: widget.size == PixelButtonSize.sm ? 4 : 6,
                      ),
                      Icon(
                        widget.trailingIcon,
                        size: _iconSize,
                        color: colors.label,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  /// Isi tombol saat mode icon-only: spinner ketika loading, selain itu icon.
  Widget _iconOnlyChild(_PixelButtonColors colors) {
    if (widget.isLoading) {
      return SizedBox(
        width: _loaderSize,
        height: _loaderSize,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: colors.label),
      );
    }
    return Icon(widget.icon, size: _iconSize, color: colors.label);
  }
}

// =============================================================================
// PIXEL ICON BUTTON
// =============================================================================

/// Versi icon-only dari PixelButton — square dengan satu icon di tengah.
///
/// ```dart
/// PixelIconButton(
///   icon: Icons.delete_outline,
///   onPressed: () {},
///   variant: PixelButtonVariant.danger,
/// )
/// ```
class PixelIconButton extends StatefulWidget {
  const PixelIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = PixelButtonVariant.ghost,
    this.size = PixelButtonSize.md,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final PixelButtonVariant variant;
  final PixelButtonSize size;

  @override
  State<PixelIconButton> createState() => _PixelIconButtonState();
}

class _PixelIconButtonState extends State<PixelIconButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null;

  double get _boxSize {
    switch (widget.size) {
      case PixelButtonSize.sm:
        return 32;
      case PixelButtonSize.md:
        return 40;
      case PixelButtonSize.lg:
        return 48;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case PixelButtonSize.sm:
        return 14;
      case PixelButtonSize.md:
        return 18;
      case PixelButtonSize.lg:
        return 22;
    }
  }

  double get _shadowDepth {
    switch (widget.size) {
      case PixelButtonSize.sm:
        return 2;
      case PixelButtonSize.md:
        return 3;
      case PixelButtonSize.lg:
        return 4;
    }
  }

  // Reuse color logic dari PixelButton
  _PixelButtonColors get _colors {
    if (_disabled) {
      return _PixelButtonColors(
        face: AppColors.surfaceVariant,
        shadow: AppColors.border,
        label: AppColors.textMuted,
        border: AppColors.border,
      );
    }
    switch (widget.variant) {
      case PixelButtonVariant.primary:
        return _PixelButtonColors(
          face: AppColors.primary,
          shadow: const Color(0xFFB8922A),
          label: AppColors.textDark,
          border: const Color(0xFFB8922A),
        );
      case PixelButtonVariant.secondary:
        return _PixelButtonColors(
          face: AppColors.secondary,
          shadow: const Color(0xFFB86A10),
          label: Colors.white,
          border: const Color(0xFFB86A10),
        );
      case PixelButtonVariant.danger:
      case PixelButtonVariant.expense:
        return _PixelButtonColors(
          face: AppColors.expense,
          shadow: const Color(0xFFA83232),
          label: Colors.white,
          border: const Color(0xFFA83232),
        );
      case PixelButtonVariant.income:
        return _PixelButtonColors(
          face: AppColors.income,
          shadow: const Color(0xFF3A5424),
          label: Colors.white,
          border: const Color(0xFF3A5424),
        );
      case PixelButtonVariant.ghost:
        return _PixelButtonColors(
          face: Colors.transparent,
          shadow: AppColors.border,
          label: AppColors.textPrimary,
          border: AppColors.border,
        );
      case PixelButtonVariant.surface:
        return _PixelButtonColors(
          face: AppColors.surfaceVariant,
          shadow: const Color(
            0xFF0D0D0D,
          ), // darker than bg → visible depth below
          label: AppColors.textPrimary,
          border: const Color(0xFF0D0D0D), // match shadow (like other variants)
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final depth = _pressed || _disabled ? 0.0 : _shadowDepth;
    final translateY = _pressed && !_disabled ? _shadowDepth : 0.0;

    return GestureDetector(
      onTapDown: (_) {
        if (_disabled) return;
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        if (_disabled) return;
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, translateY, 0),
        width: _boxSize,
        height: _boxSize,
        decoration: BoxDecoration(
          color: colors.face,
          border: Border.all(color: colors.border, width: 1.5),
          boxShadow: depth > 0
              ? [
                  BoxShadow(
                    color: colors.shadow,
                    offset: Offset(0, depth),
                    blurRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Icon(widget.icon, size: _iconSize, color: colors.label),
        ),
      ),
    );
  }
}

// =============================================================================
// INTERNAL: color config helper
// =============================================================================

class _PixelButtonColors {
  const _PixelButtonColors({
    required this.face,
    required this.shadow,
    required this.label,
    required this.border,
  });

  final Color face;
  final Color shadow;
  final Color label;
  final Color border;
}
