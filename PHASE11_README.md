# Phase 11 — Security Hardening & QA (Flutter frontend)

## What this is, and what it isn't
PHASES.md's Phase 11 checklist is mostly **backend** work:

- [ ] Rate limiting on auth and AI-triggering endpoints
- [ ] Full input validation audit (Form Requests) and Policy/RBAC review
- [ ] Penetration-style checklist: SQLi, XSS, CSRF, token expiry/rotation
- [ ] Backend test suite (PHPUnit/Pest: unit + feature tests)
- [ ] Frontend test suite (Flutter widget/unit tests, key integration flows)
- [ ] Cross-device QA pass (Android/iOS, light/dark mode, various screen sizes)

As with every phase so far, only the Flutter frontend repo has been
shared — there's no Laravel backend to add rate limiting, Form Requests,
Policies, or a Pest suite to, and no way to run a SQLi/XSS/CSRF pass
against endpoints that live in a repo I can't see. Those items are listed
under **"For the backend"** below as a concrete checklist for whoever
picks up that repo, matching the pattern already used in earlier phase
READMEs for backend-only pieces.

What **is** deliverable frontend-only, and what this patch contains:
1. A real Flutter **test suite** — the frontend half of the checklist,
   literally.
2. Two concrete findings from a **frontend security review**, fixed.
3. A **cross-device/responsiveness audit**, done by reading the code
   (this sandbox has no physical devices or simulators — see each
   phase's "no Flutter SDK" note) — findings and their status below.

## How to apply
1. Unzip at the root of `frontend/`:
   ```bash
   unzip phase11-security-qa.zip -d /path/to/frontend
   ```
2. **No `pubspec.yaml` changes** — the test suite is hand-written against
   `flutter_test` (already a dev dependency) with hand-rolled fakes for
   the repository interfaces, matching this project's existing
   no-codegen convention (no mockito/mocktail added).
3. Run the suite:
   ```bash
   flutter test
   ```

## What's included

### 1. Frontend test suite (`test/`)
- `test_utils/fixtures.dart` — small builder functions for `AppUser`,
  `TaskEntity`, `Meeting` test data.
- `test_utils/fakes/` — hand-written fakes for `TaskRepository` and
  `MeetingRepository`, plus a `FixedAuthController` that overrides
  `AuthController.build()` so controller tests depending on
  `authControllerProvider` don't need a real token/network round trip.
- **Unit tests**: `ApiFailure.from`'s DioException-unwrapping logic,
  `OutboxEntry`/`SyncConflict`/`PendingUpload` JSON round-trips (and
  their documented `copyWith` quirks — e.g. `errorMessage` is
  deliberately *not* preserved by default, since callers pass `null` to
  clear a previous failure on retry), and `TaskFilters`/`MeetingFilters`'
  query-param mapping including the "a clear flag wins over a
  simultaneous replacement value" precedence rule.
- **Widget tests**: `StatusChip`, `PriorityIndicator`, `EmptyState`,
  `DeadlineChip`, `OfflineBanner` (both online/offline render states via
  `isOnlineProvider` override), and `LoginScreen` (renders both fields,
  and shows the failure message returned by the controller on a rejected
  login).
- **Integration-style tests**: `SyncStatusChip` runs against a *real*
  temp-dir Hive store (not a mocked `OutboxSyncManager`) across all three
  of its render states — empty, pending-badge, conflict-badge — since
  it's Phase 10's actual wiring, not a stand-in. `TasksListController`
  and `MeetingsListController` are tested against the hand-written fake
  repositories, covering initial load, pagination (`loadMore`, including
  the "stop once exhausted" and "no-op while already loading" guards),
  filter application, and the "a failed page keeps existing items and
  clears the spinner" error path.

### 2. Frontend security fixes
- **`core/notifications/fcm_service.dart`** — every `debugPrint` call is
  now gated behind `kDebugMode`. `debugPrint` is **not** compiled out of
  release builds (it's throttled, not stripped), so this file was
  unconditionally writing message titles/bodies/data payloads to the
  device's system log in production — meeting/task notification content
  landing somewhere it shouldn't. Now matches the `kDebugMode` guard
  convention `main.dart` already uses for its own Firebase-init
  diagnostics.
- **`test/widget_test.dart`** — the existing smoke test pumped the full
  `MeetMindApp`, which (since Phase 10) touches `connectivity_plus`,
  `flutter_secure_storage`, and fires a live Dio request on startup, none
  of which have platform-channel mocks available under plain
  `flutter test`. Replaced with a fast, deterministic test of
  `SplashScreen` alone (the screen the app actually shows first, and a
  `ConsumerWidget` that doesn't read any provider in `build()`, so it
  needs nothing overridden). A genuine full-app boot test belongs in
  `integration_test/`, noted below.

### 3. Frontend security review — findings and status
| Area | Finding | Status |
|---|---|---|
| Token storage | Access/refresh tokens are in `flutter_secure_storage` (Keychain/Keystore-backed), not `SharedPreferences`. | Already correct — no change needed. |
| Logging | `FcmService` logged notification content unconditionally. | **Fixed** (see above). |
| Logging | `PrettyDioLogger` request/response body logging is already gated by `enableLogging = !const bool.fromEnvironment('dart.vm.product')`, i.e. off in release builds. | Already correct. |
| Deep links | `ResetPasswordScreen` receives the reset token via a `meetmindai://` deep link query parameter. | Standard practice for this flow (matches how Laravel's own signed reset links work) — flagged, not changed; the token is single-use and short-lived server-side. |
| Client secrets | `_googleServerClientId` in `auth_providers.dart` is a hardcoded OAuth **client ID**. | Not sensitive — client IDs are meant to be public/embedded; nothing to fix. |
| Network security config (Android) | `AndroidManifest.xml` doesn't set `android:usesCleartextTraffic="false"` or ship a `network_security_config.xml` pinning the API host. | **Recommended, not applied** — this is a release-build hardening step best owned alongside the real production API domain (pinning a dev IP like the current `192.168.0.104` default would break local development). |
| Release build flags | No `--obfuscate --split-debug-info=<dir>` in the documented build command. | **Recommended, not applied** — a build-time flag, not a code change; worth adding to the release checklist in `README.md` once there's a CI/CD pipeline (PHASES.md's own roadmap already earmarks this). |
| Dependency versions | `pubspec.yaml` uses caret (`^`) constraints throughout. | Acceptable for active development; recommend switching to a committed `pubspec.lock` (already `.gitignore`'d — see `.gitignore`'s `pubspec.lock` line) for release builds specifically, so a release isn't built against whatever happens to resolve that day. |

### 4. Cross-device / responsiveness audit
Reviewed in code (no physical devices/simulators available in this
sandbox — see every earlier phase's "no Flutter SDK" note):
- **Dark mode**: `AppTheme.light()`/`AppTheme.dark()` both derive from
  `ColorScheme.fromSeed`, and `MeetMindApp` sets `themeMode:
  ThemeMode.system` — every screen reads colors through `Theme.of(context)`
  rather than hardcoded `Color` literals, with the sole intentional
  exception of `AppTheme._aiAccent` (by design, per its own doc comment —
  a fixed hue so AI content reads as a distinct signal in both themes).
  No hardcoded light-only colors found elsewhere in `lib/`.
- **Responsive layout**: `TaskListScreen` already branches on
  `LayoutBuilder`'s width (Kanban ≥800px, grouped list below) —
  the one screen PHASES.md/DESIGN.md call out for this explicitly.
  Every other screen uses `Spacing`-based padding and `Expanded`/`Flexible`
  rather than fixed pixel widths, so they reflow reasonably at different
  widths without additional breakpoints.
- **Touch targets**: `IconButton`'s Material default (48dp) is used
  throughout rather than custom-sized tap targets, satisfying DESIGN.md
  5's 44×44dp minimum without any screen needing an explicit fix.
- **Text scaling**: nothing in `lib/` disables system font scaling
  (no `MediaQuery.textScalerOf` overrides found), so DESIGN.md 5's
  "respect system font-scaling settings" requirement holds by not having
  been overridden.
- **What still needs a real pass**: actual on-device verification
  (notch/gesture-bar insets, split-screen/foldable behavior, RTL layout
  mirroring if a right-to-left locale is ever added) — none of that is
  checkable from source alone, and is the one item on this phase's
  checklist that genuinely needs physical or simulated devices.

## For the backend
None of the following were implemented — there's no backend repo to add
them to — but they're what Phase 11's remaining checklist items need,
so whoever has the Laravel repo can pick them up directly:
- **Rate limiting**: Laravel's built-in `throttle` middleware on
  `POST /auth/login`, `/auth/register`, `/auth/forgot-password`, and any
  endpoint that triggers an OpenAI call (`.../recording/complete`, the
  assistant query endpoint) — these are exactly the endpoints ARCHITECTURE.md
  6 already calls out for "especially on auth and AI endpoints."
- **Form Requests / Policy audit**: confirm every mutating endpoint this
  frontend calls has a matching `FormRequest` (not just inline
  `$request->validate()`) and that every resource-scoped endpoint
  (meetings, tasks, workspaces, departments) has a `Policy` method gating
  it — ARCHITECTURE.md 3.2 already documents this as the intended
  pattern; Phase 11 is the audit pass confirming it was followed
  everywhere, not just on the endpoints built first.
- **SQLi**: audited by using Eloquent/query-builder parameter binding
  everywhere (no raw string-interpolated SQL) — straightforward to grep
  for `DB::raw(` / `whereRaw(` with untrusted input as a first pass.
- **XSS**: primarily a concern for any HTML email templates
  (`ResetPasswordNotification`, invite emails) — confirm Blade's default
  `{{ }}` escaping is used throughout and nothing user-supplied hits
  `{!! !!}`.
- **CSRF**: N/A for this API (Sanctum bearer-token auth, no
  cookie-session state for the mobile client) — worth a one-line note in
  ARCHITECTURE.md confirming that's a deliberate non-issue rather than an
  oversight.
- **Token expiry/rotation**: already documented as implemented
  server-side per ARCHITECTURE.md 3.3; Phase 11's job here is just
  confirming the actual TTL values match what's documented, and that a
  revoked/expired refresh token is rejected (not silently re-issued).
- **Backend test suite**: PHPUnit/Pest unit tests per Service class and
  feature tests per endpoint, mirroring this patch's frontend test
  suite's shape (one test file per class/controller, happy path + at
  least one failure path each).
