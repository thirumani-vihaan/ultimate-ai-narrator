# IMPROVEMENT_LOG — Ultimate AI Narrator (append-only)

One entry per kept change beyond the Phase 2 baseline. Format:
`# | dimension | change | decision (measured effect)`

1 | FEATURE COMPLETENESS / UX | Multi-question progression: progress dots + "Next question" / "Read it again", driven by the existing 3-question (3/4/5-option) sequence. | **KEPT** — demonstrates the data-driven engine live in one session; +1 controller test (`reset`), 0 analyze issues.

2 | CORRECTNESS (layout) | Fixed success-banner `RenderFlex` overflow (208 px) on ~360 dp screens by making the row `Flexible`; also made the two hint rows flexible. | **KEPT** — removed a real overflow on the exact mid-range Android width; caught + guarded by `story_flow_test`.

3 | CORRECTNESS | `nextQuestion`/`reset` build a fresh `QuizState` instead of `copyWith(lastSelected:null)` (which can't clear a nullable field). | **KEPT** — prevents a stale selection leaking into the next question; covered by `quiz_controller_test`.

4 | RELIABILITY / TEST DEPTH | Replaced wall-clock `delayed()` assertions in the narrator test with deterministic `emitsInOrder`. | **KEPT** — removed flakiness (was intermittently failing under parallel load); stable across repeated runs.

5 | UX / ACCESSIBILITY / PERFORMANCE | Honour `MediaQuery.disableAnimations`: buddy stops its perpetual animation and confetti is skipped under reduced-motion. | **KEPT** — accessibility win + saves CPU/battery on low-end devices; +2 widget tests.

6 | TEST DEPTH / RELIABILITY | Injectable `watchdogOverride` on `StoryController` + a test that directly asserts the watchdog reveals the quiz when a completion event never fires. | **KEPT** — closes the R2 coverage gap (previously asserted only indirectly); deterministic, 0 analyze issues.

7 | RELIABILITY / RESILIENCE | `FallbackNarrator`: wraps ElevenLabs (primary) → native TTS (fallback); on a primary error it transparently re-speaks on the fallback so the child never sees the failure. Wired in `main.dart` when a key is present. | **KEPT** — real graceful-degradation for the remote path; +3 fault-injection tests (success passthrough, single-fail fallback, both-fail error). 54 tests total, 0 analyze issues.

8 | UX / ACCESSIBILITY | `liveRegion` `Semantics` announcer speaks each phase to screen readers ("The story is playing", "Question 1 of 3", "Correct!"); decorative buddy wrapped in `ExcludeSemantics`. Isolated widget so it doesn't rebuild the screen. | **KEPT** — meaningful a11y for a child app; +1 semantics test. 55 tests total, 0 analyze issues.

## Third loop — "make it the best" (ROI gate lifted at user request)

9  | FEATURE / UX | Score & stars: ⭐⭐⭐/⭐⭐/⭐ per question by wrong-attempt count, running total + finish summary, animated star row. | **KEPT** — +1 stars test; fixed a duplicate-key crash found by the flow test.
10 | FEATURE / UX | Stop control during narration (`stopReading` → idle). | **KEPT** — child agency; +1 test.
11 | FEATURE / COST | Audible ElevenLabs playback via `just_audio` (`JustAudioSink`, streaming bytes source, web+mobile) + `AudioSink.dispose`. | **KEPT** — completes the bonus; web build verified.
12 | UX / FEATURE | Sound effects (bundled WAV chimes via just_audio) + mute toggle; `NoopSoundEffects` default keeps tests silent. | **KEPT** — +2 tests (sfx fire, mute toggle).
13 | UX / PERFORMANCE | Visual polish: animated sky + drifting clouds, talking-mouth buddy, staggered option-tile entrance — all `RepaintBoundary`-isolated + reduced-motion aware. | **KEPT** — web build verified; capped/cheap to protect 60 fps.
14 | UX / FEATURE | Word-highlight narration via optional `ProgressiveNarrator` capability (native TTS progress), graceful fallback where unsupported. | **KEPT** — +1 progress test; base `Narrator` contract left intact (separate capability interface).
15 | FEATURE / PERSISTENCE | Persist mute across launches (`shared_preferences` behind injectable `SettingsStore`; `MuteNotifier`). | **KEPT** — +2 tests. 61 tests total, 0 analyze issues.

## Dimension coverage so far
CORRECTNESS ✅, PERFORMANCE ✅ (fonts, RepaintBoundary, capped particles, reduced-motion),
RELIABILITY ✅, ERROR-HANDLING ✅ (narration + quiz load), OBSERVABILITY ✅ (no silent catch),
UX ✅, CODE QUALITY ✅ (analyze clean), TEST DEPTH ✅ (51 tests), DOCUMENTATION ✅,
FEATURE COMPLETENESS ✅, WIRING INTEGRITY ✅ (re-verified — see FINAL_REPORT).
