// Count Out N — the rounds, and the words built from them.
//
// The round data used to be a private const list inside the runner and the
// two spoken lines were interpolated there too, which put both out of reach
// of everything that renders a voice: `narration_script.dart` has to compile
// under plain `dart run` and cannot import a widget, and the literal sweep in
// `tool/narration_sources.dart` drops interpolated strings on purpose (a
// template is not a line). The result was that "Bring me four fawns." - the
// sentence that carries the entire instruction for a pre-reader - was still
// being read by the browser synth while the rest of the game had a narrator.
//
// Rounds and lines live together here so the script enumerates exactly what
// the game can say. Retune `targetN` and the script changes with it; the
// clip for the old wording shows up as an orphan instead of being silently
// looked up and missed.

import 'number_words.dart';
import 'parade_species.dart';

class CountOutNRound {
  const CountOutNRound({
    required this.targetN,
    required this.poolSize,
    required this.species,
    required this.keeperLine,
  });

  final int targetN;
  final int poolSize;
  final ParadeSpecies species;
  final String keeperLine;
}

const List<CountOutNRound> kCountOutNRounds = <CountOutNRound>[
  CountOutNRound(
    targetN: 4,
    poolSize: 8,
    species: kParadeFawn,
    keeperLine: 'Four fawns! Now I need some gryphons.',
  ),
  CountOutNRound(
    targetN: 6,
    poolSize: 9,
    species: kParadeGryphon,
    keeperLine: 'Six gryphons! One more round — the dragons.',
  ),
  CountOutNRound(
    targetN: 8,
    poolSize: 10,
    species: kParadeDragon,
    keeperLine: 'Eight dragons! You counted out every group.',
  ),
];

/// The keeper asking for a number of creatures. K.CC.5: the number word has
/// to name the quantity, so it is spoken, not shown.
String countOutNBasketPrompt(CountOutNRound round) =>
    'Bring me ${spellCount(round.targetN).toLowerCase()} '
    '${round.species.plural}.';

/// The "you already have enough" line, rotated so a kid who keeps dragging
/// does not hear the identical sentence four times running -
/// specs/shared/k-activity-patterns.md asks for 2-4 alternates. All three
/// name the target number, because saying the total is the whole point of
/// K.CC.5.
String countOutNOverCapLine(CountOutNRound round, int rotation) {
  final n = spellCount(round.targetN).toLowerCase();
  switch (rotation.abs() % kCountOutNOverCapRotations) {
    case 0:
      return "I have enough — that's $n!";
    case 1:
      return 'The basket has $n already. That is just right.';
    default:
      return 'Count them with me — $n is what I asked for.';
  }
}

/// How many phrasings [countOutNOverCapLine] rotates through. Named so the
/// script enumerates every one rather than a number someone has to remember
/// to bump.
const int kCountOutNOverCapRotations = 3;

/// The keeper's opening, before the first round.
const String kCountOutNIntro =
    "Sometimes I just need a few creatures, not all of them! I'll ask for "
    'a number, and you bring me exactly that many. Ready?';

/// The visit's last beat.
const String kCountOutNFinal =
    'Beautifully counted out! Just the number I asked for, every time.';

/// The one-time drag demo after the intro, on the first round's creature:
/// this line, two creatures dragged in and counted (the shared 'One.' and
/// 'Two.' clips), then the hand-off.
String countOutNDemoLine(CountOutNRound round) =>
    "Watch — I'll show you. Drag each ${round.species.singular} into the "
    'basket.';
const String kCountOutNDemoHandoff = 'Now you try!';
