import 'package:just_audio/just_audio.dart';

import '../core/logging.dart';

/// Short UI sound effects for quiz feedback. Injectable so tests (and muted
/// mode) use a no-op implementation with no audio plugin.
abstract interface class SoundEffects {
  Future<void> correct();
  Future<void> wrong();
  Future<void> dispose();
}

/// Silent implementation — the default (used in tests and when muted).
class NoopSoundEffects implements SoundEffects {
  const NoopSoundEffects();

  @override
  Future<void> correct() async {}

  @override
  Future<void> wrong() async {}

  @override
  Future<void> dispose() async {}
}

/// Real implementation playing bundled WAV chimes via just_audio. Failures are
/// logged and swallowed — a missing sound must never break the quiz.
class JustAudioSoundEffects implements SoundEffects {
  final AudioPlayer _player = AudioPlayer();

  Future<void> _play(String asset) async {
    try {
      await _player.setAsset(asset);
      await _player.play();
    } catch (e, s) {
      logError('JustAudioSoundEffects.play($asset)', e, s);
    }
  }

  @override
  Future<void> correct() => _play('assets/sfx/correct.wav');

  @override
  Future<void> wrong() => _play('assets/sfx/wrong.wav');

  @override
  Future<void> dispose() async => _player.dispose();
}
