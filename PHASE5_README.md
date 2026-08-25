# Phase 5 — Smart Task Manager (Flutter frontend)

## What this is
PHASES.md's Phase 5 was already fully built on the **backend**
(`TaskController`, `TaskService`, `TaskPolicy`, migrations, and
`tests/Feature/Task/TaskTest.php` all existed). The **frontend**
`lib/features/tasks/` directory, however, only had `.gitkeep`
placeholders — no domain layer, no API calls, no screens. This patch adds
that missing frontend, following the exact Clean Architecture conventions
already used by `meetings` and `notifications` (domain → data →
presentation, one usecase class per operation, Riverpod
`AsyncNotifier`/`AsyncNotifierProvider` controllers).

## How to apply
1. Unzip this archive at the root of the `frontend/` Flutter project (the
   paths below already match the project's structure, so extracting here
   drops files straight into place):
   ```bash
   unzip phase5-tasks.zip -d /path/to/frontend
   ```
2. `pubspec.yaml` is a full replacement — it's identical to the original
   plus one new dependency, `file_picker: ^8.1.2`, needed for generic
   (non-image) task attachment uploads. If you've since customized your
   own `pubspec.yaml`, just add that one line instead of overwriting.
3. `lib/core/router/app_routes.dart`, `lib/core/router/app_router.dart`,
   and `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
   are also full replacements of the existing files (task routes wired
   in, plus a "Your tasks" stat row on the dashboard).
4. Run:
   ```bash
   flutter pub get
   flutter run
   ```
   No `build_runner` step is needed — everything here is hand-written,
   matching how `meetings`/`auth`/`notifications` are built (no
   freezed/json_serializable codegen for this feature).
5. The old `.gitkeep` placeholder files under `lib/features/tasks/**` can
   be deleted now that real files live alongside them — harmless to leave
   in place either way.

## What's included

**Domain** (`lib/features/tasks/domain/`)
- `entities/task.dart` — `TaskEntity`, `TaskComment`, `TaskAttachment`.
  `creator`/`assignee` reuse `AppUser` from the `auth` feature (same
  convention `profile` uses), since they're the same backend `UserResource`.
- `entities/task_filters.dart`, `entities/paginated_tasks.dart`
- `repositories/task_repository.dart` — the abstract contract
- `usecases/*.dart` — one class per operation: list, get, create, update,
  delete, change status, update progress, assign, add/delete comment,
  add/delete attachment (11 usecases total)

**Data** (`lib/features/tasks/data/`)
- `models/task_model.dart`, `models/paginated_tasks_model.dart` — parse
  `TaskResource`/`TaskCommentResource`/`TaskAttachmentResource` JSON
- `datasources/task_remote_data_source.dart` — one Dio call per endpoint,
  matching `routes/api.php`'s `/tasks/*` routes exactly
- `repositories/task_repository_impl.dart`

**Presentation** (`lib/features/tasks/presentation/`)
- `providers/task_providers.dart` — DI wiring
- `providers/tasks_list_controller.dart` — filtered, paginated list state
  (mirrors `MeetingsListController`)
- `providers/task_details_controller.dart` — single-task state + all the
  mutating actions (status, progress, assign, comments, attachments)
- `providers/task_stats_provider.dart` — pending/completed counts for the
  dashboard
- `widgets/task_card.dart`, `widgets/deadline_chip.dart`
- `screens/task_list_screen.dart` — **Kanban board** (4 columns) on
  screens ≥800px wide, **grouped list with filter chips** on mobile, per
  DESIGN.md 3.7. Both share one paginated query; Kanban groups whatever's
  loaded into columns client-side.
- `screens/task_details_screen.dart` — status chips, a progress slider,
  assignee (assign-to-me/unassign), deadline, linked-meeting shortcut,
  attachments (upload/delete), and a comment thread (post/delete own).
- `screens/create_edit_task_screen.dart` — title, description, priority,
  deadline date+time, optional meeting link, and (create-only) starting
  status + "assign to me", matching exactly what
  `StoreTaskRequest`/`UpdateTaskRequest` accept.

**Wired in**
- `core/router/app_routes.dart` / `app_router.dart` — `/tasks`,
  `/tasks/new`, `/tasks/:id`, `/tasks/:id/edit`
- Dashboard now shows a "Your tasks" Pending/Completed stat row
  (DESIGN.md 3.3) linking to the task list.

## Known simplifications (documented trade-offs, not bugs)
- **Assignment** is "assign to me" / "unassign" only. The backend has no
  endpoint for listing a workspace's members (`GET /workspaces` only
  lists workspaces, not their members), so there's no data source to
  populate a "pick any teammate" picker without adding a new backend
  route. This is the same constraint the `meetings` feature works around
  by inviting participants by e-mail rather than by picking from a list.
- **Unlinking a meeting** from an existing task isn't exposed in the edit
  form — you can attach a task to a meeting or change which meeting it's
  attached to, but not clear it back to "none," because the update
  payload only sends `meeting_id` when it's non-null (the same
  `if (x != null)` convention `UpdateMeetingUseCase` already uses
  elsewhere in this codebase, so a task can't distinguish "don't touch
  this field" from "clear this field" without a sentinel value).
- No widget/unit tests were added for this feature, consistent with the
  existing frontend README's note that this sandbox has no Flutter/Dart
  SDK to run `flutter analyze`/`flutter test` against. Please run both
  after `flutter pub get` and let me know what comes up.
