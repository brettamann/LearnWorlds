// HintLadder — escalating help for a kid who has gone quiet.
//
// Before this, the only idle detection in the game was navigational: the
// NextArrowButton wiggles after ten seconds of nobody tapping it. There was no
// equivalent for the math itself, so a child who genuinely didn't know which
// shape was a hexagon could sit in front of the round indefinitely with
// nothing happening at all.
//
// The rungs, per specs/shared/adaptive-scaffolding.md ("warmth, then
// demonstration; never punitive"):
//
//   ~5s   highlight    — glow the next target. No words; she may just be
//                        thinking, and interrupting a thinking child is worse
//                        than waiting.
//   ~10s  point        — Buddy leans over and points, with a spoken nudge.
//                        Help visibly arriving from the companion rather than
//                        from the game reads as a friend noticing, not as a
//                        failure being announced.
//   ~15s  demonstrate  — do one for her. "Prefer demoting to skipping": the
//                        kid learns nothing from being stuck, and nothing from
//                        a skip button either.
//
// Any input calls [poke] and drops back to rung zero.
//
// ONE RULE FOR THE TOP RUNG. `demonstrate` says something and then does the
// thing it just described, and the doing speaks too - "One.", "There's one!",
// the name of the basket. `NarrationPlayer.speak` cuts off whatever is in
// flight, so for as long as this ladder has existed the explanation was cut
// off a few milliseconds after it started, in every activity, every time. The
// explanation is the whole content of a demonstration; the confirmation is
// not. So the action's own line is `enqueue`d when it was the ladder that
// triggered it - which is what the `fromHint` flag every runner already
// threads is for - and spoken normally when she did it herself, because a
// child tapping quickly wants "Two." to interrupt "One." rather than queue
// behind it.
//
// Modelled on the idle timer in ui/widgets/next_arrow_button.dart, which
// solves the same shape of problem for navigation.

import 'dart:async';

enum HintLevel { none, highlight, point, demonstrate }

/// Escalating idle-help thresholds. Mirrors the `hintThresholds` block already
/// authored in data/lesson-runtime/k-cc-4a-one-to-one.json.
class HintThresholds {
  const HintThresholds({
    this.highlightSec = 5,
    this.pointSec = 10,
    this.demonstrateSec = 15,
  });

  factory HintThresholds.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HintThresholds();
    return HintThresholds(
      // The authored key names predate the hint ladder, so accept both the
      // JSON spelling and the engine's.
      highlightSec: _int(json, const ['highlightNextSec', 'highlightSec'], 5),
      pointSec: _int(json, const ['narratorReminderSec', 'pointSec'], 10),
      demonstrateSec: _int(json, const ['demonstrateSec'], 15),
    );
  }

  static int _int(Map<String, dynamic> json, List<String> keys, int fallback) {
    for (final k in keys) {
      final v = json[k];
      if (v is num) return v.toInt();
    }
    return fallback;
  }

  final int highlightSec;
  final int pointSec;
  final int demonstrateSec;
}

class HintLadder {
  HintLadder({
    required this.onLevel,
    this.thresholds = const HintThresholds(),
  });

  /// Fired each time the ladder climbs. Never fired for [HintLevel.none] —
  /// resets are silent, because a kid who just tapped doesn't need to be told
  /// the hint went away.
  final void Function(HintLevel level) onLevel;

  final HintThresholds thresholds;

  Timer? _timer;
  HintLevel _level = HintLevel.none;
  int _hintsUsed = 0;
  bool _running = false;

  HintLevel get level => _level;

  /// How many times the ladder reached [HintLevel.demonstrate]. A round where
  /// this is non-zero resolves as a soft success rather than a clean one —
  /// she got there, but the game did some of the work.
  int get hintsUsed => _hintsUsed;

  /// Begin (or restart) watching. Safe to call repeatedly.
  void start() {
    _running = true;
    _reset();
  }

  /// "The kid did something." Drops back to rung zero and restarts the clock.
  void poke() {
    if (!_running) return;
    _reset();
  }

  /// Stop climbing without discarding [hintsUsed] — used while a celebration
  /// or interstitial is on screen and idleness isn't the kid's fault.
  void pause() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    _level = HintLevel.none;
  }

  void dispose() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void _reset() {
    _timer?.cancel();
    _level = HintLevel.none;
    _schedule();
  }

  void _schedule() {
    if (!_running) return;
    final next = switch (_level) {
      HintLevel.none => (HintLevel.highlight, thresholds.highlightSec),
      HintLevel.highlight => (
          HintLevel.point,
          thresholds.pointSec - thresholds.highlightSec,
        ),
      HintLevel.point => (
          HintLevel.demonstrate,
          thresholds.demonstrateSec - thresholds.pointSec,
        ),
      // Top of the ladder: stop climbing. The demonstration hands control
      // back, and the next tap restarts the whole cycle.
      HintLevel.demonstrate => null,
    };
    if (next == null) return;
    final (level, afterSec) = next;
    _timer = Timer(Duration(seconds: afterSec.clamp(1, 120)), () {
      if (!_running) return;
      _level = level;
      if (level == HintLevel.demonstrate) _hintsUsed++;
      onLevel(level);
      _schedule();
    });
  }
}
