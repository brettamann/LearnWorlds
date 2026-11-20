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
