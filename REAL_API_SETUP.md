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
- **Effect:** `buildRealOverrides()` in `lib/main.dart` selects `ElevenLabsNarrator` instead
  of `FlutterTtsNarrator`. Audio is cached by `sha1(text+voice)` so repeats don't re-hit the
  quota. Errors (429/network) degrade to a friendly retry — never a crash.
- **Voice:** override `voiceId` in `ElevenLabsClient` if desired (defaults to a standard voice).

### One remaining wiring step for *audible* remote playback
The ElevenLabs **fetch + cache + error handling** is real, production code and fully tested.
Actual playback is behind an injectable `AudioSink`; the default `SilentAudioSink` advances
the state machine without producing sound (so tests stay device-free). To hear the fetched
mp3 on device, provide a real player and pass it in `main.dart`:

```dart
// pubspec.yaml: add just_audio, then:
ElevenLabsNarrator(apiKey: key, sink: JustAudioSink()); // implement AudioSink.play(bytes)
```
No other code changes are required — the interface is already wired everywhere else.

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
