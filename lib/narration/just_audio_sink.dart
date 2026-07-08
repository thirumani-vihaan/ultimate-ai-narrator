// just_audio's streaming source API is marked experimental but is its public,
// stable-in-practice way to play in-memory bytes without a temp file.
// ignore_for_file: experimental_member_use
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import 'elevenlabs_narrator.dart' show AudioSink;

/// Serves in-memory mp3 bytes to just_audio as a streaming source (works on web
/// and mobile without touching the filesystem).
class _BytesAudioSource extends StreamAudioSource {
  _BytesAudioSource(this._bytes);

  final Uint8List _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: e - s,
      offset: s,
      stream: Stream<List<int>>.value(_bytes.sublist(s, e)),
      contentType: 'audio/mpeg',
    );
  }
}

/// Real [AudioSink] backed by just_audio. Plays the fetched ElevenLabs mp3 and
/// resolves when playback finishes, so the narrator emits `completed` at the
/// right time.
class JustAudioSink implements AudioSink {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(Uint8List mp3) async {
    await _player.setAudioSource(_BytesAudioSource(mp3));
    await _player.play(); // completes when playback ends or is stopped
    await _player.stop();
  }

  @override
  Future<void> stop() async => _player.stop();

  @override
  Future<void> dispose() async => _player.dispose();
}
