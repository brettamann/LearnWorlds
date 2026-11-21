// The two-attribute hunt (Shape Garden's K.G.4 challenge): its boards and
// every line it says.
//
// Flutter-free, like every other activity's words, so narration_script.dart
// can list exactly what the runner speaks. Positions are fractions of the
// board, not Offsets, for the same reason.

import 'shape_colors.dart';
import 'warm_lines.dart';

class HuntShape {
  const HuntShape({
    required this.id,
    required this.kind,
    required this.variant,
    required this.isLarge,
    required this.x,
    required this.y,
  });

  final String id;
  final String kind;

  /// File-name variant - the artist's material name (`stone`, `stem`,
  /// `starfruit`).
  final String variant;

  /// The colour word a child would use, read off the sprite rather than
  /// restated here. It used to be a field, and it was wrong: three shapes
  /// declared `blue` and were painted grey and gold. See `shape_colors.dart`.
  String get color => shapeVariantColor(variant);

  final bool isLarge;

  /// Centre of the shape, as a fraction of the board's width and height.
  final double x;
  final double y;
}

class HuntRound {
  const HuntRound({
    required this.title,
    required this.prompt,
    required this.matches,
    required this.shapes,
    required this.keeperLine,
  });

  /// Short pill text shown on screen ("Green AND 4 sides").
  final String title;

  /// Full narration ("Find every shape that is green and has four sides.").
  final String prompt;

  /// IDs of the shapes that satisfy both attributes.
  final Set<String> matches;

  final List<HuntShape> shapes;

  /// What the keeper says over the finished board.
  final String keeperLine;
}

const List<HuntRound> kTwoAttributeHuntRounds = <HuntRound>[
  // Round 1 — "Green AND 4 sides."
  //
  // It asked for blue until 2026-09-08, and there is no blue four-sided
  // sprite in the game - the two it lit as the answer are a near-black square
  // and a grey brick. Green is the one colour the set has enough of: a green
  // square and a green rectangle to find, and a green triangle to pass over.
  // The board keeps its shape - one near-miss on each attribute - and the
  // positions are unchanged.
  HuntRound(
    title: 'Green AND 4 sides',
    prompt: 'Find every shape that is green and has four sides. Tap each one!',
    matches: <String>{'g-sq', 'g-rect'},
    shapes: <HuntShape>[
      HuntShape(
        id: 'g-sq',
        kind: 'square',
        variant: 'green',
        isLarge: false,
        x: 0.18,
        y: 0.20,
      ),
      HuntShape(
        id: 'g-rect',
        kind: 'rectangle',
        variant: 'stem',
        isLarge: false,
        x: 0.72,
        y: 0.66,
      ),
      // Green, and not four sides.
      HuntShape(
        id: 'g-tri',
        kind: 'triangle',
        variant: 'leaf',
        isLarge: false,
        x: 0.30,
        y: 0.66,
      ),
      // Four sides, and not green.
      HuntShape(
        id: 'br-sq',
        kind: 'square',
        variant: 'brown',
        isLarge: false,
        x: 0.80,
        y: 0.22,
      ),
      HuntShape(
        id: 'p-circle',
        kind: 'circle',
        variant: 'violet',
        isLarge: false,
        x: 0.50,
        y: 0.30,
      ),
      HuntShape(
        id: 'y-pent',
        kind: 'pentagon',
        variant: 'starfruit',
        isLarge: false,
        x: 0.55,
        y: 0.80,
      ),
    ],
    keeperLine: 'Two green shapes with four sides — you spotted both!',
  ),
  // Round 2 — "Round AND big."
  HuntRound(
    title: 'Round AND big',
    prompt: 'Find every shape that is round and big.',
    matches: <String>{'big-circle-1', 'big-circle-2'},
    shapes: <HuntShape>[
      HuntShape(
        id: 'big-circle-1',
        kind: 'circle',
        variant: 'daisy',
        isLarge: true,
        x: 0.25,
        y: 0.30,
      ),
      HuntShape(
        id: 'big-circle-2',
        kind: 'circle',
        variant: 'sunflower',
        isLarge: true,
        x: 0.72,
        y: 0.30,
      ),
      HuntShape(
        id: 'small-circle',
        kind: 'circle',
        variant: 'violet',
        isLarge: false,
        x: 0.50,
        y: 0.16,
      ),
      HuntShape(
        id: 'big-tri',
        kind: 'triangle',
        variant: 'leaf',
        isLarge: true,
        x: 0.20,
        y: 0.72,
      ),
      HuntShape(
        id: 'big-rect',
        kind: 'rectangle',
        variant: 'wood',
        isLarge: true,
        x: 0.75,
        y: 0.72,
      ),
      HuntShape(
        id: 'small-semi',
        kind: 'semicircle_half',
        variant: 'green',
        isLarge: false,
        x: 0.50,
        y: 0.66,
      ),
    ],
    keeperLine: 'Two big round things — both found!',
  ),
  // Round 3 — "Pointy AND yellow."
  HuntRound(
    title: 'Pointy AND yellow',
    prompt: 'Find every shape that has corners and is yellow.',
    matches: <String>{'y-tri-1', 'y-pent'},
    shapes: <HuntShape>[
      HuntShape(
        id: 'y-tri-1',
        kind: 'triangle',
        variant: 'yellow',
        isLarge: false,
        x: 0.22,
        y: 0.24,
      ),
      // `pentagon-orange` until 2026-09-08, in the round that asks for
      // yellow. `starfruit` is the yellow one.
      HuntShape(
        id: 'y-pent',
        kind: 'pentagon',
        variant: 'starfruit',
        isLarge: false,
        x: 0.78,
        y: 0.66,
      ),
      HuntShape(
        id: 'y-circle',
        kind: 'circle',
        variant: 'sunflower',
        isLarge: false,
        x: 0.50,
        y: 0.20,
      ),
      HuntShape(
        id: 'g-tri',
        kind: 'triangle',
        variant: 'leaf',
        isLarge: false,
        x: 0.72,
        y: 0.24,
      ),
      HuntShape(
        id: 'b-rect',
        kind: 'rectangle',
        variant: 'stone',
        isLarge: false,
        x: 0.22,
        y: 0.70,
      ),
      HuntShape(
        id: 'p-hex',
        kind: 'hexagon',
        variant: 'terracotta',
        isLarge: false,
        x: 0.50,
        y: 0.74,
      ),
    ],
    keeperLine: 'Yellow with corners — sharp eye!',
  ),
];

/// Coins for clearing every round, paid once per visit. Same generosity tier
/// as the counting `tens-parade` challenge.
const int kTwoAttributeHuntBonus = 50;

const String kTwoAttributeHuntIntro =
    'Ready for the big sort? Each round names TWO things at once — '
    'tap every shape that matches BOTH. Get them all and earn '
    '$kTwoAttributeHuntBonus bonus coins!';

/// The finale of the visit that pays the bonus.
const String kTwoAttributeHuntReward =
    'All three rounds cleared! Two-attribute hunt is no match for you. '
    'Here are $kTwoAttributeHuntBonus bonus coins.';

/// Said as each match is found.
const String kTwoAttributeHitLine = 'Yes! Both.';

/// The [n]th wrong tap of a round: one attribute matched, not both.
String twoAttributeMissLine(int n) => "That's not both. ${warmMissLine(n)}";

/// The round-one demonstration: the shape it taps as a match, and the
/// near-miss it taps as "only one". Ids on the first board - they move with it.
const String kTwoAttributeDemoMatchId = 'g-sq';
const String kTwoAttributeDemoMissId = 'g-tri';

/// The demonstration's four beats, in order.
const String kTwoAttributeDemoIntro =
    'Watch me. Each round needs both things at the same time.';
const String kTwoAttributeDemoMatch =
    'This square is green AND has four sides — both. Yes!';
const String kTwoAttributeDemoMiss =
    'This triangle is green, but it has three sides — only one '
    'match. Not both.';
const String kTwoAttributeDemoHandoff =
    'Your turn. Find every shape that matches BOTH!';

/// Every line the hunt can say, apart from the shared warm hint lines.
List<String> twoAttributeHuntScriptLines() => <String>[
  kTwoAttributeHuntIntro,
  kTwoAttributeDemoIntro,
  kTwoAttributeDemoMatch,
  kTwoAttributeDemoMiss,
  kTwoAttributeDemoHandoff,
  for (final r in kTwoAttributeHuntRounds) r.prompt,
  kTwoAttributeHitLine,
  for (var n = 0; n < 4; n++) twoAttributeMissLine(n),
  for (final r in kTwoAttributeHuntRounds) r.keeperLine,
  kTwoAttributeHuntReward,
];
