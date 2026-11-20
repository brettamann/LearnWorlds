// WeTryRunner - the "we try" third of a lesson: guided practice.
//
// The phase cannot be failed. Every lesson's `passCondition` says so in its
// own words ("any tap passes", "even one drag is enough; system completes the
// rest"), so her touch is never graded: it chooses which of two warm lines she
// hears, and the demonstration carries on either way. What the phase is for
// is the touch itself - an I-Show she watched and a You-Do she is graded on,
// with nothing in between, is the gap this closes.
//
// Two rules that are not in the authored data, both there to keep the screen
// from ever going quiet on her:
//
//   * No beat starts before the previous line has finished speaking.
//     `NarrationPlayer.enqueue` holds two and silently drops the rest, so a
//     run of narration beats 0.5s apart would lose most of itself - and the
//     lines it loses are the ones answering what she just did.
//   * A gate always resolves. The hesitation rule re-lights the target, then
//     nudges, then completes the step itself. "Highlight and keep waiting"
//     has no floor, and a five-year-old who has decided not to touch this one
//     is owed the rest of her lesson anyway.
//
// Pulled out of LessonScreen so the interpreter, its four timers and its
// gate are one object with one lifetime: the screen creates it when the
// phase starts and disposes it when the phase ends.

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../data/warm_lines.dart';
import '../../engines/narration/narration_player.dart';
import '../../models/lesson_runtime.dart';
import '../../models/we_try_script.dart';
import 'lesson_scene.dart';

class WeTryRunner extends ChangeNotifier {
  WeTryRunner({
    required this.phase,
    required this.scene,
    required this.say,
    required this.chime,
    required this.pop,
    required this.hits,
    required this.onFinished,
  });

  final WeTryPhase phase;
  final LessonScene scene;

  /// Speaks a line, captioned.
  final void Function(String text, String cueId) say;

  /// The hint sound, for the hesitation nudge.
  final VoidCallback chime;

  /// The warm pop for any touch - never the "wrong" sound; this phase has no
  /// wrong answers.
  final VoidCallback pop;

  /// Whether [at] lands on any of [targets] as the stage drew them.
  final bool Function(List<String> targets, Offset at) hits;

  /// The phase is over; hand off to the You-Do.
  final VoidCallback onFinished;

  WeTryScript get _script => phase.script;

  int _cursor = 0;
  bool _lastPassed = true;
  WeTryGate? _gate;
  bool _done = false;

  /// A gate is open and waiting on her touch.
  bool get waiting => _gate != null;

  /// She has been waiting past the hesitation threshold; the halo brightens.
  bool urgent = false;

  Timer? _beatTimer;
  Timer? _hesitationTimer;
  Timer? _nudgeTimer;
  Timer? _rescueTimer;

  /// The hand walking through targets the content asked the system to finish.
  final List<Timer> _demoTimers = <Timer>[];

  void start() {
    scene.resetForWeTry(phase);
    _runBeat();
  }

  /// Runs the beat at the cursor, then schedules the next.
  void _runBeat() {
    if (_done) return;
    final beats = _script.beats;

    // Skip beats belonging to the outcome the last gate did not have.
    while (_cursor < beats.length) {
      final matches = switch (beats[_cursor].when) {
        WeTryWhen.always => true,
        WeTryWhen.onPass => _lastPassed,
        WeTryWhen.onFail => !_lastPassed,
      };
      if (matches) break;
      _cursor++;
    }
    if (_cursor >= beats.length) {
      _finish();
      return;
    }

    final beat = beats[_cursor++];
    var settle = Duration.zero;
    switch (beat) {
      case WeTryEnd():
        _finish();
        return;
      case WeTryGate():
        _openGate(beat);
        return;
      case WeTrySay():
        say(beat.text, 'wetry:${beat.cueId}');
        settle = narrationSpokenEstimate(beat.text);
      case WeTryDo():
        _applyAction(beat);
    }
    _scheduleNextBeat(settle);
  }

  /// The next beat waits for its authored gap or for the current line to
  /// finish, whichever is longer.
  void _scheduleNextBeat(Duration settle) {
    final next = _script.beats.length > _cursor
        ? _script.beats[_cursor].delay
        : Duration.zero;
    _beatTimer?.cancel();
    _beatTimer = Timer(next > settle ? next : settle, _runBeat);
  }

  /// Scene changes during We-Try. Halo actions are handled here because the
  /// halo is this phase's own affordance; everything else goes to the same
  /// applier the I-Show uses, so a lesson does not author its scene twice.
  void _applyAction(WeTryDo beat) {
    final named = <String>[
      if (beat.params['target'] is String) beat.params['target'] as String,
      for (final t in beat.params['targets'] as List<dynamic>? ?? const [])
        if (t is String) t,
    ];
    if (beat.action.startsWith('halo')) {
      // `halo-pulse-next-vertex` and friends name no target: "next" is
      // whatever is still missing, which stays correct after she has placed a
      // piece in an order the author did not predict.
      scene.halo(
        named.isNotEmpty ? named : scene.nextUnplacedFramePiece(beat.action),
      );
      return;
    }
    // `pointer-auto-*` is the system finishing what she started. It has to be
    // something she can *watch*: lighting every target at once, with no hand,
    // was the first thing reported from a real session, and the word for it
    // was "jarring". So the demonstrator's hand does it, one target at a time,
    // at the authored pace.
    if (beat.action.startsWith('pointer-auto')) {
      scene.autoCompleteFrame(beat.action);
      _walkTheHand(named, beat.params);
      return;
    }
    if (beat.action == 'frame-solidify') {
      scene.completeFrame();
      return;
    }
    scene.apply(
      AnimationStep(at: '0s', action: beat.action, params: beat.params),
    );
  }

  /// Touch each of [targets] in turn, with the hand visible, at the pace the
  /// content asked for. Nothing here waits on her, so it schedules rather
  /// than gating; the spacing is clamped rather than trusted, so a walk never
  /// runs longer than its own line.
  void _walkTheHand(List<String> targets, Map<String, dynamic> params) {
    _cancelDemo();
    if (targets.isEmpty) return;
    final spacing = Duration(
      milliseconds: (((params['spacingSec'] as num?)?.toDouble() ?? 0.9) * 1000)
          .round()
          .clamp(400, 2000),
    );
    for (var i = 0; i < targets.length; i++) {
      final id = targets[i];
      // Reach, then touch: the movement between is what reads as somebody
      // doing it.
      _demoTimers
        ..add(Timer(spacing * i, () => scene.reachFor(id)))
        ..add(Timer(spacing * i + spacing * 0.55, () => scene.touch(id)));
    }
    _demoTimers.add(Timer(spacing * targets.length, scene.handAway));
  }

  void _cancelDemo() {
    for (final t in _demoTimers) {
      t.cancel();
    }
    _demoTimers.clear();
  }

  void _openGate(WeTryGate gate) {
    _gate = gate;
    urgent = false;
    notifyListeners();
    if (gate.targets.isNotEmpty) scene.halo(gate.targets);
    // The same three rungs as everywhere else (adaptive-scaffolding.md):
    // highlight, then a word, then demonstration. What the rule's two
    // spellings choose is what the *last* rung does: `auto-complete` finishes
    // the step with the hand, `highlight-target` resolves it quietly and moves
    // the halo on. Neither fires before she has had the highlight and nudge.
    final rule = _script.hesitation;
    _cancelGateTimers();
    _hesitationTimer = Timer(rule.after, () {
      if (!waiting) return;
      urgent = true;
      notifyListeners();
    });
    _nudgeTimer = Timer(rule.after * 2, () {
      if (!waiting) return;
      chime();
      say(warmHintLine(2), 'we-try:hesitation-nudge');
    });
    _rescueTimer = Timer(rule.after * 3, () {
      final gate = _gate;
      if (gate == null) return;
      if (rule.autoCompletes) {
        _walkTheHand(_targetsOf(gate).take(1).toList(), const {});
      }
      _resolveGate(passed: true, byHer: false);
    });
  }

  /// What her touch was about. Most gates name a target; the habitat ones
  /// name only a gesture ("drag-clay-to-vertex", any vertex), so the thing
  /// she was asked about is the thing that was lit when she was asked - which
  /// also means she can never be told she missed something never shown.
  List<String> _targetsOf(WeTryGate gate) =>
      gate.targets.isNotEmpty ? gate.targets : scene.haloed.toList();

  /// A touch anywhere on the stage.
  void touch(Offset globalPosition) {
    final gate = _gate;
    if (gate == null) return;
    _resolveGate(
      passed: hits(_targetsOf(gate), globalPosition),
      byHer: true,
    );
  }

  void _resolveGate({required bool passed, required bool byHer}) {
    final gate = _gate;
    if (gate == null) return;
    _cancelGateTimers();
    final settling = _targetsOf(gate);
    _gate = null;
    urgent = false;
    _lastPassed = passed;
    notifyListeners();
    scene.settleGate(settling, byHer: byHer);

    // The same warm pop whether or not she landed on the target. A touch
    // elsewhere is not a wrong answer here, and the miss sound would teach
    // her it was one; the corrective line is the correction.
    if (byHer) pop();

    var settle = Duration.zero;
    // Fall back across the pair rather than saying nothing: several lessons
    // author only a passCue, and silence after her touch is what this phase
    // exists to stop.
    final line = passed
        ? (gate.passText ?? gate.failText)
        : (gate.failText ?? gate.passText);
    if (line != null) {
      say(line, 'wetry:gate');
      settle = narrationSpokenEstimate(line);
    }
    _scheduleNextBeat(settle);
  }

  void _cancelGateTimers() {
    _hesitationTimer?.cancel();
    _nudgeTimer?.cancel();
    _rescueTimer?.cancel();
  }

  void _finish() {
    if (_done) return;
    _stop();
    onFinished();
  }

  void _stop() {
    _done = true;
    _beatTimer?.cancel();
    _cancelGateTimers();
    _cancelDemo();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}
