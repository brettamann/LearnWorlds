// The frame every playfield shares.
//
// Eleven runners had written this out identically - a SafeArea, a column, the
// progress bar padded (24, 12, 24, 0) at the top, the round filling what is
// left - and differed only in which two expressions they passed to
// `ProgressBarToReward`. That is copy, not shape, and `counting-sequence.md`'s
// "copy the shape, not the code" rule is about round *sequencing*, not about
// the box the sequence is drawn in.
//
// Worth having as one widget mainly because of the last line of it: the round
// stops above the caption band. Left to eleven copies that reservation was
// made in one of them, and the other ten put things she has to touch behind
// an opaque subtitle - the shapes in "tap all the circles", the baskets in a
// game about dragging shapes into baskets, the companion she designed. See
// `playfield_caption_band_test.dart`, which is the guard, and
// `playfield_area.dart` for the same problem where a runner positions things
// by fractions instead.

import 'package:flutter/material.dart';

import 'caption_overlay.dart';
import 'progress_bar_to_reward.dart';

class PlayfieldScaffold extends StatelessWidget {
  const PlayfieldScaffold({
    super.key,
    required this.progress,
    required this.celebrate,
    required this.child,
  });

  /// 0..1 toward the round's reward.
  final double progress;

  final bool celebrate;

  /// The round itself.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        // The band is opaque and permanent, so this is not padding in the
        // decorative sense - it is the part of the window the round may not
        // use. Backgrounds are drawn behind this scaffold and stay full-bleed.
        padding: const EdgeInsets.only(bottom: kCaptionBandClearance),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: ProgressBarToReward(
                progress: progress,
                celebrate: celebrate,
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
