# BACKLOG — candidates considered

Candidates weighed against the ROI bar and the hard ~3 GB-RAM / 60 fps budget. Items below
did **not** clear the bar this round (kept out to protect scope/budget); they are honest
future ideas, not regressions.

| Candidate | Dimension | Why deferred |
|---|---|---|
| Word-by-word narration highlight (karaoke) | UX | High effort; `flutter_tts` word-boundary events are inconsistent across engines/web — risky vs. the delight it adds. |
| Real audio playback for ElevenLabs (`just_audio` `AudioSink`) | FEATURE | Adds a plugin + platform playback wiring; native TTS already fully satisfies narration. One documented step in `REAL_API_SETUP.md`. |
| Persistent (disk) audio cache | COST/PERF | In-memory bounded cache is enough for a single session; disk cache is a drop-in `AudioCache` swap when needed. |
| Localised UI + multilingual quiz (Hindi/Telugu…) | FEATURE | Peblo targets India; valuable next, but out of this challenge's scope. |
| CompositeNarrator (remote → auto-fallback to native) | RELIABILITY | Nice resilience; current behaviour surfaces a friendly retry, which is acceptable. |
| Buddy eye-blink / more moods | UX | Marginal delight vs. added paint cost; current vector buddy is expressive enough. |
| Golden (screenshot) tests | TEST DEPTH | Valuable but brittle across platforms; behaviour is already covered by widget tests. |

No candidate was tried-and-reverted (all attempted changes were kept). No "no-op" entries.
