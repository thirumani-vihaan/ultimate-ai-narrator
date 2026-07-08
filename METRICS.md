# METRICS — Ultimate AI Narrator

Measured on this build machine (headless): `flutter analyze`, `flutter test`,
`flutter build web --release`. On-device Android frame capture requires a physical device
(not attached); the web profile build is the stand-in and the codebase is identical for
Android.

| Metric | Baseline (Phase 2 v1) | Current | Notes |
|---|---|---|---|
| Tests passing (offline, 0 creds) | 48 | **61** | unit + widget + wiring |
| `flutter analyze` issues | 0 | **0** | strict lints (`strict-casts`, trailing commas, single quotes, const) |
| Web release build | ✅ | ✅ | `√ Built build\web` |
| Data-driven proof | 3/4/5 option tests | 3/4/5 tests **+ live 3-question sequence** | renderer never assumes a count |
| MaterialIcons font | 1 645 184 B | **8 268 B** | tree-shaken −99.5% (real build output) |
| CupertinoIcons font | 257 628 B | **1 472 B** | tree-shaken −99.4% |
| Confetti particles | 14 (capped) | 14 (capped) | + disposed on leave |
| RepaintBoundary-isolated animations | buddy, confetti, shake | same | prevents whole-tree repaint |
| Image assets | 0 | 0 | buddy is a vector `CustomPainter` |
| Direct dependencies | 5 | 5 | riverpod, flutter_tts, confetti, http, crypto |
| Direct dependencies | 5 | 7 | + just_audio, shared_preferences |
| Reduced-motion support | ❌ | ✅ | buddy + confetti + sky honour `MediaQuery.disableAnimations` |
| Remote-TTS resilience | none | ✅ | `FallbackNarrator`: ElevenLabs → native auto-fallback on error |
| Screen-reader announcements | ❌ | ✅ | `liveRegion` status per phase; decorative buddy `ExcludeSemantics` |
| Watchdog (missing-completion) coverage | indirect | ✅ | directly tested via injectable duration |
| Remote-audio cache re-fetch (same text) | 0 extra calls | 0 extra calls | proven in `elevenlabs_narrator_test` |

## Instrumentation notes
- The audio→quiz "transition" is a first-class `revealing` phase, so its timing is
  observable and testable (not an implicit gap).
- Failure paths all log their caught cause via `core/logging.dart` — no silent `catch`.
- Frame timing: `flutter run -d chrome --profile` → DevTools → Performance, record the
  read→narrate→quiz→confetti flow (manual; no device attached for Android capture).
