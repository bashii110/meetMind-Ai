# MeetMind AI — Frontend (Flutter)

Cross-platform client for MeetMind AI. See `/docs` at the repo root for the
full Architecture, Design, SRD, and Phases documents this scaffold implements.

## Stack
Flutter 3.x, Riverpod, GoRouter, Dio, Hive/Drift, Firebase Cloud Messaging —
see `pubspec.yaml` for the full dependency list.

## What's here vs. what you need to generate

This scaffold contains the **Dart source tree only** (`lib/`, `test/`,
`pubspec.yaml`). It was generated without access to the Flutter SDK or
pub.dev, so the platform folders (`android/`, `ios/`, `web/`, etc.) and
`pubspec.lock` aren't present yet. Generate them locally:

```bash
# From this frontend/ directory:
flutter create --project-name meetmind_ai --org com.meetmind --platforms android,ios .
```

`flutter create .` will not overwrite the existing `lib/` or `pubspec.yaml` —
it only fills in the missing platform folders. Then:

```bash
flutter pub get

# Code generation (freezed / json_serializable / riverpod_generator / hive_generator)
dart run build_runner build --delete-conflicting-outputs

flutter run
```

By default the app points at `http://10.0.2.2:8000/api/v1` (the Android
emulator's alias for your host machine's `localhost:8000`, matching the
backend's `php artisan serve`). Override per-build:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

On first run you should land on the onboarding slides, then the login
screen. Register an account (or use Google sign-in), and you'll land on
the dashboard — an empty "No meetings yet" state at first. Tap "New
meeting" to create one; seeing it appear in the list is your end-to-end
connectivity check (Phase 0's `/ping` card was retired now that real
data flows through the same path).

## Google Sign-In setup (FR-1.2)

`google_sign_in` v7 needs platform registration before it'll compile/run:

- **Android**: register your app's SHA-1 fingerprint in the Google Cloud
  Console (or Firebase console) for this package name. See the
  [`google_sign_in_android` README](https://pub.dev/packages/google_sign_in_android#integration).
- **iOS**: add the reversed client ID URL scheme to `Info.plist`. See the
  [`google_sign_in_ios` README](https://pub.dev/packages/google_sign_in_ios#ios-integration).

Then pass your OAuth client IDs at build time:
```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=your-server-client-id.apps.googleusercontent.com
```
`GOOGLE_SERVER_CLIENT_ID` should match the backend's `GOOGLE_CLIENT_ID`
(backend `.env`) — see `lib/features/auth/data/datasources/google_auth_data_source.dart`
for how the resulting access token gets sent to `POST /api/v1/auth/google`.

## Microphone permission setup (FR-4.x)

`audio_waveforms` needs the platform permission declared before it'll
request it at runtime:

- **Android** — add to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  ```
- **iOS** — add to `ios/Runner/Info.plist`:
  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>MeetMind AI needs microphone access to record your meetings.</string>
  ```

Both files only exist after you've run `flutter create .` per the setup
steps above. The recorder requests the OS permission dialog itself on
first use — a denial surfaces as an error in the record screen, no
separate `permission_handler` package involved.

**Why only `audio_waveforms` and not also `record`:** both packages can
capture audio; running two native audio-recording plugins in the same app
risks them fighting over the platform audio session. `audio_waveforms`'s
`RecorderController` does capture *and* live waveform rendering in one
native session, so it's the only one used here.

## A note on validation

This sandbox has no Flutter/Dart SDK, so I could not run `flutter analyze`
or `flutter test` against this code — only structural checks (syntax
balance, careful manual review, and verifying package APIs like
`google_sign_in` v7 and `audio_waveforms` v2 against current docs/examples
before writing against them — e.g. confirming `WaveStyle`'s actual field
names rather than guessing).
Please run both after `flutter pub get`:
```bash
flutter analyze
flutter test
```
and let me know what comes up — I'd rather fix real compiler feedback than
guess twice.

## Architecture — feature-first + Clean Architecture

```
lib/
├── core/            # network (Dio+interceptors), storage (Hive/secure), theme, router, di
└── features/
    └── <feature>/
        ├── data/            # DTOs, datasources (Dio/Hive), repository impls
        ├── domain/          # entities, repository interfaces, use cases (pure Dart)
        └── presentation/    # screens, widgets, Riverpod providers
```

Features scaffolded: `auth`, `meetings`, `recording`, `ai_summary`, `tasks`,
`calendar`, `notifications`, `workspace`, `search`, `analytics`, `profile`,
`admin`, plus a lightweight `dashboard` (presentation-only for now — it
aggregates other features rather than owning its own data).

`auth` and `profile` are fully implemented (Phase 1). `meetings` and
`notifications` are fully implemented (Phase 2 — CRUD, status transitions,
participant invites, basic in-app notification list; no push yet).
`recording` is implemented (Phase 3 — capture with live waveform,
chunked/resumable background upload; see "A note on the upload manager"
below). `profile`'s domain layer reuses `auth`'s `AppUser` entity rather
than duplicating it, since they represent the same backend resource — an
intentional exception to "features don't import each other," documented at
the top of `lib/features/profile/domain/repositories/profile_repository.dart`.

### A note on the upload manager

`features/recording/presentation/providers/audio_upload_manager.dart` is
deliberately **not** `autoDispose` — recording a meeting and then
navigating away must not cancel an in-flight upload (DESIGN.md 3.5). It
persists progress to Hive and resumes from the server's authoritative
`received_chunks` after a dropped connection or a full app restart, and
listens for connectivity changes to auto-resume. What it does **not** do:
true OS-level background execution once the app is fully force-quit (that
would need `flutter_background_service` or platform WorkManager/BGTaskScheduler
integration) — noted here rather than silently under-delivering on
"reliable... even on flaky connections."

Rule of thumb per layer:
- **domain/** never imports Flutter or Dio — pure Dart only.
- **data/** implements domain's repository interfaces using `core/network`
  (remote) and `core/storage` (local/offline cache).
- **presentation/** holds `ConsumerWidget`s and `Notifier`/`AsyncNotifier`
  providers; it depends on domain use cases, never on `data/` directly.

## Conventions
- Route paths live in `core/router/app_routes.dart` — never hardcode a path string.
- All AI-generated content (summaries, extracted tasks, assistant replies)
  should use `Theme.of(context).colorScheme.tertiary` (see `AppTheme.aiAccent`)
  so it's visually distinct per DESIGN.md 2.1.
- Every feature's remote calls go through the shared `dioProvider`
  (`core/di/providers.dart`) so auth headers and error mapping stay consistent.

## Tests
```bash
flutter test
```

## Known issues / version pinning
Flutter's plugin ecosystem moves fast, and federated plugins (packages split
into `_platform_interface` + one package per OS) occasionally ship
mismatched versions across their sub-packages, which fails compilation on
**every** platform, not just the one that's actually broken — Flutter
compiles the whole dependency graph into one kernel snapshot. If you hit an
error like:

```
Error: The non-abstract class 'X' is missing implementations for these members: ...
```

it's almost always this, not your code. Fix: bump the top-level package to
its current major version rather than downgrading — patch releases within
a stale major version don't get the sub-package version bumps backported.
Check `flutter pub outdated` and the package's pub.dev page for its
current dependency graph. (This project doesn't currently depend on any
federated plugins with known active skew — `audio_waveforms` bundles its
own platform implementations rather than splitting into per-OS packages —
but it's worth knowing the pattern if you add one later.)

## Next steps (see PHASES.md)
Phases 1–3 are done:
- **Phase 1** — auth (login/register/forgot-password/reset-password,
  Google sign-in) + profile.
- **Phase 2** — meetings (list/filter/search, create/edit, status,
  participant invites) + basic in-app notifications.
- **Phase 3** — recording (waveform, pause/resume/stop) + chunked,
  resumable background upload.

Phase 4 (AI Transcription, Summary & Task Extraction) is next: a
Transcript tab and an AI Summary tab replace their `_ComingSoonTab`
placeholders in `meeting_details_screen.dart`, driven by status polling
against the backend's async job pipeline.
