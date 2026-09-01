# Phase 7 — Team Collaboration & Workspaces (Flutter frontend)

## What this is
PHASES.md's Phase 7 goal is: *"Multi-user, multi-role environments"* — SRD
FR-10.1 through FR-10.4 (create/join workspaces, admin-assigned roles,
member management, and an activity timeline), plus PHASES.md's optional
"Departments grouping" sub-structure.

The frontend `lib/features/workspace/` directory previously only had
`.gitkeep` placeholders — no domain layer, no API calls, no screens. This
patch adds that missing frontend, following the exact Clean Architecture
conventions already used by `meetings` and `tasks` (domain → data →
presentation, one usecase class per operation, Riverpod
`AsyncNotifier`/`AsyncNotifierProvider` controllers, `AutoDisposeFamily`
notifiers for per-id screens).

No backend was provided for this pass, so the frontend was built against
the REST contract already documented in `ARCHITECTURE.md` (section 4's
`workspaces`/`workspace_members` tables, section 5's response envelope
conventions) and the same JSON shapes every other feature in this app
already expects (`{ data: ... }`, `{ data: { items, meta } }` for
pagination, `{ message, errors }` for failures). If your backend's actual
field names differ, the only files that need adjusting are the `*Model`
classes in `data/models/` and `WorkspaceRemoteDataSource` — the domain and
presentation layers don't know or care about JSON shape.

## How to apply
1. Unzip this archive at the root of the `frontend/` Flutter project (the
   paths below already match the project's structure):
   ```bash
   unzip phase7-workspace.zip -d /path/to/frontend
   ```
2. No `pubspec.yaml` changes needed — this feature only uses packages
   already in the project (`dio`, `equatable`, `flutter_riverpod`,
   `go_router`, `intl`), and reuses the existing shared widgets
   (`ChipInputField`, `EmptyState`) rather than adding new ones.
3. `lib/core/router/app_routes.dart`, `lib/core/router/app_router.dart`,
   and `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
   are full replacements of the existing files (workspace routes wired in,
   plus a "Workspaces" icon button on the dashboard app bar). If you've
   since customized any of these, diff before overwriting.
4. Run:
   ```bash
   flutter pub get
   flutter run
   ```
   No `build_runner` step is needed — everything here is hand-written,
   matching how `meetings`/`tasks`/`auth` are built (no
   freezed/json_serializable codegen for this feature).
5. The old `.gitkeep` placeholder files under `lib/features/workspace/**`
   can be deleted now that real files live alongside them.

## What's included

**Domain** (`lib/features/workspace/domain/`)
- `entities/workspace.dart` — `Workspace`, including `myRole` (the
  current user's own membership) and derived `isOwner`/`canManage` getters
- `entities/workspace_member.dart` — `WorkspaceMember` + the
  `WorkspaceRole` enum (`owner`/`admin`/`member`)
- `entities/department.dart`, `entities/activity_log_entry.dart`,
  `entities/paginated_activity.dart`
- `repositories/workspace_repository.dart` — the abstract contract
- `usecases/*.dart` — one class per operation: list/get/create/update/
  delete/leave workspaces; list/invite/update-role/remove/assign-department
  for members; list/create/update/delete for departments; list activity
  (16 usecases total)

**Data** (`lib/features/workspace/data/`)
- `models/*.dart` — parse the workspace/member/department/activity JSON
  shapes
- `datasources/workspace_remote_data_source.dart` — one Dio call per
  endpoint (`/workspaces`, `/workspaces/{id}/members`, `/.../department`,
  `/.../departments`, `/.../activity`)
- `repositories/workspace_repository_impl.dart`

**Presentation** (`lib/features/workspace/presentation/`)
- `providers/workspace_providers.dart` — DI wiring for the datasource,
  repository, and all 16 usecases
- `providers/workspaces_list_controller.dart` — every workspace the
  current user belongs to (mirrors `MeetingsListController`)
- `providers/workspace_details_controller.dart` — single workspace state
  + update/delete/leave
- `providers/workspace_members_controller.dart` — member list + invite/
  change-role/remove/assign-department, family-keyed by workspace id
- `providers/departments_controller.dart` — department CRUD, family-keyed
- `providers/workspace_activity_controller.dart` — paginated activity
  timeline state + `loadMore()` (mirrors `TasksListController`'s
  pagination pattern)
- `widgets/workspace_card.dart`, `widgets/role_chip.dart`,
  `widgets/member_tile.dart`, `widgets/department_tile.dart`,
  `widgets/activity_log_tile.dart`
- `screens/workspace_list_screen.dart` — every workspace the user belongs
  to, with a "New workspace" FAB
- `screens/create_edit_workspace_screen.dart` — name + description,
  create or edit
- `screens/workspace_details_screen.dart` — **four tabs**: Overview
  (description, owner, created date, role), Members (invite by email +
  role, change role, assign department, remove — all gated behind
  `canManage`), Departments (create/rename/delete, also gated), Activity
  (paginated timeline, SRD FR-10.4)

**Wired in**
- `core/router/app_routes.dart` / `app_router.dart` — `/workspace`,
  `/workspace/new`, `/workspace/:id`, `/workspace/:id/edit`
- Dashboard app bar now has a "Workspaces" icon button next to Calendar/
  Notifications/Profile, linking to the workspace list — same lightweight
  entry-point pattern Phase 6 used for Calendar, since the dashboard
  itself isn't workspace-scoped.

## Design decisions worth knowing about
- **Roles are owner/admin/member**, matching `ARCHITECTURE.md`'s
  `workspace_members` table. "System Admin" from SRD 2.2 is a *platform*
  role (the separate `admin` feature, Phase 9), not a workspace membership
  role, so it's intentionally not modeled here.
- **Only the owner can delete a workspace**; admins can rename it and
  manage members/departments but not delete it. Everyone except the owner
  can leave. This is enforced client-side via `Workspace.isOwner` /
  `Workspace.canManage` — your backend's Policies should enforce the same
  rules server-side, since client-side checks are just UX, not security.
- **Ownership transfer is out of scope** for this phase (not in
  PHASES.md's Phase 7 checklist) — there's no "make this member the
  owner" action.
- **Departments are purely organizational**, per PHASES.md's "optional
  sub-structure" framing — assigning a member to a department doesn't
  change their permissions, only where they show up for grouping.
- **@mentions in comments** (SRD FR-10.3) and **shared files** (FR-10.5)
  are *not* included in this patch — they belong inside the existing
  `tasks`/`meetings` comment threads and attachment flows respectively,
  not the workspace feature itself, and touching those files was out of
  scope for a workspace-focused patch. They're natural follow-ups: adding
  an `@`-triggered autocomplete to `ChipInputField`'s sibling text areas
  (task comments, meeting descriptions) using the member list this phase
  now exposes via `WorkspaceMembersController`.

## Known simplifications (documented trade-offs, not bugs)
- **Workspace list is not paginated** — same reasoning as
  `NotificationRepository.list()`: the number of workspaces a single user
  belongs to is small enough that a flat list is simpler than adding a
  second pagination scheme for one endpoint. Members and departments
  within a workspace are similarly unpaginated (a workspace's member count
  is bounded in practice); only the activity timeline is paginated, since
  that list grows unboundedly over time.
- **No search/filter UI** on the workspace list — SRD doesn't call for
  one at this phase (unlike meetings/tasks), and workspace counts per user
  are expected to be small.
- No widget/unit tests were added for this feature, consistent with the
  existing frontend README's note that this sandbox has no Flutter/Dart
  SDK to run `flutter analyze`/`flutter test` against. Please run both
  after `flutter pub get` and let me know what comes up.

## If you want the backend too
This patch is frontend-only, matched against the REST conventions already
established in `ARCHITECTURE.md`. If you connect a Laravel backend repo
(or want one scaffolded), the pieces this frontend expects are:
- `workspaces` / `workspace_members` tables (already in `ARCHITECTURE.md`
  section 4) + a `departments` table (workspace_id, name)
- `WorkspaceController`, `WorkspaceMemberController`,
  `DepartmentController` with the routes listed under "Data" above
- A `WorkspacePolicy` enforcing owner/admin-only actions
- Activity logging hooked into the existing `activity_logs` table
  (already in the schema, just needs writers) for meeting/task/member
  events, surfaced via `GET /workspaces/{id}/activity`
Happy to build that out as a follow-up if you share the backend repo.
