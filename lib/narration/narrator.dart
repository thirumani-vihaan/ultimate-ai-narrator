import 'package:flutter/foundation.dart';

/// Immutable state emitted by any [Narrator]. A sealed hierarchy so the
/// controller must handle every case and impossible combinations (e.g. "error
/// while speaking and completed") cannot be represented.
@immutable
sealed class NarrationState {
  const NarrationState();
}

class NarrationIdle extends NarrationState {
  const NarrationIdle();
}

class NarrationPreparing extends NarrationState {
  const NarrationPreparing();
}

class NarrationSpeaking extends NarrationState {
  const NarrationSpeaking();
}

class NarrationCompleted extends NarrationState {
  const NarrationCompleted();
}

class NarrationError extends NarrationState {
  const NarrationError(this.message, {this.cause});

  /// Friendly, child-safe text suitable for display.
  final String message;

  /// Underlying technical cause — logged, never shown.
  final Object? cause;
}

/// Speaks text aloud. Concrete engines (native TTS, remote API) sit behind this
/// interface so business logic never imports a TTS SDK directly.
///
/// Contract:
///  * [speak] MUST NOT throw — any failure is delivered as a [NarrationError]
///    on [state], the single place the UI reacts to problems.
///  * emitted sequence per call: `preparing -> speaking -> completed`, or
///    `preparing -> error`.
///  * [stop] is idempotent and safe to call when not speaking.
abstract interface class Narrator {
  Stream<NarrationState> get state;
  Future<void> speak(String text);
  Future<void> stop();
  void dispose();
}

/// Optional capability: narrators that report how many characters have been
/// spoken so far (0..text.length), enabling word-by-word highlighting. Not all
/// engines support it (e.g. remote audio), so the UI probes for it with `is`.
abstract interface class ProgressiveNarrator {
  Stream<int> get spokenChars;
}
