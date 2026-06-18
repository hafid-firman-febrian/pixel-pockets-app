import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';

/// TextStyle untuk Pixel Pocket.
///
/// Hierarki:
/// - [numeric]  → angka/nominal uang
/// - [title]    → judul layar dan heading
/// - [body]     → konten utama list item
/// - [overline] → label uppercase muted (section, field, nav)
/// - [caption]  → teks kecil pendukung (kategori, tanggal)
/// - [button]   → teks interaktif (button, chip, toggle)
/// - [input]    → teks dalam input field
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  // ── Heading ─────────────────────────────────────────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Numeric — angka & nominal uang ─────────────────────────────────────────
  /// Nominal utama (balance card).
  /// 28px · bold · tracking -0.5 · tabular
  static const TextStyle numericXl = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Nominal ringkasan (income / expense row).
  /// 13px · semibold · tabular
  static const TextStyle numericLg = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Nominal list item.
  /// 11px · bold · tabular
  static const TextStyle numericMd = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ── Title — judul layar & heading ──────────────────────────────────────────
  /// Judul AppBar.
  /// 14px · bold · tracking 0.5
  static const TextStyle titleLg = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  /// Judul section / heading card.
  /// 12px · semibold
  static const TextStyle titleMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body — konten list item ─────────────────────────────────────────────────
  /// Nama utama list item (nama transaksi).
  /// 11px · semibold
  static const TextStyle bodyBold = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Teks body normal.
  /// 12px · regular
  static const TextStyle bodyNormal = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Overline — label uppercase muted ───────────────────────────────────────
  /// Section header (RECENT, BALANCE, PERIOD).
  /// 9px · medium · tracking 2
  static const TextStyle overlineLg = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 2,
  );

  /// Label field form (AMOUNT, DATE, CATEGORY).
  /// 8px · medium · tracking 2
  static const TextStyle overlineMd = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 2,
  );

  /// Label kecil (progress label, balance item label).
  /// 8px · medium · tracking 1.5
  static const TextStyle overlineSm = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 1.5,
  );

  // ── Caption — teks kecil pendukung ─────────────────────────────────────────
  /// Sub-label list item (nama kategori).
  /// 9px · regular · tracking 0.5
  static const TextStyle captionMd = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  /// Teks terkecil (tanggal, hint).
  /// 8px · regular
  static const TextStyle captionSm = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  // ── Button — teks interaktif ────────────────────────────────────────────────
  /// Teks button besar / FAB.
  /// 12px · bold · tracking 1
  static const TextStyle buttonLg = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );

  /// Teks button standar.
  /// 11px · bold · tracking 1
  static const TextStyle buttonMd = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );

  /// Teks chip / filter / toggle.
  /// 9px · semibold · tracking 1
  static const TextStyle buttonSm = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
  );

  // ── Input — teks dalam field ────────────────────────────────────────────────
  /// Teks input field aktif (nominal diketik).
  /// 20px · bold
  static const TextStyle inputLg = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Teks input field normal.
  /// 12px · regular
  static const TextStyle inputMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Prefix / suffix input (Rp, %).
  /// 12px · regular · secondary color
  static const TextStyle inputAffix = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Navigation ─────────────────────────────────────────────────────────────
  /// Label bottom nav item.
  /// 8px · tracking 1 · warna berubah berdasarkan active state
  static TextStyle navLabel({bool active = false}) => TextStyle(
    fontSize: 8,
    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
    color: active ? AppColors.primary : AppColors.textMuted,
    letterSpacing: 1,
  );
}
