import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ultimate_ai_narrator/narration/audio_cache.dart';
import 'package:ultimate_ai_narrator/narration/elevenlabs_narrator.dart';
import 'package:ultimate_ai_narrator/narration/narrator.dart';

class _RecordingSink implements AudioSink {
  int plays = 0;

  @override
  Future<void> play(Uint8List mp3) async => plays++;

  @override
  Future<void> stop() async {}
}

void main() {
  test('cache miss fetches once; identical text is served from cache', () async {
    var httpCalls = 0;
    final mock = MockClient((request) async {
      httpCalls++;
      return http.Response.bytes(<int>[1, 2, 3], 200);
    });
    final sink = _RecordingSink();
    final narrator = ElevenLabsNarrator(
      apiKey: 'k',
      client: ElevenLabsClient(apiKey: 'k', client: mock),
      cache: InMemoryAudioCache(),
      sink: sink,
    );
    addTearDown(narrator.dispose);

    final events = <NarrationState>[];
    narrator.state.listen(events.add);

    await narrator.speak('hello');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(httpCalls, 1);
    expect(
      events.map((e) => e.runtimeType),
      containsAllInOrder(<Type>[
        NarrationPreparing,
        NarrationSpeaking,
        NarrationCompleted,
      ]),
    );

    await narrator.speak('hello'); // same text → cache hit, no new fetch
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(httpCalls, 1);
    expect(sink.plays, 2);
  });

  test('HTTP 429 surfaces a friendly NarrationError (never throws)', () async {
    final mock = MockClient((request) async => http.Response('rate', 429));
    final narrator = ElevenLabsNarrator(
      apiKey: 'k',
      client: ElevenLabsClient(apiKey: 'k', client: mock),
    );
    addTearDown(narrator.dispose);

    final events = <NarrationState>[];
    narrator.state.listen(events.add);

    await narrator.speak('x');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(events.last, isA<NarrationError>());
  });

  test('ElevenLabsClient throws TtsApiException on non-200', () async {
    final mock = MockClient((request) async => http.Response('err', 500));
    final client = ElevenLabsClient(apiKey: 'k', client: mock);
    expect(client.synthesize('x'), throwsA(isA<TtsApiException>()));
  });
}
