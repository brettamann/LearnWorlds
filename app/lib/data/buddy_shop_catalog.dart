// Buddy shop pricing — what each part costs and which ones a fresh save
// already owns.
//
// This exists because the wallet has been paying out 5 coins a round since the
// first sprint into a balance with nothing to buy. A currency that can't be
// spent is a number, not a reward; specs/shared/reward-tracks.md is explicit
// that what sustains a kid is "a new outfit on their character," not an
// incrementing counter.
//
// Deliberately data-driven off `buddy_parts_catalog.dart` rather than listing
// every purchasable item by hand: a new body colour dropped into the parts
// catalog is automatically for sale at the body price, with no edit here. The
// only hand-maintained list is `kBuddyFreeParts` — the starter wardrobe.
//
// Pricing is calibrated against the payout in
// `lib/coordinators/round_coordinator.dart` (5 coins per clean round, ~5
// rounds per sub-mode, so ~25 coins a sitting):
//   - a body colour costs slightly less than one sub-mode, so the very first
//     purchase is reachable on day one;
//   - eyes cost about one sub-mode;
//   - hats cost about two and a half, and are the thing to save up for.
//
// Locked items stay *visible* in the shop, dimmed with a price on them. That
// is a deliberate exception to specs/shared/ui-affordances.md's "missing
// buttons, not disabled buttons" rule — in a picker, hiding what you can't
// afford removes the reason to come back. The rule still holds everywhere
// else, including the character creator, which shows owned parts only.

import 'buddy_parts_catalog.dart';

/// Which slot of the Buddy a part fills. Used to namespace ownership keys —
/// eyes `v1` and mouth `v1` are different items with the same catalog id.
enum BuddyPartKind { body, eyes, mouth, arms, legs, hat }

/// Stable key persisted in the save file's `owned` list.
String buddyOwnershipKey(BuddyPartKind kind, String id) => '${kind.name}:$id';

/// Price per slot. Every part of a given kind costs the same — a K-age kid
/// reading a wall of different numbers is being asked to comparison-shop,
/// which is not the skill this screen is for.
const Map<BuddyPartKind, int> kBuddyPartPrices = <BuddyPartKind, int>{
  BuddyPartKind.body: 20,
  BuddyPartKind.eyes: 25,
  BuddyPartKind.mouth: 20,
  BuddyPartKind.arms: 30,
  BuddyPartKind.legs: 30,
  BuddyPartKind.hat: 60,
};

/// The starter wardrobe: what a brand-new save can already wear.
///
/// Three bodies and three expressions is enough for the character creator to
/// feel like a real choice on the first run — the shop must never turn
/// onboarding into a storefront.
///
/// Exactly one arm and one leg are free, and that number is load-bearing at
/// both ends. It has to be at least one, or a brand-new Buddy has nothing to
/// render. It has to be no more than one, or the character creator opens on
/// first run with an Arms tab in it, which is the storefront leaking into
/// onboarding — a create-mode category earns its tab at two owned. Three more
/// of each shipped without editing this list, exactly as the old note here
/// predicted: they price themselves off `kBuddyPartPrices`. The mouth is
/// still in the state arms and legs were.
const Set<String> kBuddyFreeParts = <String>{
  'body:gold',
  'body:pink',
  'body:blue',
  'eyes:v1',
  'eyes:v2',
  'eyes:v3',
  'mouth:v1',
  'arms:arm-1',
  'legs:leg-1',
};

/// What [id] costs in [kind], or 0 if it is part of the starter wardrobe.
int buddyPartPrice(BuddyPartKind kind, String id) =>
    kBuddyFreeParts.contains(buddyOwnershipKey(kind, id))
    ? 0
    : kBuddyPartPrices[kind]!;

/// Every part of [kind] the shop can offer, as (id, assetPath) pairs.
/// Arms and legs surface their right-hand sprite, matching the swatch the
/// character creator already draws for them.
List<({String id, String assetPath})> buddyPartsOfKind(BuddyPartKind kind) {
  switch (kind) {
    case BuddyPartKind.body:
      return [for (final o in kBuddyBodies) (id: o.id, assetPath: o.assetPath)];
    case BuddyPartKind.eyes:
      return [for (final o in kBuddyEyes) (id: o.id, assetPath: o.assetPath)];
    case BuddyPartKind.mouth:
      return [for (final o in kBuddyMouths) (id: o.id, assetPath: o.assetPath)];
    case BuddyPartKind.arms:
      return [for (final o in kBuddyArms) (id: o.id, assetPath: o.rightAsset)];
    case BuddyPartKind.legs:
      return [for (final o in kBuddyLegs) (id: o.id, assetPath: o.rightAsset)];
    case BuddyPartKind.hat:
      return [for (final o in kBuddyHats) (id: o.id, assetPath: o.assetPath)];
  }
}
