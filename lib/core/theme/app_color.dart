import 'dart:ui';

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
  static const primary = Color(0xFFFFD65A); // yellow
  static const secondary = Color(0xFFFF9D23); // orange  ← diubah
  static const textDark = Color(0xFF3A332C); // espresso
  static const income = Color(0xFF5B7E3C); // green   ← diubah
  static const expense = Color(0xFFEA5252); // red     ← diubah
  static const divider = Color(0xFFE3DACB);

  // ── Background ──────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF242424);
  static const Color surfaceVariant = Color(0xFF2E2E2E);
  static const Color border = Color(0xFF3A3A3A);

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0ECE4);
  static const Color textSecondary = Color(0xFFB0A898);
  static const Color textMuted = Color(0xFF6E6460);

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
