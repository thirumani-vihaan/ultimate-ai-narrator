import 'dart:async';

import '../core/logging.dart';
import 'narrator.dart';

/// Wraps a primary narrator and, if it emits a [NarrationError], transparently
/// retries on a fallback narrator (e.g. remote ElevenLabs → native TTS). The
/// child never sees the failure — just a brief re-prepare, then normal
/// narration. If both fail, the fallback's error is surfaced.
class FallbackNarrator implements Narrator {
  FallbackNarrator(this._primary, this._fallback) {
    _primarySub = _primary.state.listen(_onPrimary);
    _fallbackSub = _fallback.state.listen(_onFallback);
  }

  final Narrator _primary;
  final Narrator _fallback;
  final StreamController<NarrationState> _controller =
      StreamController<NarrationState>.broadcast();
  late final StreamSubscription<NarrationState> _primarySub;
  late final StreamSubscription<NarrationState> _fallbackSub;

  String _lastText = '';
  bool _usingFallback = false;
  bool _disposed = false;

  @override
  Stream<NarrationState> get state => _controller.stream;

  @override
  Future<void> speak(String text) async {
    if (_disposed) return;
    _lastText = text;
    _usingFallback = false;
    await _primary.speak(text);
  }

  void _onPrimary(NarrationState s) {
    if (_disposed || _usingFallback) return;
    if (s is NarrationError) {
      _usingFallback = true;
      logInfo('FallbackNarrator', 'primary failed (${s.message}); falling back');
      unawaited(_fallback.speak(_lastText));
      return;
    }
    _emit(s);
  }

  void _onFallback(NarrationState s) {
    // Only forward fallback events once we've switched to it; its error (if any)
    // means both engines failed, so it propagates.
    if (_disposed || !_usingFallback) return;
    _emit(s);
  }

  void _emit(NarrationState s) {
    if (!_disposed) _controller.add(s);
  }

  @override
  Future<void> stop() async {
    await _primary.stop();
    await _fallback.stop();
  }

  @override
  void dispose() {
    _disposed = true;
    _primarySub.cancel();
    _fallbackSub.cancel();
    _primary.dispose();
    _fallback.dispose();
    _controller.close();
  }
}
