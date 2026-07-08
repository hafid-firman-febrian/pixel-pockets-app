# Pixel Pocket

> A local-first personal finance app for tracking income & expenses, with a retro/pixel-style UI.

Pixel Pocket is a Flutter app for recording daily transactions, viewing balance summaries, analyzing spending by category, and visualizing it through charts. It is **local-first**: all data lives on-device in an embedded SQLite database (Drift) and the app works **fully offline**. Google Sheets is used only as an **optional backup/restore** to move data between devices — there is no backend server to run.

---

## ✨ Features

- **Dashboard** — income/expense/balance summary, recent transactions, and spending breakdown by category.
- **Transactions** — create, edit, delete, filter (date/type/category/salary period), and search.
- **Categories** — manage income/expense categories (18 defaults seeded on first launch).
- **Salary Periods** — group transactions by pay period.
- **Chart** — daily/monthly income vs expense time-series (`fl_chart`).
- **Offline-first** — every screen is computed locally from Drift; no internet required.
- **Backup & Restore** — optional sync to **Google Sheets** (manual *Backup Now* / *Restore*), plus **auto-backup** after any change (debounced, non-blocking).
- **Security** — local app lock with a PIN (SHA-256). Google sign-in is only needed for backup.

---

## 🧱 Tech Stack

| Need | Package |
|---|---|
| State management | `flutter_riverpod` |
| Local database | `drift` + `sqlite3_flutter_libs` + `path_provider` |
| Navigation | `go_router` |
| Chart | `fl_chart` |
| Backup (cloud) | `googleapis` (Sheets v4 + Drive v3), `google_sign_in` (scope `drive.file`) |
| Local metadata | `shared_preferences` |
| Security | `crypto` (PIN hashing), `flutter_secure_storage` |
| Formatting | `intl` |
| UI / Font / Icon | `google_fonts`, `pixelarticons`, `skeletonizer` |
| Models | Manual `fromJson`/`toJson` — **no freezed**. Code generation is used **only** for Drift (`drift_dev` + `build_runner`). |

---

## 🏛️ Architecture

Logic and UI are separated. Each feature follows a 4-layer structure; the data layer is backed by **Drift** (local SQLite), so datasources are DAOs rather than HTTP wrappers.

```
features/<feature>/
├── data/
│   ├── datasources/   ← Drift DAO (queries the local database)
│   └── repositories/  ← map Drift rows ↔ domain, DB errors → Failure
├── domain/
│   └── models/        ← pure entities (no DB, no Flutter, no Riverpod)
├── application/
│   └── services/      ← business logic (no Riverpod, no widgets)
└── presentation/
    ├── states/        ← Riverpod providers
    ├── controllers/   ← Riverpod glue: call services, invalidate state
    ├── screens/       ← UI only
    └── widgets/
```

Summaries, per-category breakdowns, and chart series are all computed with Drift queries on-device. The detailed layer rules live in [CLAUDE.md](CLAUDE.md).

### Folder structure

```
lib/
├── core/
│   ├── database/   ← app_database (Drift), tables, default categories
│   ├── error/      ← failure.dart
│   ├── router/     ← app_router (go_router)
│   ├── theme/      ← color, sizing, spacing, text style
│   ├── utils/      ← currency_formatter
│   └── widgets/    ← reusable components (PixelCard, PixelButton, …)
├── features/
│   ├── auth/          ← PIN lock + Google sign-in (for backup)
│   ├── backup/        ← Google Sheets backup/restore + auto-backup
│   ├── dashboard/
│   ├── transactions/
│   ├── categories/
│   ├── salary_period/
│   ├── chart/
│   └── settings/
└── main.dart
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Dart `^3.10.3`)
- Android Studio / Xcode for an emulator/simulator

### Install & run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generate Drift code
flutter run
```

No backend is required — the app runs standalone and offline. On first launch it creates the local database and seeds 18 default categories.

### App icon

```bash
dart run flutter_launcher_icons
```

---

## 💾 Data & Backup

- **Source of truth:** the on-device Drift database. The app is fully usable offline with no account.
- **New user:** launch → set a PIN → start recording transactions (categories are pre-seeded).
- **Backup:** *Settings → Connect Google Sheets*, then **Backup Now**. Enable the **Auto-backup** toggle to sync automatically after changes. Backup is best-effort and never blocks saving.
- **Restore / new device:** install → *Connect Google Sheets* with the same Google account → **Restore**. Restore replaces local data with the spreadsheet contents (confirmation required).

> ⚠️ Backup is a copy, not real-time sync. Changes made offline are lost on device change only if they were never backed up — the Settings screen shows a "not backed up yet" indicator to warn you.

### Google Cloud setup (for backup)

Backup talks to Google Sheets + Drive directly using the non-sensitive `drive.file` scope. In the Google Cloud project whose OAuth client is set in [auth_config.dart](lib/features/auth/auth_config.dart):

1. Enable **Google Sheets API** and **Google Drive API**.
2. Add the scope `.../auth/drive.file` to the OAuth consent screen and **publish the app to Production** (no Google verification needed for `drive.file`).
3. Register the OAuth clients for your build:
   - **Android** — package name + the **signing SHA-1** (use the **release** keystore SHA-1 for distributed builds).
   - **iOS** — bundle ID + `GIDClientID` in `ios/Runner/Info.plist`.

---

## 🔐 Auth & Security

Routing is handled by [`go_router`](lib/core/router/app_router.dart):

`Splash → Set PIN (first launch) / Unlock (PIN) → Dashboard`

The app does **not** require Google login to use — the PIN is the app lock (stored as a local SHA-256 hash). Google sign-in is requested only when you connect Google Sheets for backup.

---

## 📦 Build & Distribute

```bash
flutter build apk        # Android APK
flutter build appbundle  # Android App Bundle (Play Store)
flutter build ipa        # iOS (requires an Apple Developer account)
```

For backup to work on a distributed build, register that build's **release SHA-1** in the Android OAuth client. End users then only need to install the app, set a PIN, and (optionally) connect their own Google account.

---

## 🧪 Testing

```bash
flutter test       # unit & widget tests (Drift runs on an in-memory database)
flutter analyze    # lint
```
