// IShowTimeline - the "I show" third of a lesson, played off the clock.
//
// The lesson JSON authors the demonstration as timestamped narration cues
// and animation steps. This schedules them against a LessonScene, glides the
// demo hand ahead of each touch so the poke lands on its word, and says when
// the skip pill and the Continue arrow may appear.

import 'dart:async';

import '../../models/lesson_runtime.dart';
import '../widgets/lesson_hand_pointer.dart';
import 'lesson_scene.dart';

class IShowTimeline {
  IShowTimeline({
    required this.show,
    required this.scene,
    required this.say,
    required this.onSkipAvailable,
    required this.onContinueAvailable,
  });

  final IShowPhase show;
  final LessonScene scene;

  /// Speaks a cue (captioned, cutting off whatever came before).
  final void Function(String text, String cueId) say;

  final void Function() onSkipAvailable;
  final void Function() onContinueAvailable;

  final List<Timer> _timers = <Timer>[];

  void _at(Duration d, void Function() f) => _timers.add(Timer(d, f));

  /// "3s" or "3" -> 3. Authored times are whole seconds.
  static int parseSeconds(String at) {
    final trimmed = at.endsWith('s') ? at.substring(0, at.length - 1) : at;
    return int.tryParse(trimmed) ?? 0;
  }

  void start() {
    for (final cue in show.narrationScript) {
      _at(
        Duration(seconds: parseSeconds(cue.at)),
        () => say(cue.text, 'ishow:${cue.at}'),
      );
    }
    for (final step in show.animationSteps) {
      _at(Duration(seconds: parseSeconds(step.at)), () => scene.apply(step));
    }

    // Pre-glide the hand to each `pointer-touch` target so the poke, sparkle
    // and narration land together at the touch moment. The first touch is
    // arranged by the upstream `pointer-appear` step (or starts mid-screen),
    // so only the second onward needs it.
    final touches =
        show.animationSteps.where((s) => s.action == 'pointer-touch').toList();
    for (var i = 1; i < touches.length; i++) {
      final targetId = LessonScene.resolveTargetId(touches[i].params['target']);
      if (targetId == null) continue;
      final preGlideMs = parseSeconds(touches[i].at) * 1000 -
          handPointerGlideDuration.inMilliseconds;
      if (preGlideMs <= 0) continue;
      _at(Duration(milliseconds: preGlideMs), () => scene.aimAt(targetId));
    }

    if (show.skipAvailableAfterSec > 0) {
      _at(Duration(seconds: show.skipAvailableAfterSec), onSkipAvailable);
    }
    _at(Duration(seconds: show.durationSec), onContinueAvailable);
  }

  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }
}
