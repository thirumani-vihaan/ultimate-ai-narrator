import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging.dart';

/// Persists small user settings. Injectable so tests use an in-memory store with
/// no platform plugin.
abstract interface class SettingsStore {
  Future<bool> loadMuted();
  Future<void> saveMuted(bool value);
}

/// In-memory store for tests / default.
class InMemorySettingsStore implements SettingsStore {
  // ignore: prefer_initializing_formals
  InMemorySettingsStore({bool muted = false}) : _muted = muted;

  bool _muted;

  @override
  Future<bool> loadMuted() async => _muted;

  @override
  Future<void> saveMuted(bool value) async => _muted = value;
}

/// Real store backed by shared_preferences. All access is guarded — a failure to
/// read/write a preference must never break the app.
class SharedPrefsSettingsStore implements SettingsStore {
  static const String _mutedKey = 'muted';

  @override
  Future<bool> loadMuted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_mutedKey) ?? false;
    } catch (e, s) {
      logError('SharedPrefsSettingsStore.loadMuted', e, s);
      return false;
    }
  }

  @override
  Future<void> saveMuted(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mutedKey, value);
    } catch (e, s) {
      logError('SharedPrefsSettingsStore.saveMuted', e, s);
    }
  }
}
