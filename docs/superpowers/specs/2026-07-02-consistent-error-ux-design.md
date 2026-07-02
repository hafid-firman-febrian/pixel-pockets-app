# Consistent Error UX — Design

**Date:** 2026-07-02
**Status:** Approved (design)
**Scope:** Technical health → error handling & resilience → consistent error UX

## Problem

Error handling is uneven across screens:

- The `Failure` model is solid — a typed `FailureType` (`noConnection`, `timeout`,
  `server`, `notFound`, `unauthorized`, `cancelled`, `unknown`) plus a UI-safe
  `message`.
- The **transaction screen** already renders a good error state: a private
  `_ErrorView` that maps `FailureType → IconData`, shows the message, and offers a
  **"Try Again"** button.
- **Every other screen is ad-hoc.** Dashboard sections show plain text inside cards
  (`_CardMessage('Failed to load…')`) with **no icon, no retry, and no use of
  `FailureType`**. The chart shows `_CardMessage('Failed to load chart.')`. Settings
  has its own private `_LoadError → _EmptyHint`.
- Dashboard/chart pass a hardcoded string and **never read the actual `Failure`**, so
  the typed icon and the server's message are thrown away.

Result: inconsistent look, no retry affordance outside transactions, and duplicated
one-off error widgets.

## Goal

One shared, reusable error widget used by every async screen, covering both
full-screen and inside-a-card cases, with a "Try Again" retry affordance and the
typed icon/message the `Failure` model already provides.

Non-goals (explicitly out of scope):

- Connectivity / offline detection (a separate resilience goal).
- Changes to `Failure`, the `AuthInterceptor`, repositories, or Dio config.
- New dependencies.
- Retry-with-backoff or global session-expiry handling.

## Approach

**Chosen: Approach A** — a single `PixelErrorView` widget with a `compact` flag.

Rejected alternatives:

- **B — two widgets** (`PixelErrorView` full + `PixelErrorCard` inline): two things to
  keep visually in sync, more boilerplate.
- **C — an `AsyncValue` rendering extension**: most "magic," biggest refactor, touches
  how every screen branches. Overkill for the goal.

## Design

### 1. New shared widget — `lib/core/widgets/pixel_error_view.dart`

```dart
class PixelErrorView extends StatelessWidget {
  const PixelErrorView({
    required this.failure,
    required this.onRetry,
    this.compact = false,
    super.key,
  });

  final Failure failure;
  final VoidCallback onRetry;
  final bool compact;   // true → inline card variant
}
```

- Owns the `FailureType → IconData` mapping, moved verbatim out of the transactions
  `_ErrorView`:
  - `noConnection → Pixel.downasaur`
  - `timeout → Pixel.hourglass`
  - `server → Pixel.server`
  - `notFound | unauthorized | cancelled | unknown → Pixel.cellularsignaloff`
- **Full mode** (`compact: false`): centered `Column` — 48px icon, message,
  "Try Again" `PixelButton` (icon `Pixel.reload`). Visually identical to today's
  transaction error state.
- **Compact mode** (`compact: true`): smaller icon (~28px), message, and a subtle
  text/icon "Try Again" affordance sized to sit inside a `PixelCard`. This is the
  variant dashboard/chart/settings currently lack.
- Uses existing theme tokens (`AppColors.textMuted`, `AppSpacing.*`) — no new styling
  system.

### 2. Small helper — `Failure asFailure(Object? error)`

Lives in `lib/core/error/failure.dart` (top-level function or extension).

```dart
Failure asFailure(Object? error) => error is Failure
    ? error
    : Failure(message: error?.toString() ?? 'Something went wrong.');
```

Repositories already throw `Failure`, but an `AsyncValue.error` is typed `Object?`.
This lets any screen coerce it into a real `Failure` (typed icon + server message)
instead of a hardcoded string.

### 3. Per-screen wiring (swap the error branch only — no data/loading logic changes)

| Screen | Today | After |
|---|---|---|
| Transactions | private `_ErrorView` | delete it; use `PixelErrorView(...)` (full) |
| Dashboard — summary / recent / by-category | `_CardMessage('Failed to load…')` | `PixelErrorView(failure: asFailure(async.error), onRetry: () => ref.invalidate(provider), compact: true)` |
| Chart | `_CardMessage('Failed to load chart.')` | compact `PixelErrorView` |
| Settings | `_LoadError → _EmptyHint` | compact `PixelErrorView` |

- `onRetry` invalidates that section's provider (dashboard already exposes the
  providers; transactions already invalidates its controller).
- **Empty states stay as-is** — e.g. `'No transactions for this period.'` is not an
  error and keeps its existing hint widget.
- Remove the now-dead private widgets (`_ErrorView`, `_LoadError`, and any
  `_CardMessage` usages that were purely error-path).

### 4. Testing

- **Widget test** for `PixelErrorView`:
  - renders the correct icon for each `FailureType`,
  - shows the `failure.message`,
  - fires `onRetry` when "Try Again" is tapped,
  - in **both** full and compact modes.
- **Helper test** for `asFailure`: passes a `Failure` through untouched; wraps a
  non-`Failure` value.
- Existing screen tests stay green — behavior is unchanged; only the error widget is
  swapped.

## Files touched

- **New:** `lib/core/widgets/pixel_error_view.dart`
- **New:** `test/core/widgets/pixel_error_view_test.dart`
- **New:** `test/core/error/failure_test.dart` (for `asFailure`)
- **Edit:** `lib/core/error/failure.dart` (add `asFailure`)
- **Edit:** `lib/features/transactions/presentation/screens/transaction_screen.dart`
- **Edit:** `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- **Edit:** `lib/features/chart/presentation/screens/chart_screen.dart`
- **Edit:** `lib/features/settings/presentation/screens/settings_screen.dart`

## Success criteria

- Dashboard, chart, and settings error states show a typed icon, the real failure
  message, and a working "Try Again" that refetches.
- No duplicated per-screen error widgets remain.
- All existing tests pass; new `PixelErrorView` and `asFailure` tests pass.
- No new dependencies; `Failure`, interceptor, and repositories untouched.
