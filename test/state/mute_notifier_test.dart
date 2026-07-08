import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/settings/settings_store.dart';
import 'package:ultimate_ai_narrator/state/mute_notifier.dart';

void main() {
  test('loads the persisted mute value on creation', () async {
    final store = InMemorySettingsStore(muted: true);
    final notifier = MuteNotifier(store);
    await Future<void>.delayed(Duration.zero); // let the async load run
    expect(notifier.value, isTrue);
    notifier.dispose();
  });

  test('toggle flips and persists the value', () async {
    final store = InMemorySettingsStore();
    final notifier = MuteNotifier(store);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.value, isFalse);

    notifier.toggle();
    expect(notifier.value, isTrue);
    expect(await store.loadMuted(), isTrue);
    notifier.dispose();
  });
}
