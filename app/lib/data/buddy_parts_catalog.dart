// Buddy parts catalog — the canonical list of every body / eye / mouth /
// arms / legs / decor option the character creator can offer. Each
// option is just a stable id + sprite path; the BuddyWidget composes
// the selected pieces at render time.
//
// Adding a new variant: drop the sprite under
// `app/assets/buddy/<category>/<id>.png`
// and append an entry below. Mirror arms / legs L+R pairs share a
// single catalog id and the loader picks both sides at render time.
//
// Authoring rules:
//   - `bodyColors` ids match the PNG filenames in `body/` exactly so we
//     can also surface them as color-swatch chips in the picker.
//   - `eyes`, `mouths`, `armSets`, `legSets` use opaque ids — the kid
//     never sees them; the picker shows the actual sprite as the
//     option's affordance.
//   - Every category MUST have at least one entry so a fresh save can
//     hydrate a complete Buddy with defaults.

class BuddyOption {
  const BuddyOption({required this.id, required this.assetPath});

  /// Stable id persisted in the save file.
  final String id;

  /// Path to the sprite this option draws (or, for arms/legs, the
  /// "left" sprite — the right side is derived).
  final String assetPath;
}

/// Two-piece option for arms/legs. The `-l` and `-r` suffixes live in
/// the file system; the catalog stores both paths so the BuddyWidget
/// doesn't have to recompute them.
class BuddyPairOption {
  const BuddyPairOption({
    required this.id,
    required this.leftAsset,
    required this.rightAsset,
  });

  final String id;
  final String leftAsset;
  final String rightAsset;
}

// ---------------------------------------------------------------------
// Bodies — 12 colors, file stem doubles as id.
// ---------------------------------------------------------------------
const List<BuddyOption> kBuddyBodies = <BuddyOption>[
  BuddyOption(id: 'gold', assetPath: 'assets/buddy/body/gold.png'),
  BuddyOption(id: 'silver', assetPath: 'assets/buddy/body/silver.png'),
  BuddyOption(id: 'white', assetPath: 'assets/buddy/body/white.png'),
  BuddyOption(id: 'black', assetPath: 'assets/buddy/body/black.png'),
  BuddyOption(id: 'pink', assetPath: 'assets/buddy/body/pink.png'),
  BuddyOption(id: 'red', assetPath: 'assets/buddy/body/red.png'),
  BuddyOption(id: 'orange', assetPath: 'assets/buddy/body/orange.png'),
  BuddyOption(id: 'yellow', assetPath: 'assets/buddy/body/yellow.png'),
  BuddyOption(id: 'green', assetPath: 'assets/buddy/body/green.png'),
  BuddyOption(id: 'teal', assetPath: 'assets/buddy/body/teal.png'),
  BuddyOption(id: 'blue', assetPath: 'assets/buddy/body/blue.png'),
  BuddyOption(id: 'purple', assetPath: 'assets/buddy/body/purple.png'),
];

// ---------------------------------------------------------------------
// Eyes — v1..v12. Twelve clearly different face expressions; the kid
// picks the one their Buddy "feels like."
// ---------------------------------------------------------------------
const List<BuddyOption> kBuddyEyes = <BuddyOption>[
  BuddyOption(id: 'v1', assetPath: 'assets/buddy/eyes/v1.png'),
  BuddyOption(id: 'v2', assetPath: 'assets/buddy/eyes/v2.png'),
  BuddyOption(id: 'v3', assetPath: 'assets/buddy/eyes/v3.png'),
  BuddyOption(id: 'v4', assetPath: 'assets/buddy/eyes/v4.png'),
  BuddyOption(id: 'v5', assetPath: 'assets/buddy/eyes/v5.png'),
  BuddyOption(id: 'v6', assetPath: 'assets/buddy/eyes/v6.png'),
  BuddyOption(id: 'v7', assetPath: 'assets/buddy/eyes/v7.png'),
  BuddyOption(id: 'v8', assetPath: 'assets/buddy/eyes/v8.png'),
  BuddyOption(id: 'v9', assetPath: 'assets/buddy/eyes/v9.png'),
  BuddyOption(id: 'v10', assetPath: 'assets/buddy/eyes/v10.png'),
  BuddyOption(id: 'v11', assetPath: 'assets/buddy/eyes/v11.png'),
  BuddyOption(id: 'v12', assetPath: 'assets/buddy/eyes/v12.png'),
];

// ---------------------------------------------------------------------
// Mouths — only one variant for now; the picker only renders the chip
// if there are two or more, but keep the structure so future mouths
// drop in painlessly.
// ---------------------------------------------------------------------
const List<BuddyOption> kBuddyMouths = <BuddyOption>[
  BuddyOption(id: 'v1', assetPath: 'assets/buddy/mouths/v1.png'),
];

// ---------------------------------------------------------------------
// Expression mouths - driven by mood, never chosen by the child.
//
// Deliberately NOT in kBuddyMouths. That list is the cosmetic one: the
// creator offers it and buddy_shop_catalog.dart turns every entry into a
// purchasable item. These three are not cosmetics - `buddyMouthIdForMood`
// swaps them in for a beat and swaps them back - so putting them there would
// sell a child a flat line for 20 coins and then leave it on Buddy's resting
// face if she equipped it.
//
// `buddyMouthAsset` resolves across both lists, so the mood swap finds them
// and the shop does not.
// ---------------------------------------------------------------------
const List<BuddyOption> kBuddyExpressionMouths = <BuddyOption>[
  BuddyOption(id: 'v2', assetPath: 'assets/buddy/mouths/v2.png'),
  BuddyOption(id: 'v3', assetPath: 'assets/buddy/mouths/v3.png'),
  BuddyOption(id: 'v4', assetPath: 'assets/buddy/mouths/v4.png'),
];

// ---------------------------------------------------------------------
// Hats — optional accessory layered on top. Selecting null = no hat.
// ---------------------------------------------------------------------
const List<BuddyOption> kBuddyHats = <BuddyOption>[
  BuddyOption(id: 'cowboy-hat', assetPath: 'assets/buddy/hats/cowboy-hat.png'),
  BuddyOption(id: 'crown', assetPath: 'assets/buddy/hats/crown.png'),
];

// ---------------------------------------------------------------------
// Arms / Legs — paired sprites (L + R from a single catalog id).
// ---------------------------------------------------------------------
const List<BuddyPairOption> kBuddyArms = <BuddyPairOption>[
  BuddyPairOption(
    id: 'arm-1',
    leftAsset: 'assets/buddy/arms/arm-1-l.png',
    rightAsset: 'assets/buddy/arms/arm-1-r.png',
  ),
  BuddyPairOption(
    id: 'arm-2',
    leftAsset: 'assets/buddy/arms/arm-2-l.png',
    rightAsset: 'assets/buddy/arms/arm-2-r.png',
  ),
  BuddyPairOption(
    id: 'arm-3',
    leftAsset: 'assets/buddy/arms/arm-3-l.png',
    rightAsset: 'assets/buddy/arms/arm-3-r.png',
  ),
  BuddyPairOption(
    id: 'arm-4',
    leftAsset: 'assets/buddy/arms/arm-4-l.png',
    rightAsset: 'assets/buddy/arms/arm-4-r.png',
  ),
];

const List<BuddyPairOption> kBuddyLegs = <BuddyPairOption>[
  BuddyPairOption(
    id: 'leg-1',
    leftAsset: 'assets/buddy/legs/leg-1-l.png',
    rightAsset: 'assets/buddy/legs/leg-1-r.png',
  ),
  BuddyPairOption(
    id: 'leg-2',
    leftAsset: 'assets/buddy/legs/leg-2-l.png',
    rightAsset: 'assets/buddy/legs/leg-2-r.png',
  ),
  BuddyPairOption(
    id: 'leg-3',
    leftAsset: 'assets/buddy/legs/leg-3-l.png',
    rightAsset: 'assets/buddy/legs/leg-3-r.png',
  ),
  BuddyPairOption(
    id: 'leg-4',
    leftAsset: 'assets/buddy/legs/leg-4-l.png',
    rightAsset: 'assets/buddy/legs/leg-4-r.png',
  ),
];

/// Default Buddy used on a fresh save (first body / first eyes / etc.).
/// Keeps the rest of the app from having to handle null parts.
const String kBuddyDefaultBodyId = 'gold';
const String kBuddyDefaultEyesId = 'v1';
const String kBuddyDefaultMouthId = 'v1';
const String kBuddyDefaultArmsId = 'arm-1';
const String kBuddyDefaultLegsId = 'leg-1';

/// Returns the sprite path for a given catalog id; falls back to the
/// default if the id has been removed or never existed. The fallback
/// keeps a save migration from breaking the Hub.
String buddyBodyAsset(String id) => kBuddyBodies
    .firstWhere((o) => o.id == id, orElse: () => kBuddyBodies.first)
    .assetPath;

String buddyEyesAsset(String id) => kBuddyEyes
    .firstWhere((o) => o.id == id, orElse: () => kBuddyEyes.first)
    .assetPath;

/// Cosmetic mouths first, then the mood-driven expression set.
///
/// Falls back to the default rather than throwing, so a mood can name a mouth
/// whose art has not been drawn yet without ever rendering a missing asset.
String buddyMouthAsset(String id) => <BuddyOption>[
  ...kBuddyMouths,
  ...kBuddyExpressionMouths,
].firstWhere((o) => o.id == id, orElse: () => kBuddyMouths.first).assetPath;

String buddyHatAsset(String id) => kBuddyHats
    .firstWhere((o) => o.id == id, orElse: () => kBuddyHats.first)
    .assetPath;

BuddyPairOption buddyArms(String id) =>
    kBuddyArms.firstWhere((o) => o.id == id, orElse: () => kBuddyArms.first);

BuddyPairOption buddyLegs(String id) =>
    kBuddyLegs.firstWhere((o) => o.id == id, orElse: () => kBuddyLegs.first);
