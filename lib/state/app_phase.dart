import 'package:flutter/foundation.dart';

/// The single orchestration state of the screen. Sealed so the UI must handle
/// every case and impossible combinations (e.g. "preparing + error") cannot be
/// represented. Only [StoryController] mutates this, via explicit transitions.
@immutable
sealed class StoryPhase {
  const StoryPhase();
}

/// Buddy waiting; the "Read Me a Story" button is enabled.
class PhaseIdle extends StoryPhase {
  const PhaseIdle();
}

/// TTS is being initialised / audio prepared. Shows a loading state.
class PhasePreparing extends StoryPhase {
  const PhasePreparing();
}

/// Audio is playing; the buddy is "talking".
class PhaseNarrating extends StoryPhase {
  const PhaseNarrating();
}

/// Audio finished; the quiz is animating in. This is the explicit "transition
/// state between audio ending and quiz appearing" the spec asks about.
class PhaseRevealing extends StoryPhase {
  const PhaseRevealing();
}

/// The quiz is interactive.
class PhaseQuiz extends StoryPhase {
  const PhaseQuiz();
}

/// Correct answer given — celebration + Success state.
class PhaseSuccess extends StoryPhase {
  const PhaseSuccess();
}

/// A narration failure occurred; the UI shows [message] and a Retry action.
class PhaseError extends StoryPhase {
  const PhaseError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is PhaseError && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
