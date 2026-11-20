// What the Tens Parade keeper says on the hundredth tap.
//
// Flutter-free and split out of the runner for the same reason as
// `shape_words.dart` and `wheres_buddy_words.dart`: the runner is a widget, so
// `narration_script.dart` — which has to compile under plain `dart run` —
// could not reach these lines. The literal sweep in `tool/narration_sources.dart`
// could not reach them either, because it drops interpolated strings and this
// one interpolates the coin count. Between the two, the single loudest moment
// in the game — the payoff for a hundred taps — was still being read by the
// browser synth voice.
//
// The coin count is spelled from the same const the wallet is paid from, so
// the number she hears cannot drift from the number she is given.

import 'count_on_by_ones_rounds.dart';
import 'number_words.dart';

/// Coins awarded for one successful run to a hundred.
///
/// Final-check payouts sit comfortably above a regular round (5 coins) without
/// dwarfing the long-running rewards from the rest of the curriculum.
const int kTensParadeRewardCoins = 50;

/// How many taps the challenge runs to.
const int kTensParadeTarget = 100;

/// Spoken by the keeper when the hundredth creature is tapped.
///
/// Two wordings, because the Cloud Unicorn is granted exactly once and she can
/// come back to the challenge on a later visit. A run that finds the card
/// already hers must not promise it again. (An "Again!" run in the same visit
/// pays nothing, and says [kTensParadeRepeatLine] instead.)
///
/// The card wording deliberately says nothing about coins even though coins are
/// still paid. It is one idea per line for a five-year-old, the card is the
/// event, and the coins announce themselves by flying into the counter.
String tensParadeRewardLine({required bool earnedCard}) {
  // The shared opening is repeated rather than hoisted to a const. Hoisting it
  // left 'One hundred! You counted every single one.' sitting in this file as a
  // literal of its own, and the sweep in `tool/narration_sources.dart` duly
  // rendered a clip for a fragment nothing ever says.
  if (earnedCard) {
    return 'One hundred! You counted every single one. '
        'A Cloud Unicorn came down out of the sky to find you. '
        'She is yours to keep.';
  }
  final coins = spellCount(kTensParadeRewardCoins).toLowerCase();
  return 'One hundred! You counted every single one. '
      "Here are $coins bonus coins — you've earned them.";
}

/// The last beat of an "Again!" run in the same visit. The bonus and the card
/// are paid once per visit, so a repeat run must not promise either; this is
/// Count On By Ones' own last line, which says exactly what she just did.
const String kTensParadeRepeatLine = kCountOnByOnesFinal;

/// Spoken once as the demo creature drifts across, before the challenge.
const String kTensParadeDemoLine =
    'Count the animals with me out loud as they do their parade!';

/// What the demo's Start arrow says when she leaves it waiting.
const String kTensParadeDemoStartHint = 'Tap the arrow to start the challenge!';

/// The challenge's opening call, and what the "?" button replays.
String countingChallengePrompt(int target) =>
    'Tap the creatures as they go by — count all the way to $target!';
