# Dashboard Period Filter — Design

**Date:** 2026-06-18
**Branch:** `feature/dashboard-period-filter`
**Type:** New feature

## Goal

Make the dashboard's `PeriodFilterCard` tappable: it opens a bottom sheet listing
all salary periods (from `GET /api/salary-periods`), the user picks one (or
"Semua Periode"), and the selection filters the dashboard summary
(`GET /api/summary?salary_period_id=<id>`).

## Decisions (locked)

| Decision | Choice |
|---|---|
| Source of periods | `GET /api/salary-periods` (a new `salary_period` feature) |
| Summary data | Wire the REAL `GET /api/summary` (replace the current stub), with `salary_period_id` |
| Filter scope | Dashboard only (does NOT touch transactions) |
| Default selection | Auto: the period containing today's date (`DateTime.now()`); falls back to "Semua Periode" if none |
| Picker UI | Bottom sheet: a client-side **year filter** (default = current year) + "Semua Periode" item + the periods of the selected year |
| Selection model | `sealed class PeriodSelection` = `AutoPeriod` (default) \| `AllPeriods` \| `SpecificPeriod(period)`; an `effectivePeriodProvider` resolves it to a `SalaryPeriod?` |
| Feature folder | `lib/features/salary_period/` (singular — the empty folder already present) |
| by-category list | OUT OF SCOPE (separate future work) |

## Architecture

Follows the existing Clean Architecture (data → domain ← repository; service;
presentation states/screens). Two feature areas change.

### A. New feature: `salary_period`

```
features/salary_period/
├── domain/models/salary_period.dart            SalaryPeriod (pure)
├── data/dtos/salary_period_dto.dart             fromJson + toDomain
├── data/datasources/
│   └── salary_period_remote_data_source.dart    GET /api/salary-periods → List<SalaryPeriodDto>
├── data/repositories/salary_period_repository.dart   map + DioException→Failure
├── application/services/salary_period_service.dart   list()
└── presentation/states/salary_period_state.dart      salaryPeriodsProvider
```

- `SalaryPeriod` fields (per CLAUDE.md `SalaryPeriodModel`): `id:int`, `name:String`,
  `startDate:String`, `endDate:String`, `salaryAmount:double?`. API returns camelCase
  (`startDate`, `endDate`, `salaryAmount`).
- `salaryPeriodsProvider : FutureProvider<List<SalaryPeriod>>`.

### B. Dashboard changes

1. **Selected-period state** — `presentation/states/dashboard_state.dart`:
   - `selectedPeriodProvider : StateProvider<SalaryPeriod?>` (null = "Semua Periode").
   - `dashboardSummaryProvider` watches it and passes `period?.id` to the service.
2. **Real summary API** — `data/datasources/dashboard_remote_data_source.dart`:
   - Take a `Dio` (via `dioProvider`), call `GET /api/summary` with
     `queryParameters: { if (id != null) 'salary_period_id': id }`, unwrap `"data"`,
     return `SummaryDto.fromJson(...)`. Removes the hardcoded stub.
3. **Error mapping** — `data/repositories/dashboard_repository.dart`:
   - `getSummary(int? periodId)` now wraps the Dio call in `try/catch DioException → Failure.fromDio`.
   - `DashboardService.summary(int? periodId)` forwards the id.
4. **Interactive card** — `presentation/screens/widgets/period_filter_card.dart`:
   - `StatelessWidget` → `ConsumerWidget`.
   - Label shows `selectedPeriod?.name ?? 'Semua Periode'`.
   - On tap → `showModalBottomSheet` listing `salaryPeriodsProvider` via `.when`
     (loading spinner / error+retry / data list), plus a "Semua Periode" item that
     sets the selection back to null. Picking an item sets `selectedPeriodProvider`
     and closes the sheet.

## Data flow

```
PeriodFilterCard (tap)
  └─▶ bottom sheet → salaryPeriodsProvider → GET /api/salary-periods
        └─▶ user picks period (or "Semua Periode")
              └─▶ set selectedPeriodProvider
                    │ (watched)
                    ▼
              dashboardSummaryProvider → GET /api/summary?salary_period_id=<id>
                    ▼
              summary card numbers update + card label updates
```

## Error handling

- `salaryPeriodsProvider`: repository maps `DioException → Failure`; the bottom
  sheet renders loading / error (with a retry that invalidates the provider) / data.
- `dashboardSummaryProvider`: now hits the real API, so transport errors surface as
  `Failure`; the existing `summaryAsync.when(error: ...)` on the dashboard screen
  handles them (can be upgraded to show `Failure.message`).

## Testing

- Unit-ish: `SalaryPeriodDto.fromJson` maps the documented JSON to the domain model
  (including null `salaryAmount`).
- Provider: with an overridden repository returning a fixed list, `salaryPeriodsProvider`
  resolves to the expected domain list.
- Provider: `dashboardSummaryProvider` passes the selected period's id to the service
  (override the service/repository, assert the id received) and refetches when
  `selectedPeriodProvider` changes.
- Regression: `flutter analyze` adds no new issues; existing smoke test still passes.

## Out of scope

- The "expenses by category" list (`GET /api/summary/by-category`).
- Any change to the transactions screen/filter.
- A salary-period CRUD/seed UI (only listing is needed here).

## Notes / risks

- In debug on Android the base URL points at production (per `ApiClient`), so the real
  `/api/summary` and `/api/salary-periods` calls hit the deployed Vercel API. Requires a
  signed-in user; the existing auth interceptor attaches the Bearer token automatically.
- If `/api/salary-periods` returns an empty list, the bottom sheet shows only the
  "Semua Periode" item — acceptable.
