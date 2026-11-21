// Wallet — minimal coin balance for the active kid. Sprint 1 ships a single
// integer; the real economy (chest tiers, pity timers, blueprints) lands in
// later sprints when the Foundry is built out.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class Wallet extends Notifier<int> {
  @override
  int build() => 0;

  void award(int coins) {
    state = state + coins;
  }

  /// Attempt a purchase. Returns false and leaves the balance alone when the
  /// kid can't afford it, so callers never have to pre-check and never drive
  /// the balance negative.
  ///
  /// The refusal is silent here on purpose — the shop turns it into a warm
  /// "not yet" beat rather than an error, per specs/shared/ui-affordances.md.
  bool spend(int coins) {
    if (coins < 0 || coins > state) return false;
    state = state - coins;
    return true;
  }

  /// Boot-time hydration from disk via SaveCoordinator.
  void set(int coins) {
    state = coins;
  }
}

final walletProvider = NotifierProvider<Wallet, int>(Wallet.new);
