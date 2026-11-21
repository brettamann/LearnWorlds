// BuddyWardrobe — which shop parts the kid has bought.
//
// State is the set of purchased ownership keys ('body:purple', 'hat:crown').
// The starter wardrobe in `kBuddyFreeParts` is deliberately NOT stored here:
// it is checked separately by `owns`, so changing the free set later re-prices
// existing saves correctly instead of leaving them holding stale grants.
//
// Grandfathering matters more than it looks. A save written before the shop
// existed may already be wearing a part the shop now charges for — the kid
// picked purple in the character creator months ago. Taking it away would be
// the single most punishing thing this feature could do, so `hydrate` folds
// whatever the saved Buddy is wearing into the owned set.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/buddy_shop_catalog.dart';
import '../models/buddy_appearance.dart';

/// The ownership keys a given appearance is currently wearing.
Set<String> buddyAppearanceKeys(BuddyAppearance a) => <String>{
  buddyOwnershipKey(BuddyPartKind.body, a.bodyId),
  buddyOwnershipKey(BuddyPartKind.eyes, a.eyesId),
  buddyOwnershipKey(BuddyPartKind.mouth, a.mouthId),
  buddyOwnershipKey(BuddyPartKind.arms, a.armsId),
  buddyOwnershipKey(BuddyPartKind.legs, a.legsId),
  if (a.hatId != null) buddyOwnershipKey(BuddyPartKind.hat, a.hatId!),
};

class BuddyWardrobe extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// True for anything the kid may equip: the starter wardrobe plus whatever
  /// has been bought.
  bool owns(String key) => kBuddyFreeParts.contains(key) || state.contains(key);

  /// Record a purchase. Idempotent, so a double-tap on a shop tile can't
  /// charge twice — the caller checks `owns` before spending.
  void grant(String key) {
    if (state.contains(key)) return;
    state = <String>{...state, key};
  }

  /// Boot-time hydration. [appearance] is folded in so a Buddy assembled
  /// before the shop existed keeps every part it is wearing. Free parts are
  /// filtered out so the save doesn't accumulate rows it never needed.
  void hydrate(Set<String> owned, {required BuddyAppearance appearance}) {
    state = <String>{...owned, ...buddyAppearanceKeys(appearance)}
      ..removeWhere(kBuddyFreeParts.contains);
  }
}

final buddyWardrobeProvider = NotifierProvider<BuddyWardrobe, Set<String>>(
  BuddyWardrobe.new,
);
