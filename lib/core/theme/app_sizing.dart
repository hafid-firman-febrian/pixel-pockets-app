class AppSizing {
  AppSizing._();

  // ── Icon ───────────────────────────────────────────────────────────────────
  static const double iconSm = 14; // icon dalam SVG / button kecil
  static const double iconMd = 16; // icon navigasi
  static const double iconLg = 20; // icon standar
  static const double iconXl = 24; // icon besar / FAB

  // ── Touchable (button, icon button) ───────────────────────────────────────
  static const double touchSm = 32; // icon button appbar
  static const double touchMd = 44; // button utama, FAB, input field
  static const double touchLg = 52; // button besar

  // ── Indicator (dot, bar) ───────────────────────────────────────────────────
  static const double dotSm = 6; // dot income/expense label
  static const double dotMd = 8; // dot warna kategori

  static const double barXs = 3; // color bar list item (lebar)
  static const double barSm = 4; // progress bar (tinggi)
  static const double barMd = 28; // color bar list item (tinggi dashboard)
  static const double barLg = 32; // color bar list item (tinggi transaction)

  // ── Navigation ─────────────────────────────────────────────────────────────
  static const double navHeight = 60; // tinggi bottom nav bar
  static const double navIndicator = 24; // lebar garis aktif atas icon
  static const double navIndicatorH = 2; // tinggi garis aktif atas icon

  // ── Border ─────────────────────────────────────────────────────────────────
  static const double borderThin = 1; // divider dalam list
  static const double borderNormal = 1.5; // card, input, button
  static const double borderThick = 2; // container utama / emphasis

  // ── Pixel shadow depth ─────────────────────────────────────────────────────
  static const double shadowSm = 2; // ghost button, secondary
  static const double shadowMd = 3; // button normal
  static const double shadowLg = 4; // primary button, card
  static const double shadowXl = 5; // button besar
}
