# REAL_API_SETUP — going live

Everything works with **zero credentials and zero devices** by default (native/browser TTS
+ bundled quiz asset + fixtures for tests). Enabling the real/optional integrations is
**configuration only — no code changes**.

## 1. ElevenLabs remote TTS (bonus, optional)
Higher-quality narration. Default is the credential-free native/browser TTS.

- **Env var:** `ELEVENLABS_API_KEY`
- **Where to get it:** create a free account at <https://elevenlabs.io> → Profile → API Key.
- **How to pass it** (compile-time define, works on every platform incl. web):
  ```bash
  flutter run   -d chrome --dart-define=ELEVENLABS_API_KEY=xxxxxxxx
  flutter build web        --dart-define=ELEVENLABS_API_KEY=xxxxxxxx
  ```
- **Effect:** `buildRealOverrides()` in `lib/main.dart` selects `ElevenLabsNarrator`
  (wrapped in `FallbackNarrator` → native TTS if it errors). Audio is fetched, **cached** by
  `sha1(text+voice)` so repeats don't re-hit the quota, and **played aloud via `just_audio`**
  (`JustAudioSink`, works on web + mobile). Errors (429/network) degrade to native TTS, then
  to a friendly retry — never a crash.
- **Voice:** override `voiceId` in `ElevenLabsClient` if desired (defaults to a standard voice).

> Note: browsers gate audio autoplay behind a user gesture; the flow is tap-initiated
> ("Read Me a Story"), so playback is permitted. On Android/iOS there is no such gate.

## 2. Real quiz backend (optional)
By default the quiz loads from `assets/quiz/quiz.json`. To fetch it from a live backend:

- **Env var:** `QUIZ_ENDPOINT` (a URL returning the quiz JSON)
- **How:** `flutter run -d chrome --dart-define=QUIZ_ENDPOINT=https://your.api/quiz`
- **Effect:** `buildRealOverrides()` selects `HttpQuizRepository`. It accepts the same three
  payload shapes (array / `{"questions":[…]}` / single object) and validates every field, so
  a malformed response degrades to a friendly error instead of crashing.

## 3. Nothing is required for tests
`flutter test` and `flutter analyze` run fully offline with fixtures/fakes. No env var,
network, credential, microphone, or device is needed at any point.
