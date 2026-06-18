import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // ── Base scale ─────────────────────────────────────────────────────────────
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;

  // ── Screen ─────────────────────────────────────────────────────────────────
  /// Padding kiri-kanan konten utama layar.
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: s16);

  /// Padding konten scroll (semua sisi).
  static const EdgeInsets screenAll = EdgeInsets.all(s16);

  // ── Header / AppBar ────────────────────────────────────────────────────────
  /// Padding AppBar dan row header (period bar, filter row).
  static const EdgeInsets header = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s12,
  );

  /// Padding row tipis (period selector, sub-header).
  static const EdgeInsets headerSm = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s8,
  );

  // ── Section ────────────────────────────────────────────────────────────────
  /// Padding group label di dalam list (date group header).
  static const EdgeInsets sectionLabel = EdgeInsets.fromLTRB(s16, s8, s16, s4);

  // ── Card ───────────────────────────────────────────────────────────────────
  /// Padding dalam card / balance card.
  static const EdgeInsets card = EdgeInsets.all(s16);

  // ── List item ──────────────────────────────────────────────────────────────
  /// Padding list item dengan horizontal lebih sempit (dashboard recent).
  static const EdgeInsets listItemSm = EdgeInsets.symmetric(
    horizontal: s12,
    vertical: s10,
  );

  /// Padding list item standar (transaction screen).
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s10,
  );

  // ── Chip / Badge ───────────────────────────────────────────────────────────
  /// Padding filter chip, tag, badge kecil.
  static const EdgeInsets chip = EdgeInsets.symmetric(
    horizontal: s10,
    vertical: s4,
  );

  // ── Input ──────────────────────────────────────────────────────────────────
  /// Padding dalam input field.
  static const EdgeInsets input = EdgeInsets.symmetric(
    horizontal: s12,
    vertical: s10,
  );

  // ── Form ───────────────────────────────────────────────────────────────────
  /// Padding screen form (tambah/edit transaksi).
  static const EdgeInsets form = EdgeInsets.all(s16);

  // ── Button ─────────────────────────────────────────────────────────────────
  /// Padding dalam button icon kecil (appbar action).
  static const EdgeInsets iconBtn = EdgeInsets.all(s10);

  // ── Navigation ─────────────────────────────────────────────────────────────
  /// Padding item bottom nav.
  static const EdgeInsets navItem = EdgeInsets.fromLTRB(s4, s10, s4, s12);

  /// Padding wrapper FAB / tombol di bawah layar.
  static const EdgeInsets fab = EdgeInsets.fromLTRB(s16, 0, s16, s12);

  static const double section = s16;

  static const double item = s12;
}
