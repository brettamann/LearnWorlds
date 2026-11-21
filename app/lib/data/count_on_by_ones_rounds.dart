// Count On By Ones — the rounds, and the words built from them.
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

import 'number_words.dart';
import 'parade_species.dart';

class CountOnByOnesRound {
  const CountOnByOnesRound({
    required this.startN,
    required this.species,
    required this.keeperLine,
  });

  /// Where we pick up counting from — 10, 20, ..., 90.
  final int startN;
  final ParadeSpecies species;
  final String keeperLine;

  /// Always 10 — we cross one decade per round.
  int get arrivalsCount => 10;

  int get finalCount => startN + arrivalsCount;
}

// Four sampled decades, each a fresh species so no two rounds look alike.
const List<CountOnByOnesRound> kCountOnByOnesRounds = <CountOnByOnesRound>[
  CountOnByOnesRound(
    startN: 10,
    species: kParadeFawn,
    keeperLine: 'Twenty fawns! The dragons are already up at forty.',
  ),
  CountOnByOnesRound(
    startN: 40,
    species: kParadeDragon,
    keeperLine: 'Fifty dragons! Now — the phoenixes are at seventy.',
  ),
  CountOnByOnesRound(
    startN: 70,
    species: kParadePhoenix,
    keeperLine: 'Eighty phoenixes! The golden eggs are at ninety.',
  ),
  CountOnByOnesRound(
    startN: 90,
    species: kParadeGoldenEgg,
    keeperLine: 'One hundred! You counted all the way to one hundred by ones.',
  ),
];

/// Beat one of the round: where the parade has got to.
///
/// Spoken in tens rather than as digits, because K.CC.1's point is that the
/// decade names are a sequence you can hear.
///
/// This used to be the first clause of the prompt below, and the round opened
/// on one sentence spoken once over a board that was already fully drawn. The
/// only thing telling a child which creatures were hers to tap was the words
/// "count by ones" printed between the rows, which is no use at all to someone
/// who cannot read. Two beats now, with the newcomers walking on between them.
String countOnByOnesAlreadyCountedLine(CountOnByOnesRound round) =>
    "We're at ${kSpelledTens[round.startN ~/ 10].toLowerCase()} already.";

/// Beat two: the go signal, spoken as the new creatures arrive.
///
/// Still names the decade at the far end. Unlike Count Forward From N, where
/// naming the next number would do the counting-on for her, the destination is
/// the frame rather than the answer here — the skill is walking the ten
/// steps between, and hearing where they land is the whole point of K.CC.1.
String countOnByOnesPrompt(CountOnByOnesRound round) {
  final end = kSpelledTens[round.finalCount ~/ 10].toLowerCase();
  final more = spellCount(round.arrivalsCount).toLowerCase();
  return 'Here come $more more ${round.species.plural}! '
      'Touch each one and count by ones up to $end.';
}

/// The visit's last beat. (The opening is the animated demo, not a keeper
/// line.)
const String kCountOnByOnesFinal =
    'One hundred! Counting by ones got you all the way there. '
    'Amazing work.';

/// What the Done arrow says when she leaves it waiting.
const String kCountOnByOnesDoneHint =
    'Beautifully counted! Tap the arrow to keep going.';

/// The opening demo counts to ten, folds the ten into one group, then lays
/// the decades out to a hundred. Each count and decade word is the shared
/// 'Seven.' / 'Seventy.' clip; these are the two sentences around them.
const String kCountOnByOnesDemoCollapse =
    'When we count to ten, we get a special new number. '
    'And the ones start over.';
const String kCountOnByOnesDemoKickoff = "Let's count all the different tens!";

/// What the demo's Start arrow says when she leaves it waiting.
const String kCountOnByOnesDemoStartHint =
    'Tap the arrow when you are ready to count!';
