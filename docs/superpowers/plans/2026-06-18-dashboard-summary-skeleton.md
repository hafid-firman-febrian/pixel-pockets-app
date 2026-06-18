# Dashboard Summary Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **Catatan:** Langkah test sengaja DIHILANGKAN — Anda menulis test sendiri setelahnya. Tiap task diakhiri `flutter analyze` + commit.

**Goal:** Saat dashboard memuat ringkasan, komponen non-database (header, PeriodFilterCard, label) langsung tampil; hanya **angka dari API** (balance, income, expense, spent %, bar) yang ditampilkan sebagai skeleton sampai datanya datang.

**Architecture:** Pisahkan tanggung jawab. `TransactionSummaryCard` tetap **murni** — hanya mendeklarasikan bentuk dan menandai label dengan `Skeleton.keep`. **Screen** yang memutuskan kapan skeleton: `.when` dipersempit ke slot card, dan cabang `loading` membungkus card dengan `Skeletonizer`.

**Tech Stack:** Flutter, flutter_riverpod, package `skeletonizer`.

## Keputusan teknik (kenapa cara ini)

Dipilih: **screen membungkus `Skeletonizer` + card menandai label `Skeleton.keep`** (card tanpa flag `isLoading`).

| Alternatif | Kenapa tidak dipilih |
|---|---|
| Flag `isLoading` di dalam card + `Skeletonizer` di card | Mencampur logika loading ke widget presentasi → card jadi kurang reusable; concern tidak terpisah. |
| Widget skeleton terpisah yang menyalin layout card | Duplikasi layout → dua tempat harus dijaga sinkron. |
| `shimmer` manual + `_ShimmerBox` per angka | Banyak kode (`if (isLoading)` di tiap angka), perlu animasi sendiri. |

**Kenapa pilihan ini paling tepat (kecepatan + best practice):**
- **Best practice:** pemisahan tanggung jawab — card murni & reusable; "kapan skeleton" jadi urusan screen. `Skeleton.keep` bersifat deklaratif dan **tidak berefek** di luar `Skeletonizer`, jadi card tetap normal saat menampilkan data asli.
- **Cepat:** `Skeletonizer` hanya membungkus subtree card (bukan seluruh layar) dan menangani animasi shimmer secara efisien — tanpa `AnimationController` manual, tanpa cabang `if` per angka.

## Prasyarat

Plan ini melanjutkan hasil `2026-06-18-dashboard-period-filter.md` (Task 1–4 sudah ada): `dashboardSummaryProvider` dan `TransactionSummaryCard` sudah ada di kode. Kerjakan setelah period-filter selesai, di branch yang sama (`feature/dashboard-period-filter`) atau branch baru sesuai preferensi.

## Global Constraints

- Nama package `pixel_pocket`. Semua import pakai bentuk absolut `package:pixel_pocket/...`.
- `TransactionSummaryCard` **tetap murni** — TIDAK ada parameter `isLoading`. Label ("BALANCE", "INCOME"/"EXPENSE", "SPENT", divider, titik warna) ditandai `Skeleton.keep`. Angka dibiarkan polos → otomatis jadi bone.
- Skeletonisasi diaktifkan dari `dashboard_screen.dart`: `.when` dipersempit ke slot card; cabang `loading` membungkus card dengan `Skeletonizer` + kirim `summary` placeholder (nol) sekadar untuk bentuk bone.
- Error dibuat sederhana: satu baris pesan di slot card (header/period/label tetap tampil).
- Tidak ada trailer co-author di commit.
- Pengaman tiap task: `flutter analyze` tidak menambah issue; `flutter test` (suite yang ada) tetap lulus.
- Test untuk kode baru ditulis belakangan oleh Anda.

## File map

- Modify: `pubspec.yaml` — tambah dependency `skeletonizer`
- Modify: `lib/features/dashboard/presentation/screens/widgets/transaction_summary_card.dart`
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

> **Catatan test (untuk nanti):** widget test bagus di sini: (1) saat card dibungkus `Skeletonizer(enabled: true)`, label ("BALANCE", "SPENT", dll) tetap ditemukan (`find.text`), membuktikan `Skeleton.keep` bekerja; (2) `dashboard_screen` pada state loading menampilkan header + PeriodFilterCard + label "EXPENSES BY CATEGORY" (tidak hilang), berbeda dari sebelum perubahan.

---

## Task 1: Tambah dependency `skeletonizer`

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Tambah package**

Run:
```bash
flutter pub add skeletonizer
```
Expected: `pubspec.yaml` bertambah `skeletonizer: ^1.4.3` (atau versi terbaru), `flutter pub get` sukses.

- [ ] **Step 2: Analyze + commit**

```bash
flutter analyze
git add pubspec.yaml pubspec.lock
git commit -m "chore: add skeletonizer dependency"
```
Expected: analyze tidak menambah issue.

---

## Task 2: Card tetap murni + `Skeleton.keep` pada label

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/widgets/transaction_summary_card.dart`

**Interfaces:**
- Consumes: `TransactionSummary` (domain), tema (`AppColors`, `AppSpacing`, `AppTextStyles`), `CurrencyFormatter`, package `skeletonizer`.
- Produces: `TransactionSummaryCard({required TransactionSummary summary})` — tanpa flag loading; label dibungkus `Skeleton.keep`.

> **Penjelasan (belajar):** Card tidak tahu sedang loading atau tidak. Ia hanya menandai bagian mana yang **tetap solid** saat di-skeleton: semua label dibungkus `Skeleton.keep`. Angka (balance, income/expense, persen, bar) dibiarkan polos. Saat card TIDAK dibungkus `Skeletonizer` (menampilkan data asli), `Skeleton.keep` transparan — tidak mengubah apa pun. Saat dibungkus `Skeletonizer` oleh screen (Task 3), label tetap solid dan angka jadi bone. Inilah pemisahan tanggung jawabnya.

- [ ] **Step 1: Ganti isi `transaction_summary_card.dart`**

Ganti SELURUH isi `lib/features/dashboard/presentation/screens/widgets/transaction_summary_card.dart` dengan:
```dart
import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/utils/currency_formatter.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Card ringkasan — TETAP murni (tanpa flag loading). Label ditandai
/// [Skeleton.keep] supaya tetap solid bila card dibungkus [Skeletonizer]
/// dari layar. Di luar [Skeletonizer], [Skeleton.keep] tidak berefek.
class TransactionSummaryCard extends StatelessWidget {
  const TransactionSummaryCard({super.key, required this.summary});

  final TransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.border,
                offset: Offset(0, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: AppSpacing.card,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label statis — tetap solid walau di-skeleton
                  Skeleton.keep(
                    child: Text(
                      'BALANCE',
                      style: AppTextStyles.bodyNormal.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.item),
                  // Angka balance — jadi bone saat di-skeleton
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Rp ',
                          style: AppTextStyles.bodyNormal.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: CurrencyFormatter.formatWhileTyping(
                            summary.balance.toString(),
                          ),
                          style: AppTextStyles.numericXl.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.section),
                  Skeleton.keep(child: Divider(color: AppColors.border)),
                  SizedBox(height: AppSpacing.section),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TotalTransaction(summary: summary, isIncome: true),
                      SizedBox(width: AppSpacing.s24),
                      _TotalTransaction(summary: summary, isIncome: false),
                    ],
                  ),
                  SizedBox(height: AppSpacing.section),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Skeleton.keep(
                        child: Text('SPENT', style: AppTextStyles.overlineSm),
                      ),
                      Text(
                        summary.spentPercentageString,
                        style: AppTextStyles.overlineLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s4),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final percentage = summary.spentPercentage.clamp(0.0, 1.0);
                      final spentWidth = constraints.maxWidth * percentage;
                      return Container(
                        width: double.infinity,
                        height: 5,
                        decoration: BoxDecoration(color: AppColors.border),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: spentWidth,
                            height: 10,
                            decoration: BoxDecoration(color: AppColors.expense),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalTransaction extends StatelessWidget {
  const _TotalTransaction({
    required this.summary,
    required this.isIncome,
  });

  final TransactionSummary summary;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (titik warna + INCOME/EXPENSE) — tetap solid
        Skeleton.keep(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
              SizedBox(width: AppSpacing.s4),
              Text(
                isIncome ? 'INCOME' : 'EXPENSE',
                style: AppTextStyles.overlineSm,
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.s4),
        // Angka — jadi bone saat di-skeleton
        Text(
          CurrencyFormatter.format(
            isIncome ? summary.totalIncome : summary.totalExpense,
          ),
          style: AppTextStyles.bodyNormal.copyWith(
            color: isIncome ? AppColors.income : AppColors.expense,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Analyze + commit**

```bash
flutter analyze
git add lib/features/dashboard/presentation/screens/widgets/transaction_summary_card.dart
git commit -m "feat(dashboard): mark summary card labels with Skeleton.keep"
```
Expected: analyze tidak menambah issue.

---

## Task 3: Persempit `.when` + bungkus `Skeletonizer` di screen

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

**Interfaces:**
- Consumes: `dashboardSummaryProvider` (period-filter plan), `TransactionSummaryCard` (Task 2), `Skeletonizer` (package), tema, `authControllerProvider`.

> **Penjelasan (belajar):** `.when` TIDAK lagi membungkus seluruh `Scaffold body`. Header, `PeriodFilterCard`, dan label "EXPENSES BY CATEGORY" dipindah ke luar `.when` sehingga selalu tampil. Hanya **slot card** yang punya tiga keadaan: `loading` → `Skeletonizer(child: TransactionSummaryCard(summary: placeholder))` (label solid, angka bone); `error` → satu baris pesan; `data` → card dengan data asli. `_placeholderSummary` (nol) hanya memberi bentuk bone — angkanya tidak terlihat karena jadi tulang.

- [ ] **Step 1: Ganti isi `dashboard_screen.dart`**

Ganti SELURUH isi `lib/features/dashboard/presentation/screens/dashboard_screen.dart` dengan (sesuaikan bila screen Anda sudah berbeda — yang penting pola `.when` dipersempit ke slot card dan cabang `loading` dibungkus `Skeletonizer`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/period_filter_card.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/transaction_summary_card.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Nilai dummy hanya untuk memberi bentuk skeleton saat loading.
const _placeholderSummary = TransactionSummary(
  totalIncome: 0,
  totalExpense: 0,
  balance: 0,
  transactionCount: 0,
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.section),
          child: Column(
            children: [
              // ── Statis: selalu tampil ──────────────────────────────
              Padding(
                padding: AppSpacing.card,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '~\$ Pixel-Pocket',
                      style: AppTextStyles.displayMedium,
                    ),
                    PixelButton(
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                      variant: PixelButtonVariant.danger,
                      icon: Pixel.logout,
                      size: PixelButtonSize.sm,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.section),
              const PeriodFilterCard(),
              SizedBox(height: AppSpacing.section),
              Padding(
                padding: AppSpacing.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hanya slot card yang loading/error ───────────
                    summaryAsync.when(
                      loading: () => const Skeletonizer(
                        child: TransactionSummaryCard(
                          summary: _placeholderSummary,
                        ),
                      ),
                      error: (e, _) => Padding(
                        padding: AppSpacing.card,
                        child: const Text('Gagal memuat ringkasan.'),
                      ),
                      data: (summary) =>
                          TransactionSummaryCard(summary: summary),
                    ),
                    SizedBox(height: AppSpacing.section),
                    Text(
                      'EXPENSES BY CATEGORY',
                      style: AppTextStyles.bodyNormal,
                    ),
                    SizedBox(height: AppSpacing.section),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze + test**

```bash
flutter analyze
flutter test
```
Expected: analyze tidak menambah issue; smoke test yang ada tetap lulus.

- [ ] **Step 3: Verifikasi manual (jalankan app)**

Run: `flutter run` (login Google aktif).
Cek:
1. Saat dibuka, header, PeriodFilterCard, dan label di card ("BALANCE", "INCOME", "EXPENSE", "SPENT") **langsung muncul**.
2. Angka summary tampil sebagai **skeleton (bone beranimasi)** sampai data API datang, lalu berganti angka asli.
3. Ganti period → angka kembali skeleton sebentar lalu update.
4. Bila API gagal → slot card menampilkan teks "Gagal memuat ringkasan." (bagian lain tetap tampil).

- [ ] **Step 4: Commit**

```bash
git add lib/features/dashboard/presentation/screens/dashboard_screen.dart
git commit -m "feat(dashboard): skeletonize only summary numbers, keep static UI visible"
```

---

## Self-Review (saat penulisan plan)

- **Cakupan:** dependency (Task 1) ✓; card murni + `Skeleton.keep` (Task 2) ✓; screen persempit `.when` + `Skeletonizer` loading + error sederhana (Task 3) ✓. Per-field (label tampil, angka bone) terpenuhi via `Skeleton.keep`. ✓
- **Placeholder:** tidak ada TBD/TODO — tiap step berisi kode lengkap atau perintah konkret. ✓
- **Konsistensi tipe:** `TransactionSummaryCard({required summary})` (tanpa `isLoading`) konsisten antara Task 2 (definisi) dan Task 3 (pemakaian: `loading` pakai placeholder, `data` pakai summary asli). ✓
