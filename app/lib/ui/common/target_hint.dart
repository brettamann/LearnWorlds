// The standard idle help for a round with one obvious next thing to touch.
//
// Most rounds answer the hint ladder the same way: at the first rung, ring the
// next target; at the second, ring it, chime, and say "look here"; at the
// top, say what it is and do the step for her. That was written out by hand
// in every runner, with small accidental differences. A round whose help is
// genuinely different (it rings Buddy first, or changes what it asks) keeps
// its own handler; everything else calls this.

import '../../data/warm_lines.dart';
import '../../engines/scaffolding/hint_ladder.dart';

/// Answers [level] for the next target.
///
/// - [ring] glows the target (pass null to clear nothing; it is called at the
///   first two rungs).
/// - [chime] plays the hint sound (rungs two and three).
/// - [say] speaks a line without making it the replay prompt.
/// - [demonstrate] does the step for her, as a hint (so it should queue its
///   own line rather than cut this one off).
/// - [demonstrateLine] is what the top rung says first; defaults to the warm
///   "watch me" line.
void answerTargetHint(
  HintLevel level, {
  required void Function() ring,
  required void Function() chime,
  required void Function(String line) say,
  required void Function() demonstrate,
  String? demonstrateLine,
}) {
  switch (level) {
    case HintLevel.none:
      return;
    case HintLevel.highlight:
      ring();
    case HintLevel.point:
      ring();
      chime();
      say(warmHintLine(2));
    case HintLevel.demonstrate:
      chime();
      say(demonstrateLine ?? warmHintLine(3));
      demonstrate();
  }
}
