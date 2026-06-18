// ─────────────────────────────────────────────
// Model satu tab
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';

class PixelNavItem {
  const PixelNavItem({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}

// ─────────────────────────────────────────────
// Bottom nav bar
// ─────────────────────────────────────────────
class PixelBottomNav extends StatelessWidget {
  const PixelBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<PixelNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(
              items.length,
              (i) => _PixelNavTab(
                item: items[i],
                isActive: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Satu tab — dengan animasi tekan
// ─────────────────────────────────────────────
class _PixelNavTab extends StatefulWidget {
  const _PixelNavTab({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final PixelNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_PixelNavTab> createState() => _PixelNavTabState();
}

class _PixelNavTabState extends State<_PixelNavTab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          color: _pressed ? AppColors.surfaceVariant : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Garis aktif di atas icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: 2,
                width: widget.isActive ? 24 : 0,
                color: AppColors.primary,
                margin: const EdgeInsets.only(bottom: 6),
              ),

              // Icon
              Icon(widget.item.icon, size: 20, color: color),

              const SizedBox(height: 4),

              // Label
              Text(
                widget.item.label,
                style: TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 8,
                  fontWeight: widget.isActive
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: color,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
