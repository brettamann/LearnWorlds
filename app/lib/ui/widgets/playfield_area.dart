// The part of a playfield a child can actually see and touch.
//
// Every runner is mounted full-bleed inside `activity_screen`, which also
// mounts `CaptionOverlay` — an opaque band across the bottom of the screen.
// So the box a runner lays out in is taller than the space it can put things
// in, and a runner that positions anything by a fraction of its own height
// will sooner or later put something underneath the band.
//
// It has now done so three times, and none of them looked broken:
//
//   * Counting Parade's companion stood at the bottom of the meadow with the
//     band across it. Fixed in place, by that one runner, with a local
//     constant — which is where `kCaptionBandClearance` came from.
//   * Where's Buddy parked the Buddy she has to *pick up* at 0.92 of the
//     clearing, and answered "below the mushroom" in the same strip.
//   * Shape Garden scattered its shapes on a 4x3 grid over the full height,
//     so the bottom row — two of the three circles in a round about tapping
//     circles — sat behind the band, and its three sorting bins each had
//     eighty pixels of drop target under it.
//
// The shape of the mistake is always the same and so is the fix: lay the
// scene out inside the visible area rather than nudging whatever fell foul of
// the band. Individual nudges change a composition that was authored; scaling
// the whole thing keeps every relationship as designed.
//
// `playfield_caption_band_test.dart` is the guard, and it checks the thing
// that actually matters rather than this class being used: no playfield may
// leave anything touchable under the band, by any route.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'caption_overlay.dart';

@immutable
class PlayfieldArea {
  /// The visible part of a [width] x [height] playfield box.
  factory PlayfieldArea({required double width, required double height}) {
    // Never take more than half: a very short window would otherwise leave a
    // scene with nowhere to be, and a squashed playfield beats an empty one.
    final usable = math.max(height - kCaptionBandClearance, height * 0.5);
    return PlayfieldArea._(width: width, height: usable);
  }

  factory PlayfieldArea.of(BoxConstraints constraints) => PlayfieldArea(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
      );

  const PlayfieldArea._({required this.width, required this.height});

  final double width;

  /// Excludes the caption band.
  final double height;

  double get shortest => math.min(width, height);

  /// A normalized position in pixels.
  Offset place(Offset normalized) =>
      Offset(normalized.dx * width, normalized.dy * height);

  /// A fraction of the shorter visible side, in pixels.
  double sizeOf(double fraction) => shortest * fraction;
}
