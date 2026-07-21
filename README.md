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
- **Security** — local app lock with a PIN (per-PIN random salt + SHA-256, stored in `flutter_secure_storage`). Google sign-in is only needed for backup.

---

## 🧱 Tech Stack

| Need | Package |
|---|---|
| State management | `flutter_riverpod` |
| Local database | `drift` + `sqlite3_flutter_libs` + `path_provider` + `path` |
| Navigation | `go_router` |
| Chart | `fl_chart` |
| Backup (cloud) | `googleapis` (Sheets v4 + Drive v3), `google_sign_in` (scope `drive.file`), `http` |
| Local metadata | `shared_preferences` |
| Security | `crypto` (salted SHA-256 PIN hashing), `flutter_secure_storage` |
| Formatting | `intl` |
| UI / Font / Icon | `google_fonts`, `pixelarticons`, `skeletonizer` |
| Launch screen / icon | `flutter_native_splash`, `flutter_launcher_icons` |
| Models | Pure domain entities — **no `fromJson`/`toJson`**, no freezed. Code generation is used **only** for Drift (`drift_dev` + `build_runner`). |

---

## 🏛️ Architecture

Logic and UI are separated. Each feature follows a 4-layer structure; the data layer is backed by **Drift** (local SQLite), so datasources are DAOs rather than HTTP wrappers.

```
features/<feature>/
├── data/
│   ├── datasources/   ← Drift DAO: query the database, map rows → domain models
│   └── repositories/  ← thin pass-through to the DAO
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

Summaries, per-category breakdowns, and chart series are all computed with Drift queries on-device.

There is no `dtos/` layer. Drift generates typed row classes from a schema we own ([tables.dart](lib/core/database/tables.dart)) rather than an external wire format, so the row → domain mapping is done inline in the DAO and repositories stay pass-through. `Failure` mapping only happens where an external SDK is involved — [auth](lib/features/auth/data/repositories/auth_repository.dart) (`google_sign_in`) and [backup](lib/features/backup/data/repositories/backup_repository.dart) (Sheets/Drive). The detailed layer rules live in [CLAUDE.md](CLAUDE.md).

### Folder structure

```
lib/
├── core/
│   ├── cache/      ← shared_preferences wrapper (local metadata, not an API cache)
│   ├── database/   ← app_database (Drift), tables, default categories
│   ├── error/      ← failure.dart
│   ├── router/     ← app_router (go_router)
│   ├── theme/      ← theme, color, sizing, spacing, text style
│   ├── utils/      ← currency & thousands-separator formatters
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
- Target platforms: Android API 24+ (Flutter default `minSdk`) / iOS 13.0+

### Install & run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generate Drift code
flutter run
```

No backend is required — the app runs standalone and offline. On first launch it creates the local database and seeds 18 default categories.

Backup is optional and needs its own setup — see [Google Cloud setup](#google-cloud-setup-for-backup). Without it every other feature still works.

### App icon & launch screen

Regenerate after changing `assets/icons/app_icon.png` or the splash colors in `pubspec.yaml`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## 💾 Data & Backup

- **Source of truth:** the on-device Drift database. The app is fully usable offline with no account.
- **New user:** launch → set a PIN → start recording transactions (categories are pre-seeded).
- **Backup:** *Settings → Connect Google Sheets*, then **Backup Now**. Enable the **Auto-backup** toggle to sync automatically after changes. Backup is best-effort and never blocks saving.
- **Restore / new device:** install → *Connect Google Sheets* with the same Google account → **Restore**. Restore replaces local data with the spreadsheet contents (confirmation required).

> ⚠️ Backup is a copy, not real-time sync. Changes made offline are lost on device change only if they were never backed up — the Settings screen shows a "not backed up yet" indicator to warn you.

### Google Cloud setup (for backup)

Backup talks to Google Sheets + Drive directly using the non-sensitive `drive.file` scope. It needs your **own** Google Cloud project:

1. Enable **Google Sheets API** and **Google Drive API**.
2. Add the scope `.../auth/drive.file` to the OAuth consent screen and **publish the app to Production** (no Google verification needed for `drive.file`).
3. Register the OAuth clients for your build:
   - **Android** — package name + the **signing SHA-1** (use the **release** keystore SHA-1 for distributed builds).
   - **iOS** — bundle ID.
4. Point the app at your clients:
   - `AuthConfig.serverClientId` in [auth_config.dart](lib/features/auth/auth_config.dart) — replace the checked-in Web client ID with yours.
   - `GIDClientID` in [ios/Runner/Info.plist](ios/Runner/Info.plist) — currently the placeholder `IOS_CLIENT_ID.apps.googleusercontent.com`, so **backup does not work on iOS until this is filled in**.

> The client ID committed in `auth_config.dart` belongs to the original project. If you fork this repo and leave it as is, sign-in will fail (or hit someone else's OAuth client) — swap it before shipping.

---

## 🔐 Auth & Security

Routing is handled by [`go_router`](lib/core/router/app_router.dart):

`Splash → Set PIN (first launch) / Unlock (PIN) → Dashboard`

The app does **not** require Google login to use — the PIN is the app lock. It is never stored in plaintext: [`PinService`](lib/features/auth/application/services/pin_service.dart) hashes it with a per-PIN random salt (SHA-256) and keeps hash + salt in `flutter_secure_storage`. Google sign-in is requested only when you connect Google Sheets for backup.

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
flutter test              # unit & widget tests (Drift runs on an in-memory database)
flutter test --coverage   # writes coverage/lcov.info
flutter analyze           # lint
```

Tests cover the DAOs (transactions, categories, salary periods, chart, summary), the PIN service, and backup serialization / restore / auto-backup — all against an in-memory Drift database, so no device or Google account is needed.
