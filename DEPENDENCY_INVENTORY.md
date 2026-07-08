# DEPENDENCY_INVENTORY — Ultimate AI Narrator

Every external dependency the spec implies. Each sits behind an **injectable interface** (mock-first, per the brief). **Nothing here may be *required* for the offline test suite to pass** — the fake/default path must fully work with zero credentials and zero devices.

---

## 1. Native device TTS — `flutter_tts` (DEFAULT narration path)
- **Purpose:** speak the story text on-device (Android `TextToSpeech`, iOS `AVSpeechSynthesizer`, Web `SpeechSynthesis`).
- **Credential:** none.
- **Platform gotchas:**
  - **Platform-channel plugin** → **not available under `flutter test`** (Dart VM, no platform channels). MUST sit behind an injectable `Narrator` interface; tests use a fake. The real plugin is only exercised in a running app / integration test.
  - **Async init that can fail/stall:** Android TTS engine init is async and occasionally slow or unavailable; a requested language/voice may be missing on low-end devices → treat "not initialized" / "language unavailable" as a **failure → retry**, don't hang.
  - **Completion handler drives the quiz reveal:** must use `setCompletionHandler`. Missing/duplicate completion callbacks are a real risk → guard the audio→quiz transition with an **explicit state**, not just the raw callback.
  - **Web:** works via browser Web Speech API — this is our live demo path on the build machine.
  - **Desktop:** `flutter_tts` desktop support is limited → rely on the fake for automated verification.
- **Injectable interface:** `Narrator { Future<void> speak(String text); Future<void> stop(); Stream<NarrationState> state; }` — real = `FlutterTtsNarrator`, fake = `FakeNarrator` (fixture-driven timing + forced failure modes).

## 2. ElevenLabs remote TTS (BONUS, optional)
- **Purpose:** higher-quality narration via free-tier API.
- **Credential:** `ELEVENLABS_API_KEY` (env). **Never required for tests;** default is fake/native.
- **Gotchas:** network required; free-tier **rate limits / quota (429)**; latency variable → show loading state and, in metrics, separate "genuine processing latency" from "retry/backoff wait"; returns **mp3** → needs audio playback + **caching by text hash**.
- **Injectable:** same `Narrator` interface (`RemoteNarrator`), selected only when the key is present.

## 3. Audio playback for remote mp3 — `just_audio` / `audioplayers`
- **Purpose:** play ElevenLabs mp3 bytes (native TTS handles its own playback).
- **Credential:** none.
- **Gotchas:** platform-channel plugin → behind an interface, faked in tests; **dispose players** to avoid leaks.

## 4. Haptic feedback — `HapticFeedback` (flutter/services) / `vibration`
- **Purpose:** wrong-answer buzz.
- **Credential:** none.
- **Gotchas:** **no-op on emulator/web/desktop**; must be optional (respect a reduced-motion / no-haptics setting) and never block logic. Behind a tiny `Haptics` interface, faked in tests.

## 5. Confetti / celebration — `confetti` package (or custom `CustomPainter`)
- **Purpose:** correct-answer celebration.
- **Credential:** none. Pure Dart.
- **Gotchas:** particle count / overdraw can blow the **60fps / 3GB budget** on low-end devices → cap particles, wrap in `RepaintBoundary`, **stop + dispose** the controller when done. This is a performance-tuning candidate, not a dependency risk.

## 6. Quiz data source (simulated backend) — `QuizRepository`
- **Purpose:** supply quiz JSON "as if from our backend."
- **Credential:** none (default = local asset). Optional real HTTP endpoint behind config.
- **Gotchas:** must tolerate **variable option counts (3/4/5)** and **missing/malformed JSON** (validation + friendly error, never crash). fake = bundled asset fixtures (valid + malformed + varying option counts); real = `HttpQuizRepository`.

---

## Build-machine reality (this Windows box, from `flutter doctor`)
| Target | Status | Use |
|---|---|---|
| `flutter test` / `flutter analyze` | ✅ headless | **Primary automated verification** |
| Flutter **web** (Chrome/Edge) | ✅ | **Runnable demo / screen recording**; real browser TTS |
| Android SDK / APK / emulator | ❌ not installed | Cannot build/run Android here; design mobile-first regardless |
| Windows desktop | ❌ VS C++ components missing | Not a run target |

**Implication:** the whole dependency layer must degrade cleanly to fakes for `flutter test`, and to browser-native APIs for the web demo — no dependency may hard-require an Android device or a paid credential.
