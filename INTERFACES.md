# INTERFACES — Ultimate AI Narrator

Exact contracts at every boundary from ARCHITECTURE §"Module boundaries". These are **immutable contracts**: changing one is a flagged, high-visibility event, not a polish edit.

---

## Narration boundary

```dart
/// Sealed state emitted by any Narrator. Immutable.
sealed class NarrationState { const NarrationState(); }
class NarrationIdle      extends NarrationState { const NarrationIdle(); }
class NarrationPreparing extends NarrationState { const NarrationPreparing(); }
class NarrationSpeaking  extends NarrationState { const NarrationSpeaking(); }
class NarrationCompleted extends NarrationState { const NarrationCompleted(); }
class NarrationError extends NarrationState {
  final String message;      // friendly, child-safe
  final Object? cause;       // logged, never shown
  const NarrationError(this.message, {this.cause});
}

abstract interface class Narrator {
  Stream<NarrationState> get state;   // broadcast; replays nothing
  Future<void> speak(String text);    // MUST NOT throw; failures => NarrationError on `state`
  Future<void> stop();                // idempotent; safe if not speaking
  void dispose();                     // cancels controllers/subscriptions
}
```
**Error contract:** `speak()` returns normally even on failure; the error is delivered as `NarrationError` on `state` (single place the UI reacts). Implementations MUST NOT `catch (_) {}` silently — every catch logs `cause` via `core/logging.dart`.
**Real impls:** `FlutterTtsNarrator` (native/web), `ElevenLabsNarrator` (bonus).
**Fake:** `FakeNarrator({Duration prepare, Duration speak, NarrationError? forceError, int seed})`.

## Audio cache boundary (remote TTS only)

```dart
abstract interface class AudioCache {
  Future<Uint8List?> get(String key);          // key = sha1(text+voice)
  Future<void> put(String key, Uint8List data);
}
```
Default `InMemoryAudioCache` (+ optional file-backed). Contract: `get` returns null on miss, never throws.

## Quiz model (immutable schema — the data-driven contract)

```dart
@immutable
class Question {
  final String prompt;         // "question"
  final List<String> options;  // 2..N, rendered dynamically
  final String answer;         // MUST be one of options

  const Question({required this.prompt, required this.options, required this.answer});

  factory Question.fromJson(Map<String, dynamic> json);
  // Validation (throws QuizFormatException with a clear message):
  //  - "question" is a non-empty String
  //  - "options" is a List<String> with >= 2 entries, no blanks, no dupes
  //  - "answer" is a String present in options
  bool isCorrect(String selected) => selected == answer;
}
```
**Design note:** nothing in `Question` assumes 4 options — the count is `options.length`. The renderer (`quiz_panel.dart`) lays out `options.length` tiles, so 3/4/5 "just work" with no code change. This is the spec's most-scrutinised requirement, encoded in the type.

## Quiz repository boundary

```dart
abstract interface class QuizRepository {
  Future<List<Question>> loadQuestions();  // throws QuizLoadException / QuizFormatException
}
class QuizLoadException implements Exception { final String message; final Object? cause; ... }
class QuizFormatException implements Exception { final String message; ... }
```
**Default:** `AssetQuizRepository(assetPath)` reads bundled JSON. **Optional real:** `HttpQuizRepository(uri)`.
**Error contract:** repository throws; `QuizController` catches, logs `cause`, and sets a friendly error state. No bare swallow.

## Haptics boundary

```dart
abstract interface class Haptics {
  Future<void> wrong();    // short buzz; no-op where unsupported
  Future<void> correct();  // celebratory pattern
}
```
`RealHaptics` (uses `HapticFeedback`), `FakeHaptics` (records calls for tests). Never throws; never blocks.

## Controller intents (UI ↔ state boundary)

```dart
// StoryController: StateNotifier<StoryState>
void readStory();   // idle/error -> preparing -> ... (subscribes to Narrator)
void retry();       // error -> preparing (re-issues speak)
// internal: _onNarration(NarrationState) reduces events -> StoryPhase

// QuizController: StateNotifier<QuizState>
Future<void> load();               // fills questions from QuizRepository
void answer(String option);        // wrong -> shake+haptic+attempt++, correct -> success+haptic
void nextQuestion();               // if a sequence is provided
```
`StoryState`/`QuizState` are immutable with `copyWith`; equality by value so Riverpod rebuilds only on real change.

---

## WIRING — the ONE real-entry-point construction site (contract for Phase 2 §2.3)

**File `lib/main.dart` is the single place real implementations are constructed and injected.** Every injectable interface below is wired here (and ONLY here in production code):

| Interface | Provider | Real factory (constructed in `main.dart` overrides) | Fake (tests) |
|---|---|---|---|
| `Narrator` | `narratorProvider` | `ELEVENLABS_API_KEY` set → `ElevenLabsNarrator(...)` else `FlutterTtsNarrator()` | `FakeNarrator(...)` |
| `QuizRepository` | `quizRepositoryProvider` | `QUIZ_ENDPOINT` set → `HttpQuizRepository(uri)` else `AssetQuizRepository('assets/quiz.json')` | `AssetQuizRepository(test asset)` / fake |
| `Haptics` | `hapticsProvider` | `RealHaptics()` | `FakeHaptics()` |

```dart
void main() {
  final overrides = buildRealOverrides();   // reads env, constructs real impls
  runApp(ProviderScope(overrides: overrides, child: const UltimateAiNarratorApp()));
}
```
Phase 2 §2.3 will grep-assert each real factory is referenced from `main.dart`/`buildRealOverrides` (outside its own module, outside tests) and add one reachability test per dependency that boots via the real entry point and asserts the real type was instantiated.
