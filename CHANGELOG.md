# Changelog

All notable changes to the MeetMind AI Flutter client, phase by phase.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).
This project has been built as a sequence of spec-driven phases (see
`phases.md`) rather than incremental version bumps, so entries are
grouped by phase; the whole sequence together is what `v1.0.0` should
tag once the backend catches up and a device QA pass is done.

## Phase 12 — Polish, Bonus Features & Launch Prep
### Added
- Shimmer-based skeleton loaders for meetings and notifications lists
  (DESIGN.md 4 — `shimmer` had been a dependency since the original
  scaffold but was never wired up).
- `GlassCard` — a reusable glassmorphism treatment applied to AI-content
  surfaces (executive summary card, meeting score badge, productivity
  tips card).
- Export a meeting summary as PDF, Markdown, or Word (.rtf); share it
  as a file or as plain text via the OS share sheet (SRD FR-5.4).
- **AI Meeting Score** — a heuristic 0–100 score computed client-side
  from the generated summary's mood/decisions/next steps/deadlines/risks.
- **Productivity tips** — short, heuristic dashboard nudges based on
  task stats and today's meeting load.
- `AnimatedSwitcher` fade transitions between loading/empty/data states
  on the dashboard and notifications list.
### Changed
- `SummaryTab` now receives the full `Meeting`, not just its id, so the
  export sheet has title/date/time without a second fetch.
- README overhauled: architecture diagram, feature highlights, phase
  table, setup instructions.
### Dependencies
- Added `pdf` (PDF generation) and `share_plus` (OS share sheet).

## Phase 11 — Security Hardening & QA
### Added
- Frontend test suite: unit tests (`ApiFailure`, outbox/conflict/pending-
  upload JSON round-trips, filter query mapping, AI status), widget
  tests (`StatusChip`, `PriorityIndicator`, `EmptyState`, `DeadlineChip`,
  `OfflineBanner`, `LoginScreen`), and Hive-backed integration tests
  (`SyncStatusChip`, `TasksListController`, `MeetingsListController`).
### Fixed
- `FcmService` no longer unconditionally logs notification titles/bodies/
  payloads in release builds (`debugPrint` isn't stripped from release —
  all calls are now gated behind `kDebugMode`).
- `test/widget_test.dart`'s smoke test pumped the full app and could hang
  on ungated plugin calls since Phase 10; replaced with a fast, isolated
  `SplashScreen` test.
### Documented
- Frontend security review findings and a backend security/QA checklist
  (rate limiting, Form Request/Policy audit, SQLi/XSS/CSRF, Pest suite)
  for whoever picks up the Laravel repo.

## Phase 10 — Offline Support & Sync Hardening
### Added
- `ConnectivityController` — single online/offline signal the app watches.
- Hive-backed local caches for meetings and tasks; repositories now read
  cache-first and fall back on a connection error.
- Outbox pattern: offline create/update/delete/status-change is queued
  and replayed on reconnect, with temp-id → real-id remapping.
- Conflict resolution: meetings stay last-write-wins; task updates
  detect a diverged server copy and route to a manual-merge screen.
- `OfflineBanner` and `SyncStatusChip` UI.

## Phase 9 — Analytics & Admin
### Added
- Workspace-scoped analytics: productivity score gauge, meetings/month
  bar chart, task-completion donut, department/user activity breakdown
  (`fl_chart`).
- Admin panel: platform stats, storage usage, user management (search +
  disable), content moderation queue — gated to `system_admin`.

## Phase 8 — AI Chat Assistant & Search
### Added
- In-meeting AI assistant chat tab with suggested prompts (summarize,
  who-owns-what, draft follow-up email, generate minutes, project plan).
- Global search across meetings, tasks, and people with debounced
  search-as-you-type and recent searches.

## Phase 7 — Team Collaboration & Workspaces
### Added
- Workspaces with owner/admin/member roles, department grouping, member
  invite/role/remove management, and a paginated activity timeline.

## Phase 6 — Notifications & Calendar
### Added
- Firebase Cloud Messaging push notifications (meeting reminders, task
  assignment/completion, deadlines, invitations).
- Calendar with month/week/day views and a day-agenda bottom sheet.

## Phase 5 — Smart Task Manager
### Added
- Full task CRUD, Kanban board (wide screens) / grouped list (mobile),
  comments, attachments, progress tracking, assignment.

## Phase 4 — AI Transcription, Summary & Task Extraction
### Added
- Transcript and AI summary tabs with status polling.
- Task-candidate review/confirm flow for AI-suggested action items.

## Phase 3 — Audio Recording & Upload
### Added
- Record screen with live waveform, pause/resume/stop.
- Chunked, resumable background upload with an offline queue that
  survives app restarts.

## Phase 2 — Meetings Core (CRUD)
### Added
- Meeting list/filter/search, create/edit, status transitions,
  participant invites, basic in-app notifications.

## Phase 1 — Authentication & User Foundation
### Added
- Splash, onboarding, login/register/forgot-password screens, Google
  sign-in, and profile management.

## Phase 0 — Foundation & Setup
### Added
- Flutter feature-first project scaffold, Riverpod/GoRouter/Dio/Hive base
  configuration, Laravel `/ping` connectivity check.
