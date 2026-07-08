import 'dart:async';

import '../core/logging.dart';
import 'narrator.dart';

/// Wraps a primary narrator and, if it emits a [NarrationError], transparently
/// retries on a fallback narrator (e.g. remote ElevenLabs → native TTS). The
/// child never sees the failure — just a brief re-prepare, then normal
/// narration. If both fail, the fallback's error is surfaced.
///
/// It also reports the *currently-active* voice label (via [NamedVoice]), so the
/// UI can show which engine is speaking — including after a fallback.
class FallbackNarrator implements Narrator, NamedVoice {
  FallbackNarrator(this._primary, this._fallback) {
    _primarySub = _primary.state.listen(_onPrimary);
    _fallbackSub = _fallback.state.listen(_onFallback);

    final primary = _primary;
    if (primary is NamedVoice) {
      _primaryVoiceSub = (primary as NamedVoice).voiceLabel.listen((label) {
        _primaryLabel = label;
        if (!_usingFallback) _setVoice(label);
      });
    }
    final fallback = _fallback;
    if (fallback is NamedVoice) {
      _fallbackVoiceSub = (fallback as NamedVoice).voiceLabel.listen((label) {
        _fallbackLabel = label;
        if (_usingFallback) _setVoice(label);
      });
    }
  }

  final Narrator _primary;
  final Narrator _fallback;
  final StreamController<NarrationState> _controller =
      StreamController<NarrationState>.broadcast();
  final StreamController<String> _voiceController =
      StreamController<String>.broadcast();
  late final StreamSubscription<NarrationState> _primarySub;
  late final StreamSubscription<NarrationState> _fallbackSub;
  StreamSubscription<String>? _primaryVoiceSub;
  StreamSubscription<String>? _fallbackVoiceSub;

  String _lastText = '';
  bool _usingFallback = false;
  bool _disposed = false;

  String _primaryLabel = 'Premium voice';
  String _fallbackLabel = 'Built-in voice';
  String _currentVoice = 'Premium voice';

  @override
  Stream<NarrationState> get state => _controller.stream;

  @override
  Stream<String> get voiceLabel async* {
    yield _currentVoice;
    yield* _voiceController.stream;
  }

  @override
  Future<void> speak(String text) async {
    if (_disposed) return;
    _lastText = text;
    _usingFallback = false;
    _setVoice(_primaryLabel);
    await _primary.speak(text);
  }

  void _onPrimary(NarrationState s) {
    if (_disposed || _usingFallback) return;
    if (s is NarrationError) {
      _usingFallback = true;
      _setVoice(_fallbackLabel);
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

  void _setVoice(String label) {
    _currentVoice = label;
    if (!_disposed) _voiceController.add(label);
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
    _primaryVoiceSub?.cancel();
    _fallbackVoiceSub?.cancel();
    _primary.dispose();
    _fallback.dispose();
    _controller.close();
    _voiceController.close();
  }
}
