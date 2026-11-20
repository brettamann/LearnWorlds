// BuddyCompanion — the Buddy standing in the scene, reacting to what the kid
// does.
//
// The point of this widget is attachment. A child spends real effort designing
// a Buddy in the character creator and then, until now, never saw it again
// outside the Hub — so the investment went nowhere and there was nobody in the
// activity to be doing the math *for*. Putting the companion on the playfield
// is what turns "answer the questions" into "show Buddy how".
//
// It subscribes to buddyReactionProvider rather than taking a mood parameter,
// which is the whole reason a runner gets a reactive Buddy without mentioning
// the Buddy at all — FeedbackEngine publishes, this listens.
//
// Note the RepaintBoundary: three controllers over a six-layer sprite stack
// should not be marking the whole playfield dirty every frame.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/feedback/feedback_engine.dart';
import '../../models/buddy_mood.dart';
import '../../providers/buddy_reaction_provider.dart';
import 'buddy_widget.dart';
import 'caption_overlay.dart';

class BuddyCompanion extends ConsumerWidget {
  const BuddyCompanion({
    super.key,
    this.size = 150,
    this.facing = BuddyFacing.right,
  });

  final double size;

  /// Which way the Buddy looks. Face it toward the playfield — a companion
  /// staring off-screen reads as scenery rather than as a participant.
  final BuddyFacing facing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reaction = ref.watch(buddyReactionProvider);
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: BuddyWidget(
              size: size,
              mood: reaction.mood,
              reactionToken: reaction.token,
              facing: facing,
            ),
          ),
          // He can be poked, and that is the only thing in the game with no
          // right answer in it — the engagement plan's own rubric scored
          // agency, "is there anywhere with no right answer?", as absent. The
          // two Buddy chirps had been rendered, bundled into every build and
          // played by nothing. Touching him costs nothing and cannot be got
          // wrong.
          //
          // The tap surface is a circle over his body rather than the whole
          // box, and the reason is that the companion stands in the corner of
          // a live playfield: the box is much bigger than he is, and an
          // opaque hit test across it would eat taps on the shapes, creatures
          // and replay button beside him. Over his body it costs nothing —
          // anything under there is behind an opaque sprite and was already
          // untappable in practice.
          SizedBox(
            width: size * 0.5,
            height: size * 0.5,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.read(feedbackEngineProvider).buddyPoke(),
            ),
          ),
        ],
      ),
    );
  }
}

/// The companion in its usual place: bottom-left of a playfield, clear of the
/// caption band.
///
/// Nine runners wrote `Positioned(left: 12, bottom: 12, child:
/// BuddyCompanion())` and every one of them was wrong by the height of the
/// caption band - the character the child designs, put on the playfield so
/// there is somebody to be doing the math *for*, spent every round with a
/// subtitle across his legs. He is 150 tall and the band is 96, so it was most
/// of him.
///
/// Counting Parade was the exception, because it walks its Buddy around the
/// meadow and had already worked the clearance out for itself
/// (`_kBuddyHomeInset`). Nothing carried that from the one runner that knew to
/// the eight that did not - which is what this widget is for. The number lives
/// here now, and `playfield_caption_band_test.dart` fails if any playfield
/// puts something touchable under the band by any other route.
class BuddyCompanionCorner extends StatelessWidget {
  const BuddyCompanionCorner({
    super.key,
    this.size = 150,
    this.facing = BuddyFacing.right,
  });

  final double size;
  final BuddyFacing facing;

  /// Gap between the companion and the top of the caption band.
  static const double inset = 12;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: inset,
      bottom: kCaptionBandClearance + inset,
      child: BuddyCompanion(size: size, facing: facing),
    );
  }
}
