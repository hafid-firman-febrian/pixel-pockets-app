import 'package:flutter/material.dart';

/// Retro color scheme + Material 3 theme for Pixel Pocket.
///
/// The category colors mirror the API seed data exactly so that a
/// transaction's `categoryColor` (a hex string) lines up with these.
class AppColors {
  AppColors._();

  // ---- Expense category colors (from seed) ----
  static const groceries = Color(0xFF7D9B76); // sage green
  static const beverage = Color(0xFF5F8A8B); // teal
  static const coffee = Color(0xFF8B6355); // warm brown
  static const cigarettes = Color(0xFF8C7B6B); // taupe
  static const dailyNeeds = Color(0xFFC4A882); // warm tan
  static const ecommerce = Color(0xFF6B7C8D); // slate blue
  static const entertainment = Color(0xFF9B6B8C); // dusty mauve
  static const housing = Color(0xFFB5847A); // dusty rose
  static const meal = Color(0xFFCC7358); // terracotta
  static const selfcare = Color(0xFFA0856C); // sand
  static const subscription = Color(0xFF7B6D8D); // muted purple
  static const transport = Color(0xFF4A7C8C); // dark teal
  static const other = Color(0xFF8C8C7B); // warm gray

  // ---- Income category colors (from seed) ----
  static const salary = Color(0xFF6B8C5F); // muted green
  static const freelance = Color(0xFF5B7A8C); // dusty blue
  static const investment = Color(0xFF8C7A3D); // golden brown
  static const bonus = Color(0xFF8C5B3D); // burnt sienna
  static const otherIncome = Color(0xFF7A8C6B); // sage olive

  // ---- App palette ----
  static const background = Color(0xFFF4EFE6); // warm cream
  static const surface = Color(0xFFFBF8F1); // lighter cream
  static const primary = Color(0xFFCC7358); // terracotta accent
  static const secondary = Color(0xFF5F8A8B); // teal accent
  static const textDark = Color(0xFF3A332C); // espresso
  static const textMuted = Color(0xFF8C8378); // muted taupe
  static const income = Color(0xFF6B8C5F); // green
  static const expense = Color(0xFFCC5B4A); // red-terracotta
  static const divider = Color(0xFFE3DACB);

  /// Parses an API hex color string (e.g. `"#CC7358"`) into a [Color].
  /// Falls back to [AppColors.other] when null or malformed.
  static Color fromHex(String? hex) {
    if (hex == null) return other;
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? other : Color(parsed);
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onSurface: AppColors.textDark,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
