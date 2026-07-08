import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../core/logging.dart';
import 'narrator.dart';

/// Real narration via the device / browser TTS engine (Android `TextToSpeech`,
/// iOS `AVSpeechSynthesizer`, Web `SpeechSynthesis`). This is the default,
/// credential-free path.
///
/// The engine's start/completion/error callbacks are the only source of truth
/// for state; they map 1:1 onto [NarrationState]. `speak` never throws — any
/// failure is delivered as a [NarrationError] instead.
class FlutterTtsNarrator implements Narrator, ProgressiveNarrator, NamedVoice {
  FlutterTtsNarrator({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    unawaited(_configure());
  }

  static const String _friendlyError =
      'Oops! I could not read the story out loud. Tap to try again.';

  final FlutterTts _tts;
  final StreamController<NarrationState> _controller =
      StreamController<NarrationState>.broadcast();
  final StreamController<int> _progress = StreamController<int>.broadcast();
  bool _configured = false;
  bool _disposed = false;

  @override
  Stream<NarrationState> get state => _controller.stream;

  @override
  Stream<int> get spokenChars => _progress.stream;

  @override
  Stream<String> get voiceLabel => Stream<String>.value('Built-in voice');

  Future<void> _configure() async {
    try {
      _tts
        ..setStartHandler(() => _emit(const NarrationSpeaking()))
        ..setCompletionHandler(() => _emit(const NarrationCompleted()))
        ..setCancelHandler(() => _emit(const NarrationIdle()))
        ..setProgressHandler((String text, int start, int end, String word) {
          if (!_disposed && !_progress.isClosed) _progress.add(end);
        })
        ..setErrorHandler(
          (dynamic msg) => _emit(NarrationError(_friendlyError, cause: msg)),
        );
      // Slower, warmer delivery for young children.
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.1);
      _configured = true;
    } catch (e, s) {
      logError('FlutterTtsNarrator._configure', e, s);
    }
  }

  void _emit(NarrationState s) {
    if (!_disposed) _controller.add(s);
  }

  @override
  Future<void> speak(String text) async {
    if (_disposed) return;
    if (!_progress.isClosed) _progress.add(0);
    _emit(const NarrationPreparing());
    try {
      if (!_configured) await _configure();
      await _tts.speak(text);
    } catch (e, s) {
      logError('FlutterTtsNarrator.speak', e, s);
      _emit(const NarrationError(_friendlyError));
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e, s) {
      logError('FlutterTtsNarrator.stop', e, s);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_tts.stop());
    unawaited(_controller.close());
    unawaited(_progress.close());
  }
}
