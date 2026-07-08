import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../core/logging.dart';
import 'audio_cache.dart';
import 'narrator.dart';

/// Raised by [ElevenLabsClient] on any non-success response. Carries the HTTP
/// status so the caller can distinguish a rate-limit (429) from other failures.
class TtsApiException implements Exception {
  const TtsApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => 'TtsApiException($statusCode): $message';
}

/// Plays synthesized audio bytes. Abstracted so the narrator's fetch/cache logic
/// is fully testable without a real audio device.
abstract interface class AudioSink {
  Future<void> play(Uint8List mp3);
  Future<void> stop();
}

/// Default sink when no real player plugin is wired. It does not emit sound; it
/// logs and briefly simulates playback so the state machine still advances.
/// Wiring a real player (e.g. just_audio) is the documented final step in
/// REAL_API_SETUP.md — no other code changes are needed.
class SilentAudioSink implements AudioSink {
  const SilentAudioSink();

  @override
  Future<void> play(Uint8List mp3) async {
    logInfo('SilentAudioSink', 'Would play ${mp3.length} bytes of audio.');
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> stop() async {}
}

/// Real ElevenLabs text-to-speech client. Injectable [http.Client] so tests
/// exercise the real request/response/error paths with a fake transport.
class ElevenLabsClient {
  ElevenLabsClient({
    required this.apiKey,
    this.voiceId = 'JBFqnCBsd6RMkjVDRZzb',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String voiceId;
  final http.Client _client;

  Future<Uint8List> synthesize(String text) async {
    final uri = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/$voiceId',
    );
    final http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: <String, String>{
              'xi-api-key': apiKey,
              'accept': 'audio/mpeg',
              'content-type': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'text': text,
              'model_id': 'eleven_multilingual_v2',
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e, s) {
      logError('ElevenLabsClient.synthesize', e, s);
      throw const TtsApiException('Network error contacting ElevenLabs.');
    }
    if (res.statusCode == 429) {
      throw const TtsApiException('Rate limited.', statusCode: 429);
    }
    if (res.statusCode != 200) {
      throw TtsApiException(
        'ElevenLabs returned HTTP ${res.statusCode}.',
        statusCode: res.statusCode,
      );
    }
    return res.bodyBytes;
  }
}

/// Bonus remote narration via ElevenLabs. Fetches mp3 (cached by content hash so
/// identical text never re-hits the quota), then plays it via [AudioSink].
/// Selected only when `ELEVENLABS_API_KEY` is present; native TTS remains the
/// default. `speak` never throws — failures surface as [NarrationError].
class ElevenLabsNarrator implements Narrator {
  ElevenLabsNarrator({
    required String apiKey,
    ElevenLabsClient? client,
    AudioCache? cache,
    AudioSink? sink,
  })  : _client = client ?? ElevenLabsClient(apiKey: apiKey),
        _cache = cache ?? InMemoryAudioCache(),
        _sink = sink ?? const SilentAudioSink();

  static const String _friendlyError =
      'Oops! I could not read the story out loud. Tap to try again.';

  final ElevenLabsClient _client;
  final AudioCache _cache;
  final AudioSink _sink;

  final StreamController<NarrationState> _controller =
      StreamController<NarrationState>.broadcast();
  bool _disposed = false;

  @override
  Stream<NarrationState> get state => _controller.stream;

  @override
  Future<void> speak(String text) async {
    if (_disposed) return;
    _emit(const NarrationPreparing());
    try {
      final key = _cacheKey(text);
      var bytes = await _cache.get(key);
      if (bytes == null) {
        bytes = await _client.synthesize(text);
        await _cache.put(key, bytes);
      } else {
        logInfo('ElevenLabsNarrator', 'cache hit for "$key"');
      }
      _emit(const NarrationSpeaking());
      await _sink.play(bytes);
      _emit(const NarrationCompleted());
    } on TtsApiException catch (e) {
      logError('ElevenLabsNarrator.speak', e);
      _emit(NarrationError(_friendlyError, cause: e));
    } catch (e, s) {
      logError('ElevenLabsNarrator.speak', e, s);
      _emit(const NarrationError(_friendlyError));
    }
  }

  String _cacheKey(String text) =>
      sha1.convert(utf8.encode('$text|${_client.voiceId}')).toString();

  void _emit(NarrationState s) {
    if (!_disposed) _controller.add(s);
  }

  @override
  Future<void> stop() async {
    await _sink.stop();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_sink.stop());
    unawaited(_controller.close());
  }
}
