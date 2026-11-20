// Flat vs Solid shape registry for K.G.3.
//
// Two pools — flat (2D) shapes drawn from the K.G.2 sprite set, and solid
// (3D) shapes drawn from the Shape-Garden creature sprites (cube-turtle,
// sphere-jellyfish, cylinder-golem, pyramid-fish, cone-gnome). Both share
// the same `FlatOrSolidShape` shape so the lesson + activity round can
// treat them uniformly: pick from a pool, draw the sprite, and the
// `isFlat` flag answers "which bin does this belong in?".
//
// The K.G.3 lesson teaches flat-vs-solid by walking through paired
// introductions — for each pair (flat ↔ solid) it shows the flat 2D
// example, cross-fades to the abstract 3D outline, then cross-fades to
// the themed creature sprite. The `FlatSolidPairing` records and the
// helpers below feed that intro choreography + the per-pairing sort
// rounds that follow it.

import 'asset_paths.dart';

class FlatOrSolidShape {
  const FlatOrSolidShape({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.assetPath,
    required this.isFlat,
  });

  /// Short stable id unique within a single round (e.g. `flat-circle`,
  /// `solid-sphere`).
  final String id;

  /// Canonical kind key (`circle`, `square`, `cube`, `sphere`...). The
  /// activity uses this for the narrator's per-shape feedback ("Cube —
  /// solid!"), so the kind is the *geometric* name even when the sprite
  /// is themed as a creature.
  final String kind;

  /// Human-readable name used in narration ("triangle", "cube",
  /// "cylinder"). For solid shapes this is the geometry name, not the
  /// creature name — the kid should learn "cube" rather than "cube-turtle".
  final String displayName;

  /// Path to the painted sprite.
  final String assetPath;

  /// True when the shape lives in the 2D / flat bin.
  final bool isFlat;
}

/// Flat-shape pool. One variant per kind so the kid sees a clean
/// representative drawing of each. Variants picked to match the K.G.2
/// intro layer (same yellow triangle, same green square, etc.).
const List<FlatOrSolidShape> kFlatShapes = <FlatOrSolidShape>[
  FlatOrSolidShape(
    id: 'flat-circle',
    kind: 'circle',
    displayName: 'circle',
    assetPath: 'assets/activities/shape-garden/shape_2d_circle-sunflower.png',
    isFlat: true,
  ),
  FlatOrSolidShape(
    id: 'flat-square',
    kind: 'square',
    displayName: 'square',
    assetPath: 'assets/activities/shape-garden/shape_2d_square-green.png',
    isFlat: true,
  ),
  FlatOrSolidShape(
    id: 'flat-triangle',
    kind: 'triangle',
    displayName: 'triangle',
    assetPath: 'assets/activities/shape-garden/shape_2d_triangle-yellow.png',
    isFlat: true,
  ),
  FlatOrSolidShape(
    id: 'flat-rectangle',
    kind: 'rectangle',
    displayName: 'rectangle',
    assetPath: 'assets/activities/shape-garden/shape_2d_rectangle-stone.png',
    isFlat: true,
  ),
  FlatOrSolidShape(
    id: 'flat-pentagon',
    kind: 'pentagon',
    displayName: 'pentagon',
    assetPath: 'assets/activities/shape-garden/shape_2d_pentagon-starfruit.png',
    isFlat: true,
  ),
  FlatOrSolidShape(
    id: 'flat-hexagon',
    kind: 'hexagon',
    displayName: 'hexagon',
    assetPath: 'assets/activities/shape-garden/shape_2d_hexagon-honeycomb.png',
    isFlat: true,
  ),
];

/// Solid-shape pool — the K.G.3 creature sprites. Each pairs the geometry
/// (cube, sphere, ...) with a Sanctuary creature theming (turtle, jellyfish,
/// ...). Narration says the geometry name; the art shows the creature.
List<FlatOrSolidShape> kSolidShapes = <FlatOrSolidShape>[
  FlatOrSolidShape(
    id: 'solid-cube',
    kind: 'cube',
    displayName: 'cube',
    assetPath: AssetPaths.shapeGarden3dCreature('cube', 'turtle'),
    isFlat: false,
  ),
  FlatOrSolidShape(
    id: 'solid-sphere',
    kind: 'sphere',
    displayName: 'sphere',
    assetPath: AssetPaths.shapeGarden3dCreature('sphere', 'jellyfish'),
    isFlat: false,
  ),
  FlatOrSolidShape(
    id: 'solid-cylinder',
    kind: 'cylinder',
    displayName: 'cylinder',
    assetPath: AssetPaths.shapeGarden3dCreature('cylinder', 'golem'),
    isFlat: false,
  ),
  FlatOrSolidShape(
    id: 'solid-pyramid',
    kind: 'pyramid',
    displayName: 'pyramid',
    assetPath: AssetPaths.shapeGarden3dCreature('pyramid', 'fish'),
    isFlat: false,
  ),
  FlatOrSolidShape(
    id: 'solid-cone',
    kind: 'cone',
    displayName: 'cone',
    assetPath: AssetPaths.shapeGarden3dCreature('cone', 'gnome'),
    isFlat: false,
  ),
];

/// A flat ↔ solid pairing used by the K.G.3 lesson's per-pairing intro.
/// Each pairing carries the three sprites needed for the cross-fade
/// (painted flat, abstract 3D outline, themed creature) plus the names the
/// narrator uses ("circle / sphere / ball / jellyfish").
class FlatSolidPairing {
  const FlatSolidPairing({
    required this.id,
    required this.flatKind,
    required this.flatName,
    required this.flatVariants,
    required this.solidKind,
    required this.solidName,
    required this.solidAltName,
    required this.creatureName,
  });

  /// Stable id ("circle-sphere", "square-cube", ...).
  final String id;

  /// Canonical 2D kind key (`circle`, `square`, `triangle`, `rectangle`).
  final String flatKind;

  /// Word the narrator uses for the flat shape ("circle").
  final String flatName;

  /// Painted variants of the flat kind, used to draw distinct sprites for
  /// multiple instances in a sort round (so the kid sees 3 circles that
  /// look subtly different — same kind, different material).
  final List<String> flatVariants;

  /// Canonical 3D kind key (`sphere`, `cube`, `pyramid`, `cylinder`).
  final String solidKind;

  /// Geometry name the narrator says ("sphere").
  final String solidName;

  /// Friendlier alternate name ("ball"). Used in the "we call it a sphere
  /// or a ball" intro line.
  final String solidAltName;

  /// Creature theming for the solid sprite ("jellyfish" → cube-turtle,
  /// "turtle" → cube-turtle...). Used to (a) load the themed sprite and
  /// (b) call it out in the third intro stage ("see how this jellyfish
  /// looks like a sphere?").
  final String creatureName;

  /// 2D `*-example` sprite (the dot-bearing one, displayed for stage 1 of
  /// the pairing intro). Magenta dots are 1-px and invisible at display
  /// resolution.
  String get flatExampleAsset => AssetPaths.shapeGarden2dExample(flatKind);

  /// Abstract 3D outline (stage 2 of the pairing intro).
  String get solidOutlineAsset => AssetPaths.shapeGarden3dOutline(solidKind);

  /// Themed 3D creature sprite (stage 3 of the pairing intro + the sort
  /// round's "solid" instances).
  String get solidThemedAsset =>
      AssetPaths.shapeGarden3dCreature(solidKind, creatureName);
}

/// Pairings introduced in lesson order. Most-intuitive correspondences
/// first (round / square) → less-intuitive (pyramid / cylinder).
const List<FlatSolidPairing> kFlatSolidPairings = <FlatSolidPairing>[
  FlatSolidPairing(
    id: 'circle-sphere',
    flatKind: 'circle',
    flatName: 'circle',
    flatVariants: <String>['sunflower', 'daisy', 'violet'],
    solidKind: 'sphere',
    solidName: 'sphere',
    solidAltName: 'ball',
    creatureName: 'jellyfish',
  ),
  FlatSolidPairing(
    id: 'square-cube',
    flatKind: 'square',
    flatName: 'square',
    flatVariants: <String>['green', 'brown', 'gray'],
    solidKind: 'cube',
    solidName: 'cube',
    solidAltName: 'box',
    creatureName: 'turtle',
  ),
  FlatSolidPairing(
    id: 'triangle-pyramid',
    flatKind: 'triangle',
    flatName: 'triangle',
    flatVariants: <String>['yellow', 'leaf', 'petal'],
    solidKind: 'pyramid',
    solidName: 'pyramid',
    solidAltName: 'tent shape',
    creatureName: 'fish',
  ),
  // Second triangle pairing — reinforces that one flat shape can take
  // multiple solid forms. The kid has already seen pyramids; cones show
  // up next with the same silhouette but the iconic round base + tip.
  FlatSolidPairing(
    id: 'triangle-cone',
    flatKind: 'triangle',
    flatName: 'triangle',
    flatVariants: <String>['petal', 'leaf', 'yellow'],
    solidKind: 'cone',
    solidName: 'cone',
    solidAltName: 'ice cream cone',
    creatureName: 'gnome',
  ),
  FlatSolidPairing(
    id: 'rectangle-cylinder',
    flatKind: 'rectangle',
    flatName: 'rectangle',
    flatVariants: <String>['stone', 'sand', 'wood'],
    solidKind: 'cylinder',
    solidName: 'cylinder',
    solidAltName: 'can',
    creatureName: 'golem',
  ),
];

/// One painted-flat instance for sorting. `instance` cycles through the
/// pairing's variant list so multiple flat copies look distinct.
FlatOrSolidShape flatShapeFromPairing(FlatSolidPairing p, int instance) {
  final variant = p.flatVariants[instance % p.flatVariants.length];
  return FlatOrSolidShape(
    id: 'flat-${p.flatKind}-$instance',
    kind: p.flatKind,
    displayName: p.flatName,
    assetPath: AssetPaths.shapeGarden2dSprite(p.flatKind, variant),
    isFlat: true,
  );
}

/// One themed-solid instance for sorting. There's only a single creature
/// sprite per solid kind, so multiple instances reuse the same sprite —
/// only the id differs (`solid-sphere-0`, `solid-sphere-1`, ...).
FlatOrSolidShape solidShapeFromPairing(FlatSolidPairing p, int instance) {
  return FlatOrSolidShape(
    id: 'solid-${p.solidKind}-$instance',
    kind: p.solidKind,
    displayName: p.solidName,
    assetPath: p.solidThemedAsset,
    isFlat: false,
  );
}

// ---------------------------------------------------------------------------
// What a flat-or-solid round says
// ---------------------------------------------------------------------------
//
// FlatOrSolidRound (the K.G.3 lesson's you-do beat and the Shape Garden
// sorting sub-mode) builds its lines here, so the narration script can list
// exactly what the round says rather than restating the templates.

/// The round's opening instruction, unless the host gives its own.
const String kFlatOrSolidPrompt =
    'Sort the shapes! Flat ones in the flat basket. Solid ones in the solid '
    'basket.';

/// Said as the last shape lands.
const String kFlatOrSolidDoneLine = 'Nicely done! You sorted them all.';

/// Said when [shape] lands in the right basket: "Triangle — flat!".
String flatOrSolidHitLine(FlatOrSolidShape shape) {
  final name = shape.displayName;
  final capitalized =
      name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
  return '$capitalized — ${shape.isFlat ? 'flat' : 'solid'}!';
}

/// Said when a shape is dropped in the wrong basket.
String flatOrSolidMissLine({required bool shapeIsFlat}) {
  final correctSide = shapeIsFlat ? 'flat' : 'solid';
  final wrongSide = shapeIsFlat ? 'solid' : 'flat';
  return "That's $correctSide, not $wrongSide. Try the other basket.";
}

// ---------------------------------------------------------------------------
// Shape Garden's flat-or-solid sub-mode
// ---------------------------------------------------------------------------

/// One sorting round's shape mix, and what the keeper says over it once it
/// is sorted.
class GardenSortingRound {
  const GardenSortingRound({
    required this.flatCount,
    required this.solidCount,
    required this.keeperLine,
  });

  final int flatCount;
  final int solidCount;

  /// What the keeper says over the finished baskets, setting up the next.
  final String keeperLine;
}

const List<GardenSortingRound> kGardenSortingRounds = <GardenSortingRound>[
  GardenSortingRound(
    flatCount: 2,
    solidCount: 2,
    keeperLine: 'Wonderful sorting! Try another round.',
  ),
  GardenSortingRound(
    flatCount: 2,
    solidCount: 2,
    keeperLine: "You're getting the hang of it. One more.",
  ),
  GardenSortingRound(
    flatCount: 3,
    solidCount: 2,
    keeperLine: 'Lovely! Let me bring out a few more shapes.',
  ),
  GardenSortingRound(
    flatCount: 2,
    solidCount: 3,
    keeperLine: 'Almost done — one last basket-round!',
  ),
  GardenSortingRound(
    flatCount: 3,
    solidCount: 3,
    keeperLine: 'You sorted every shape! Wonderful work.',
  ),
];

/// The shapes for sorting round [round]: `flatCount + solidCount` drawn from
/// the two pools with a round-keyed offset, so each round shows a different
/// mix without surprise repeats.
List<FlatOrSolidShape> gardenSortingShapes(int round) {
  final r = kGardenSortingRounds[round];
  return <FlatOrSolidShape>[
    for (var i = 0; i < r.flatCount; i++)
      kFlatShapes[(round * 2 + i) % kFlatShapes.length],
    for (var i = 0; i < r.solidCount; i++)
      kSolidShapes[(round + i) % kSolidShapes.length],
  ];
}

/// The banner over the round: "Round 2 of 5 — flat or solid?".
String gardenSortingHeader(int round) =>
    'Round ${round + 1} of ${kGardenSortingRounds.length} — flat or solid?';

const String kGardenSortingIntro =
    'Some shapes are flat — like drawings on a page. Others are solid '
    '— you can hold them in your hand. Help me sort them into the right '
    'baskets!';

/// The visit's last beat. It used to name the clean-round total (25), which
/// overstated the payout whenever a round needed help; like every other
/// place, it says "some coins".
const String kGardenSortingFinal =
    'You sorted every shape! Here are some coins for your help.';

/// Every line a garden sorting visit can say: the shell's, and the round's.
List<String> gardenSortingScriptLines() {
  final shapes = <FlatOrSolidShape>{
    for (var i = 0; i < kGardenSortingRounds.length; i++)
      ...gardenSortingShapes(i),
  };
  return <String>[
    kGardenSortingIntro,
    for (final r in kGardenSortingRounds) r.keeperLine,
    kGardenSortingFinal,
    kFlatOrSolidPrompt,
    kFlatOrSolidDoneLine,
    for (final line in <String>{for (final s in shapes) flatOrSolidHitLine(s)})
      line,
    flatOrSolidMissLine(shapeIsFlat: true),
    flatOrSolidMissLine(shapeIsFlat: false),
  ];
}
