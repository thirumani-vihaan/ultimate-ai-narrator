# TASK_PLAN — Ultimate AI Narrator

Ordered tasks with explicit dependencies and RISK. **HIGH-risk first** so a wrong assumption surfaces while the system is small. Each dependency's wiring check (§2.3) is recorded here as a verified ✅/❌, not assumed.

Legend: RISK = LOW / MED / HIGH. `deps:` = must be done first.

---

### T0 — Project scaffold & toolchain  · RISK: LOW
Create the Flutter app, pin deps in `pubspec.yaml`, add `analysis_options.yaml` (strict lints), brand theme, asset registration. Confirm `flutter analyze` + `flutter test` run headlessly.
- Deliverable: compiling empty app, green analyze, 1 trivial passing test.

### T1 — SPIKE: `flutter_tts` completion + web reachability  · RISK: HIGH · deps: T0
Throwaway spike proving: (a) `flutter_tts` speaks on Chrome (web), (b) `setCompletionHandler` fires exactly once at end → we can drive the quiz reveal. Validate the single riskiest assumption (audio→quiz handoff) before building the machine around it. If completion is unreliable, fall back to a duration-estimate + guard.
- Deliverable: spike note in RISK_LOG; decision recorded.

### T2 — Quiz schema + repository + fixtures  · RISK: HIGH · deps: T0
`Question.fromJson` with full validation; `QuizRepository` + `AssetQuizRepository`; fixtures: valid-4-option (spec), 3-option, 5-option, malformed (missing answer / answer∉options / empty options / not-JSON). This is the most-evaluated feature — build + test it early.
- Deliverable: unit tests proving 3/4/5 parse and each malformed case throws the right exception.

### T3 — Narration interface + fakes + native impl  · RISK: MED · deps: T1
`Narrator`, `NarrationState`, `FakeNarrator` (timing + forced errors), `FlutterTtsNarrator`. Business logic depends only on the interface.
- Deliverable: unit tests over `FakeNarrator` state sequences (happy + error).

### T4 — Story phase machine (`StoryController`)  · RISK: MED · deps: T3
Immutable `StoryState`/`StoryPhase`; reduce `NarrationState` → phases; idempotent handling of duplicate/late completion; error→retry.
- Deliverable: unit tests for every transition incl. duplicate-completion and error-then-retry.

### T5 — Quiz answer logic (`QuizController`)  · RISK: LOW · deps: T2
Attempts, wrong→shake trigger+haptic, correct→success. Pure logic, no widgets.
- Deliverable: unit tests (wrong then correct; multiple wrong; N-option questions).

### T6 — Haptics interface + impls  · RISK: LOW · deps: T0
`Haptics`, `RealHaptics`, `FakeHaptics`.
- Deliverable: `FakeHaptics` call-recording test.

### T7 — UI: story screen + widgets  · RISK: MED · deps: T4, T5, T6
Buddy (moods), story card, read button (preparing/narrating), loading, error+retry, **data-driven quiz panel** (N tiles), option shake, celebration overlay (confetti). Kid-friendly Peblo theme. Performance: `const`, `select`, `RepaintBoundary`.
- Deliverable: widget tests — renders 3/4/5 options from JSON; wrong shows shake+retry; correct shows success; error shows retry.

### T8 — Remote TTS bonus: `ElevenLabsNarrator` + `AudioCache`  · RISK: MED · deps: T3
Real client (request/response/error/429 handling), cache by sha1(text). Key-gated; native remains default. Fake path for offline tests.
- Deliverable: unit test of cache hit/miss + error handling via a fake HTTP layer (no key needed).

### T9 — WIRING (mandatory, §2.3)  · RISK: MED · deps: T3, T5, T6, T8
Implement `buildRealOverrides()` in `main.dart`; grep-confirm each real factory is constructed there (outside its module + outside tests); add one reachability test per dependency booting via the real entry point asserting the real type was instantiated.
- Deliverable + checklist (Phase 2 — VERIFIED):
  - [x] `FlutterTtsNarrator` reachable from `main` — grep: `main.dart` `: FlutterTtsNarrator();` · test: `wiring_test.dart` asserts `isA<FlutterTtsNarrator>()`
  - [x] `AssetQuizRepository` reachable from `main` — grep: `main.dart` `: AssetQuizRepository(kQuizAssetPath);` · test: `wiring_test.dart` asserts `isA<AssetQuizRepository>()` + `assetPath == kQuizAssetPath`
  - [x] `RealHaptics` reachable from `main` — grep: `main.dart` `hapticsProvider.overrideWith((ref) => const RealHaptics())` · test: `wiring_test.dart` asserts `isA<RealHaptics>()`
  - [x] `ElevenLabsNarrator` selected when key present — grep: `main.dart` `? ElevenLabsNarrator(apiKey: _elevenLabsKey)` · test: `elevenlabs_narrator_test.dart` (real HTTP path via MockClient: cache hit/miss + 429)

### T10 — Offline test suite + analyze gate  · RISK: LOW · deps: T2–T9
Full `flutter test` green with **zero credentials/devices**; `flutter analyze` clean. Data-driven proof test (3/4/5) included.
- Deliverable: CI-shaped one-command verification documented in README.

---

## Ordering summary
```
T0 ─┬─ T1(HIGH spike) ─ T3 ─ T4 ─┐
    ├─ T2(HIGH) ───────────── T5 ─┼─ T7 ─┐
    └─ T6 ───────────────────────┘       ├─ T9(wiring) ─ T10
                         T8(bonus) ───────┘
```
HIGH-risk T1 and T2 run right after scaffold; the wiring task T9 is explicit and independently checked, never assumed.
