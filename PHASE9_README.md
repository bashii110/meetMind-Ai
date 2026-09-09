# Phase 9 — Analytics & Admin (Flutter frontend)

## What this is
PHASES.md's Phase 9 goal: *"Insight and platform governance"* — SRD
FR-13.1 (analytics charts) and FR-16.1–16.3 (admin user management,
storage usage, content moderation).

Both `lib/features/analytics/` and `lib/features/admin/` previously only
had `.gitkeep` placeholders — no domain layer, no API calls, no screens.
This patch fills both in, following the same Clean Architecture
conventions as every other feature (domain → data → presentation, one
usecase class per operation, Riverpod `AsyncNotifier` controllers).

No backend was provided, so both were built against
`ARCHITECTURE.md`'s documented conventions: the analytics endpoint it
explicitly lists (`GET /workspaces/{id}/analytics`), and REST endpoints
for admin following the same `{ data: ... }` / `{ data: { items, meta } }`
envelope every other feature in this app already expects. If your
backend's actual field names differ, only the `*Model` classes and the
two datasources need adjusting.

## How to apply
1. Unzip at the root of `frontend/`:
   ```bash
   unzip phase9-analytics-admin.zip -d /path/to/frontend
   ```
2. This assumes **Phases 7 and 8 have already been applied** —
   `app_router.dart` and `dashboard_screen.dart` here are full
   replacements that build on top of those patches (workspace/search
   routes and icons are still present, plus the new Analytics/Admin
   ones). Apply Phase 7 → Phase 8 → this, in order, if you haven't yet.
3. **No `pubspec.yaml` changes** — `fl_chart: ^0.68.0` was already a
   dependency (added ahead of time specifically for this phase; see the
   pubspec's own "Charts (Analytics screen — DESIGN.md 3.11)" comment).
   Everything else uses packages already in the project.
4. Run:
   ```bash
   flutter pub get
   flutter run
   ```
   No `build_runner` step needed — hand-written, no codegen.
5. `lib/features/analytics/**` and `lib/features/admin/**`'s old
   `.gitkeep` placeholders can be deleted now that real files live
   alongside them.

## What's included

### Analytics (`lib/features/analytics/`)
- `domain/entities/analytics_summary.dart` — `MonthlyMeetingCount`,
  `TaskCompletionStats`, `ActivityBreakdownEntry`, and the aggregate
  `AnalyticsSummary`. Together these cover every chart SRD FR-13.1 lists:
  meetings/month, completed + pending tasks (one `TaskCompletionStats`
  covers both), average duration, productivity, time spent, and
  department/user activity.
- `domain/repositories/analytics_repository.dart`,
  `domain/usecases/get_workspace_analytics_usecase.dart`
- `data/models/analytics_summary_model.dart`,
  `data/datasources/analytics_remote_data_source.dart` (`GET
  /workspaces/{id}/analytics`), `data/repositories/analytics_repository_impl.dart`
- `presentation/providers/analytics_providers.dart` — DI wiring
- `presentation/providers/analytics_controller.dart` — family-keyed by
  workspace id
- `presentation/widgets/`:
  - `productivity_score_gauge.dart` — a plain `CircularProgressIndicator`
    ring (not fl_chart — a single value doesn't need a full pie chart)
  - `meetings_per_month_chart.dart` — `fl_chart` `BarChart`
  - `task_completion_chart.dart` — `fl_chart` donut `PieChart` + legend
  - `activity_breakdown_list.dart` — ranked `LinearProgressIndicator`
    rows for department/user activity (simpler than a third chart type
    for what's really just "top N vs. the max")
  - `analytics_stat_card.dart` — small stat tiles (avg. duration, time
    spent, active users, pending tasks)
- `presentation/screens/analytics_screen.dart` — a workspace picker at
  the top (reusing Phase 7's `workspacesListControllerProvider`), then
  the productivity gauge, stat grid, and all four charts/lists for
  whichever workspace is selected.

**Wired in**: `/analytics` (the route constant already existed in
`app_routes.dart` from the original scaffold) now renders
`AnalyticsScreen`. A permanent Analytics icon sits in the dashboard app
bar for every signed-in user — this data isn't admin-gated (SRD FR-2.5
makes productivity visible to regular users too).

### Admin (`lib/features/admin/`)
- `domain/entities/`: `PlatformStats` (with a `storageUsageRatio`
  helper), `AdminUser` + `PaginatedAdminUsers`, `ModerationItem` +
  `PaginatedModerationItems`
- `domain/repositories/admin_repository.dart` +  5 usecases:
  get-platform-stats, list-users, set-user-disabled,
  list-moderation-queue, resolve-moderation-item
- `data/models/*.dart`, `data/datasources/admin_remote_data_source.dart`
  (`/admin/stats`, `/admin/users`, `/admin/users/{id}/disable`,
  `/admin/moderation`, `/admin/moderation/{id}/resolve`),
  `data/repositories/admin_repository_impl.dart`
- `presentation/providers/`: DI wiring plus three controllers —
  `PlatformStatsController`, `AdminUsersController` (paginated + search,
  mirrors `TasksListController`), `ModerationQueueController` (paginated,
  removes an item from local state as soon as it's resolved rather than
  re-fetching the page)
- `presentation/widgets/`: `AdminUserTile` (a `Switch` toggles
  enabled/disabled), `ModerationItemTile` (Dismiss / Remove content
  actions)
- `presentation/screens/admin_screen.dart` — **three tabs**: Overview
  (platform stat grid + a storage-usage bar, SRD FR-16.2), Users
  (search + paginated list + disable toggle, SRD FR-16.1), Moderation
  (paginated report queue with dismiss/remove actions, SRD FR-16.3)

**Wired in**: `/admin` now renders `AdminScreen`. The dashboard only
shows the Admin icon when the signed-in user's `AppUser.role ==
'system_admin'` (the `role` field already existed on `AppUser` from
Phase 1 — SRD 2.2's three user classes). `AdminScreen` re-checks the role
itself and shows a plain "no access" message otherwise, since hiding the
icon is just UX — the real enforcement has to be the backend Policy on
every `/admin/*` endpoint.

## Design decisions worth knowing about
- **Analytics is workspace-scoped, not platform-wide.** `ARCHITECTURE.md`
  explicitly documents `GET /workspaces/{id}/analytics`, not a global
  endpoint, and SRD's "department/user activity" chart only makes sense
  within a workspace. A dropdown picks which of the user's workspaces to
  view, defaulting to the first one — there's no separate "my personal
  analytics" view, since every meeting/task in this app already belongs
  to a workspace.
- **Admin's account-disable toggle can't target the signed-in admin's own
  account.** Letting an admin disable themselves from this screen would
  lock them out of the screen they're using — `AdminUserTile.onToggleDisabled`
  is `null` for that one row.
- **Resolving a moderation item removes it from local state immediately**
  rather than re-fetching the page, since a resolved item (by definition)
  no longer belongs in a "pending reports" queue — avoids an extra round
  trip and a flash of the item disappearing mid-refresh.
- **fl_chart only for the two chart types that actually need it**
  (bar + donut). The productivity score and the department/user activity
  breakdown use plain `CircularProgressIndicator`/`LinearProgressIndicator`
  instead, since neither needs fl_chart's API surface — same philosophy
  Phase 7 used for gauges/lists vs. charts.

## Known simplifications (documented trade-offs, not bugs)
- No widget/unit tests were added, consistent with this frontend's
  existing note that this sandbox has no Flutter/Dart SDK to run
  `flutter analyze`/`flutter test` against. Please run both after
  `flutter pub get` and let me know what comes up.
- Admin's Overview tab shows platform-wide counts and storage but doesn't
  duplicate the workspace-level charts from the `analytics` feature —
  SRD FR-16.2 says admins "view platform analytics," which this
  interprets as the platform-wide numbers (total users/meetings/tasks,
  storage), not a re-rendering of every workspace's charts inline. An
  admin can still open `analytics` for any workspace they belong to.
- No route-level guard on `/admin` (e.g. redirecting non-admins away) —
  `AdminScreen` handles the check itself and shows a friendly message,
  which was simpler than adding a second role-aware branch to the
  router's `redirect` callback for a single screen.

## If you want the backend too
This patch is frontend-only. If you connect a Laravel backend repo (or
want one scaffolded), the pieces this frontend expects are:
- `WorkspaceAnalyticsController::index(Workspace $workspace)` — aggregates
  meetings/tasks/activity for that workspace (cached in Redis per
  ARCHITECTURE.md 3.5) and returns the `AnalyticsSummaryModel` shape.
- `Admin\StatsController`, `Admin\UserController` (`index`, `disable`),
  `Admin\ModerationController` (`index`, `resolve`) — all behind an
  `AdminPolicy`/`system_admin`-only middleware, matching SRD FR-16.x.
Happy to build that out as a follow-up if you share the backend repo.
