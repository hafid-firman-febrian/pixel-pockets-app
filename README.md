# Pixel Pocket

> A personal finance app for tracking income & expenses, with a retro/pixel-style UI.

Pixel Pocket is a Flutter app for recording daily financial transactions, viewing balance summaries, analyzing spending by category, and visualizing it through charts. It connects to a REST backend deployed on Vercel.

---

## ✨ Features

- **Dashboard** — income/expense/balance summary, recent transactions, and spending breakdown by category.
- **Transactions** — list, create, update, and delete transactions with date & category filters plus search.
- **Categories** — manage income/expense categories (seed 18 default categories available).
- **Salary Periods** — group transactions by pay period.
- **Chart** — daily income vs expense time-series (`fl_chart`).
- **Auth & Security** — Google Sign-In login + local app lock with a PIN (SHA-256).
- **Backup** — export data to Google Sheets.

---

## 🧱 Tech Stack

| Need | Package |
|---|---|
| State management | `flutter_riverpod` |
| HTTP client | `dio` |
| Navigation | `go_router` |
| Chart | `fl_chart` |
| Auth | `google_sign_in`, `crypto` (PIN hashing) |
| Secure storage | `flutter_secure_storage` |
| Formatting | `intl` |
| UI / Font / Icon | `google_fonts`, `pixelarticons`, `skeletonizer` |
| JSON | Manual `toJson` / `fromJson` — **no freezed, no code gen** |

---

## 🏛️ Architecture

Logic and UI are separated. Each feature follows Clean Architecture with 4 layers:

```
features/<feature>/
├── data/
│   ├── datasources/   ← Dio/SDK wrapper, returns DTOs
│   ├── dtos/          ← fromJson / toJson + mapping to domain
│   └── repositories/  ← map DTO↔domain, DioException → Failure
├── domain/
│   └── models/        ← pure entities (no JSON, Dio, Flutter)
├── application/
│   └── services/      ← business logic (no Riverpod, no widgets)
└── presentation/
    ├── states/        ← Riverpod providers
    ├── controllers/   ← Riverpod glue: call services, invalidate state
    ├── screens/       ← UI only
    └── widgets/
```

The detailed rules for each layer live in [CLAUDE.md](CLAUDE.md).

### Main folder structure

```
lib/
├── core/
│   ├── api/        ← api_client, api_endpoints, auth_interceptor
│   ├── error/      ← failure.dart
│   ├── router/     ← app_router (go_router)
│   ├── theme/      ← color, sizing, spacing, text style
│   ├── utils/      ← currency_formatter
│   └── widgets/    ← reusable components (PixelCard, PixelButton, etc.)
├── features/
│   ├── auth/
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
flutter run
```

### Backend configuration

The base URL is selected automatically by [`ApiClient`](lib/core/api/api_client.dart). By default **all builds use production** (Vercel):

| Environment | Base URL |
|---|---|
| Production (default) | `https://<your-project>.vercel.app` |
| Android emulator (dev) | `http://10.0.2.2:3000` |
| iOS simulator (dev) | `http://localhost:3000` |

To use a local server during development, set `_useLocalDevServer = true` in [api_client.dart](lib/core/api/api_client.dart).

### Google Sign-In configuration

Fill in the OAuth Client ID in [auth_config.dart](lib/features/auth/auth_config.dart). `serverClientId` must match the client ID verified by the backend (it becomes the `aud` claim on the ID token). The iOS Client ID is best set via `GIDClientID` in `ios/Runner/Info.plist`.

### App icon

```bash
flutter pub run flutter_launcher_icons
```

---

## 🔌 API

All responses are wrapped in a `"data"` key (paginated lists also include `"meta"`).

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/google` | Log in with a Google ID token |
| POST | `/api/auth/refresh` | Refresh the session token |
| POST | `/api/auth/logout` | Log out |
| GET | `/api/auth/me` | User profile |
| GET | `/api/categories` | List categories |
| POST | `/api/categories/seed` | Seed 18 default categories |
| GET | `/api/salary-periods` | List salary periods |
| GET | `/api/transactions` | List transactions (filter + pagination) |
| POST/PUT/DELETE | `/api/transactions/:id` | Transaction CRUD |
| GET | `/api/summary` | Total income/expense/balance |
| GET | `/api/summary/by-category` | Breakdown by category |
| GET | `/api/summary/chart` | Time-series for the chart |
| POST | `/api/backup/spreadsheet` | Export to Google Sheets |

Date filters accepted by the transactions & summary endpoints: `salary_period_id`, `filter` (`week`/`month`/`year`/`custom`), `start_date`, `end_date`, `transaction_type`, `category_id`. The full list lives in [api_endpoints.dart](lib/core/api/api_endpoints.dart).

---

## 🔐 Auth Flow

Routing is handled by [`go_router`](lib/core/router/app_router.dart) based on auth state:

`Splash → Login (Google) → Set PIN (first time) → Unlock (PIN) → Dashboard`

The session token is stored securely in `flutter_secure_storage`; the PIN is stored as a local SHA-256 hash and used to lock the app.

---

## 🧪 Testing

```bash
flutter test                  # unit & widget tests
flutter test integration_test # integration tests
flutter analyze               # lint
```
