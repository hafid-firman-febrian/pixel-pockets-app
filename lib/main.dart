import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: PixelPocketApp()));
}

class PixelPocketApp extends ConsumerWidget {
  const PixelPocketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonizerConfig(
      data: SkeletonizerConfigData.dark().copyWith(
        // preset tema gelap
        effect: const ShimmerEffect(
          baseColor: AppColors.surfaceVariant,
          highlightColor: AppColors.border, // lebih terang dari base
          duration: Duration(milliseconds: 1100),
        ),
        textBorderRadius: const TextBoneBorderRadius(
          BorderRadius.all(Radius.circular(0)),
        ),
      ),
      child: MaterialApp.router(
        title: 'Pixel Pocket',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
