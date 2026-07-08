# SPEC_SUMMARY — Ultimate AI Narrator

**Source:** Peblo Flutter/Swift Developer Intern Challenge — *"The AI Story Buddy & Quiz Component."* Full brief: `project challenge.pdf`.

## Mission
Build a joyful, kid-first mobile mini-feature: an **AI Story Buddy** that (1) narrates a short story snippet aloud via text-to-speech, then (2) smoothly reveals a fully **data-driven** interactive quiz. It must feel delightful and production-solid, and stand out among all submissions — going "10 steps beyond" a baseline entry, strictly within the hard performance budget.

## Chosen stack
- **Flutter** 3.44.2 / Dart 3.12.2 — the only framework buildable **and** testable on this Windows machine (Swift/iOS cannot be compiled here). Flutter binary at `C:\Users\kathyayanit\flutter\bin` (not on PATH).
- **State management:** to be finalized in Phase 1 (spec allows Provider / Riverpod / BLoC). Leaning Riverpod for testable, rebuild-scoped state.
- **Native TTS:** `flutter_tts` (default, credential-free; uses Web Speech API on web, Android `TextToSpeech` on device).
- **Bonus remote TTS:** ElevenLabs behind `ELEVENLABS_API_KEY` (optional, never required).
- **Animations:** `AnimationController` for shake + quiz reveal; a confetti effect for celebration.

## Hard constraints (MUST NOT cross)
1. **Performance / memory on mid-range ~3GB-RAM Android** — ~60fps (<16ms frames) for shake + confetti + quiz reveal, low memory footprint, small install size, no jank, no leaks. **This is THE hard limit** besides correctness.
2. **Correctness** — answer logic, TTS state machine, no crashes/hangs.
3. **Data-driven quiz** — rendered from JSON, NOT hardcoded; handles 3/4/5+ options and different text with zero code changes.
4. **Graceful failure** — TTS failure / no network → friendly message + retry; never hang or crash.
5. **Leak-free audio** — completion callbacks/delegates must not retain-cycle; dispose all controllers.

## Soft guidelines (may deviate with justification)
- **"Single screen" is soft** — a 2-screen flow is allowed if it improves the child experience without harming the hard budget.
- Wireframe + brand colours are a **structural guide**, not pixel-perfect.

## Functional requirements
**UI:** vibrant kid-friendly screen; an AI Buddy character (placeholder asset OK); a prominent **"Read Me a Story"** button; a **story text card**.
**TTS:** tap → narrate the story text; show a **loading/preparing** state; on failure show a friendly message + **retry**.
**Story text:** *"Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods..."*
**Quiz (most important):**
- Rendered from JSON `{question, options[], answer}` — data-driven, variable option count.
- Revealed **smoothly as soon as audio finishes** (explicit transition state).
- **Wrong answer** → shake card + haptic/visual feedback, allow retry.
- **Correct answer** → celebratory moment (confetti, Buddy smiling, happy state) + **"Success"** state.
**Provided quiz JSON:**
```json
{ "question": "What colour was Pip the Robot's lost gear?", "options": ["Red","Green","Blue","Yellow"], "answer": "Blue" }
```

## Acceptance criteria (evaluation)
- Clean, readable, well-structured code.
- Smooth, joyful, kid-appropriate UI + animation.
- Correct, leak-free audio playback + state transitions.
- **Genuinely data-driven** quiz (not hardcoded) — proven with 3/4/5-option JSON.
- Production-mindedness: loading states, error handling, performance on modest devices.

## Performance budgets
- Frame build+raster ≤ ~16ms (60fps) during shake + confetti + quiz reveal.
- Minimal widget rebuilds (scoped state, `const` widgets, `RepaintBoundary` around animations).
- Low memory; small assets; fast cold start.
- Remote audio **cached** (no repeat API hits for identical text).

## Deliverables (submission)
- ✅ GitHub repo (exists: `thirumani-vihaan/ultimate-ai-narrator`).
- **README** covering: framework choice + why; transition-state handling (audio→quiz); data-driven quiz (variable option count); caching approach (+ remote audio); audio loading/failure states; performance profiling (measured/changed/before-after + frame-timing screenshot); lightweight-on-Android approach; AI usage & judgment (a rejected suggestion + something that didn't work + resolution).
- **Screen recording** of the full flow (audio → quiz → wrong-answer feedback → success). *[MANUAL — user records; recommended target: Flutter web in Chrome on this machine.]*
- Google Form submission. *[MANUAL — user.]*

## Explicit non-goals
- Swift/iOS native build (impossible on this Windows machine).
- A real backend server for quiz JSON (simulated via injectable repository; local asset fixture is the default).
- Accounts, analytics backend, multi-story content library (design for extensibility, don't build).
- Pixel-perfect wireframe replication.

## Build-machine reality (from `flutter doctor`)
- **Android SDK: not installed** → no APK build / Android emulator here. Design mobile-first anyway; the hard budget still targets Android ~3GB RAM.
- **Web (Chrome/Edge): available** → primary **runnable/demo** target on this machine; `flutter_tts` works via browser Web Speech API (real narration, no key).
- **Windows desktop:** VS missing C++ components → not a viable run target.
- **Automated verification:** `flutter test` + `flutter analyze`, headless. ✅

## Ambiguities flagged (with default decisions)
1. **Quiz source** — spec says "as if served by our backend." → **Decision:** `QuizRepository` injectable interface; default fake = bundled asset JSON, optional real = HTTP endpoint behind config. No live backend required.
2. **Multiple questions?** — spec gives one but says "the next question we send." → **Decision:** schema supports a *sequence* of questions so option-count/text variability is genuinely exercised; ship at least the provided one (plus fixtures with 3/4/5 options).
3. **Remote-audio caching** — README asks caching approach for remote audio. → **Decision:** cache mp3 by text hash; implement even in fake mode so the path is proven offline.
4. **Screen-recording target** — no Android device here. → **Decision:** record the flow on **Flutter web (Chrome)**; note in README the same codebase targets Android.
