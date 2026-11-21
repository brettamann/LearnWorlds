// Long Parade (count by tens) — the rounds, and the words built from them.
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

import 'parade_species.dart';

class LongParadeRound {
  const LongParadeRound({
    required this.clusterCount,
    required this.species,
    required this.keeperLine,
  });

  final int clusterCount;
  final ParadeSpecies species;
  final String keeperLine;

  int get totalCreatures => clusterCount * 10;
}

// K.CC.1 standard: "Count to 100 by ones and by tens." Reaching one hundred
// is the point, so the last round stays at ten clusters — but the eight-round
// staircase that used to climb 30/40/50/60/70/80/90/100 was fifty-two taps of
// the same interaction, and each round differed from the last only by being
// slightly longer. Four well-spaced steps get to the same place in twenty-five
// taps, and skipping decades makes each round feel like new ground rather than
// the previous one plus one.
const List<LongParadeRound> kLongParadeRounds = <LongParadeRound>[
  LongParadeRound(
    clusterCount: 3,
    species: kParadeFawn,
    keeperLine: 'Thirty fawns! Next: more groups of ten — dragons.',
  ),
  LongParadeRound(
    clusterCount: 5,
    species: kParadeDragon,
    keeperLine: 'Fifty dragons! Phoenix babies are next.',
  ),
  LongParadeRound(
    clusterCount: 7,
    species: kParadePhoenix,
    keeperLine: 'Seventy phoenixes! Last group — the golden eggs.',
  ),
  LongParadeRound(
    clusterCount: 10,
    species: kParadeGoldenEgg,
    keeperLine:
        "One hundred! You counted to one hundred by tens — that's amazing.",
  ),
];

/// The instruction. Names the creature but not a number: every round of this
/// activity counts by tens, and which ten you are on is what the taps say.
String longParadeCountingPrompt(LongParadeRound round) =>
    'Tap each group of ${round.species.plural} — count by tens out loud '
    'with me!';

/// The keeper's opening, before the first round.
const String kLongParadeIntro =
    "Today's parade is HUGE — but we won't count one by one. Each group "
    'is ten. Tap each group and count by tens together!';

/// The visit's last beat.
const String kLongParadeFinal =
    'One hundred! Counting by tens carries you all the way there.';

/// What the Done arrow says when she leaves it waiting.
const String kLongParadeDoneHint =
    'Great counting by tens! Tap the arrow to keep going.';
