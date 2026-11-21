// Care Pantry - its rounds and every word it says. K.MD.3.
//
// See ten_frame_words.dart for why rounds and words live together here.

import '../activities/sub_mode_ids.dart';
import 'asset_paths.dart';
import 'number_words.dart';
import 'round_pick.dart';
import 'warm_lines.dart';

/// A kind of thing in the pantry.
class PantryKind {
  const PantryKind({
    required this.id,
    required this.singular,
    required this.plural,
    required this.asset,
    this.colour,
  });

  final String id;
  final String singular;
  final String plural;
  final String asset;

  /// For the colour-sorting challenge: which colour crate it belongs in.
  final String? colour;
}

// Named for what the picture shows, not for what was asked for. The berries
// came back from the art pipeline as a bunch of three cherries on a stem, and
// a five-year-old calls that "cherries" - a name that argues with its picture
// is the bug `shared_names_test.dart` exists for.
const PantryKind kPantryAcorn = PantryKind(
  id: 'acorn',
  singular: 'acorn',
  plural: 'acorns',
  asset: AssetPaths.carePantryAcorn,
);
const PantryKind kPantryApple = PantryKind(
  id: 'apple',
  singular: 'apple',
  plural: 'apples',
  asset: AssetPaths.carePantryApple,
  colour: 'red',
);
const PantryKind kPantryCarrot = PantryKind(
  id: 'carrot',
  singular: 'carrot',
  plural: 'carrots',
  asset: AssetPaths.carePantryCarrot,
  colour: 'orange',
);
const PantryKind kPantryCherries = PantryKind(
  id: 'cherries',
  singular: 'bunch of cherries',
  plural: 'cherries',
  asset: AssetPaths.carePantryBerries,
  colour: 'red',
);
const PantryKind kPantryPumpkin = PantryKind(
  id: 'pumpkin',
  singular: 'pumpkin',
  plural: 'pumpkins',
  asset: AssetPaths.caretakersPumpkin,
  colour: 'orange',
);
const PantryKind kPantryLeaf = PantryKind(
  id: 'leaf',
  singular: 'leaf',
  plural: 'leaves',
  asset: AssetPaths.caretakersLeaf,
  colour: 'green',
);
const PantryKind kPantryWatermelon = PantryKind(
  id: 'watermelon',
  singular: 'watermelon',
  plural: 'watermelons',
  asset: AssetPaths.caretakersWatermelon,
  colour: 'green',
);

/// A crate: either one kind of thing, or (the challenge) one colour.
class PantryCrate {
  const PantryCrate({required this.name, required this.count, this.kind});

  /// What she hears and what the crate is called: "apples", "red things".
  final String name;

  /// How many of it are on the floor.
  final int count;

  /// Set for a kind crate - its picture is pinned to the front. Null for a
  /// colour crate, whose front is painted in the colour instead.
  final PantryKind? kind;

  bool get byColour => kind == null;
}

class PantryRound {
  const PantryRound({
    required this.crates,
    this.askMost = true,
    this.askFewest = false,
    this.items = const <PantryKind>[],
  });

  final List<PantryCrate> crates;
  final bool askMost;
  final bool askFewest;

  /// For colour rounds: the things on the floor, in order.
  final List<PantryKind> items;
}

/// Every round each sub-mode can play; [pantryRoundsFor] picks a visit's.
///
/// Counts are chosen so the most and the fewest are never tied: "which has
/// the most" with two crates of four has no answer a child can find.
const Map<String, List<PantryRound>> kPantryRounds =
    <String, List<PantryRound>>{
      CarePantryModes.categorizeOnly: <PantryRound>[
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'apples', count: 3, kind: kPantryApple),
            PantryCrate(name: 'acorns', count: 2, kind: kPantryAcorn),
          ],
          askMost: false,
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'carrots', count: 2, kind: kPantryCarrot),
            PantryCrate(name: 'apples', count: 4, kind: kPantryApple),
          ],
          askMost: false,
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'acorns', count: 4, kind: kPantryAcorn),
            PantryCrate(name: 'carrots', count: 3, kind: kPantryCarrot),
          ],
          askMost: false,
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'cherries', count: 2, kind: kPantryCherries),
            PantryCrate(name: 'carrots', count: 3, kind: kPantryCarrot),
          ],
          askMost: false,
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'apples', count: 2, kind: kPantryApple),
            PantryCrate(name: 'cherries', count: 3, kind: kPantryCherries),
          ],
          askMost: false,
        ),
      ],
      CarePantryModes.simplePantry: <PantryRound>[
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'apples', count: 2, kind: kPantryApple),
            PantryCrate(name: 'acorns', count: 4, kind: kPantryAcorn),
          ],
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'carrots', count: 3, kind: kPantryCarrot),
            PantryCrate(name: 'apples', count: 1, kind: kPantryApple),
            PantryCrate(name: 'acorns', count: 2, kind: kPantryAcorn),
          ],
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'acorns', count: 2, kind: kPantryAcorn),
            PantryCrate(name: 'cherries', count: 3, kind: kPantryCherries),
            PantryCrate(name: 'carrots', count: 5, kind: kPantryCarrot),
          ],
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'apples', count: 4, kind: kPantryApple),
            PantryCrate(name: 'cherries', count: 2, kind: kPantryCherries),
            PantryCrate(name: 'acorns', count: 3, kind: kPantryAcorn),
          ],
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'cherries', count: 3, kind: kPantryCherries),
            PantryCrate(name: 'apples', count: 5, kind: kPantryApple),
          ],
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'carrots', count: 4, kind: kPantryCarrot),
            PantryCrate(name: 'acorns', count: 1, kind: kPantryAcorn),
            PantryCrate(name: 'cherries', count: 2, kind: kPantryCherries),
          ],
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'apples', count: 3, kind: kPantryApple),
            PantryCrate(name: 'carrots', count: 2, kind: kPantryCarrot),
            PantryCrate(name: 'acorns', count: 5, kind: kPantryAcorn),
          ],
        ),
      ],
      CarePantryModes.fullPantry: <PantryRound>[
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'apples', count: 3, kind: kPantryApple),
            PantryCrate(name: 'carrots', count: 5, kind: kPantryCarrot),
            PantryCrate(name: 'acorns', count: 1, kind: kPantryAcorn),
            PantryCrate(name: 'cherries', count: 2, kind: kPantryCherries),
          ],
          askFewest: true,
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'acorns', count: 6, kind: kPantryAcorn),
            PantryCrate(name: 'cherries', count: 4, kind: kPantryCherries),
            PantryCrate(name: 'apples', count: 2, kind: kPantryApple),
            PantryCrate(name: 'carrots', count: 3, kind: kPantryCarrot),
          ],
          askFewest: true,
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'carrots', count: 2, kind: kPantryCarrot),
            PantryCrate(name: 'apples', count: 4, kind: kPantryApple),
            PantryCrate(name: 'cherries', count: 1, kind: kPantryCherries),
            PantryCrate(name: 'acorns', count: 5, kind: kPantryAcorn),
          ],
          askFewest: true,
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'cherries', count: 5, kind: kPantryCherries),
            PantryCrate(name: 'acorns', count: 2, kind: kPantryAcorn),
            PantryCrate(name: 'carrots', count: 4, kind: kPantryCarrot),
            PantryCrate(name: 'apples', count: 1, kind: kPantryApple),
          ],
          askFewest: true,
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'apples', count: 6, kind: kPantryApple),
            PantryCrate(name: 'carrots', count: 1, kind: kPantryCarrot),
            PantryCrate(name: 'acorns', count: 3, kind: kPantryAcorn),
            PantryCrate(name: 'cherries', count: 4, kind: kPantryCherries),
          ],
          askFewest: true,
        ),
      ],
      // The challenge sorts by colour, which is a rule she has to hold in her
      // head against the pictures - two red things that are not the same thing
      // go in one crate.
      CarePantryModes.unfamiliarRules: <PantryRound>[
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'red things', count: 3),
            PantryCrate(name: 'orange things', count: 2),
          ],
          items: <PantryKind>[
            kPantryApple,
            kPantryCarrot,
            kPantryCherries,
            kPantryPumpkin,
            kPantryApple,
          ],
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'green things', count: 3),
            PantryCrate(name: 'red things', count: 2),
            PantryCrate(name: 'orange things', count: 1),
          ],
          items: <PantryKind>[
            kPantryLeaf,
            kPantryCherries,
            kPantryWatermelon,
            kPantryCarrot,
            kPantryApple,
            kPantryLeaf,
          ],
        ),
        PantryRound(
          crates: <PantryCrate>[
            PantryCrate(name: 'orange things', count: 4),
            PantryCrate(name: 'green things', count: 2),
          ],
          items: <PantryKind>[
            kPantryPumpkin,
            kPantryWatermelon,
            kPantryCarrot,
            kPantryCarrot,
            kPantryLeaf,
            kPantryPumpkin,
          ],
        ),
      ],
    };

/// The rounds for one visit, the fewest things on the floor first.
List<PantryRound> pantryRoundsFor(String subMode, {int seed = 0}) {
  final pool =
      kPantryRounds[subMode] ?? kPantryRounds[CarePantryModes.simplePantry]!;
  return pickRounds(
    pool,
    count: subMode == CarePantryModes.simplePantry ? 4 : 3,
    seed: seed,
    ease: (r) => r.crates.fold<int>(0, (n, c) => n + c.count),
  );
}

/// The colour word a colour crate is for: "red things" -> "red".
String pantryCrateColour(PantryCrate c) => c.name.split(' ').first;

bool pantryBelongs(PantryKind item, PantryCrate crate) => crate.byColour
    ? item.colour == pantryCrateColour(crate)
    : item.id == crate.kind!.id;

// ---- words ----------------------------------------------------------------

const String kPantryIntro =
    'Oh dear, the supply hut is in a muddle! Let us '
    'put everything away in the right crate.';
const String kPantryDemo = 'Watch. Tap one, and in it goes!';
const String kPantryDemoBack = 'Oops, back it comes. Now you try.';
const String kPantryAskMost = 'Which crate has the most?';
const String kPantryAskFewest = 'And which crate has the fewest?';
const String kPantryFinal =
    'The pantry is so tidy! The creatures will find '
    'their food so easily now. Here are some coins, with thanks.';

const List<String> kPantryKeeperLines = <String>[
  'Everything in its place.',
  'So tidy! Thank you.',
  'The creatures will be so pleased.',
  'What a helper you are.',
];

String pantryKeeperLine(int round) =>
    kPantryKeeperLines[round % kPantryKeeperLines.length];

String pantryPutAway(PantryCrate c) => c.byColour
    ? 'Put away everything ${pantryCrateColour(c)}! Tap each one.'
    : 'Put away the ${c.kind!.plural}! Tap every one.';

/// Said as the last of a kind goes in - the count is the point.
String pantryCounted(PantryCrate c) {
  final n = spellNumber(c.count);
  final cap = n[0].toUpperCase() + n.substring(1);
  if (c.byColour) return '$cap ${c.name}.';
  return c.count == 1 ? 'One ${c.kind!.singular}.' : '$cap ${c.kind!.plural}.';
}

String pantryMissKind(int n, PantryCrate c) => c.byColour
    ? '${warmMissLine(n)} Look for ${pantryCrateColour(c)} ones.'
    : '${warmMissLine(n)} Look for the ${c.kind!.plural}.';

const String kPantryLookFull = 'Look at how full each crate is.';

String pantryMissCrate(int n) => '${warmMissLine(n)} $kPantryLookFull';

String pantryRightMost(PantryCrate c) => 'Yes! The ${c.name} have the most.';
String pantryRightFewest(PantryCrate c) =>
    'Yes! The ${c.name} have the fewest.';

List<String> pantryScriptLines() {
  final lines = <String>{
    kPantryIntro,
    kPantryDemo,
    kPantryDemoBack,
    kPantryAskMost,
    kPantryAskFewest,
    kPantryFinal,
    kPantryLookFull,
    ...kPantryKeeperLines,
    for (var n = 0; n < 4; n++) pantryMissCrate(n),
  };
  for (final rounds in kPantryRounds.values) {
    for (final r in rounds) {
      for (final c in r.crates) {
        lines
          ..add(pantryPutAway(c))
          ..add(pantryCounted(c))
          ..add(pantryRightMost(c))
          ..add(pantryRightFewest(c));
        for (var n = 0; n < 4; n++) {
          lines.add(pantryMissKind(n, c));
        }
      }
    }
  }
  return lines.toList();
}
