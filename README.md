# Ultimate AI Narrator 🎧🤖

An **AI Story Buddy** for children. The spec asks for a buddy that reads *one* story and
asks *one* quiz — so I took it further: the child **designs their own adventure** (their
name, a buddy animal, a magical place) and the app **generates a unique, personalised story
*and* a matching quiz derived from that story**, then narrates it and quizzes them — with
gentle "try again" feedback and a confetti celebration.

Built for the **Peblo Flutter Developer Intern Challenge**, with performance on
mid-range (~3 GB RAM) Android devices treated as a hard constraint.

## 🌟 The headline: "Make YOUR Story" — an AI story + quiz generator

- **The child creates the story.** Pick a name, a buddy (🦊🐉🐰🤖🦉) and a place
  (🌲🚀🐚🍭☁️) → tap **"Make My Story!"**.
- **The app generates it.** A `StoryGenerator` weaves those choices into a coherent tale,
  then builds a quiz whose questions & answers are **derived from the generated story's own
  facts** (not hard-coded) — so the "data-driven quiz" requirement now spans the *entire*
  content, with genuinely varying 3/4/5-option questions.
- **Mock-first, offline-safe.** A real **on-device generative engine**
  (`TemplateStoryGenerator`) works with **zero keys / no network**; a real **LLM**
  (`LlmStoryGenerator`, OpenAI-compatible, key-gated) is a drop-in upgrade that **falls back
  to the on-device engine** on any error. Infinite, personalised, multi-story.

> **Live demo target on the build machine:** Flutter **web** (Chrome), where `flutter_tts`
> speaks via the browser Web Speech API — real narration, no API key. The same codebase
> targets Android.

---

## 🔊 Premium narration — powered by [ElevenLabs](https://elevenlabs.io)

The story isn't just shown on screen — it's **spoken in a warm, natural voice** by
**ElevenLabs** premium text-to-speech, the app's flagship "wow" moment:

- **Real ElevenLabs TTS**, on the **`eleven_flash_v2_5` ("Flash")** model — near-realtime
  latency and ~**half the credits** per character, so a 10K-credit budget stretches far.
- **Zero-cost repeats.** Every clip is cached by **`sha1(text + voice)`**, so replaying a
  story (or re-reading the same words) never spends another credit or re-hits the API.
- **Web-reliable playback.** Audio plays through a **base64 data-URI** into `just_audio`,
  which is robust across browsers (raw byte-streaming is flaky on `just_audio_web`).
- **Never breaks the experience.** A `FallbackNarrator` **auto-degrades to the device's
  built-in voice** on any error (missing/invalid key, 401, 429, offline) — the story is
  *always* read aloud.
- **Honest, live attribution.** The UI shows **which voice is actually speaking**
  ("Voice: ElevenLabs · Flash" vs "Built-in voice"), and a **"Powered by ElevenLabs"**
  credit appears **only while ElevenLabs is the active voice**.
- **Key-gated & mock-first.** With no key it uses free native/browser TTS; drop a key in
  `keys.json` and the premium voice lights up — *no code change*.

> **Enable it:** put your key in `keys.json` (git-ignored) and run with
> `--dart-define-from-file=keys.json`. The key must have the **`text_to_speech`**
> permission. Full steps in [`REAL_API_SETUP.md`](REAL_API_SETUP.md).

---

## ✨ What it does

| Stage | Behaviour |
|------|-----------|
| **Create** | The child designs their adventure; the AI conjures a story + quiz. |
| **Idle** | Buddy waits; a prominent **"Read Me a Story"** button. |
| **Preparing** | Loading state ("Warming up my voice…") while TTS initialises. |
| **Narrating** | Story card highlights; buddy "talks"; story is spoken aloud. |
| **Revealing** | Explicit transition state ("Here comes a question!") as the quiz animates in. |
| **Quiz** | Rendered **from JSON** — 3, 4 or 5 options, no code change. |
| **Wrong** | The tapped tile **shakes** (damped), a haptic buzz fires, gentle retry message. |
| **Correct** | **Confetti** + happy buddy + a "You did it!" Success state. |
| **Progression** | A 3-question sequence (with 3/4/5 options) demonstrates the data-driven engine live; progress dots + "Next question" / "Read it again". |

## 🌟 Extras (beyond the brief)

- **Score & stars** — ⭐⭐⭐ per question (fewer wrong tries = more stars) with a running
  total and a finish summary.
- **Word-highlight narration** — the story text lights up word-by-word as Pip reads
  (native TTS progress; graceful fallback on web).
- **Sound effects + mute** — gentle bundled chimes on correct/wrong, with a mute toggle
  that **persists across launches** (`shared_preferences`).
- **Stop control** — a child can stop the story mid-read.
- **Premium ElevenLabs narration** *(see the dedicated section above)* — real ElevenLabs
  TTS on the Flash model, cached by content hash so repeats are free, with a **live
  "Voice: ElevenLabs · Flash" indicator** and a **"Powered by ElevenLabs"** credit; it
  auto-falls-back to the built-in device voice on any error.
- **Delightful, cheap visuals** — animated sky + drifting clouds, a talking-mouth buddy,
  staggered option-tile entrances — all `RepaintBoundary`-isolated and reduced-motion aware.
- **Accessibility** — screen-reader live announcements per phase, reduced-motion support,
  large tap targets, high contrast.

---

## 🧱 Project structure

```
lib/
  main.dart                    # REAL ENTRY POINT — builds ProviderScope with real impls
  app.dart                     # MaterialApp + Peblo theme
  core/                        # theme + logging
  narration/                   # Narrator interface, FlutterTts + ElevenLabs impls, fake, cache
  quiz/                        # Question schema (validated), repositories (asset + http)
  haptics/                     # Haptics interface + real/fake
  state/                       # StoryController (phase machine), QuizController, providers
  ui/                          # StoryScreen + widgets (buddy, quiz panel, confetti, …)
assets/quiz/quiz.json          # default quiz "as if served by the backend"
test/                          # 68 offline tests (no devices, no credentials)
*.md                           # architecture, interfaces, plan, risk log, metrics, reports (repo root)
```

Design docs: [`ARCHITECTURE.md`](ARCHITECTURE.md), [`INTERFACES.md`](INTERFACES.md),
[`SPEC_SUMMARY.md`](SPEC_SUMMARY.md), [`RISK_LOG.md`](RISK_LOG.md),
[`METRICS.md`](METRICS.md), [`FINAL_REPORT.md`](FINAL_REPORT.md).

---

## ▶️ Running it

```bash
flutter pub get

# Web demo (real browser TTS, no key needed):
flutter run -d chrome

# Premium ElevenLabs narration (recommended) — put your key in keys.json (git-ignored):
flutter run -d chrome --dart-define-from-file=keys.json
# …or pass it inline (uses the eleven_flash_v2_5 "Flash" model by default):
flutter run -d chrome --dart-define=ELEVENLABS_API_KEY=xxxxxxxx

# Optional: fetch the quiz from a real backend instead of the bundled asset
flutter run -d chrome --dart-define=QUIZ_ENDPOINT=https://your.api/quiz
```

### Tests & static analysis (fully offline, zero credentials)
```bash
flutter analyze        # 0 issues (strict lints)
flutter test           # 68 tests pass
```

---

## 📝 Design answers (the challenge's README questions)

### 1. Which framework, and why
**Flutter.** It gives one codebase for Android (the target audience), a crisp
60 fps animation pipeline, and — decisively for this environment — it can be **built and
tested headlessly on Windows** and demoed on **web** with real browser TTS. State is
managed with **Riverpod** for rebuild-scoped, easily-injectable, unit-testable state.

### 2. Managing the transition state between audio ending and the quiz appearing
The whole screen is a **sealed state machine** (`StoryPhase`: idle → preparing → narrating
→ **revealing** → quiz → success, plus error). The audio→quiz handoff is its own explicit
`revealing` phase, so it is testable and can't collide with other states. `StoryController`
is the **single consumer** of the narrator's event stream and maps `NarrationCompleted` to
`revealing`, then (after a short reveal animation) to `quiz`. Crucially the completion
handling is **idempotent** — duplicate/late TTS completion callbacks can't double-advance —
and a **watchdog timer** guarantees the quiz still appears even if a completion event never
fires (a real TTS quirk). See `story_controller_test.dart`.

### 3. Building the quiz to be data-driven
The renderer draws `question.options.length` tiles via a `.map` — it never references a
fixed count or index. `Question.fromJson` validates the payload (non-empty prompt, ≥2
unique non-blank options, answer ∈ options) and throws a typed `QuizFormatException` on
anything malformed. The repository accepts a bare array, a `{"questions":[…]}` wrapper, or
a single question object, so it tolerates whatever a backend sends. **Proof:** tests feed
3-, 4- and 5-option JSON and assert the UI renders exactly that many tiles
(`quiz_panel_test.dart`, `quiz_models_test.dart`), and the shipped quiz itself cycles
through 4-, 3- and 5-option questions.

### 4. Caching approach (incl. remote audio)
The bundled quiz asset needs no runtime cache. Remote **audio** (ElevenLabs) is cached by
**`sha1(text + voice)`** in a small bounded LRU (`InMemoryAudioCache`, capped at 16 entries
to protect memory) so re-reading the same story never re-hits the API/quota. Tests prove a
second identical request is served from cache with **zero** extra HTTP calls
(`elevenlabs_narrator_test.dart`). To persist across launches, the same `AudioCache`
interface can be swapped for a file-backed implementation with no caller changes.

### 5. Audio loading & failure states
Loading is a first-class `preparing` phase with a spinner. `Narrator.speak()` **never
throws** — every failure (no engine, no network, 429 rate-limit, timeout) is delivered as a
friendly, child-safe `NarrationError` on the state stream, which drives an `error` phase
showing "Oops! I could not read the story out loud." + a big **Try Again** button. Nothing
hangs or crashes; the watchdog also prevents a stuck spinner.

### 6. Performance profiling — what I measured & changed
- **Font tree-shaking (measured from the real `flutter build web` output):**
  `MaterialIcons` **1 645 184 → 8 268 bytes (−99.5%)**, `CupertinoIcons`
  **257 628 → 1 472 bytes (−99.4%)** — the icon fonts are the single biggest asset, so
  tree-shaking keeps the download tiny on slow connections.
- **Rebuild scoping:** UI is a pure function of two `StateNotifier`s; a shake rebuilds only
  the affected tile, not the story card (Riverpod + `const` widgets).
- **Animation isolation:** buddy, confetti and shake are each wrapped in a
  **`RepaintBoundary`**, and animate via `AnimatedBuilder`/`AnimationController` (never
  `setState`), so they don't repaint the whole tree.
- **Confetti cost:** particle count is capped at **14** and the controller is stopped +
  disposed on leave, keeping the 60 fps budget on modest GPUs.
- **A real before/after fix caught by tests:** the success banner overflowed by 208 px on a
  360 dp-wide screen (exactly a mid-range Android). A widget test surfaced it; the fix
  (making the row `Flexible`) removed the overflow. See `story_flow_test.dart`.
- **How to capture frame timings:** run `flutter run -d chrome --profile`, open DevTools →
  Performance, and record the read→narrate→quiz→confetti flow. *(On-device Android frame
  capture needs a physical device, which isn't attached to this build machine — the web
  profile run is the stand-in; the codebase is unchanged for Android.)*

### 7. Staying lightweight on mid-range Android
No image assets — the buddy is a tiny `CustomPainter` (vector), so it scales crisply and
costs almost nothing in memory. Fonts tree-shaken (above). Bounded audio cache. Capped
particles. `const`-heavy widget tree with scoped rebuilds. Only 5 small pure-Dart
dependencies. Everything is disposed (controllers, streams, timers) — the spec's leak
warning applied to Dart.

### 8. AI usage & judgment
I used an AI coding assistant throughout, under a strict plan-first, mock-first process
(see `AGENT_BRIEF.md` / `TASK_PLAN.md`).
- **A suggestion I changed:** the quick path was to reset per-question fields with
  `copyWith(lastSelected: null, attempts: 0)`. I rejected it — this `copyWith` can't
  *clear* a nullable field (passing `null` keeps the old value), so "Next question" would
  have silently carried the previous selection. I build a fresh `QuizState` instead. (The
  analyzer's `avoid_redundant_argument_values` hint was the tell.)
- **What didn't work, and how I fixed it:** the end-to-end widget test's taps missed —
  first because options sat below the default 800×600 test viewport, then because the
  quiz's reveal `AnimatedSwitcher` landed *exactly* on the pump boundary so tiles were
  mid-transition. Fixed by sizing the test surface to a phone and adding a settle-pump.
  Separately, a narrator test was flaky because it asserted a stream after a fixed
  `delayed()`; I made it deterministic with `emitsInOrder`.

---

## 🎥 Screen recording

Record the full flow on Chrome (`flutter run -d chrome`): tap **Read Me a Story** → hear
narration → quiz reveals → tap a wrong answer (shake) → tap the correct answer (confetti +
Success) → **Next question** through the 3/4/5-option sequence.

---

## 🧪 Tech

Flutter 3.44 · Dart 3.12 · Riverpod · **ElevenLabs** (premium TTS) · `flutter_tts` (native
TTS fallback) · `just_audio` · `confetti` · `http` · `crypto` · `shared_preferences`.
**68 tests**, `flutter analyze` clean. No credentials or devices required to build,
analyse, or test.
