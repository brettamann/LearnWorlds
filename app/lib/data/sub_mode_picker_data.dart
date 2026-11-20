// Per-sub-mode metadata for the Sanctuary node picker — the symbol drawn
// and the short label shown in the bottom sheet when the kid taps an activity
// node that has more than one available sub-mode.
//
// Challenge sub-modes share the same metadata block as regular ones; the
// picker decides whether to surface them. The convention going forward
// is: challenge sub-modes live at the end of an activity's chain and only
// appear in the picker once every regular sub-mode is complete, marked
// with a "Challenge!" chip so the kid knows it's optional. Demotion floors
// never appear at all and so are deliberately absent from this file.
//
// THESE LABELS ARE SPOKEN. That is why they live in a Flutter-free file the
// narration script can enumerate — same reason as map_labels.dart, and
// discovered the same way. Nothing below may import Flutter: keep positions
// as plain doubles, not `Offset`, or `dart run tool/dump_narration_script.dart`
// stops compiling and narration_script_test.dart says so.
//
// The picker is, after the two maps, the most-seen screen in the game: from
// the second visit to an activity onwards it stands between every tap on a
// node and the thing behind it.
//
// WHAT A SYMBOL IS FOR
// --------------------
// Every option used to be a single borrowed sprite, and six of them were
// openly marked as stop-gaps in this file: the three Where's Buddy options
// were a toucan, a phoenix and a unicorn, and the three Build-a-Habitat ones
// were three grey outline solids that differ from each other about as much as
// three grey outline solids can. Two of the six were also *the same sprite as
// a Counting Parade option* — the baby phoenix meant "Count by ones" on one
// node and "Put Buddy there" on another, the baby unicorn meant "Big parade"
// and "In the middle". A child learning which picture opens which game was
// being taught a contradiction.
//
// So a symbol is not a mascot now. It is a miniature of the round:
//
//   - Where's Buddy draws *her* Buddy — the one she built, in her colours —
//     hiding behind the hollow tree, standing on the rocks, or between two
//     toadstools. Those are the three sub-modes, drawn literally, using the
//     same landmark sprites the round itself puts on screen.
//   - Build-a-Habitat draws the habitat she finishes, out of the blueprint
//     data the round is built from: the triangle shelter, the square roost,
//     the pentagon gazebo. It cannot drift from the activity because it *is*
//     the activity's data.
//   - Shape Garden and Counting Parade keep a single sprite each, because
//     there a single sprite is already honest — a shape is what Shape Garden
//     is about, and a species is what a parade is made of.
//
// Naming the concept is better than naming the mechanic: "In the middle"
// tells her something, "Relational mode" does not. Keep the words short,
// sayable, and in a five-year-old's vocabulary — every one of them goes
// through the recording pipeline.

import 'asset_paths.dart';

/// How a picker card draws itself.
///
/// Sealed so the renderer's switch is exhaustive: a new kind of symbol added
/// here fails to compile in `sub_mode_symbol.dart` rather than falling
/// through to a blank card.
sealed class PickerSymbol {
  const PickerSymbol();

  /// A stable string naming this symbol, so a test can assert no two options
  /// anywhere in the game draw the same thing. Compared, never displayed.
  String get identity;
}

/// One borrowed sprite, drawn to fill the card's symbol box.
class PickerSprite extends PickerSymbol {
  const PickerSprite(this.asset);

  final String asset;

  @override
  String get identity => 'sprite:$asset';
}

/// A small arrangement of sprites — and optionally the kid's own Buddy —
/// standing in for what the round looks like.
class PickerScene extends PickerSymbol {
  const PickerScene(this.layers);

  /// Painted in order, so a layer listed later sits in front. That is how
  /// "hiding behind the tree" is drawn: Buddy first, then the tree.
  final List<PickerSceneLayer> layers;

  @override
  String get identity =>
      'scene:${layers.map((l) => l.asset ?? 'buddy').join('+')}';
}

/// One element of a [PickerScene], positioned as fractions of the square
/// symbol box: [x] and [y] are its centre, [size] the fraction of the box its
/// longer side takes up.
class PickerSceneLayer {
  const PickerSceneLayer.sprite(
    String this.asset, {
    required this.x,
    required this.y,
    required this.size,
    this.flip = false,
  });

  /// The kid's Buddy, as she built him. Not a sprite path because there is no
  /// one path — he is a stack of parts read from her save.
  const PickerSceneLayer.buddy({
    required this.x,
    required this.y,
    required this.size,
  })  : asset = null,
        flip = false;

  /// Null means "draw Buddy here".
  final String? asset;
  final double x;
  final double y;
  final double size;

  /// Mirrored horizontally. A pair of identical sprites bracketing Buddy
  /// reads as a repeated stamp; the same pair with one flipped reads as two
  /// toadstools. Same trick, and the same reason, as `BuddyFacing` — a
  /// mirrored sprite is a transform, never a second asset.
  final bool flip;

  bool get isBuddy => asset == null;
}

/// The finished habitat from `kHabitatBlueprints[blueprintIndex]`, drawn from
/// the same corners, sticks and roof pieces the round assembles.
///
/// An index rather than the blueprint itself: the blueprints carry `Offset`,
/// so importing them here would drag Flutter into a file that must not have
/// it. The renderer does the lookup.
class PickerHabitat extends PickerSymbol {
  const PickerHabitat(this.blueprintIndex);

  final int blueprintIndex;

  @override
  String get identity => 'habitat:$blueprintIndex';
}

class SubModePickerOption {
  const SubModePickerOption({
    required this.label,
    required this.symbol,
  });

  /// Short button label shown beneath the symbol, and spoken.
  final String label;

  /// What the card draws. Same box and treatment for every option so the kid
  /// can compare them at a glance.
  final PickerSymbol symbol;
}

/// Picker metadata keyed by `(activityId, subModeId)`. A missing entry
/// means we draw a generic placeholder — keeps the picker forgiving of
/// sub-modes whose runtime hasn't shipped yet.
final Map<String, Map<String, SubModePickerOption>> kSubModePickerData =
    <String, Map<String, SubModePickerOption>>{
  'shape-garden': <String, SubModePickerOption>{
    'find-shape': SubModePickerOption(
      label: 'Find the shape',
      symbol:
          PickerSprite(AssetPaths.shapeGarden2dSprite('triangle', 'yellow')),
    ),
    'flat-or-solid': SubModePickerOption(
      label: 'Flat or solid',
      symbol: PickerSprite(
        AssetPaths.shapeGarden3dCreature('sphere', 'jellyfish'),
      ),
    ),
    'sort-by-attribute': SubModePickerOption(
      label: 'Sort them out',
      symbol: PickerSprite(
        AssetPaths.shapeGarden2dSprite('hexagon', 'honeycomb'),
      ),
    ),
    'two-attribute-hunt': SubModePickerOption(
      label: 'Two things at once',
      symbol: PickerSprite(
        AssetPaths.shapeGarden2dSprite('pentagon', 'starfruit'),
      ),
    ),
  },
  'ten-frame-pond': <String, SubModePickerOption>{
    'fill-to-target': const SubModePickerOption(
      label: 'Fill the lily pads',
      symbol: PickerSprite(AssetPaths.tenFrameFrogGreen),
    ),
    'two-ways': const SubModePickerOption(
      label: 'Two kinds of frog',
      symbol: PickerScene(<PickerSceneLayer>[
        PickerSceneLayer.sprite(
          AssetPaths.tenFrameFrogGreen,
          x: 0.30,
          y: 0.55,
          size: 0.52,
        ),
        PickerSceneLayer.sprite(
          AssetPaths.tenFrameFrogOrange,
          x: 0.70,
          y: 0.55,
          size: 0.52,
        ),
      ]),
    ),
    'make-ten': const SubModePickerOption(
      label: 'Make ten',
      symbol: PickerScene(<PickerSceneLayer>[
        PickerSceneLayer.sprite(
          AssetPaths.tenFrameLilyPad,
          x: 0.5,
          y: 0.58,
          size: 0.9,
        ),
        PickerSceneLayer.sprite(
          AssetPaths.tenFrameFrogGreen,
          x: 0.5,
          y: 0.5,
          size: 0.56,
        ),
      ]),
    ),
    'ten-plus-n': const SubModePickerOption(
      label: 'Ten and more',
      symbol: PickerSprite(AssetPaths.countingParadeMeadowFrog),
    ),
    'three-frames': const SubModePickerOption(
      label: 'How many frogs?',
      symbol: PickerSprite(AssetPaths.tenFrameFrogWaving),
    ),
  },
  'care-pantry': <String, SubModePickerOption>{
    'simple-pantry': const SubModePickerOption(
      label: 'Tidy the pantry',
      symbol: PickerSprite(AssetPaths.carePantryAcorn),
    ),
    'full-pantry': const SubModePickerOption(
      label: 'The big tidy',
      symbol: PickerSprite(AssetPaths.carePantryCarrot),
    ),
    'unfamiliar-rules': const SubModePickerOption(
      label: 'Sort by colour',
      symbol: PickerScene(<PickerSceneLayer>[
        PickerSceneLayer.sprite(
          AssetPaths.carePantryApple,
          x: 0.28,
          y: 0.4,
          size: 0.42,
        ),
        PickerSceneLayer.sprite(
          AssetPaths.caretakersLeaf,
          x: 0.72,
          y: 0.4,
          size: 0.42,
        ),
        PickerSceneLayer.sprite(
          AssetPaths.carePantryCarrot,
          x: 0.5,
          y: 0.72,
          size: 0.42,
        ),
      ]),
    ),
  },
  'scribes-tower': <String, SubModePickerOption>{
    'trace-numeral': const SubModePickerOption(
      label: 'Trace a number',
      symbol: PickerSprite(AssetPaths.countingParadeFireflySprite),
    ),
    'write-from-cue': const SubModePickerOption(
      label: 'Count, then write',
      symbol: PickerScene(<PickerSceneLayer>[
        PickerSceneLayer.sprite(
          AssetPaths.countingParadeFireflySprite,
          x: 0.27,
          y: 0.4,
          size: 0.42,
        ),
        PickerSceneLayer.sprite(
          AssetPaths.countingParadeFireflySprite,
          x: 0.73,
          y: 0.4,
          size: 0.42,
        ),
        PickerSceneLayer.sprite(
          AssetPaths.countingParadeFireflySprite,
          x: 0.5,
          y: 0.72,
          size: 0.42,
        ),
      ]),
    ),
    'match-numeral': const SubModePickerOption(
      label: 'Find the number',
      symbol: PickerSprite(AssetPaths.countingParadeLanternMoth),
    ),
    'audio-only-teens': const SubModePickerOption(
      label: 'The big numbers',
      symbol: PickerSprite(AssetPaths.countingParadeMoonlightOwl),
    ),
  },
  'storytellers-pond': <String, SubModePickerOption>{
    'add-to': const SubModePickerOption(
      label: 'More are coming',
      symbol: PickerSprite(AssetPaths.storytellersDuckling),
    ),
    'take-from': const SubModePickerOption(
      label: 'Time to go home',
      symbol: PickerScene(<PickerSceneLayer>[
        PickerSceneLayer.sprite(
          'assets/activities/wheres-buddy/landmark-cottage.png',
          x: 0.62,
          y: 0.46,
          size: 0.66,
        ),
        PickerSceneLayer.sprite(
          AssetPaths.tenFrameFrogGreen,
          x: 0.28,
          y: 0.72,
          size: 0.42,
        ),
      ]),
    ),
    'put-together': const SubModePickerOption(
      label: 'All together',
      symbol: PickerScene(<PickerSceneLayer>[
        PickerSceneLayer.sprite(
          AssetPaths.storytellersDuckling,
          x: 0.3,
          y: 0.55,
          size: 0.52,
        ),
        PickerSceneLayer.sprite(
          AssetPaths.tenFrameFrogGreen,
          x: 0.7,
          y: 0.55,
          size: 0.52,
        ),
      ]),
    ),
    'take-apart': const SubModePickerOption(
      label: 'Some in the water',
      symbol: PickerSprite(AssetPaths.countingParadeMossBunny),
    ),
    'two-step': const SubModePickerOption(
      label: 'A longer story',
      symbol: PickerSprite(AssetPaths.countingParadeStarTurtle),
    ),
  },
  'caretakers-bench': <String, SubModePickerOption>{
    'describe-attributes': const SubModePickerOption(
      label: 'Heavy or light',
      symbol: PickerScene(<PickerSceneLayer>[
        PickerSceneLayer.sprite(
          AssetPaths.caretakersPumpkin,
          x: 0.34,
          y: 0.55,
          size: 0.58,
        ),
        PickerSceneLayer.sprite(
          AssetPaths.rewardFeather,
          x: 0.74,
          y: 0.45,
          size: 0.4,
        ),
      ]),
    ),
    'compare-two': const SubModePickerOption(
      label: 'Weigh them',
      symbol: PickerSprite(AssetPaths.caretakersScaleStand),
    ),
    'order-three-by-length': const SubModePickerOption(
      label: 'Line them up',
      symbol: PickerSprite(AssetPaths.caretakersLeaf),
    ),
  },
  'picnic-baskets': <String, SubModePickerOption>{
    'match-by-line': const SubModePickerOption(
      label: 'Find a partner',
      symbol: PickerSprite(AssetPaths.picnicBasket),
    ),
    'count-and-compare': const SubModePickerOption(
      label: 'Count and compare',
      symbol: PickerSprite(AssetPaths.carePantryBerries),
    ),
    'numeral-compare': const SubModePickerOption(
      label: 'Bigger number',
      symbol: PickerScene(<PickerSceneLayer>[
        PickerSceneLayer.sprite(
          AssetPaths.countingParadeBabyUnicorn,
          x: 0.3,
          y: 0.55,
          size: 0.55,
        ),
        PickerSceneLayer.sprite(
          AssetPaths.countingParadeBabyDragon,
          x: 0.72,
          y: 0.55,
          size: 0.55,
        ),
      ]),
    ),
    'three-way-compare': const SubModePickerOption(
      label: 'Three at the picnic',
      symbol: PickerSprite(AssetPaths.countingParadeBabyCentaur),
    ),
  },
  'fluency-within-5': <String, SubModePickerOption>{
    'casual': const SubModePickerOption(
      label: 'Quick puzzles',
      symbol: PickerScene(<PickerSceneLayer>[
        PickerSceneLayer.buddy(x: 0.42, y: 0.55, size: 0.72),
        PickerSceneLayer.sprite(
          AssetPaths.carePantryAcorn,
          x: 0.78,
          y: 0.7,
          size: 0.34,
        ),
      ]),
    ),
    'speed-run': const SubModePickerOption(
      label: 'Just the numbers',
      symbol: PickerSprite(AssetPaths.countingParadeSunbeamStag),
    ),
  },
  'counting-parade': <String, SubModePickerOption>{
    'count-the-parade': const SubModePickerOption(
      label: 'Count the parade',
      symbol: PickerSprite(AssetPaths.countingParadeFawn),
    ),
    'count-forward-from-n': const SubModePickerOption(
      label: 'Counting on',
      symbol: PickerSprite(AssetPaths.countingParadeBabyGryphon),
    ),
    'count-out-n': const SubModePickerOption(
      label: 'Count out that many',
      symbol: PickerSprite(AssetPaths.countingParadeGoldenEgg),
    ),
    // The phoenix and the unicorn below used to be shared with Where's
    // Buddy's "Put Buddy there" and "In the middle" — the same picture
    // opening two different games from two different nodes. They are the
    // parade's alone now that those three cards draw their own scene.
    'count-on-by-ones': const SubModePickerOption(
      label: 'Count by ones',
      symbol: PickerSprite(AssetPaths.countingParadeBabyPhoenix),
    ),
    'long-parade': const SubModePickerOption(
      label: 'Big parade',
      symbol: PickerSprite(AssetPaths.countingParadeBabyUnicorn),
    ),
    'tens-parade': const SubModePickerOption(
      label: 'Count to 100',
      symbol: PickerSprite(AssetPaths.countingParadeBabyDragon),
    ),
  },
  'wheres-buddy': <String, SubModePickerOption>{
    // K.G.1. Each card is the round in miniature, drawn with the landmark
    // sprites the playfield uses and with the kid's own Buddy — so what she
    // is choosing between is the *arrangement*, which is exactly what the
    // three sub-modes differ by. Nothing here is a stand-in.
    //
    // The numbers were set by rendering them, not by reasoning about them.
    // The first attempt had Buddy at 0.50 of a 96-pixel box, which is a
    // 34-pixel Buddy once BoxFit and his own transparent margin are taken
    // out: a green smudge next to a tree. Two elements only ever both read
    // here when one is clearly the subject and the other clearly the scenery.
    'find-mode': const SubModePickerOption(
      label: 'Hide and seek',
      symbol: PickerScene(<PickerSceneLayer>[
        // Buddy first so the trunk covers him — a hiding Buddy has to be
        // behind something. About a third of him is occluded, which is what
        // makes it "peeking" rather than "standing next to".
        PickerSceneLayer.buddy(x: 0.30, y: 0.66, size: 0.56),
        PickerSceneLayer.sprite(
          'assets/activities/wheres-buddy/landmark-hollow-tree.png',
          x: 0.60,
          y: 0.50,
          size: 0.84,
        ),
      ]),
    ),
    'place-mode': const SubModePickerOption(
      label: 'Put Buddy there',
      symbol: PickerScene(<PickerSceneLayer>[
        // The rocks are a low wide mound, which makes them a plinth: Buddy
        // standing on top of them is a placement, and a placement is the
        // sub-mode. The toadstools were tried here first and read as Buddy
        // standing behind a mushroom.
        PickerSceneLayer.sprite(
          'assets/activities/wheres-buddy/landmark-rock-cluster.png',
          x: 0.50,
          y: 0.80,
          size: 0.70,
        ),
        PickerSceneLayer.buddy(x: 0.50, y: 0.33, size: 0.62),
      ]),
    ),
    'relational-mode': const SubModePickerOption(
      label: 'In the middle',
      symbol: PickerScene(<PickerSceneLayer>[
        // Two of the same landmark, one mirrored, so "between" has two
        // matching things to be between. Standing stones were tried and read
        // as a pair of gravestones, which is its own kind of wrong.
        PickerSceneLayer.sprite(
          'assets/sanctuary/decor/toadstool-cluster.png',
          x: 0.12,
          y: 0.68,
          size: 0.44,
        ),
        PickerSceneLayer.sprite(
          'assets/sanctuary/decor/toadstool-cluster.png',
          x: 0.88,
          y: 0.68,
          size: 0.44,
          flip: true,
        ),
        PickerSceneLayer.buddy(x: 0.50, y: 0.48, size: 0.62),
      ]),
    ),
  },
  'build-a-habitat': <String, SubModePickerOption>{
    // K.G.5 + K.G.6 — build the frame with clay and sticks, then raise the
    // habitat with 3D pieces. The card draws the finished build straight from
    // the blueprint the sub-mode runs, so the three cards differ by the thing
    // the three sub-modes actually differ by: a triangle, a square, a
    // pentagon. `creature-home` plays all three blueprints in a row; its card
    // shows the square, which is the one it adds.
    'simple-shelter': const SubModePickerOption(
      label: 'Simple shelter',
      symbol: PickerHabitat(0),
    ),
    'creature-home': const SubModePickerOption(
      label: 'Creature home',
      symbol: PickerHabitat(1),
    ),
    'grand-habitat': const SubModePickerOption(
      label: 'Grand habitat',
      symbol: PickerHabitat(2),
    ),
  },
};

SubModePickerOption? pickerOptionFor({
  required String activityId,
  required String subModeId,
}) {
  return kSubModePickerData[activityId]?[subModeId];
}

/// What the keeper asks when the picker opens.
///
/// Also drawn at the top of the sheet, so it is spoken without a caption —
/// see the authoring rules on ReadAloudGate.
const String kSubModePickerQuestion = 'What do you want to play?';

/// Every string the picker says out loud, for the recording script.
///
/// Sorted so the batch reads in a stable order at the microphone; a set
/// first because nothing stops two activities from agreeing on a label, and
/// clips are keyed by their words, so a duplicate is one clip, not two.
List<String> spokenSubModeLabels() => <String>[
      kSubModePickerQuestion,
      ...<String>{
        for (final activity in kSubModePickerData.values)
          for (final option in activity.values) option.label,
      }.toList()
        ..sort(),
    ];

/// Every sprite path the picker draws directly, for the test that checks the
/// files are really there.
///
/// Habitat symbols are deliberately absent: their sprites come from
/// `kHabitatBlueprints`, which lives behind a Flutter import. The test walks
/// those itself.
List<String> pickerSpriteAssets() => <String>[
      for (final activity in kSubModePickerData.values)
        for (final option in activity.values)
          ...switch (option.symbol) {
            PickerSprite(:final asset) => <String>[asset],
            PickerScene(:final layers) => <String>[
                for (final layer in layers)
                  if (layer.asset != null) layer.asset!,
              ],
            PickerHabitat() => <String>[],
          },
    ];
