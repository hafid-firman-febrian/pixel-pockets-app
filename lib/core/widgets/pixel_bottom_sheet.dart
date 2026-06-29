import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixelarticons/pixel.dart';

/// Bottom-sheet frame in the pixel-card style — surface fill, hard border, 3D
/// offset shadow, sharp corners — with a title + close header. Shared by the
/// period picker and the transaction form so all sheets look the same.
///
/// Open it with `showModalBottomSheet(backgroundColor: Colors.transparent, ...)`.
class PixelBottomSheetFrame extends StatelessWidget {
  const PixelBottomSheetFrame({
    super.key,
    required this.child,
    required this.title,
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Lift the sheet above the on-screen keyboard when a field is focused.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s16 + keyboard,
        ),
        child: Container(
          width: size.width,
          constraints: BoxConstraints(maxHeight: size.height * 0.85),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.border,
                offset: Offset(0, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PixelSheetHeader(title: title),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _PixelSheetHeader extends StatelessWidget {
  const _PixelSheetHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s8,
        AppSpacing.s12,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headingSmall,
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.s4),
              child: Icon(
                Pixel.close,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
