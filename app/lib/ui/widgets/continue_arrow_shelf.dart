// ContinueArrowShelf — the right-edge column where every practice
// surface, demo, and overlay parks its NextArrowButton. Lives here so
// the position is defined in exactly one place: vertically-centered,
// 140 pt wide. Live kid-testing surfaced that a wandering arrow
// (sometimes bottom, sometimes right) is confusing — this shelf is the
// shared answer.
//
// USAGE:
//   - Build a Row at the top of your layer with `Expanded(content)`,
//     a 24 pt gap, and `kContinueArrowShelf(child: …)` on the right.
//   - Pass `null` when the arrow shouldn't render (e.g. mid-round, no
//     "Done" yet); the shelf still reserves its width so content
//     doesn't reflow when the arrow appears.
//
// The vertical centering matches the LessonScreen's Continue arrow,
// which already used the right-edge pattern; the runners are catching
// up to that precedent.

import 'package:flutter/material.dart';

/// Fixed-width "shelf" for the Continue arrow. Always reserves its
/// width so the surrounding layout doesn't shift when the child swaps
/// from null to a NextArrowButton mid-round.
SizedBox kContinueArrowShelf({required Widget? child}) {
  return SizedBox(
    width: 140,
    child: Center(child: child ?? const SizedBox.shrink()),
  );
}
