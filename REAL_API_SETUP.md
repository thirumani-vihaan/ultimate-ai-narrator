# REAL_API_SETUP — going live

Everything works with **zero credentials and zero devices** by default (native/browser TTS
+ bundled quiz asset + fixtures for tests). Enabling the real/optional integrations is
**configuration only — no code changes**.

## 1. ElevenLabs premium narration (the flagship voice)
The story is read aloud in a warm, natural **ElevenLabs** voice. The credential-free
native/browser TTS is the automatic fallback, so the app always talks even without a key.

- **Env vars:** `ELEVENLABS_API_KEY` (required) and `ELEVENLABS_MODEL` (optional; defaults
  to **`eleven_flash_v2_5`** — the "Flash" model, ~half the credits per character and low
  latency).
- **Where to get it:** create an account at <https://elevenlabs.io> → Profile → API Keys.
  **The key must have the `text_to_speech` permission** (a key without it returns `401` and
  the app silently falls back to the built-in voice).
- **How to pass it** (compile-time defines, work on every platform incl. web). The tidy way
  is a git-ignored `keys.json` (copy `keys.example.json`):
  ```jsonc
  // keys.json  (git-ignored)
  { "ELEVENLABS_API_KEY": "sk_..." }
  ```
  ```bash
  flutter run   -d chrome --dart-define-from-file=keys.json
  flutter build web        --dart-define-from-file=keys.json
  # …or inline:
  flutter run   -d chrome --dart-define=ELEVENLABS_API_KEY=sk_...
  ```
- **Effect:** `buildRealOverrides()` in `lib/main.dart` selects `ElevenLabsNarrator`
  (wrapped in `FallbackNarrator` → built-in TTS if it errors). Audio is fetched, **cached**
  by `sha1(text+voice)` so repeats don't re-hit the quota, and **played aloud** on web via a
  **base64 data-URI** into `just_audio` (`JustAudioSink`; byte-streaming is flaky on
  `just_audio_web`). Errors (401/429/network) degrade to the built-in voice, then to a
  friendly retry — never a crash.
- **Live attribution in-app:** the UI shows the active voice ("Voice: ElevenLabs · Flash"
  vs "Built-in voice") and a **"Powered by ElevenLabs"** credit while ElevenLabs is playing.
- **Voice:** override `voiceId` in `ElevenLabsClient` to pick a different ElevenLabs voice
  (defaults to a standard narrator voice).

> Note: browsers gate audio autoplay behind a user gesture; the flow is tap-initiated
> ("Read Me a Story"), so playback is permitted. On Android/iOS there is no such gate.

## 2. Real quiz backend (optional)

The quiz now ships **generated from the story** (see below), so there's no separate quiz
endpoint to configure.

## 3. AI story generator (optional real LLM)

Story + quiz are created by a `StoryGenerator`. The default is the **on-device engine**
(no key, no network). To use a real LLM instead (with the on-device engine as fallback):

- **Env var:** `OPENAI_API_KEY`
- **Where to get it:** <https://platform.openai.com/api-keys>.
- **How:** `flutter run -d chrome --dart-define=OPENAI_API_KEY=sk-...`
- **Effect:** `buildRealOverrides()` selects `LlmStoryGenerator` (OpenAI-compatible chat
  completions, strict-JSON response). On any error (network / bad status / malformed JSON)
  it transparently falls back to the on-device engine — a story is always produced.
- **Model/endpoint:** override `model` / `endpoint` on `LlmStoryGenerator` for other
  OpenAI-compatible providers.

## 4. Nothing is required for tests
`flutter test` and `flutter analyze` run fully offline with fixtures/fakes. No env var,
network, credential, microphone, or device is needed at any point.
