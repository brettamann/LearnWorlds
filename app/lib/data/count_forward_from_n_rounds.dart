// Count Forward From N — the rounds, and the words built from them.
//
// The round data used to be a private const list inside the runner and the
// counting prompt was interpolated there too, which put both out of reach of
// everything that renders a voice: `narration_script.dart` has to compile
// under plain `dart run` and cannot import a widget, and the literal sweep in
// `tool/narration_sources.dart` drops interpolated strings on purpose - a
// template is not a line. So the sentence carrying the entire instruction for
// a pre-reader was still being read by the browser synth while the rest of the
// game had a narrator.
//
// Rounds and the lines built from them live together so the script enumerates
// exactly what the game can say. Retune a round and the script changes with
// it, and the clip for the old wording turns up as an orphan rather than being
// silently looked up and missed.

import 'asset_paths.dart';
import 'number_words.dart';

class CountForwardRound {
  const CountForwardRound({
    required this.startN,
    required this.arrivalsCount,
    required this.spriteAsset,
    required this.singular,
    required this.plural,
    required this.keeperLine,
  });

  final int startN;
  final int arrivalsCount;
  final String spriteAsset;
  final String singular;
  final String plural;
  final String keeperLine;

  int get finalCount => startN + arrivalsCount;
}

const List<CountForwardRound> kCountForwardRounds = <CountForwardRound>[
  CountForwardRound(
    startN: 3,
    arrivalsCount: 3,
    spriteAsset: AssetPaths.countingParadeFawn,
    singular: 'fawn',
    plural: 'fawns',
    keeperLine: 'Six fawns! Now some gryphons are catching up.',
  ),
  CountForwardRound(
    startN: 5,
    arrivalsCount: 3,
    spriteAsset: AssetPaths.countingParadeBabyGryphon,
    singular: 'gryphon',
    plural: 'gryphons',
    keeperLine: 'Eight gryphons! Last one — the dragons.',
  ),
  CountForwardRound(
    startN: 7,
    arrivalsCount: 3,
    spriteAsset: AssetPaths.countingParadeBabyDragon,
    singular: 'dragon',
    plural: 'dragons',
    keeperLine: 'Ten dragons! Beautifully counted on.',
  ),
];

/// Beat one of the round: name what is already counted.
///
/// This used to be the first clause of the prompt below, and the whole round
/// opened on one dense sentence spoken once, over a screen that was already
/// showing everything. A five-year-old had no way to tell when the game had
/// stopped explaining and started waiting for her — the only thing marking the
/// creatures she was meant to tap was the words "new arrivals" printed above
/// them, which is no help at all to a kid who cannot read.
///
/// So the opening is two beats now, and the arrivals walk on between them. The
/// count is spoken because K.CC.2 is precisely the skill of trusting a number
/// you were told rather than starting over at one.
String countForwardAlreadyCountedLine(CountForwardRound round) =>
    'We already counted '
    '${kSpelledCounts[round.startN].toLowerCase()} ${round.plural}.';

/// Beat two: the go signal, spoken as the new creatures arrive.
///
/// Deliberately does not say "start at four". Naming the next number does the
/// counting-on for her, and that is the entire thing being learned — the
/// ladder tone and the spoken number on her first tap confirm it instead.
String countForwardPrompt(CountForwardRound round) =>
    'Here come ${kSpelledCounts[round.arrivalsCount].toLowerCase()} more! '
    'Now touch each new ${round.singular} and keep counting.';
