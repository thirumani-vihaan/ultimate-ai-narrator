import 'dart:typed_data';

/// Caches synthesized audio bytes by key (a hash of text + voice) so identical
/// narration never re-hits a remote TTS API. Injectable so the cache strategy
/// (memory today, disk later) can change without touching callers.
abstract interface class AudioCache {
  Future<Uint8List?> get(String key);
  Future<void> put(String key, Uint8List data);
}

/// Simple bounded in-memory LRU-ish cache. Evicts the oldest entry when full to
/// keep the memory footprint small on mid-range devices.
class InMemoryAudioCache implements AudioCache {
  InMemoryAudioCache({this.maxEntries = 16});

  final int maxEntries;
  final Map<String, Uint8List> _store = <String, Uint8List>{};

  @override
  Future<Uint8List?> get(String key) async {
    final value = _store.remove(key);
    if (value != null) _store[key] = value; // mark as most-recently-used
    return value;
  }

  @override
  Future<void> put(String key, Uint8List data) async {
    _store.remove(key);
    if (_store.length >= maxEntries) {
      _store.remove(_store.keys.first);
    }
    _store[key] = data;
  }

  int get length => _store.length;
}
