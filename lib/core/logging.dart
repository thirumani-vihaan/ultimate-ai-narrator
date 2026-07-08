import 'package:flutter/foundation.dart';

/// Minimal logger. Every caught error MUST be routed here with context so that
/// no exception is ever silently swallowed at a module boundary (a silent
/// `catch (_) {}` is indistinguishable from the boundary not existing).
void logError(String where, Object error, [StackTrace? stack]) {
  debugPrint('[ERROR] $where: $error');
  if (stack != null && kDebugMode) {
    debugPrint(stack.toString());
  }
}

void logInfo(String where, String message) {
  debugPrint('[INFO] $where: $message');
}
