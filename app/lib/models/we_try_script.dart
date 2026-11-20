// The We-Try phase, compiled from its authored choreography into beats.
//
// Every lesson in `data/lesson-runtime/` has authored a `weTry` block since
// the content was written: a scene, a choreography, and its own narration
// script. All 22 of them. Nothing has ever run one — `LessonScreen` went
// straight from I-Show to You-Do — so the middle third of every
// I-Show / We-Try / You-Do lesson in the game has been missing.
//
// What the phase is, taken from what the content says it is rather than from
// what the word "try" suggests: **a participation beat that cannot be failed.**
// All 22 `passCondition` lines say so in their own words —
//
//   "Any tap inside or near a highlighted cluster passes. Even a tap on the
//    wrong cluster passes."
//   "Any kid attempt to trace passes the lesson."
//   "Any kid drag onto any zone passes (correct steers; incorrect corrects)."
//   "Even one drag is enough; system completes the rest."
//
// — and `tolerantOfMiss: true` is on most of the kid steps. So the kid's touch
// is never graded. It chooses which of two already-authored warm lines she
// hears, and then the demonstration carries on either way. That is why this is
// one interpreter over authored data rather than 22 bespoke mini-games: 22
// mechanics that all resolve to "she touched something, tell her what she did"
// are one mechanic.
//
// The compiler turns the choreography's three timing forms into a flat list of
// beats, each with a delay from the previous one:
//
//   "4s"            absolute on the phase clock
//   "+0.5s"         relative to the beat before it
//   "on-kid-input"  wait for her
//
// plus `on-correct` / `on-incorrect` (and the trace lesson's
// `on-stroke-complete-pass` / `-fail`), which are the same "wait" position but
// only run on one outcome of the gate above them.
//
// Absolute times are dropped once a gate has been passed, and this matters: a
// script that says `22s phase-end` means "22 seconds if she watches the whole
// thing", but she may have tapped at 11s, and the remaining beats then have
// nothing to wait for. Honouring the wall clock there leaves a five-year-old
// looking at a finished scene for eleven seconds. Her touch takes over the
// pacing the moment she gives one.

import 'dart:math' as math;

/// Which outcome of the gate above it a beat belongs to.
enum WeTryWhen {
  /// Runs regardless — the overwhelming majority.
  always,

  /// Only after a touch that landed on the named target.
  onPass,

  /// Only after one that did not.
  onFail,
}

sealed class WeTryBeat {
  const WeTryBeat({required this.delay, required this.when});

  /// How long after the *previous beat resolved* this one runs. Never negative.
  final Duration delay;

  final WeTryWhen when;
}

/// Speak a line. The text is resolved at compile time from the phase's own
/// `narrationScript`, which is keyed by cueId in its `at` field.
class WeTrySay extends WeTryBeat {
  const WeTrySay({
    required this.cueId,
    required this.text,
    required super.delay,
    super.when = WeTryWhen.always,
  });

  final String cueId;
  final String text;
}

/// Change the scene. Handed to the lesson screen's existing animation-step
/// applier, which already ignores actions it has no drawing for — so a
/// choreography naming `bar-model-fill-result` costs nothing until there is a
/// bar model to fill.
class WeTryDo extends WeTryBeat {
  const WeTryDo({
    required this.action,
    required this.params,
    required super.delay,
    super.when = WeTryWhen.always,
  });

  final String action;
  final Map<String, dynamic> params;
}

/// Wait for her.
class WeTryGate extends WeTryBeat {
  const WeTryGate({
    required this.targets,
    required this.passText,
    required this.failText,
    required super.delay,
    super.when = WeTryWhen.always,
  });

  /// Scene ids a touch must land on to count as a hit. Empty means anything
  /// does — which is not a fallback but the authored intent for the steps that
  /// name no target at all.
  final List<String> targets;

  /// The two already-authored responses. Both are warm, both advance; a miss
  /// is answered by naming the right answer, never by asking again.
  final String? passText;
  final String? failText;
}

/// Hand off to You-Do.
class WeTryEnd extends WeTryBeat {
  const WeTryEnd({required super.delay, super.when = WeTryWhen.always});
}

/// What to do when she doesn't touch anything.
class WeTryHesitation {
  const WeTryHesitation({required this.after, required this.autoCompletes});

  factory WeTryHesitation.fromJson(Map<String, dynamic>? json) {
    final sec = (json?['thresholdSec'] as num?)?.toDouble() ?? 5.0;
    return WeTryHesitation(
      after: Duration(milliseconds: (sec * 1000).round()),
      autoCompletes: json?['action'] == 'auto-complete',
    );
  }

  final Duration after;

  /// `auto-complete` finishes the step for her; `highlight-target` re-lights
  /// the target and repeats the prompt. Either way she is never left on a
  /// screen where nothing will ever happen again — the interpreter completes
  /// the step at twice this threshold whichever the rule says, because
  /// "highlight and keep waiting" has no floor.
  final bool autoCompletes;
}

/// The compiled phase.
class WeTryScript {
  const WeTryScript({required this.beats, required this.hesitation});

  /// Compiles `phases.weTry` as authored.
  ///
  /// [narrationByCueId] is the phase's own narration script; a `narration`
  /// action whose cueId is not in it is dropped rather than spoken as its own
  /// id, which is the one way this could put a slug in a child's ears.
  factory WeTryScript.compile({
    required List<Map<String, dynamic>> choreography,
    required Map<String, String> narrationByCueId,
    Map<String, dynamic>? hesitationRule,
  }) {
    final beats = <WeTryBeat>[];
    var cursorSec = 0.0;
    var gated = false;

    for (var i = 0; i < choreography.length; i++) {
      final step = choreography[i];
      final at = step['at'] as String? ?? '0s';
      final params = step['params'] is Map
          ? Map<String, dynamic>.from(step['params'] as Map)
          : <String, dynamic>{};

      // A feedback step is the tail of the gate above it, not a beat of its
      // own: its whole content is the passCue/failCue pair the gate already
      // absorbed.
      if (i > 0 && _isFeedback(params['action']) && _lastIsGate(beats)) {
        continue;
      }

      final (delay, cond) = _timing(at, cursorSec, gated);
      cursorSec += delay.inMilliseconds / 1000.0;

      if (step['type'] == 'kid-action-expected') {
        final feedback = _feedbackAfter(choreography, i);
        beats.add(
          WeTryGate(
            targets: _targetsOf(params),
            passText: narrationByCueId[feedback?['passCue']],
            failText: narrationByCueId[feedback?['failCue']],
            delay: delay,
            when: cond,
          ),
        );
        gated = true;
        continue;
      }

      final action = params['action'];
      if (action == 'narration' || action == 'narration-if-monochrome') {
        final cueId = params['cueId'] as String?;
        final text = cueId == null ? null : narrationByCueId[cueId];
        if (text == null) continue;
        beats.add(
          WeTrySay(cueId: cueId!, text: text, delay: delay, when: cond),
        );
        continue;
      }
      if (action == 'phase-end') {
        beats.add(WeTryEnd(delay: delay, when: cond));
        continue;
      }
      if (action is! String) continue;
      beats.add(
        WeTryDo(action: action, params: params, delay: delay, when: cond),
      );
    }

    return WeTryScript(
      beats: List<WeTryBeat>.unmodifiable(beats),
      hesitation: WeTryHesitation.fromJson(hesitationRule),
    );
  }

  final List<WeTryBeat> beats;
  final WeTryHesitation hesitation;

  /// True once the script has something for her to do. A phase with no gate is
  /// a second I-Show, and the test suite refuses to let one ship.
  bool get hasGate => beats.any((b) => b is WeTryGate);
}

/// `drop-feedback`, `tile-feedback`, `tap-feedback`, `tag-feedback`,
/// `symbol-feedback`, `indicator-feedback` — six names for one thing across
/// the 22 lessons, each carrying only a passCue/failCue pair.
bool _isFeedback(Object? action) =>
    action is String && action.endsWith('-feedback');

bool _lastIsGate(List<WeTryBeat> beats) =>
    beats.isNotEmpty && beats.last is WeTryGate;

/// The feedback step belonging to the kid step at [index], if it authored one.
/// Always the next step in every one of the 17 places a lesson writes one, but
/// searched over a short window so a scene action wedged between them doesn't
/// silently cost her the response to her own touch.
Map<String, dynamic>? _feedbackAfter(
  List<Map<String, dynamic>> choreography,
  int index,
) {
  for (var j = index + 1; j < math.min(index + 4, choreography.length); j++) {
    final params = choreography[j]['params'];
    if (params is! Map) continue;
    if (params.containsKey('passCue') || params.containsKey('failCue')) {
      return Map<String, dynamic>.from(params);
    }
  }
  return null;
}

/// Scene ids that count as a hit.
///
/// `expectedTarget` names one directly (`fawn-1`). `expectedZone` names a
/// place (`above-well`, `behind-tree`). `expectedAction` names only a gesture
/// (`drag-fish-to-pad`) and no target at all — and that is authored, not
/// missing: those steps are the ones whose passCondition says any drag passes.
List<String> _targetsOf(Map<String, dynamic> params) {
  final out = <String>[];
  for (final key in const ['expectedTarget', 'expectedZone']) {
    final value = params[key];
    if (value is String && value.isNotEmpty) out.add(value);
    if (value is List) {
      for (final v in value) {
        if (v is String && v.isNotEmpty) out.add(v);
      }
    }
  }
  return List<String>.unmodifiable(out);
}

/// One `at` string as a delay from the previous beat, plus the outcome it
/// belongs to.
(Duration, WeTryWhen) _timing(String at, double cursorSec, bool gated) {
  switch (at) {
    case 'on-correct':
    case 'on-stroke-complete-pass':
      return (Duration.zero, WeTryWhen.onPass);
    case 'on-incorrect':
    case 'on-stroke-complete-fail':
      return (Duration.zero, WeTryWhen.onFail);
  }
  if (at.startsWith('on-')) return (Duration.zero, WeTryWhen.always);

  if (at.startsWith('+')) {
    final sec = double.tryParse(at.substring(1).replaceAll('s', '')) ?? 0;
    return (_seconds(sec), WeTryWhen.always);
  }

  // Absolute. Meaningless once she has taken over the pacing.
  if (gated) return (Duration.zero, WeTryWhen.always);
  final sec = double.tryParse(at.replaceAll('s', '')) ?? cursorSec;
  return (_seconds(math.max(0, sec - cursorSec)), WeTryWhen.always);
}

Duration _seconds(double s) => Duration(milliseconds: (s * 1000).round());
