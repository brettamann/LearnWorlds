// The pieces the Counting Parade's round bodies have in common.
//
// Five parade runners used to be hand copies of one another, lifecycle and
// all. The lifecycle went to SanctuaryRoundShell; what is left here is the
// part of the copying that was about counting: the counted step (a note up
// the ladder and the number said out loud), the creature that walks on to be
// counted, the 2x5 group-of-ten card, and the Done arrow that ends a round
// counted by tapping.

import 'package:flutter/material.dart';

import '../../data/button_labels.dart';
import '../../data/number_words.dart';
import '../../engines/feedback/feedback_engine.dart';
import 'animated_fawn.dart';
import 'continue_arrow_shelf.dart';
import 'glitter_burst.dart';
import 'next_arrow_button.dart';

/// How a body speaks: [RoundContext.say]'s shape.
typedef SayLine = void Function(String line, {bool replay, bool queue});

/// One counted thing: a note up the scale and its number said aloud.
///
/// [step] is the note and [value] the word, and they differ on purpose
/// between activities. Most climb with the taps this round, so every round
/// restarts at the bottom of the scale and crossing a decade sounds the same
/// at ninety as at ten; Count Forward From N climbs from where the parade
/// already is, because counting on should sound like carrying on; the
/// hundred-tap challenge restarts the scale every ten.
///
/// Queued when the hint ladder made the step: what is in flight then is the
/// demonstration's own explanation, the one line in the round that says why,
/// and speaking would cut it off. See HintLadder.
void countAloud(
  SayLine say,
  FeedbackEngine feedback, {
  required int step,
  required int value,
  bool fromHint = false,
}) {
  feedback.countStep(step);
  say('${spellCount(value)}.', replay: false, queue: fromHint);
}

/// The walk from off-stage right, and back off it once counted.
const Duration kArrivalWalk = Duration(milliseconds: 750);

/// A newcomer in a count-on round: walks on from the right when [landed]
/// turns true, glitters when counted, and wanders back off once [gone].
///
/// The key belongs on this widget; the first GestureDetector under it is the
/// creature's own, and its `onTap` is null whenever it cannot be counted.
class ArrivingCreature extends StatelessWidget {
  const ArrivingCreature({
    super.key,
    required this.spriteAsset,
    required this.size,
    required this.heightFactor,
    required this.burstRadius,
    required this.landed,
    required this.tapped,
    required this.gone,
    required this.pointed,
    required this.onTap,
  });

  final String spriteAsset;
  final double size;
  final double heightFactor;
  final double burstRadius;

  /// False before the walk-on. Off-stage right before they arrive and off-stage
  /// right once counted, so one pair of offsets covers both; the zero duration
  /// while waiting is what stops the first build animating them in from
  /// nowhere.
  final bool landed;
  final bool tapped;
  final bool gone;

  /// The hint ladder's glow, through AnimatedFawn's own `pointed` state.
  final bool pointed;

  /// Null while it cannot be counted (locked, or already gone).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final waiting = !landed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: gone ? null : onTap,
      child: AnimatedSlide(
        duration: waiting ? Duration.zero : kArrivalWalk,
        curve: gone ? Curves.easeInQuart : Curves.easeOutCubic,
        offset: (gone || waiting) ? const Offset(2.2, 0) : Offset.zero,
        child: AnimatedOpacity(
          duration: waiting ? Duration.zero : const Duration(milliseconds: 600),
          opacity: (gone || waiting) ? 0 : 1,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedFawn(
                active: tapped,
                pointed: pointed,
                width: size,
                height: size * heightFactor,
                spriteAsset: spriteAsset,
              ),
              if (tapped)
                Positioned.fill(
                  child: IgnorePointer(
                    child: GlitterBurst(maxRadius: burstRadius),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A group of ten drawn as five rows of two - the shape the K.CC.1 lesson
/// teaches a ten to have.
class TenClusterGrid extends StatelessWidget {
  const TenClusterGrid({
    super.key,
    required this.spriteAsset,
    required this.spriteSize,
    required this.gap,
    required this.rowGap,
  });

  final String spriteAsset;
  final double spriteSize;

  /// Between the two in a row.
  final double gap;

  /// Above and below each row.
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final sprite = Image.asset(
      spriteAsset,
      width: spriteSize,
      height: spriteSize,
      fit: BoxFit.contain,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 5; row++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: rowGap),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [sprite, SizedBox(width: gap), sprite],
            ),
          ),
      ],
    );
  }
}

/// The right-hand shelf of a round counted by tapping: empty until everything
/// is counted, then the Done arrow - which is what ends the round, so she
/// says when she has finished counting rather than the game deciding.
class ParadeDoneShelf extends StatelessWidget {
  const ParadeDoneShelf({
    super.key,
    required this.arrowKey,
    required this.visible,
    required this.idleHintText,
    required this.onDone,
  });

  final Key arrowKey;
  final bool visible;

  /// Spoken if she leaves the arrow waiting.
  final String idleHintText;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return kContinueArrowShelf(
      child: visible
          ? NextArrowButton(
              key: arrowKey,
              idleHintEnabled: true,
              idleHintText: idleHintText,
              onPressed: onDone,
              label: kLabelDone,
            )
          : null,
    );
  }
}
