import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../narration/narrator.dart';
import 'app_phase.dart';

/// Owns the [StoryPhase] state machine. It is the single consumer of the
/// [Narrator] event stream and maps narration events to phase transitions.
///
/// Every transition is idempotent: duplicate or late narration events (a real
/// risk with TTS completion callbacks) cannot double-advance the machine, and a
/// watchdog guarantees the quiz still appears if a completion event never fires.
class StoryController extends StateNotifier<StoryPhase> {
  StoryController(
    this._narrator, {
    this.revealDelay = const Duration(milliseconds: 650),
    this.watchdogOverride,
  }) : super(const PhaseIdle()) {
    _sub = _narrator.state.listen(_onNarration);
  }

  final Narrator _narrator;

  /// The text most recently requested (for retry and the watchdog window).
  String _lastText = '';

  /// How long the "revealing" transition lasts before the quiz becomes
  /// interactive (matches the reveal animation).
  final Duration revealDelay;

  /// Optional fixed watchdog duration (used by tests to exercise the
  /// missing-completion path deterministically). Production computes it from
  /// the story length.
  final Duration? watchdogOverride;

  late final StreamSubscription<NarrationState> _sub;
  Timer? _revealTimer;
  Timer? _watchdogTimer;

  /// Current phase — exposed for tests only (production reads via the provider).
  @visibleForTesting
  StoryPhase get currentPhase => state;

  /// Intent: begin (or restart) narration of [text].
  void readStory(String text) {
    if (state is PhasePreparing || state is PhaseNarrating) return;
    _cancelTimers();
    _lastText = text;
    state = const PhasePreparing();
    _narrator.speak(text);
  }

  /// Intent: retry after an error.
  void retry() {
    if (state is PhaseError) readStory(_lastText);
  }

  /// Intent: stop the narration and return to idle (child taps "Stop").
  void stopReading() {
    if (state is PhaseNarrating || state is PhasePreparing) {
      _cancelTimers();
      _narrator.stop();
      state = const PhaseIdle();
    }
  }

  /// Reset to idle for a brand-new story (called when a new story is generated).
  void resetToIdle() {
    _cancelTimers();
    _narrator.stop();
    state = const PhaseIdle();
  }

  /// Called when the quiz has been solved, to enter the celebratory state.
  void markSolved() {
    if (state is PhaseQuiz) state = const PhaseSuccess();
  }

  /// Return to the interactive quiz (e.g. after advancing to the next question).
  void goToQuiz() {
    if (state is PhaseSuccess || state is PhaseRevealing) {
      state = const PhaseQuiz();
    }
  }

  void _onNarration(NarrationState event) {
    switch (event) {
      case NarrationPreparing():
        if (state is PhaseIdle || state is PhaseError) {
          state = const PhasePreparing();
        }
      case NarrationSpeaking():
        if (state is PhasePreparing) {
          state = const PhaseNarrating();
          _startWatchdog();
        }
      case NarrationCompleted():
        // Idempotent: only a completion while actually narrating reveals the
        // quiz. Late/duplicate completions after that are ignored.
        if (state is PhaseNarrating) {
          _beginReveal();
        }
      case NarrationError(:final String message):
        if (state is PhasePreparing || state is PhaseNarrating) {
          _cancelTimers();
          state = PhaseError(message);
        }
      case NarrationIdle():
        if (state is PhasePreparing || state is PhaseNarrating) {
          _cancelTimers();
          state = const PhaseIdle();
        }
    }
  }

  void _beginReveal() {
    _cancelTimers();
    state = const PhaseRevealing();
    _revealTimer = Timer(revealDelay, () {
      if (state is PhaseRevealing) state = const PhaseQuiz();
    });
  }

  /// If no completion event arrives within a generous window, reveal anyway so
  /// the child is never stuck on a spinner (guards flaky TTS engines / web).
  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(watchdogOverride ?? _watchdogDuration(_lastText), () {
      if (state is PhaseNarrating) _beginReveal();
    });
  }

  static Duration _watchdogDuration(String text) {
    final words = text.trim().split(RegExp(r'\s+')).length;
    final seconds = (words * 0.6).clamp(3, 60) + 8;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  void _cancelTimers() {
    _revealTimer?.cancel();
    _watchdogTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelTimers();
    _sub.cancel();
    super.dispose();
  }
}
