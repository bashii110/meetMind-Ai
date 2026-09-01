# Phase 8 — AI Chat Assistant & Search (Flutter frontend)

## What this is
PHASES.md's Phase 8 goal: *"Conversational interaction with meeting/task
data"* — SRD FR-11.1/FR-11.2 (an in-meeting AI assistant) and FR-12.1
(global search across meetings, transcripts, tasks, users, dates, tags,
and summaries).

Two independent pieces landed in this patch:

1. **AI Chat Assistant** — a new "Assistant" tab on `MeetingDetailsScreen`,
   added to the existing `ai_summary` feature (the feature that already
   owns the meeting-scoped AI pipeline: status polling, transcript,
   summary, task candidates).
2. **Global Search** — the `search` feature, which previously only had
   `.gitkeep` placeholders, is now fully built out following the same
   Clean Architecture conventions as every other feature.

No backend was provided, so both were built against the REST contract
already documented in `ARCHITECTURE.md` (`POST /meetings/{id}/assistant/query`
and `GET /search?q=...`) and the same response envelope every other
feature in this app expects. If your backend's actual field names differ,
only the data-layer files listed below need adjusting.

## How to apply
1. Unzip at the root of `frontend/`:
   ```bash
   unzip phase8-assistant-search.zip -d /path/to/frontend
   ```
2. This assumes **Phase 7's workspace patch has already been applied** —
   `app_router.dart` and `dashboard_screen.dart` here are full
   replacements that build on top of Phase 7's versions (workspace routes
   and the Workspaces app-bar icon are still present, plus the new Search
   ones). If you haven't applied Phase 7 yet, apply it first, then this.
3. No `pubspec.yaml` changes — this uses only packages already in the
   project (`dio`, `equatable`, `flutter_riverpod`, `go_router`, `intl`,
   `uuid` — the last already used by `AudioUploadRepositoryImpl`).
4. Run:
   ```bash
   flutter pub get
   flutter run
   ```
   No `build_runner` step needed — hand-written, no codegen, matching
   every other feature in this app.
5. `lib/features/search/**`'s old `.gitkeep` placeholders can be deleted
   now that real files live alongside them.

## What's included

### AI Chat Assistant (`lib/features/ai_summary/`)
- `domain/entities/chat_message.dart` — `ChatMessage` + `ChatRole` enum.
  Purely client-side (no `fromJson`): the assistant endpoint is stateless
  per ARCHITECTURE.md, so there's nothing to fetch from the server.
- `domain/repositories/ai_summary_repository.dart` — **modified**, added
  `queryAssistant(meetingId, prompt)` to the existing interface.
- `domain/usecases/query_assistant_usecase.dart` — **new**.
- `data/datasources/ai_summary_remote_data_source.dart` — **modified**,
  added the `POST /meetings/{id}/assistant/query` call.
- `data/repositories/ai_summary_repository_impl.dart` — **modified**,
  wires the new method through.
- `presentation/providers/ai_summary_providers.dart` — **modified**,
  added `queryAssistantUseCaseProvider`.
- `presentation/providers/assistant_chat_controller.dart` — **new**.
  `AssistantChatController extends AutoDisposeFamilyNotifier` (sync, not
  async — chat state is just a growing list + a sending flag, mirroring
  how `RecordingController` uses the sync `AutoDisposeNotifier` variant
  elsewhere in this app), family-keyed by meeting id.
- `presentation/widgets/assistant_tab.dart` — **new**. Chat bubbles (user
  right-aligned, assistant left-aligned in the AI-accent tertiary color,
  per `AppTheme.aiAccent`'s existing convention), a row of suggested-prompt
  chips shown before the first message, a typing indicator while a query
  is in flight, and a text composer. Gated on `AiStatus` exactly like
  `TranscriptTab` — the assistant only needs the transcript, not the full
  summary/task-extraction pipeline, so it unlocks as soon as that's ready.

**Wired in**: `MeetingDetailsScreen` now has 6 tabs — Overview,
Transcript, Summary, **Assistant**, Tasks, Files — instead of 5. Nothing
else on that screen changed (the "Files" tab is still the pre-existing
`_ComingSoonTab` placeholder from before this patch — untouched, out of
scope for Phase 8).

### Global Search (`lib/features/search/`)
- `domain/entities/search_result.dart` — `SearchResult` +
  `SearchResultType` (meeting/task/user), carrying a `matchedIn` field
  (title/transcript/summary/description/tag/email) so the UI can show
  *where* a query matched without needing a distinct entity per source.
- `domain/entities/search_results.dart` — `SearchResults`, the
  `{ meetings, tasks, users }` categorized envelope.
- `domain/repositories/search_repository.dart`,
  `domain/usecases/search_usecase.dart`
- `data/models/*.dart`, `data/datasources/search_remote_data_source.dart`
  (`GET /search?q=...`), `data/repositories/search_repository_impl.dart`
- `presentation/providers/search_providers.dart` — DI wiring
- `presentation/providers/search_controller.dart` — debounced (400ms)
  search-as-you-type, filter state (All/Meetings/Tasks/People), and an
  in-memory recent-searches list, all in one `AutoDisposeNotifier` (same
  pattern `RecordingController` already uses in this codebase)
- `presentation/widgets/search_result_tile.dart`
- `presentation/screens/search_screen.dart` — search bar as the app-bar
  title (auto-focused on open), filter chips, recent searches when the
  query is empty, sectioned results (Meetings/Tasks/People) otherwise.
  Tapping a meeting/task result navigates to its details screen; tapping
  a person shows a small dialog (there's no "view another user's profile"
  screen in this app yet — `ProfileScreen` is scoped to the signed-in
  user only).

**Wired in**: `core/router/app_router.dart` now has
`GoRoute(path: AppRoutes.search, ...)` (the `search` route constant
already existed in `app_routes.dart` from the original scaffold — no
change needed there). Dashboard app bar now has a Search icon, first in
the action row.

## Design decisions worth knowing about
- **One generic assistant endpoint, many suggested prompts.** SRD
  FR-11.2 lists several distinct capabilities (summarize, follow-up
  email, meeting minutes, project plan). Rather than bespoke UI/endpoints
  per capability, `AssistantTab` offers them as tappable presets that all
  go through the same `queryAssistant(meetingId, prompt)` call — the
  backend's OpenAI call differentiates behavior by prompt text, not by
  route. This matches PHASES.md's own framing ("assistant query endpoint
  ... with suggested prompts") and keeps the API surface to the one
  endpoint ARCHITECTURE.md already documents.
- **Chat history is ephemeral, not persisted.** ARCHITECTURE.md only
  documents a single stateless query endpoint, not a
  messages-list/history endpoint, so `AssistantChatController` keeps the
  conversation in memory for as long as the Assistant tab stays mounted
  and nothing more. Natural follow-up if you want persistence: add an
  `assistant_messages` table + `GET /meetings/{id}/assistant/messages`,
  and swap the controller's `build()` to load from that instead of
  starting empty.
- **Search results are grouped by type, not one flat ranked list** — the
  screen renders three clearly-labeled sections instead of interleaving
  meetings/tasks/people by relevance score, which is both simpler to
  implement client-side and easier to scan.
- **Recent searches are in-memory only**, not persisted to Hive. Adding
  persistence would mean a new box in `core/storage/local_db.dart`
  (`HiveBoxes.searchHistory`) opened at startup — a small addition, but
  deliberately left out here to keep this patch's blast radius to the
  `search` feature plus the two files it needed wiring into.
- **No date-range picker.** SRD FR-12.1 mentions searching "... and
  dates," which is interpreted here as: dates are shown on results for
  context, and any date-like text in the query is just part of the
  full-text query sent to the backend, same as any other term. A
  dedicated date-range filter would be a reasonable follow-up but isn't
  called for explicitly enough in the spec to justify the extra UI here.

## Known simplifications (documented trade-offs, not bugs)
- No widget/unit tests were added, consistent with this frontend's
  existing note that this sandbox has no Flutter/Dart SDK to run
  `flutter analyze`/`flutter test` against. Please run both after
  `flutter pub get` and let me know what comes up.
- The assistant's suggested prompts are a fixed static list
  (`_suggestedPrompts` in `assistant_tab.dart`) rather than
  server-driven — simplest option, and there's no documented endpoint for
  fetching dynamic prompt suggestions.

## If you want the backend too
This patch is frontend-only, matched against `ARCHITECTURE.md`'s
documented endpoints. If you connect a Laravel backend repo (or want one
scaffolded), the pieces this frontend expects are:
- `AssistantController::query(Meeting $meeting, Request $request)` —
  pulls the meeting's transcript (and tasks, for ownership/deadline
  prompts) as context, calls OpenAI with the user's `prompt`, and returns
  `{ data: { reply: "..." } }`.
- `SearchController::index(Request $request)` — full-text/indexed search
  (Laravel Scout + Meilisearch/Algolia, or MySQL `FULLTEXT` indexes for a
  simpler start) across meeting titles/transcripts/summaries, task
  titles/descriptions, and user names/emails, returning
  `{ data: { meetings: [...], tasks: [...], users: [...] } }` with each
  item carrying `matched_in` (which field/source the hit came from).
Happy to build that out as a follow-up if you share the backend repo.
