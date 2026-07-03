import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'core/cache/cache_store.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PixelPocketApp(),
    ),
  );
}

class PixelPocketApp extends ConsumerWidget {
  const PixelPocketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Remove the native splash once we know where to route (no longer unknown).
    ref.listen(authControllerProvider, (previous, next) {
      if (next is! AuthUnknown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FlutterNativeSplash.remove();
        });
      }
    });

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
