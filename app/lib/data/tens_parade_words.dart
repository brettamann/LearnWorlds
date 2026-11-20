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

import 'number_words.dart';

/// Coins awarded for one successful run to a hundred.
///
/// Final-check payouts sit comfortably above a regular round (5 coins) without
/// dwarfing the long-running rewards from the rest of the curriculum.
const int kTensParadeRewardCoins = 50;

/// Spoken by the keeper when the hundredth creature is tapped.
///
/// Two wordings, because the Cloud Unicorn is granted exactly once and she can
/// replay — the reward overlay offers "Again!" as its primary button. A repeat
/// run must not promise a card she already owns.
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
