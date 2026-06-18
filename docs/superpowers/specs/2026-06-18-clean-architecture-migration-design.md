# Clean Architecture Migration — Pixel Pocket

**Date:** 2026-06-18
**Branch:** `refactor/clean-architecture`
**Type:** Structural refactor (no behavior change)

## Goal

Migrate the codebase from the current simpler 4-layer feature structure
(`models` / `repositories` / `providers` / `screens`) to the full Clean
Architecture described in `_imageRef/riverpod_architecture.png`:

- **Presentation Layer** — Widgets → States → Controllers
- **Application Layer** — Services
- **Domain Layer** — Models (pure)
- **Data Layer** — Repositories → DTOs → Data Sources

## Decisions (locked)

| Decision | Choice |
|---|---|
| Target architecture | Full Clean Architecture (all diagram boxes) |
| Data Source style | Concrete classes only (no abstract interfaces) |
| CLAUDE.md | Update to describe the new architecture |
| Scope / rollout | All features migrated in one pass |
| Behavior | Unchanged — structural refactor only |

## Current vs. target

| Diagram layer | Diagram boxes | Current state | Action |
|---|---|---|---|
| Presentation | Widgets → States → Controllers | `screens/` + Riverpod providers + `*Controller` classes | Reorganize into `presentation/{widgets,states,controllers,screens}` |
| Application | Services | Missing (controllers call repos directly) | **Add** `application/services/` |
| Domain | Models | `models/` mix domain + JSON | Split: pure domain `models/`, JSON moves to DTOs |
| Data | Repositories → DTOs → Data Sources | `repositories/` call Dio + parse inline | **Add** `data/dtos/`, `data/datasources/`; repos stop touching Dio directly |

## Target folder structure (per feature)

```
features/<feature>/
├── data/
│   ├── datasources/   ← concrete Dio wrapper; unwraps "data"; returns DTOs; throws DioException
│   ├── dtos/          ← fromJson/toJson + fromDomain()/toDomain()
│   └── repositories/  ← DataSource → Domain mapping; DioException → Failure
├── domain/
│   └── models/        ← PURE entities (no JSON, no Dio, no Flutter import)
├── application/
│   └── services/      ← business orchestration (no Riverpod, no widgets)
└── presentation/
    ├── states/        ← Riverpod FutureProvider/StateProvider (screen-facing reads)
    ├── controllers/   ← Riverpod glue: holds Ref, calls services, invalidates state
    ├── screens/       ← UI only
    └── widgets/
```

DI providers (`Provider<Repository>`, `Provider<Service>`, `Provider<DataSource>`)
are co-located at the bottom of each class's file (standard Riverpod practice).

## Layer rules

| Layer | May import / use | Must NOT |
|---|---|---|
| `domain/models` | Dart core only | JSON, Dio, Flutter, Riverpod |
| `data/dtos` | domain models, Dart core | Dio, Flutter, Riverpod widgets |
| `data/datasources` | Dio, DTOs, api_endpoints | domain mapping, Failure mapping, widgets |
| `data/repositories` | datasources, DTOs, domain, Failure | Dio directly, widgets |
| `application/services` | repositories, domain | Riverpod state objects, widgets, Dio |
| `presentation/states` | Riverpod, services/repos via DI | widgets logic, Dio, parsing |
| `presentation/controllers` | Riverpod (Ref), services | Dio, parsing, business rules best kept in service |
| `presentation/screens+widgets` | Widgets, ref.watch | Dio, parsing, business logic |

## Data flow

**Read** (`getAll`):
`State (FutureProvider)` → `Service.getAll(filter)` → `Repository.getAll(filter)` →
`DataSource.getAll(filter)` (Dio call, unwrap `"data"`, return `List<Dto>`) →
Repository maps `Dto.toDomain()` → returns pure `List<Transaction>`.

**Write** (`create`/`update`):
`Controller` (form inputs) → `Service` builds a domain `Transaction` →
`Repository.create(Transaction)` converts via `Dto.fromDomain(t).toJson()` →
`DataSource.create(json)` → returns `Dto` → `toDomain()` →
Controller invalidates the list `State`.

### Responsibility rules
- **DTOs own all JSON** (`fromJson`/`toJson`). Domain models are pure.
- **Repository owns error mapping** (`DioException` → `Failure`).
- **DataSource owns Dio + the `"data"` envelope + query-param building** from a
  domain `TransactionFilter` (keeps domain free of API detail).
- **Service = pure business logic** (no Riverpod import).
- **Controller = Riverpod glue** (holds `Ref`, performs `invalidate`).

## Per-feature plan

### transactions
- domain: `transaction.dart` (pure; keeps `isIncome`/`isExpense` getters), `transaction_filter.dart` (pure value object)
- data/dtos: `transaction_dto.dart` (fromJson/toJson/fromDomain/toDomain)
- data/datasources: `transaction_remote_data_source.dart` (getAll/create/update/delete; builds query params from filter)
- data/repositories: `transaction_repository.dart` (DTO↔domain, Failure mapping)
- application/services: `transaction_service.dart` (CRUD orchestration, payload building from inputs)
- presentation/states: list FutureProvider + filter StateProvider
- presentation/controllers: `transaction_controller.dart` (create/update/delete + invalidation)
- presentation/screens + widgets: move existing screen + 3 widgets

### categories
- domain: `category.dart` (pure; `isIncome`/`isExpense` getters)
- data/dtos: `category_dto.dart`
- data/datasources: `category_remote_data_source.dart`
- data/repositories: `category_repository.dart`
- application/services: `category_service.dart`
- presentation/states: categories + expense/income derived providers
- presentation/screens: existing category screen

### dashboard
- domain: summary + chart/period domain models (pure)
- data/dtos: matching DTOs
- data/datasources: `dashboard_remote_data_source.dart` (dummy data becomes a detail here until API wired)
- data/repositories: `dashboard_repository.dart`
- application/services: `dashboard_service.dart`
- presentation/states + screens + widgets: existing dashboard screen + 2 cards

### auth (special case)
- **No DTO / no JSON** — data source wraps the Google Sign-In SDK.
- data/datasources: `auth_remote_data_source.dart` (SDK wrapper: initialize, authEvents, lightweightAuthentication, signIn, signOut, currentIdToken)
- data/repositories: `auth_repository.dart` (delegates to data source)
- application/services: `auth_service.dart`
- presentation/states: `AuthState` sealed class + provider
- presentation/controllers: `auth_controller.dart` (lifecycle, login/logout)
- presentation/screens: login + splash
- `auth_config.dart` stays at feature root (cross-layer config)

## Cross-cutting

- `core/` (api, theme, router, error, utils, widgets) stays as-is; only import
  paths that move get fixed.
- `core/api/auth_interceptor.dart`: update imports to new auth paths; behavior unchanged.
- `core/router/app_router.dart`: update screen import paths.
- `main.dart`: update import paths.

## Verification

- `flutter analyze` clean (no new warnings/errors).
- `flutter test` passes; `test/widget_test.dart` imports updated as needed.
- No behavior change — purely structural.

## Out of scope

- Wiring dashboard to the real `/api/summary` endpoints (stays on dummy data).
- Abstract data-source interfaces.
- Any new features or UI changes.
