# Phase 10 — Offline Support & Sync Hardening (Flutter frontend)

## What this is
PHASES.md's Phase 10 goal: *"Reliable mobile-first experience without
connectivity."* This patch delivers all four checklist items:

- **Local caching finalized** for meetings and tasks (Hive as the
  offline-first source of truth, ARCHITECTURE.md 2.3) — recording's
  offline queue already existed from Phase 3 and is untouched.
- **Outbox pattern** for offline mutations — create/edit/delete/status-
  change on a meeting or task made while offline is queued and replayed
  automatically on reconnect.
- **Conflict resolution UI/logic** — meetings use last-write-wins (per
  this project's existing policy); tasks get a manual-merge screen when
  the server's copy has changed since an offline edit was queued.
- **Offline-usable app** — a persistent banner while offline, and a sync
  status chip surfacing pending changes / conflicts needing review.

## How to apply
1. Unzip at the root of `frontend/`:
   ```bash
   unzip phase10-offline-sync.zip -d /path/to/frontend
   ```
2. This assumes **Phases 7–9 have already been applied** — `app_router.dart`
   and `dashboard_screen.dart` here are full replacements building on top
   of those patches. Apply in order if you haven't yet.
3. **No `pubspec.yaml` changes** — this uses only packages already in the
   project: `connectivity_plus` (already used by `AudioUploadManager`),
   `uuid` (already used by the recording and assistant-chat features),
   `hive`/`hive_flutter`, and `dio`.
4. Run:
   ```bash
   flutter pub get
   flutter run
   ```
   No `build_runner` step needed — hand-written, no codegen, matching
   every other feature in this app.

## What's included

**Core (`lib/core/`)**
- `network/connectivity_controller.dart` — a single online/offline signal
  (`isOnlineProvider`) the rest of the app watches, wrapping
  `connectivity_plus` the same way `AudioUploadManager` already did
  ad hoc in Phase 3, generalized app-wide.
- `storage/local_db.dart` — **modified**: the `meetings`, `tasks`,
  `outbox`, and a new `syncConflicts` Hive box are now opened eagerly at
  startup (previously only `pendingUploads` was).
- `sync/outbox_entry.dart`, `sync/outbox_local_data_source.dart` — the
  queued-mutation model and its Hive-backed FIFO store.
- `sync/sync_conflict.dart`, `sync/conflict_local_data_source.dart` — a
  detected task conflict (local edit vs. current server copy) and its
  store.
- `sync/outbox_sync_manager.dart` — the engine. Replays queued entries in
  the order they were created (so a status change queued after a create
  resolves against that create's real server id), swaps temporary
  `local_<uuid>` ids for real ones as creates succeed, and — for task
  updates specifically — compares the task's server `updated_at` against
  the snapshot taken when the offline edit was queued; if the server has
  moved on, the entry becomes a `SyncConflict` instead of silently
  overwriting someone else's change. Meeting updates never do this check
  (last-write-wins, matching this project's existing documented policy).
  Not `autoDispose`, same reasoning as `AudioUploadManager`: a sync pass
  must survive navigation.
- `widgets/offline_banner.dart` — a slim, non-blocking bar shown above
  the whole app (wired into `main.dart`'s `MaterialApp.router.builder`)
  whenever `isOnlineProvider` is false.
- `widgets/sync_status_chip.dart` — an app-bar icon that shows a spinner
  while syncing, a badge + tap-to-review when there are conflicts, a
  badge + tap-to-sync-now when there's just a pending queue, and nothing
  otherwise.

**Meetings & Tasks (`lib/features/meetings/`, `lib/features/tasks/`)**
- `data/datasources/meeting_local_data_source.dart`,
  `data/datasources/task_local_data_source.dart` — **new**. Hive caches
  keyed by id, mirroring `PendingUploadLocalDataSource`'s hand-written
  JSON-in-a-Box convention.
- `data/repositories/meeting_repository_impl.dart`,
  `data/repositories/task_repository_impl.dart` — **modified**.
  `list()`/`getById()` try the network first and fall back to cache on a
  connection error (or when already known to be offline). `create()`
  mints a `local_<uuid>` id and returns an optimistic local entity when
  offline; `update()`/`delete()`/`changeStatus()` patch the cache and
  enqueue an `OutboxEntry` the same way. Task updates additionally
  snapshot `updatedAt` into the outbox entry for conflict detection.
- `presentation/providers/meeting_providers.dart`,
  `presentation/providers/task_providers.dart` — **modified**: the
  repository provider now injects an `isOnline` callback backed by
  `isOnlineProvider`.

**Conflict resolution (`lib/features/sync/`)**
- `presentation/screens/conflict_resolution_screen.dart` — **new**. Lists
  pending task conflicts with a side-by-side "your offline changes" vs.
  "server's current version" card, and *Keep my changes* / *Keep server
  version* actions. Presentation-only, same convention `dashboard`
  already uses for a feature that aggregates others rather than owning
  its own data layer.

**Wired in**
- `core/router/app_routes.dart` / `app_router.dart` — `/sync/conflicts`.
- `main.dart` — resolves real connectivity and replays any leftover
  outbox once at startup, auto-syncs on reconnect, and wraps the app in
  the offline banner.
- `dashboard_screen.dart` — the sync status chip sits next to
  Notifications in the app bar.

## Design decisions worth knowing about
- **Cache-first reads, not cache-only.** `list()`/`getById()` always try
  the network first when there's any doubt, and only fall back to Hive on
  a genuine connection failure — this keeps the cache from ever
  *shadowing* fresher server data while online.
- **Replay stops on the first failure in a pass**, rather than skipping a
  failed entry and continuing. A later queued entry can depend on an
  earlier one (a status change on something an earlier entry creates), so
  retrying out of order risks a worse state than just waiting for the
  next sync trigger (reconnect, or the sync chip's manual tap).
- **Meetings: last-write-wins. Tasks: manual merge.** This carries
  forward the policy already established for this project — meetings are
  simpler, lower-stakes objects to just overwrite; tasks (assignment,
  progress, deadlines) are worth a prompt when two edits genuinely
  diverge.
- **Conflict detection is update-only.** A `create` replays unconditionally
  (nothing to conflict with yet), and `delete`/`changeStatus` don't
  compare `updated_at` — a delete is unambiguous intent, and a status
  change is a single-field transition where last-write-wins is a
  reasonable default even for tasks (documented here as a scope
  boundary, not an oversight).

## Known simplifications (documented trade-offs, not bugs)
- **Participant invites/removal/RSVPs (meetings) and progress/assignment/
  comments/attachments (tasks) stay online-only.** These are secondary,
  lower-frequency actions compared to core CRUD and status changes;
  queuing a multipart file upload (task attachments) offline in
  particular would need meaningfully more plumbing (local file retention
  until sync) than this phase's scope covers.
- **The cache doesn't round-trip participants, comments, or attachments** —
  an offline-fallback meeting/task detail view shows everything except
  those collections. Reasonable trade-off for keeping the cache schema
  simple; a participant/comment cache would be a natural Phase 10.1.
- **Offline list reads ignore filters** — `MeetingFilters`/`TaskFilters`
  aren't applied to the cached fallback, which returns everything cached
  as a single unpaginated page. Good enough to keep the list screen
  usable offline; not a full client-side filter engine.
- **No exponential backoff on retry** — a failed outbox entry is retried
  on the next `syncNow()` call (auto-triggered on reconnect, or via the
  sync chip), with `retryCount`/`lastError` tracked on the entry for
  future UI (e.g. surfacing a "this change keeps failing" state) but not
  yet surfaced anywhere.
- No widget/unit tests were added, consistent with this frontend's
  existing note that this sandbox has no Flutter/Dart SDK to run
  `flutter analyze`/`flutter test` against. Please run both after
  `flutter pub get` and let me know what comes up.
