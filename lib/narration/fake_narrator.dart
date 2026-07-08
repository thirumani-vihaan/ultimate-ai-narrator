import 'dart:async';

import 'narrator.dart';

/// Fixture-driven fake used by all offline tests and by the app when no real
/// engine is available. Emits a realistic `preparing -> speaking -> completed`
/// sequence (or a forced error) with no platform channel, so the whole suite
/// runs on the Dart VM with zero devices or credentials.
class FakeNarrator implements Narrator {
  FakeNarrator({
    this.prepareDelay = const Duration(milliseconds: 10),
    this.speakDelay = const Duration(milliseconds: 20),
    this.forceError,
  });

  /// Time spent in [NarrationPreparing] before speaking (or erroring).
  final Duration prepareDelay;

  /// Time spent in [NarrationSpeaking] before completing.
  final Duration speakDelay;

  /// When set, the fake emits this error instead of speaking — used to exercise
  /// the failure/retry path deterministically.
  final NarrationError? forceError;

  final StreamController<NarrationState> _controller =
      StreamController<NarrationState>.broadcast();
  Timer? _prepareTimer;
  Timer? _speakTimer;
  bool _disposed = false;

  @override
  Stream<NarrationState> get state => _controller.stream;

  @override
  Future<void> speak(String text) async {
    if (_disposed) return;
    _cancelTimers();
    _controller.add(const NarrationPreparing());
    _prepareTimer = Timer(prepareDelay, () {
      if (_disposed) return;
      final error = forceError;
      if (error != null) {
        _controller.add(error);
        return;
      }
      _controller.add(const NarrationSpeaking());
      _speakTimer = Timer(speakDelay, () {
        if (_disposed) return;
        _controller.add(const NarrationCompleted());
      });
    });
  }

  @override
  Future<void> stop() async {
    _cancelTimers();
    if (!_disposed) _controller.add(const NarrationIdle());
  }

  void _cancelTimers() {
    _prepareTimer?.cancel();
    _speakTimer?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    _controller.close();
  }
}
