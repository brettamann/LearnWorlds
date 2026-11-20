// The words the sort-by-attribute round speaks, and the shapes it shows so
// that the words are not the only thing to go on.
//
// Split out of `shape_garden_sort_by_attribute_runner.dart` for the same
// reason as `shape_words.dart` and `wheres_buddy_words.dart`: the runner is a
// widget and imports Flutter, so `narration_script.dart` - which has to
// compile under plain `dart run` - could not reach these strings, and the two
// lines built from them stayed in the browser synth voice while the rest of
// the game had rendered narration.
//
// (The filename says words and half of it is now pictures. They live together
// on purpose: a bin needs both, and a new one added in a file that only held
// strings would get a label and no picture, which is the state this whole file
// was just dug out of. `sort_bin_test.dart` holds the pair together too.)
//
// The runner reads these back through getters rather than storing copies, so
// the script and the game cannot disagree about the wording. A drift would be
// silent: the clip would be filed under the old sentence, never looked up, and
// the line would quietly revert to the synth voice.

import 'asset_paths.dart';
import 'warm_lines.dart';

/// Round attribute id -> the words spoken in "Sort by <word>."
const Map<String, String> kSortAttributeWords = <String, String>{
  'sides': 'number of sides',
  'size': 'size',
  'curves': 'curves or corners',
};

/// Bin id -> the label, drawn under the basket and read aloud when the basket
/// is tapped.
///
/// The tap was described here long before it existed: the baskets are drag
/// targets and nothing listened for a tap on one, so seven clips were rendered
/// for a beat the game never played. They are real now - a tap on a basket
/// says its name and does nothing else, which is safe precisely because a tap
/// has no meaning in this mechanic.
///
/// '5+ sides' is spoken as written. If that reads badly once there is a voice
/// on it, the fix is to change the label here - it is one string, and the
/// clip re-renders for free.
/// The three side-count labels, named so the K.G.4 lesson layer can use the
/// same const rather than retyping them. It used to retype them, which is one
/// reword away from a lesson and a round disagreeing about what the middle
/// basket is called - and from one of the two speaking in the synth voice.
const String kSortBin3Sides = '3 sides';
const String kSortBin4Sides = '4 sides';
const String kSortBin5PlusSides = '5+ sides';

const Map<String, String> kSortBinLabels = <String, String>{
  '3-sides': kSortBin3Sides,
  '4-sides': kSortBin4Sides,
  '5plus-sides': kSortBin5PlusSides,
  'small': 'small',
  'big': 'big',
  'round': 'round',
  'pointy': 'pointy',
};

/// One shape drawn on a basket to say what belongs in it.
class SortBinExemplar {
  const SortBinExemplar({
    required this.kind,
    this.variant = 'example',
    this.scale = 1.0,
  });

  /// Shape kind, as `AssetPaths.shapeGarden2dSprite` names it.
  final String kind;

  /// Colour variant. `example` is the plain red one the lesson art uses for
  /// "a triangle" as opposed to "this particular leaf-coloured triangle",
  /// which is exactly the register a bin label wants.
  final String variant;

  /// Drawn size relative to the others on the same basket. Only the size
  /// round uses anything but 1.0, and there it is the whole point.
  final double scale;

  String get asset => AssetPaths.shapeGarden2dSprite(kind, variant);
}

/// Bin id -> the shapes drawn on its basket.
///
/// This is what makes the round playable by the child it is written for. The
/// baskets were labelled '3 sides', '4 sides', '5+ sides', 'small', 'big',
/// 'round' and 'pointy' - in twelve-point type, on a 28px basket icon, in
/// front of a pre-reader. Sorting is a task whose entire content is telling
/// the bins apart, and she could not tell them apart at all, so every drop
/// was a guess and being right taught her nothing.
///
/// How much to show is a real decision, not a maximum:
///
///   - `4-sides` shows a square and the round also contains a rectangle. She
///     has to see that a rectangle belongs with the square, which is the
///     generalisation K.G.4 is asking for. Showing both would remove it.
///   - `5plus-sides` shows two, because "five or more" is genuinely a
///     category rather than a shape, and one pentagon would read as "the
///     pentagon basket" with the hexagon left homeless.
///   - `small` and `big` show the same circle at different sizes, because the
///     attribute *is* the size and any two different shapes would invite her
///     to sort by shape instead.
const Map<String, List<SortBinExemplar>> kSortBinExemplars =
    <String, List<SortBinExemplar>>{
  '3-sides': <SortBinExemplar>[SortBinExemplar(kind: 'triangle')],
  '4-sides': <SortBinExemplar>[SortBinExemplar(kind: 'square')],
  '5plus-sides': <SortBinExemplar>[
    SortBinExemplar(kind: 'pentagon'),
    SortBinExemplar(kind: 'hexagon'),
  ],
  'small': <SortBinExemplar>[SortBinExemplar(kind: 'circle', scale: 0.55)],
  'big': <SortBinExemplar>[SortBinExemplar(kind: 'circle')],
  'round': <SortBinExemplar>[SortBinExemplar(kind: 'circle')],
  'pointy': <SortBinExemplar>[SortBinExemplar(kind: 'triangle')],
};

/// The full spoken prompt for a round sorting by [attributeId].
///
/// Lives here rather than in the runner so the narration script builds the
/// line with the same code the game does, instead of restating the template
/// and drifting from it.
String sortAttributePrompt(String attributeId) =>
    'Sort by ${kSortAttributeWords[attributeId] ?? attributeId}. '
    'Drop each shape in the right basket!';

// ---------------------------------------------------------------------------
// The rounds
// ---------------------------------------------------------------------------

/// One shape to sort: its sprite, and the basket it belongs in this round.
class SortItem {
  const SortItem({
    required this.id,
    required this.kind,
    required this.variant,
    required this.targetBinId,
    this.isLarge = false,
  });

  final String id;

  /// Canonical shape kind (`triangle`, `square`, ...).
  final String kind;
  final String variant;

  /// The basket this item belongs in for its round's attribute.
  final String targetBinId;

  /// Drawn at the "big" size. Only the size round uses it.
  final bool isLarge;

  String get asset => AssetPaths.shapeGarden2dSprite(kind, variant);
}

/// One round of sorting by a single attribute.
class SortRound {
  const SortRound({
    required this.attribute,
    required this.binIds,
    required this.items,
    required this.keeperLine,
  });

  /// A key of [kSortAttributeWords].
  final String attribute;

  /// Keys of [kSortBinLabels], left to right.
  final List<String> binIds;
  final List<SortItem> items;

  /// What the keeper says over the sorted baskets.
  final String keeperLine;

  /// Words spoken in "Sort by <word>."
  String get attributeWord => kSortAttributeWords[attribute] ?? attribute;
}

/// Three rounds, each sorting by a different attribute K.G.4 names.
const List<SortRound> kSortAttributeRounds = <SortRound>[
  // Number of sides. Mirrors the lesson runtime.
  SortRound(
    attribute: 'sides',
    binIds: <String>['3-sides', '4-sides', '5plus-sides'],
    items: <SortItem>[
      SortItem(
        id: 'tri-1',
        kind: 'triangle',
        variant: 'yellow',
        targetBinId: '3-sides',
      ),
      SortItem(
        id: 'tri-2',
        kind: 'triangle',
        variant: 'leaf',
        targetBinId: '3-sides',
      ),
      SortItem(
        id: 'sq-1',
        kind: 'square',
        variant: 'green',
        targetBinId: '4-sides',
      ),
      SortItem(
        id: 'rect-1',
        kind: 'rectangle',
        variant: 'stone',
        targetBinId: '4-sides',
      ),
      SortItem(
        id: 'pent-1',
        kind: 'pentagon',
        variant: 'starfruit',
        targetBinId: '5plus-sides',
      ),
      SortItem(
        id: 'hex-1',
        kind: 'hexagon',
        variant: 'honeycomb',
        targetBinId: '5plus-sides',
      ),
    ],
    keeperLine:
        'Sides sorted! Triangles, squares + rectangles, pentagons + hexagons.',
  ),
  // Size: big vs small.
  SortRound(
    attribute: 'size',
    binIds: <String>['small', 'big'],
    items: <SortItem>[
      SortItem(
        id: 'small-circle',
        kind: 'circle',
        variant: 'sunflower',
        targetBinId: 'small',
      ),
      SortItem(
        id: 'small-square',
        kind: 'square',
        variant: 'gray',
        targetBinId: 'small',
      ),
      SortItem(
        id: 'small-tri',
        kind: 'triangle',
        variant: 'petal',
        targetBinId: 'small',
      ),
      SortItem(
        id: 'big-circle',
        kind: 'circle',
        variant: 'daisy',
        targetBinId: 'big',
        isLarge: true,
      ),
      SortItem(
        id: 'big-rect',
        kind: 'rectangle',
        variant: 'wood',
        targetBinId: 'big',
        isLarge: true,
      ),
      SortItem(
        id: 'big-hex',
        kind: 'hexagon',
        variant: 'terracotta',
        targetBinId: 'big',
        isLarge: true,
      ),
    ],
    keeperLine: 'Big to one side, small to the other — perfect.',
  ),
  // Curves vs corners: round vs pointy.
  SortRound(
    attribute: 'curves',
    binIds: <String>['round', 'pointy'],
    items: <SortItem>[
      SortItem(
        id: 'round-1',
        kind: 'circle',
        variant: 'sunflower',
        targetBinId: 'round',
      ),
      SortItem(
        id: 'round-2',
        kind: 'semicircle_half',
        variant: 'green',
        targetBinId: 'round',
      ),
      SortItem(
        id: 'round-3',
        kind: 'semicircle_quarter',
        variant: 'brown',
        targetBinId: 'round',
      ),
      SortItem(
        id: 'pointy-1',
        kind: 'triangle',
        variant: 'yellow',
        targetBinId: 'pointy',
      ),
      SortItem(
        id: 'pointy-2',
        kind: 'pentagon',
        variant: 'starfruit',
        targetBinId: 'pointy',
      ),
      SortItem(
        id: 'pointy-3',
        kind: 'hexagon',
        variant: 'honeycomb',
        targetBinId: 'pointy',
      ),
    ],
    keeperLine: 'Round things together, pointy things together. '
        "That's grouping by curves.",
  ),
];

const String kSortAttributeIntro =
    "Let's group the shapes! I'll tell you what to sort by — the "
    'number of sides, the size, or whether they have curves or '
    'corners. Drop each shape into the basket that matches.';

const String kSortAttributeStartLabel = "Let's sort!";

const String kSortAttributeFinal =
    'Every shape sorted! You can group things by all kinds of '
    'differences.';

/// The [n]th wrong-basket line of a round: a rotating warm line, then the
/// attribute again.
String sortAttributeMissLine(int n, String attributeId) => '${warmMissLine(n)} '
    'Sort by ${kSortAttributeWords[attributeId] ?? attributeId}.';
