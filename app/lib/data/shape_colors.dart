// What colour each 2D shape sprite is actually painted.
//
// The sprite files are named for their *material* - `stone`, `stem`,
// `starfruit`, `daisy` - which is good naming for art and useless as a
// predicate. So the two-attribute hunt carried a second, hand-written `color`
// field beside the variant, and nothing ever compared the two. They disagreed,
// and because the round's answer set is authored by hand as well, they
// disagreed in the same direction: the game's hardest round asked a child to
// "find every shape that is blue and has four sides" and lit two *grey* ones
// as the answer. There is no blue four-sided sprite in the set. There never
// was. Nothing failed, because nothing read the field.
//
// So the colour is derived from the variant here instead of being restated
// per shape, and `two_attribute_hunt_test.dart` checks that every colour word
// a round speaks is a colour something on that round's board really is.
//
// These are reading words, not colorimetry: `sunflower` is a gold circle and
// is called yellow because that is what a five-year-old would call it. The
// list was written by rendering every sprite side by side and looking at them
// - the sheet is trivial to regenerate, and worth regenerating before adding
// a row.

/// Sprite variant -> the colour word a child would use for it.
const Map<String, String> kShapeVariantColor = <String, String>{
  'blue': 'blue',
  'brown': 'brown',
  'cement': 'gray',
  'daisy': 'blue',
  'gray': 'gray',
  'green': 'green',
  'honeycomb': 'yellow',
  'leaf': 'green',
  'orange': 'orange',
  'petal': 'pink',
  'sand': 'tan',
  'starfruit': 'yellow',
  'stem': 'green',
  'stone': 'gray',
  'sunflower': 'yellow',
  'terracotta': 'orange',
  'violet': 'purple',
  'wood': 'brown',
  'yellow': 'yellow',
};

/// The colour word for [variant], or the variant itself if it is not a
/// painted 2D shape. Falling back to the variant rather than to null keeps a
/// missing row visible - it will not match any colour word a round speaks,
/// so the guard names it - without making every caller handle a null.
String shapeVariantColor(String variant) =>
    kShapeVariantColor[variant] ?? variant;
