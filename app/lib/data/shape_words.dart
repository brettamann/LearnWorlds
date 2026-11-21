// What the narrator calls each shape.
//
// Pure Dart, and deliberately not in `shape_intro_layer.dart` where it used to
// live. That file imports flutter/material and riverpod, so anything wanting to
// know a shape's spoken name had to drag the widget toolkit along - which meant
// `narration_script.dart` could not enumerate the Shape Garden lines, and those
// lines were the last ones still speaking in the browser synth voice while
// every other line in the game had a rendered one.
//
// Keys match the `targetKind` on a Shape Garden round and the sprite kind in
// `asset_paths.dart`.

/// Display name used in narration: "This one is a <name>."
///
/// Right triangle and the semicircles get custom phrasing rather than the raw
/// key, which would be read aloud as "semicircle underscore half".
const Map<String, String> kShapeDisplayName = <String, String>{
  'circle': 'circle',
  'triangle': 'triangle',
  'triangle-right': 'right triangle',
  'square': 'square',
  'rectangle': 'rectangle',
  'pentagon': 'pentagon',
  'hexagon': 'hexagon',
  'semicircle_half': 'half circle',
  'semicircle_quarter': 'quarter circle',
};

/// Plural used in narration: "Tap all the <plural>."
///
/// Held separately rather than appending an "s", because "half circles" and
/// "quarter circles" pluralise the noun rather than the whole phrase.
const Map<String, String> kShapeDisplayPlural = <String, String>{
  'circle': 'circles',
  'triangle': 'triangles',
  'triangle-right': 'right triangles',
  'square': 'squares',
  'rectangle': 'rectangles',
  'pentagon': 'pentagons',
  'hexagon': 'hexagons',
  'semicircle_half': 'half circles',
  'semicircle_quarter': 'quarter circles',
};

/// Every shape kind the garden can name, in a stable order.
List<String> get kShapeKinds => kShapeDisplayName.keys.toList();
