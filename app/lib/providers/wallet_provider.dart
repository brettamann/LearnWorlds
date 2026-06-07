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

  /// Boot-time hydration from disk via SaveCoordinator.
  void set(int coins) {
    state = coins;
  }
}

final walletProvider = NotifierProvider<Wallet, int>(Wallet.new);
