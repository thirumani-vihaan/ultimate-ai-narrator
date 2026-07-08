# ARCHITECTURE — Ultimate AI Narrator

Feature-first Flutter app with a clean, injectable, **immutable-state + explicit-transition** core. Design optimized for the hard constraint: smooth on ~3GB-RAM Android.

## Component map (single responsibility each)

```
lib/
  main.dart                     # REAL ENTRY POINT: builds ProviderScope with real factories
  app.dart                      # MaterialApp + PebloTheme + StoryScreen
  core/
    theme/peblo_theme.dart      # brand colours, typography, kid-friendly tokens
    logging.dart                # tiny logger (every caught error logs context)
  narration/
    narrator.dart               # Narrator interface + NarrationState (sealed)
    flutter_tts_narrator.dart   # real native/browser TTS
    elevenlabs_narrator.dart    # real remote TTS (bonus, key-gated) + AudioCache use
    fake_narrator.dart          # fixture-driven fake (timing + forced failures)
    audio_cache.dart            # AudioCache interface + in-memory/file impl (hash->bytes)
  quiz/
    quiz_models.dart            # Question (immutable) + fromJson validation
    quiz_repository.dart        # QuizRepository interface
    asset_quiz_repository.dart  # DEFAULT: bundled asset JSON
    http_quiz_repository.dart   # optional real backend (key/config-gated)
  haptics/
    haptics.dart                # Haptics interface + Real + Fake
  state/
    app_phase.dart              # StoryPhase sealed states (the state machine)
    story_state.dart            # immutable StoryState (+ copyWith)
    story_controller.dart       # StateNotifier: orchestrates narration + phase machine
    quiz_state.dart             # immutable QuizState
    quiz_controller.dart        # StateNotifier: answer logic (attempts, wrong/correct)
    providers.dart              # Riverpod providers (overridden in main + tests)
  ui/
    story_screen.dart           # the screen (composes the widgets below)
    widgets/
      buddy_character.dart      # AI buddy; mood: idle | talking | happy | thinking
      story_card.dart           # narrative text card
      read_button.dart          # "Read Me a Story" (reflects preparing/narrating)
      loading_indicator.dart    # preparing state
      error_retry.dart          # friendly failure message + Retry
      quiz_panel.dart           # DATA-DRIVEN renderer (N options)
      option_tile.dart          # one answer; shake on wrong
      celebration_overlay.dart  # confetti + success (RepaintBoundary-wrapped)
```

## State machine (`StoryPhase`) — the heart of the app
Immutable sealed states; only `StoryController` mutates, via explicit transitions:

```
idle ──tapRead──▶ preparing ──ttsReady──▶ narrating ──ttsComplete──▶ revealing ──animDone──▶ quiz
  ▲                   │                        │                                              │
  │                   └────ttsError───────┐    └────ttsError──────┐                           │
  └──────────────── retry ◀── error ◀─────┴───────────────────────┘                          │
                                                                          correctAnswer ──▶ success
```
- `idle` — buddy waiting, button enabled.
- `preparing` — TTS being initialized/fetched (loading UI); button shows spinner.
- `narrating` — audio playing; buddy "talking".
- `revealing` — audio finished; quiz animating in (the explicit **transition state** the spec asks about).
- `quiz` — quiz interactive; wrong→shake+haptic+retry (stays in `quiz`), correct→`success`.
- `success` — celebration + Success state.
- `error(message)` — reachable from `preparing`/`narrating`; offers Retry back to `preparing`.

**Why explicit states, not booleans:** the audio→quiz handoff and error/retry are exactly where "no single test catches it" bugs live. A sealed phase makes every transition a named, testable, idempotent event and prevents "loading + error + playing" impossible combos.

## Data flow & ownership
- **State lives in two `StateNotifier`s** (`StoryController`, `QuizController`); UI is a pure function of their immutable state (`ConsumerWidget` + scoped `select`). No scattered `setState` for core logic.
- `StoryController` is the **single consumer** of `Narrator.state`.
- Fire-and-forget side effects (`Haptics`) are called from the controller, never awaited in a way that blocks the UI.

## Module boundaries (integration points — where bugs hide)
1. **StoryController ↔ Narrator** — `speak()` + `Stream<NarrationState>`. *Contract:* `speak()` never throws; errors arrive as `NarrationError`. Duplicate/late events after `revealing` are ignored (idempotent).
2. **QuizController ↔ QuizRepository** — `loadQuestions()` → `List<Question>`. *Contract:* throws `QuizLoadException`/`QuizFormatException`; controller catches, logs, sets error.
3. **UI ↔ Controllers** — watch state, call intents (`readStory()`, `answer(option)`, `retry()`).
4. **Narrator(Remote) ↔ AudioCache ↔ player** — cache lookup by SHA-1(text) before any network call.
5. **main.dart ↔ providers** — the ONE place real impls are constructed (see INTERFACES §Wiring).

## Concurrency model (explicit)
- `Narrator` is an **async producer**; `StoryController` is the **single consumer** on the UI event loop. Events are processed **sequentially** in arrival order.
- The narration stream is **long-lived** but the controller expects a **finite logical sequence per read** (`preparing → speaking → completed|error`). After a terminal event, the controller unsubscribes / ignores further events until the next `readStory()`. This prevents the "connection open but nothing happens" class of bug and duplicate-completion double-transitions.
- No two flows write the same state; all mutation funnels through the controller's reducer-style handlers.

## Performance design (hard-budget-driven)
- `const` widgets everywhere possible; `select`-scoped rebuilds so a shake doesn't rebuild the story card.
- Animations via `AnimationController` + `AnimatedBuilder`, each wrapped in `RepaintBoundary`.
- Confetti particle count capped; controller stopped+disposed on leave.
- No heavy assets; buddy is a lightweight vector/emoji-style widget (no large PNGs).
- All controllers/streams `dispose()`d — leak-free (spec's Swift memory note applied to Dart).
