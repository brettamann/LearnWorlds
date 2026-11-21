// Shop — the one way coins become things.
//
// The Buddy shop and the Sanctuary decor tray each wrote out "check owned,
// spend, grant, play a sound, save" by hand, and the copies had drifted: they
// played different sounds for the same moment, and only one of them saved.
// Saving is autosave's job now; this owns the rest, once.
//
// What a refusal looks like stays with the caller - a shaking swatch in one
// place, a spoken line in the other - because that is genuinely different.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/buddy_shop_catalog.dart';
import '../data/sanctuary_decor_catalog.dart';
import '../engines/feedback/feedback_engine.dart';
import '../providers/buddy_wardrobe_provider.dart';
import '../providers/sanctuary_decor_provider.dart';
import '../providers/wallet_provider.dart';

enum PurchaseOutcome {
  /// Paid for and now hers.
  bought,

  /// Already hers (or free); nothing was charged.
  alreadyOwned,

  /// Not enough coins yet; nothing was charged.
  cannotAfford,
}

class Shop {
  Shop(this._ref);

  final Ref _ref;

  /// Buys the Buddy part [key] ([buddyOwnershipKey]) at [price].
  PurchaseOutcome buyBuddyPart(String key, int price) {
    final wardrobe = _ref.read(buddyWardrobeProvider.notifier);
    return _buy(
      owns: wardrobe.owns(key),
      price: price,
      grant: () {
        wardrobe.grant(key);
      },
    );
  }

  /// Buys the Sanctuary decoration [id] at its catalog price.
  PurchaseOutcome buyDecor(String id) {
    final ownership = _ref.read(decorOwnershipProvider.notifier);
    return _buy(
      owns: ownership.owns(id),
      price: decorPrice(id),
      grant: () {
        ownership.grant(id);
      },
    );
  }

  PurchaseOutcome _buy({
    required bool owns,
    required int price,
    required void Function() grant,
  }) {
    if (owns) return PurchaseOutcome.alreadyOwned;
    // Wallet.spend refuses rather than going negative, so an unaffordable
    // purchase cannot half-complete.
    if (!_ref.read(walletProvider.notifier).spend(price)) {
      return PurchaseOutcome.cannotAfford;
    }
    grant();
    _ref.read(feedbackEngineProvider).purchase();
    return PurchaseOutcome.bought;
  }
}

final shopProvider = Provider<Shop>(Shop.new);
