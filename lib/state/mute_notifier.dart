import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_store.dart';

/// Holds the mute preference, loading it from (and saving it to) the injected
/// [SettingsStore] so the choice persists across launches.
class MuteNotifier extends StateNotifier<bool> {
  MuteNotifier(this._store) : super(false) {
    _load();
  }

  final SettingsStore _store;

  @visibleForTesting
  bool get value => state;

  Future<void> _load() async {
    state = await _store.loadMuted();
  }

  void toggle() {
    state = !state;
    _store.saveMuted(state);
  }
}
