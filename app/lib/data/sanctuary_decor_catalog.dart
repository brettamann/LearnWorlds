// Sanctuary decor — what she can buy and put on the map.
//
// This is the game's answer to the one rubric row in the engagement plan still
// scored Absent: "is there anywhere with no right answer?" Everything else
// CritMath does is assessed. Appendix A is blunt that this matters — Toca Boca
// and Sago Mini succeed with no rules, no goals and no win condition at all,
// and the lesson taken there is not "remove the math" but that agency is
// itself the engagement mechanic. A decorated map is also the only thing in
// the game besides fog that persists visibly between sittings, which is what
// specs/shared/reward-tracks.md means by a reward that changes the world she
// inhabits rather than a counter.
//
// Deliberately mirrors `buddy_shop_catalog.dart` rather than inventing a
// second economy: one price per tier, not per item. That file's reasoning
// holds here unchanged — a K-age kid reading a wall of different numbers is
// being asked to comparison-shop, which is not the skill this screen is for.
//
// Flutter-free on purpose. `narration_script.dart` has to enumerate the spoken
// names under plain `dart run`, and a widget import would put them out of
// reach exactly the way the Tens Parade reward line was.

/// Size band an item belongs to. The only thing a band decides is price and
/// the order items appear in the tray, so adding an item is one row.
enum DecorTier { small, large, special }

class DecorItem {
  const DecorItem({
    required this.id,
    required this.displayName,
    required this.spriteAsset,
    required this.tier,
    required this.widthFraction,
  });

  /// Stable key. Persisted in the save file, so renaming one abandons whatever
  /// she had bought and placed.
  final String id;

  /// Spoken when she taps it in the tray, and drawn under the tray tile.
  final String displayName;

  final String spriteAsset;
  final DecorTier tier;

  /// Rendered width as a fraction of the map's shortest side.
  ///
  /// Held per item rather than derived from the tier because these are drawn
  /// objects with their own proportions: a rainbow arch reads as an arch only
  /// if it is wide, and a toadstool that size would look like a tree. A lesson
  /// node is 0.07 for reference.
  final double widthFraction;
}

/// Price per tier, calibrated against the same ~25-coin sub-mode payout the
/// Buddy shop is priced against: one small item is reachable inside a single
/// sitting, and the two special items are the things to save for.
const Map<DecorTier, int> kDecorPrices = <DecorTier, int>{
  DecorTier.small: 15,
  DecorTier.large: 30,
  DecorTier.special: 60,
};

/// What a brand-new save already owns.
///
/// Two items, for the same reason the Buddy shop hands over a starter
/// wardrobe: the first time she opens the tray it must be a box of things she
/// can use, not a storefront. One of each of the cheap shapes is enough to
/// discover that dragging works.
const Set<String> kDecorFreeItems = <String>{
  'toadstool-cluster',
  'flower-patch',
};

const List<DecorItem> kSanctuaryDecor = <DecorItem>[
  DecorItem(
    id: 'toadstool-cluster',
    displayName: 'Toadstools',
    spriteAsset: 'assets/sanctuary/decor/toadstool-cluster.png',
    tier: DecorTier.small,
    widthFraction: 0.075,
  ),
  DecorItem(
    id: 'flower-patch',
    displayName: 'Flowers',
    spriteAsset: 'assets/sanctuary/decor/flower-patch.png',
    tier: DecorTier.small,
    widthFraction: 0.08,
  ),
  DecorItem(
    id: 'garden-lantern',
    displayName: 'Lantern',
    spriteAsset: 'assets/sanctuary/decor/garden-lantern.png',
    tier: DecorTier.small,
    widthFraction: 0.06,
  ),
  DecorItem(
    id: 'standing-stone',
    displayName: 'Standing Stone',
    spriteAsset: 'assets/sanctuary/decor/standing-stone.png',
    tier: DecorTier.large,
    widthFraction: 0.09,
  ),
  DecorItem(
    id: 'lily-pond',
    displayName: 'Lily Pond',
    spriteAsset: 'assets/sanctuary/decor/lily-pond.png',
    tier: DecorTier.large,
    widthFraction: 0.13,
  ),
  DecorItem(
    id: 'topiary-tree',
    displayName: 'Topiary Tree',
    spriteAsset: 'assets/sanctuary/decor/topiary-tree.png',
    tier: DecorTier.large,
    widthFraction: 0.085,
  ),
  DecorItem(
    id: 'star-fountain',
    displayName: 'Star Fountain',
    spriteAsset: 'assets/sanctuary/decor/star-fountain.png',
    tier: DecorTier.special,
    widthFraction: 0.14,
  ),
  DecorItem(
    id: 'rainbow-arch',
    displayName: 'Rainbow Arch',
    spriteAsset: 'assets/sanctuary/decor/rainbow-arch.png',
    tier: DecorTier.special,
    widthFraction: 0.17,
  ),
];

/// What [id] costs, or 0 if it is part of the starter set.
int decorPrice(String id) {
  if (kDecorFreeItems.contains(id)) return 0;
  final item = decorItemById(id);
  return item == null ? 0 : kDecorPrices[item.tier]!;
}

DecorItem? decorItemById(String id) {
  for (final item in kSanctuaryDecor) {
    if (item.id == id) return item;
  }
  return null;
}

/// Spoken when she taps an item she owns in the tray.
///
/// The tray draws the name, which is no use to a pre-reader — the same gap the
/// creature-card album had. Saying it is also the only teaching this screen
/// does, and it is the kind that sticks: she asked what it was called.
String decorNameLine(DecorItem item) => '${item.displayName}.';

/// Spoken when she taps something she cannot afford yet.
///
/// Warm, and never a refusal. `specs/shared/ui-affordances.md` keeps locked
/// items visible precisely so there is something to want, which only works if
/// wanting it is a pleasant experience.
const String kDecorTooExpensiveLine = 'Not enough coins for that one yet. '
    'Play a round and come back!';

/// Spoken the first time she opens the tray in a session.
const String kDecorInviteLine = 'This is your sanctuary. '
    'Put things wherever you like — there is no wrong place.';
