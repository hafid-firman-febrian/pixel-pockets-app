# Pixel Pocket

**A local-first personal finance app for tracking income and expenses, built with Flutter and a retro pixel-art UI.**

Pixel Pocket records daily transactions, summarises balances, breaks spending down by category, and charts it over time. Every screen is computed on-device from an embedded SQLite database (Drift), so the app works **fully offline with no account and no backend to run**. Google Sheets is supported purely as an *optional* backup target for moving data between devices.

---

## Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Data & Backup](#data--backup)
- [Auth & Security](#auth--security)
- [Build & Distribution](#build--distribution)
- [Testing](#testing)

---

## Features

| Area | Capabilities |
|---|---|
| **Dashboard** | Income / expense / balance summary, recent transactions, spending breakdown by category |
| **Transactions** | Create, edit, delete, search by description or category, and filter by date range, type, category, or salary period |
| **Categories** | Manage income and expense categories — 18 defaults seeded on first launch |
| **Salary Periods** | Group transactions by pay period instead of calendar month |
| **Chart** | Income vs. expense time series — daily for week/month ranges, monthly for a full year (`fl_chart`) |
| **Offline-first** | No network required; every summary and chart is a local Drift query |
| **Backup & Restore** | Optional Google Sheets sync — manual *Backup Now* / *Restore*, plus debounced auto-backup after changes |
| **Security** | Local app lock via PIN (per-PIN random salt + SHA-256, held in `flutter_secure_storage`) |

---

## Tech Stack

| Need | Package |
|---|---|
| State management | `flutter_riverpod` |
| Local database | `drift`, `sqlite3_flutter_libs`, `path_provider`, `path` |
| Navigation | `go_router` |
| Charts | `fl_chart` |
| Backup (optional) | `googleapis` (Sheets v4 + Drive v3), `google_sign_in` (scope `drive.file`), `http` |
| Local metadata | `shared_preferences` |
| Security | `crypto` (salted SHA-256), `flutter_secure_storage` |
| Formatting | `intl` |
| UI, fonts, icons | `google_fonts`, `pixelarticons`, `skeletonizer` |
| Launch screen & icon | `flutter_native_splash`, `flutter_launcher_icons` |

**Models are pure domain entities** — no `fromJson` / `toJson`, no `freezed`. Code generation is used *only* for Drift (`drift_dev` + `build_runner`).

---

## Architecture

Logic and UI are strictly separated. Features that own data follow four layers; the data layer is backed by Drift, so datasources are DAOs rather than HTTP clients.

```
features/<feature>/
├── data/
│   ├── datasources/       Drift DAO — queries AppDatabase, maps rows to domain models
│   └── repositories/      Thin pass-through to the DAO
├── domain/
│   └── models/            Pure entities (no Drift, no Flutter, no Riverpod)
├── application/
│   └── services/          Business logic (no Riverpod, no widgets)
└── presentation/
    ├── states/            Riverpod providers
    ├── controllers/       Riverpod glue — call services, invalidate state
    └── screens/
        └── widgets/       Widgets local to those screens
```

### Layer rules

| Layer | May use | Must not use |
|---|---|---|
| `domain/models` | Pure entities, getters | JSON, Drift, Flutter, Riverpod |
| `data/datasources` | `AppDatabase` (Drift), domain models | Riverpod state, widgets |
| `data/repositories` | Datasources, domain models, `Failure` | Drift directly, widgets |
| `application/services` | Repositories, domain models | Riverpod state, widgets |
| `presentation/states` | Riverpod, services via DI | Drift, parsing |
| `presentation/controllers` | Riverpod `Ref`, services | Drift, parsing |
| `presentation/screens` + `widgets` | Widgets, `ref.watch` | Drift, parsing, business logic |

There is no `dtos/` layer. Drift generates typed row classes from a schema we own ([tables.dart](lib/core/database/tables.dart)) rather than an external wire format, so row → domain mapping happens inline in the DAO and repositories stay pass-through. `Failure` mapping is applied only where an external SDK is involved: [auth](lib/features/auth/data/repositories/auth_repository.dart) (`google_sign_in`) and [backup](lib/features/backup/data/repositories/backup_repository.dart) (Sheets/Drive).

### Layers per feature

Not every feature needs all four layers. What each one actually carries:

| Feature | `data` | `domain` | `application` | `presentation` |
|---|:---:|:---:|:---:|:---:|
| `transactions`, `categories`, `salary_period`, `chart`, `dashboard`, `auth` | ✓ | ✓ | ✓ | ✓ |
| `backup` | ✓ | — | ✓ | ✓ |
| `settings` | — | — | — | ✓ |

Deliberate exceptions, so they are not mistaken for drift:

- **`backup` has no `domain/`.** [`backup_serialization.dart`](lib/features/backup/data/backup_serialization.dart) serialises Drift row classes directly, since a backup is a snapshot of the database rather than a business entity. For the same reason it sits at the root of `data/` instead of under `datasources/`.
- **`backup/application/auto_backup_coordinator.dart`** sits at the root of `application/` rather than in `services/`. It is a scheduler (debounce timer + dirty flag), not a business service.
- **`settings` is presentation-only.** [`settings_screen.dart`](lib/features/settings/presentation/screens/settings_screen.dart) is a composition surface — it renders widgets and controllers owned by `auth`, `backup`, `categories`, and `salary_period`, and holds no state of its own.
- **`auth` keeps widgets at `presentation/widgets/`** rather than nested under `screens/`, because `PinScaffold`, `PinDots`, and `PixelPinPad` are shared between the Set PIN and Unlock screens. Every other feature nests widgets under the screens that use them.

The rules above are also documented for contributors in [CLAUDE.md](CLAUDE.md).

---

## Project Structure

```
lib/
├── core/
│   ├── cache/       shared_preferences wrapper (local metadata, not an API cache)
│   ├── database/    app_database.dart (Drift), tables.dart, default_categories.dart
│   ├── error/       failure.dart
│   ├── router/      app_router.dart (go_router)
│   ├── theme/       app_theme, app_color, app_sizing, app_spacing, app_text_style
│   ├── utils/       currency & thousands-separator formatters
│   └── widgets/     shared pixel components (PixelCard, PixelButton, PixelChip, …)
├── features/
│   ├── auth/            PIN lock + Google sign-in (for backup)
│   ├── backup/          Google Sheets backup/restore + auto-backup
│   ├── categories/
│   ├── chart/
│   ├── dashboard/
│   ├── salary_period/
│   ├── settings/
│   └── transactions/
└── main.dart
```

The Drift schema (`schemaVersion` 1) holds three tables: `Categories`, `SalaryPeriods`, and `Transactions`.

---

## Getting Started

### Prerequisites

- Flutter SDK with Dart `^3.10.3`
- Android Studio or Xcode for an emulator/simulator
- Targets: Android (Flutter's default `minSdk`) and iOS 13.0+

### Install and run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generate Drift code
flutter run
```

No backend is required. On first launch the app creates the local database and seeds 18 default categories. Backup is optional and needs [its own setup](#google-cloud-setup) — every other feature works without it.

### Regenerating icon and splash

Run after changing `assets/icons/app_icon.png` or the splash colours in `pubspec.yaml`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## Data & Backup

- **Source of truth** — the on-device Drift database. Fully usable offline, no account needed.
- **First run** — launch, set a PIN, start recording. Categories are pre-seeded.
- **Backup** — *Settings → Connect Google Sheets*, then **Backup Now**. Enable **Auto-backup** to sync after changes; it is debounced and best-effort, and never blocks a save.
- **Restore** — install on the new device, connect the same Google account, then **Restore**. This replaces local data with the spreadsheet contents and requires confirmation.

> **Backup is a copy, not real-time sync.** Offline changes are lost on a device switch only if they were never backed up. The Settings screen surfaces the last backup time so you can tell.

### Google Cloud setup

Backup talks to Google Sheets and Drive directly using the non-sensitive `drive.file` scope, and requires **your own** Google Cloud project:

1. Enable the **Google Sheets API** and **Google Drive API**.
2. Add the `.../auth/drive.file` scope to the OAuth consent screen and publish the app to **Production**. No Google verification is needed for `drive.file`.
3. Register OAuth clients for your builds:
   - **Android** — package name plus the signing SHA-1. Use the **release** keystore SHA-1 for distributed builds.
   - **iOS** — bundle ID.
4. Point the app at your clients:
   - `AuthConfig.serverClientId` in [auth_config.dart](lib/features/auth/auth_config.dart) — replace the checked-in Web client ID.
   - `GIDClientID` in [ios/Runner/Info.plist](ios/Runner/Info.plist) — still the placeholder `IOS_CLIENT_ID.apps.googleusercontent.com`, so **backup does not work on iOS until this is filled in**.

> The client ID committed in `auth_config.dart` belongs to the original project. Forking this repo without replacing it will make sign-in fail or reach someone else's OAuth client. Swap it before shipping.

---

## Auth & Security

Routing is handled by [`go_router`](lib/core/router/app_router.dart):

```
Splash → Set PIN (first launch) / Unlock → Dashboard
```

Google login is **not** required to use the app — the PIN is the app lock. It is never stored in plaintext: [`PinService`](lib/features/auth/application/services/pin_service.dart) derives a per-PIN random salt from `Random.secure()`, hashes `salt:pin` with SHA-256, and keeps the hash and salt in `flutter_secure_storage`. Google sign-in is requested only when connecting Google Sheets for backup.

---

## Build & Distribution

```bash
flutter build apk        # Android APK
flutter build appbundle  # Android App Bundle (Play Store)
flutter build ipa        # iOS — requires an Apple Developer account
```

For backup to work on a distributed build, register that build's **release SHA-1** in the Android OAuth client. End users then only need to install the app, set a PIN, and optionally connect their own Google account.

---

## Testing

```bash
flutter test              # unit & widget tests
flutter test --coverage   # writes coverage/lcov.info
flutter analyze           # lint
```

19 test files run entirely against an in-memory Drift database, so no device, network, or Google account is needed:

| Scope | Covered |
|---|---|
| DAOs | Transactions, categories, salary periods, chart, summary, plus range-filter behaviour |
| Services | PIN hashing and verification, dashboard aggregation, auth controller |
| Backup | Serialization, restore, full-database replace, auto-backup coordinator, metadata store |
| Core | Database setup, cache store, `Failure` mapping, `PixelErrorView` widget |
