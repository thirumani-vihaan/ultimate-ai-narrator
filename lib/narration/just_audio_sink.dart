import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import '../core/logging.dart';
import 'elevenlabs_narrator.dart' show AudioSink;

/// Real [AudioSink] backed by just_audio. Plays the fetched ElevenLabs mp3 via a
/// base64 `data:` URI, which is reliable across web (HTML5 audio) and mobile,
/// and resolves when playback finishes so the narrator emits `completed` at the
/// right time.
class JustAudioSink implements AudioSink {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(Uint8List mp3) async {
    final dataUri = Uri.dataFromBytes(mp3, mimeType: 'audio/mpeg').toString();
    await _player.setUrl(dataUri);
    await _player.play(); // completes when playback ends or is stopped
    await _player.stop();
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e, s) {
      logError('JustAudioSink.stop', e, s);
    }
  }

  @override
  Future<void> dispose() async => _player.dispose();
}
