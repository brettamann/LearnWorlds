// Haptics — a thin wrapper over HapticFeedback so call sites read as intent
// ("this was a counted tap") rather than as API ("selectionClick").
//
// Every method is a silent no-op on web and desktop, which is exactly what we
// want: the same runner code runs on the dev machine's touchscreen monitor and
// on the iPad the game is actually targeting, and only one of them buzzes.
//
// Haptics are the cheapest of the feedback channels — no assets, no latency,
// no volume setting to respect — and for a child holding a tablet they carry
// a surprising amount of the "that did something" signal.

import 'package:flutter/services.dart';

abstract final class Haptics {
  /// One counted object registered. Deliberately the lightest tick available:
  /// a child taps this ten times in a row and it must not become annoying.
  static void tick() => _guard(HapticFeedback.selectionClick);

  /// Something good landed — a round passed, a reward paid out.
  static void pop() => _guard(HapticFeedback.lightImpact);

  /// A gentle "not that one". Firmer than a tick so it's distinguishable
  /// without eyes on the screen, but never sharp — specs/shared/
  /// art-direction.md rules out anything that reads as punishment.
  static void nudge() => _guard(HapticFeedback.mediumImpact);

  static void _guard(Future<void> Function() action) {
    // Platforms without a haptics channel throw rather than no-op.
    try {
      action();
    } catch (_) {}
  }
}
