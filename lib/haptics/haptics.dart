import 'package:flutter/services.dart';

import '../core/logging.dart';

/// Tactile feedback for quiz interactions. Implementations no-op silently where
/// haptics are unsupported (web, desktop, many emulators) and never throw or
/// block the UI.
abstract interface class Haptics {
  Future<void> wrong();
  Future<void> correct();
}

class RealHaptics implements Haptics {
  const RealHaptics();

  @override
  Future<void> wrong() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e, s) {
      logError('RealHaptics.wrong', e, s);
    }
  }

  @override
  Future<void> correct() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e, s) {
      logError('RealHaptics.correct', e, s);
    }
  }
}

/// Records calls for assertions in tests.
class FakeHaptics implements Haptics {
  final List<String> calls = <String>[];

  @override
  Future<void> wrong() async => calls.add('wrong');

  @override
  Future<void> correct() async => calls.add('correct');
}
