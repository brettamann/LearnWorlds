// FeedbackEngine — the single place the non-visual half of answer feedback
// fires from: audio, haptics, and the Buddy's reaction.
//
// The point is that a runner's correct/wrong branches stay one line each. The
// app previously had ten runners each hand-rolling their own response to a tap,
// which is how wrong answers ended up producing *nothing at all* in most of
// them — there was no single place to notice the gap.
//
// This class deliberately draws no pixels. Visual feedback lives in
// AnswerFeedback, because a runner often wants the visual attached to one
// specific sprite while the sound is global.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sfx_catalog.dart';
import '../../models/buddy_mood.dart';
import '../../platform/haptics.dart';
import '../../platform/sfx_engine.dart';
import '../../providers/buddy_reaction_provider.dart';

class FeedbackEngine {
  FeedbackEngine(this._ref);

  final Ref _ref;

  SfxEngine get _sfx => _ref.read(sfxEngineProvider);
  BuddyReactionController get _buddy =>
      _ref.read(buddyReactionProvider.notifier);

  /// A correct tap that is part of a count. [step] is 1-based.
  ///
  /// This is the one piece of feedback in the game that is genuinely
  /// pedagogical rather than decorative: the pitch climbs with the count, so
  /// the child hears the number line ascend as she taps. See kCountLadder.
  void countStep(int step) {
    _sfx.playCountStep(step);
    Haptics.tick();
  }

  /// A correct answer outside a counting ladder — a shape found, a Buddy
  /// placed in the right spot.
  void correct() {
    _sfx.play(Sfx.pop);
    Haptics.tick();
  }

  /// A wrong answer.
  ///
  /// Soft thud, gentle haptic, Buddy tilts its head. NEVER a buzzer and never
  /// a red flash — specs/shared/art-direction.md and the "soft no puff" risk
  /// in specs/shared/playtest-watchlist.md both require this read as
  /// "not that one", not as punishment.
  ///
  /// Before this existed, a wrong tap in most runners produced no output of
  /// any kind, which to a pre-reading child was indistinguishable from the app
  /// having frozen.
  void wrong() {
    _sfx.play(Sfx.wrongSoft);
    // The other half of the beat this was always specified as: "a head-tilt
    // and a 'hmm', never a buzzer or a sad face". The tilt shipped and the
    // hmm did not - `Sfx.buddyCurious` was in the catalog, rendered, bundled
    // into every build, and played by nothing.
    _sfx.play(Sfx.buddyCurious);
    Haptics.nudge();
    _buddy.react(BuddyMood.curious, hold: const Duration(milliseconds: 1100));
  }

  /// A round was passed. The coin sound is separate from the chime so the
  /// payout reads as its own beat rather than blurring into the success.
  void roundPass({bool payout = true}) {
    _sfx.play(Sfx.correct);
    if (payout) _sfx.play(Sfx.coin);
    Haptics.pop();
    _buddy.react(BuddyMood.happy, hold: const Duration(milliseconds: 2000));
  }

  /// The whole sub-mode is done. The big one.
  void celebrate() {
    _sfx.play(Sfx.fanfare);
    Haptics.pop();
    _buddy.react(BuddyMood.happy, hold: const Duration(milliseconds: 3000));
  }

  /// A hint fired. Buddy leans in — the help visibly comes from the companion.
  void hint() {
    _sfx.play(Sfx.hint);
    _buddy.react(
      BuddyMood.encouraging,
      hold: const Duration(milliseconds: 2600),
    );
  }

  /// A shop purchase went through. Coin first, then the sparkle, so the money
  /// is audibly *spent* before the new thing appears — the causal order is the
  /// whole lesson of a shop.
  void purchase() {
    _sfx.play(Sfx.coin);
    _sfx.play(Sfx.sparkle);
    Haptics.pop();
    _buddy.react(BuddyMood.happy, hold: const Duration(milliseconds: 2400));
  }

  void sparkle() => _sfx.play(Sfx.sparkle);

  /// A control was pressed. Fired from inside `ReadAloudGate` so every piece
  /// of chrome in the game gets it from one place — before that it was called
  /// from the character creator and nowhere else, so the arrow that ends
  /// every round in every activity made no sound when she pressed it.
  void uiTap() => _sfx.play(Sfx.uiTap);

  /// A sheet or overlay is arriving. Had no call site at all, so every sheet
  /// in the game slid in silently.
  void whoosh() => _sfx.play(Sfx.whoosh);

  /// A dragged thing landed where it was meant to.
  ///
  /// Distinct from [correct] on purpose: three of the game's mechanics are
  /// drags, and the sound of something being *put down* is the half of that
  /// gesture the player is waiting for. `Sfx.drop` had no call site.
  void drop() {
    _sfx.play(Sfx.drop);
    Haptics.tick();
  }

  /// The keeper's speech bubble is sliding in.
  void bubble() => _sfx.play(Sfx.bubbleIn);

  /// The mystery egg moved a stage.
  ///
  /// The one sound in the catalog written for a specific beat, and the beat
  /// had no sound: `Sfx.eggCrack` was never played by anything.
  void eggAdvance() {
    _sfx.play(Sfx.eggCrack);
    Haptics.pop();
  }

  /// Somebody poked the Buddy.
  ///
  /// There is no right answer here and nothing is scored — it is the only
  /// interaction in the game like that, which specs/shared's own rubric had
  /// scored as missing entirely. He chirps and hops, and that is all.
  void buddyPoke() {
    _sfx.play(Sfx.buddyHappy);
    Haptics.tick();
    _buddy.react(BuddyMood.happy, hold: const Duration(milliseconds: 1400));
  }

  /// Start of a round: drop back to the bottom of the counting scale and clear
  /// any leftover Buddy reaction from the previous round.
  void resetRound() {
    _sfx.resetCountLadder();
    _buddy.settle();
  }
}

final feedbackEngineProvider = Provider<FeedbackEngine>(FeedbackEngine.new);
