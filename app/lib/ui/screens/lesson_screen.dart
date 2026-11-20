// LessonScreen — plays a lesson as a captioned + animated preview that
// mirrors the activity round the kid is about to play.
//
// Two top-level shapes:
//   - **Fawn / iShow lessons** (K.CC.4a-style): keeper intro → iShow scene
//     scheduled from runtime.iShow narration + animation steps → Continue
//     hands off to /activity.
//   - **Shape lessons** (K.G.2): keeper intro → fixed 9-step per-shape
//     sequence (circle, triangle, right-triangle, square, rectangle,
//     pentagon, hexagon, half-circle, quarter-circle). Each step is a
//     ShapeIntroLayer beat (sprite + count its sides) followed by a
//     ShapeFindRound beat (tap all the X). After the last shape, a
//     Continue arrow hands off to /activity.
//
// Detection: `runtime.iShow.shapes.isNotEmpty` picks the shape branch.
// K.CC.4a-style lessons skip the per-shape sequence entirely and run the
// existing iShow scheduler (badge, fawns, hand pointer pre-glide).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activities/activity_launch.dart';
import '../../data/asset_paths.dart';
import '../../data/build_a_habitat_blueprints.dart';
import '../../data/button_labels.dart';
import '../../data/lesson_loader.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../models/lesson_runtime.dart';
import '../../models/we_try_script.dart';
import '../../navigation/routes.dart';
import '../../platform/sfx_engine.dart';
import '../../ui/common/round_back_button.dart';
import '../lesson/lesson_scene.dart';
import '../lesson/lesson_stages.dart';
import '../widgets/caption_overlay.dart';
import '../widgets/clearing_lesson_stage.dart';
import '../widgets/habitat_lesson_stage.dart';
import '../widgets/keeper_intro_overlay.dart';
import '../widgets/kg3_flat_or_solid_lesson_layer.dart';
import '../widgets/kg4_sort_by_attribute_lesson_layer.dart';
import '../widgets/lesson_hand_pointer.dart';
import '../widgets/lesson_target_registry.dart';
import '../widgets/next_arrow_button.dart';
import '../widgets/shape_find_demo.dart';
import '../widgets/shape_find_round.dart';
import '../widgets/shape_intro_layer.dart';
import '../widgets/we_try_halo.dart';

/// Order the K.G.2 lesson introduces shapes in. Simple → complex; circles
/// first (no sides, easiest), then the polygon ladder, then the imperfect
/// circles which depend on understanding "side" already. 3D shapes land in
/// a later sprint per the lesson spec.
const List<String> kShapeIntroSequence = <String>[
  'circle',
  'triangle',
  'triangle-right',
  'square',
  'rectangle',
  'pentagon',
  'hexagon',
  'semicircle_half',
  'semicircle_quarter',
];

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    super.key,
    required this.lessonId,
    this.subModeOverride,
  });

  final String lessonId;

  /// When set, overrides the lesson runtime's `youDo.subMode` on the
  /// hand-off to the activity. Used by the Sanctuary node picker so a
  /// kid who picked one sub-mode but a lesson covering a different
  /// sub-mode is required (e.g. the K.CC.1 lesson is shared across the
  /// long-parade and count-on-by-ones chain entries) doesn't get
  /// dropped into the wrong activity body. Null = use the lesson's own
  /// youDo.subMode.
  final String? subModeOverride;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

enum _LessonPhase {
  keeperIntro,
  shapeIntro,
  shapeFindDemo,
  shapeFindRound,
  shapesDone,
  flatOrSolidLesson,
  sortByAttributeLesson,
  iShow,

  /// Guided practice. Authored in all 22 lessons since the content was
  /// written; until now the screen went straight from `iShow` to You-Do, so
  /// the middle third of every lesson existed only on disk.
  weTry,
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  Future<LessonRuntime>? _future;
  final List<Timer> _timers = [];
  bool _continueEnabled = false;
  bool _skipEnabled = false;
  LessonRuntime? _runtime;
  _LessonPhase _phase = _LessonPhase.keeperIntro;
  bool _musicClaimed = false;

  /// Read eagerly — `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfxForDispose;

  // Per-shape sequence cursor (K.G.2 only). Indexes kShapeIntroSequence.
  int _currentShapeIdx = 0;

  /// What the stage shows, and the rules for moving it. Driven by the I-Show
  /// timeline and the We-Try beats; observed here.
  final LessonScene _scene = LessonScene();

  /// We-Try interpreter state: how far down the compiled beat list we are,
  /// whether we are waiting on her, and how the last gate resolved (which
  /// selects the `on-correct` / `on-incorrect` beats below it).
  int _weTryCursor = 0;
  bool _weTryWaiting = false;
  bool _weTryLastPassed = true;
  bool _weTryUrgent = false;
  WeTryGate? _weTryGate;
  Timer? _weTryBeatTimer;
  Timer? _weTryHesitationTimer;
  Timer? _weTryNudgeTimer;
  Timer? _weTryRescueTimer;

  /// The hand walking through targets the content asked the system to finish.
  final List<Timer> _weTryDemoTimers = <Timer>[];

  final LessonTargetRegistry _targets = LessonTargetRegistry();

  /// Concept-specific keeper dialogue. Kept here so every introducing
  /// activity's keeper line lives in one place. The fawns line is the
  /// K.CC.4a default — every other concept that uses LessonScreen needs
  /// its own case so the kid doesn't hear "the fawns wander off" before
  /// a lesson about clusters or counting on.
  String _keeperIntroDialog(LessonRuntime? runtime) {
    switch (runtime?.conceptId) {
      case 'K.G.2':
        return 'Look — some plants in the garden have grown into shapes! '
            "Help me find them all, won't you?";
      case 'K.G.3':
        return 'Some shapes are flat — like drawings on a page. Others are '
            'solid — you can hold them in your hand. Help me sort them into '
            'the right baskets!';
      case 'K.G.4':
        return "Shapes can group by how many sides they have. Let's put "
            'the three-sided ones together, the four-sided ones together, '
            'and the ones with five or more sides together.';
      case 'K.CC.1':
        return "Today the parade is HUGE. Don't worry — we can count by "
            'tens! Watch how a big group of ten becomes one easy count.';
      case 'K.CC.2':
        return "We don't always start at one. When some are already counted, "
            'we can keep going from there. Let me show you.';
      default:
        return "Oh, thank goodness you're here. The fawns wander off every "
            'time I blink. Can you help me make sure all three are still '
            'in the meadow?';
    }
  }

  String _keeperIntroStartLabel(LessonRuntime? runtime) {
    switch (runtime?.conceptId) {
      case 'K.G.2':
        return "Let's look!";
      case 'K.G.3':
        return "Let's sort!";
      case 'K.G.4':
        return "Let's sort!";
      case 'K.CC.1':
      case 'K.CC.2':
        return "Let's count!";
      default:
        return "Let's count!";
    }
  }

  /// Idempotent keeper-intro narration. The post-frame callback in the
  /// FutureBuilder calls this on every rebuild; the flag makes it a no-op
  /// after the first fire.
  bool _keeperIntroSpoken = false;

  @override
  void initState() {
    super.initState();
    _sfxForDispose = ref.read(sfxEngineProvider);
    _future = const LessonLoader().load(widget.lessonId);
    _scene.addListener(_onSceneChanged);
  }

  void _onSceneChanged() {
    if (mounted) setState(() {});
  }

  /// Claim the scene's bed as soon as the lesson has loaded.
  ///
  /// The kid usually arrives here from a runner that was already playing this
  /// same file, so this is normally a no-op that cancels that runner's pending
  /// release — the music simply keeps going across the route change instead of
  /// fading out for the length of the lesson and starting over afterwards.
  void _claimMusicOnce(LessonRuntime runtime) {
    if (_musicClaimed) return;
    _musicClaimed = true;
    unawaited(
      ref
          .read(sfxEngineProvider)
          .startMusicBed(runtime.iShow.musicBed ?? kDefaultMusicBed),
    );
  }

  void _speakKeeperIntroOnce(LessonRuntime runtime) {
    if (_keeperIntroSpoken) return;
    _keeperIntroSpoken = true;
    ref.narration.say(
      _keeperIntroDialog(runtime),
      cueId: 'lesson:keeper-intro',
      speaker: kKeeperSpeaker,
      caption: false,
    );
  }

  /// True for lessons whose iShow scene includes painted shapes (K.G.2).
  /// We use this rather than the conceptId switch so adjacent shape-recog
  /// lessons get the same treatment without touching this file.
  bool _isShapeLesson(LessonRuntime runtime) => runtime.iShow.shapes.isNotEmpty;

  void _onKeeperStartPressed() {
    final runtime = _runtime;
    if (runtime == null) return;
    if (runtime.conceptId == 'K.G.3') {
      setState(() => _phase = _LessonPhase.flatOrSolidLesson);
      return;
    }
    if (runtime.conceptId == 'K.G.4') {
      setState(() => _phase = _LessonPhase.sortByAttributeLesson);
      return;
    }
    if (_isShapeLesson(runtime)) {
      setState(() {
        _currentShapeIdx = 0;
        _phase = _LessonPhase.shapeIntro;
      });
      return;
    }
    setState(() => _phase = _LessonPhase.iShow);
    _scheduleIShow(runtime);
  }

  void _onFlatOrSolidLessonComplete() {
    if (!mounted) return;
    _goToYouDo();
  }

  void _onSortByAttributeLessonComplete() {
    if (!mounted) return;
    _goToYouDo();
  }

  void _onShapeIntroComplete() {
    if (!mounted) return;
    // Show the auto-walk demo only before the *first* find round of the
    // whole sequence (index 0 — circles). After that the kid already
    // knows the mechanic; subsequent shapes go straight to interactive
    // play.
    final nextPhase = _currentShapeIdx == 0
        ? _LessonPhase.shapeFindDemo
        : _LessonPhase.shapeFindRound;
    setState(() => _phase = nextPhase);
  }

  void _onShapeFindDemoComplete() {
    if (!mounted) return;
    setState(() => _phase = _LessonPhase.shapeFindRound);
  }

  void _onShapeFindRoundComplete() {
    if (!mounted) return;
    final next = _currentShapeIdx + 1;
    if (next >= kShapeIntroSequence.length) {
      // All 9 shapes done — celebratory beat, then hand off via the
      // Continue arrow.
      ref.narration.say(
        'Wow! You learned every shape in the garden.',
        cueId: 'lesson:shapes-done',
      );
      setState(() {
        _phase = _LessonPhase.shapesDone;
        _continueEnabled = true;
      });
      return;
    }
    setState(() {
      _currentShapeIdx = next;
      _phase = _LessonPhase.shapeIntro;
    });
  }

  void _scheduleIShow(LessonRuntime runtime) {
    final player = ref.narration;

    // Narration cues.
    for (final cue in runtime.iShow.narrationScript) {
      final at = _parseSeconds(cue.at);
      _timers.add(
        Timer(Duration(seconds: at), () {
          if (!mounted) return;
          player.speak(
            NarrationLine(text: cue.text, cueId: 'ishow:${cue.at}'),
          );
        }),
      );
    }

    // Animation steps.
    for (final step in runtime.iShow.animationSteps) {
      final at = _parseSeconds(step.at);
      _timers.add(
        Timer(Duration(seconds: at), () {
          if (!mounted) return;
          _scene.apply(step);
        }),
      );
    }

    // Pre-glide the hand to each `pointer-touch` target so the poke +
    // sparkle + narration land in sync at the touch moment. The first
    // touch is arranged by the upstream `pointer-appear` step (or starts
    // mid-screen if there isn't one); we only need 2nd onward.
    final touches = runtime.iShow.animationSteps
        .where((s) => s.action == 'pointer-touch')
        .toList();
    for (var i = 1; i < touches.length; i++) {
      final touch = touches[i];
      final targetId = LessonScene.resolveTargetId(touch.params['target']);
      if (targetId == null) continue;
      final touchAtMs = _parseSeconds(touch.at) * 1000;
      final preGlideAtMs = touchAtMs - handPointerGlideDuration.inMilliseconds;
      if (preGlideAtMs <= 0) continue;
      _timers.add(
        Timer(Duration(milliseconds: preGlideAtMs), () {
          if (!mounted) return;
          _scene.aimAt(targetId);
        }),
      );
    }

    final skipAt = runtime.iShow.skipAvailableAfterSec;
    if (skipAt > 0) {
      _timers.add(
        Timer(Duration(seconds: skipAt), () {
          if (!mounted) return;
          setState(() => _skipEnabled = true);
        }),
      );
    }
    _timers.add(
      Timer(Duration(seconds: runtime.iShow.durationSec), () {
        if (!mounted) return;
        setState(() => _continueEnabled = true);
      }),
    );
  }

  int _parseSeconds(String at) {
    final trimmed = at.endsWith('s') ? at.substring(0, at.length - 1) : at;
    return int.tryParse(trimmed) ?? 0;
  }

  // ==========================================================================
  // We-Try - the middle third
  // ==========================================================================
  //
  // The phase cannot be failed. Every lesson's `passCondition` says so in its
  // own words ("any tap passes", "even one drag is enough; system completes
  // the rest"), so her touch is never graded: it chooses which of two warm
  // lines she hears, and the demonstration carries on either way. What the
  // phase is actually for is the touch itself - an I-Show she watched and a
  // You-Do she is graded on, with nothing in between, is the gap this closes.
  //
  // Two rules that are not in the authored data, both there to keep the screen
  // from ever going quiet on her:
  //
  //   * No beat starts before the previous line has finished speaking.
  //     `NarrationPlayer.enqueue` holds two and silently drops the rest, so a
  //     run of narration beats 0.5s apart would lose most of itself - and the
  //     lines it loses are the ones answering what she just did.
  //   * A gate always resolves. The authored hesitation rule re-lights the
  //     target at 5s, and whether or not it says `auto-complete`, the step
  //     completes itself at twice that. "Highlight and keep waiting" has no
  //     floor, and a five-year-old who has decided not to touch this one is
  //     owed the rest of her lesson anyway.

  void _startWeTry(LessonRuntime runtime) {
    setState(() {
      _phase = _LessonPhase.weTry;
      _continueEnabled = false;
      _skipEnabled = false;
      _weTryCursor = 0;
      _weTryLastPassed = true;
      _weTryUrgent = false;
      _weTryGate = null;
      _weTryWaiting = false;
    });
    _scene.resetForWeTry(runtime.weTry);
    _runWeTryBeat();
  }

  /// Runs the beat at the cursor, then schedules the next.
  void _runWeTryBeat() {
    if (!mounted || _phase != _LessonPhase.weTry) return;
    final script = _runtime?.weTry.script;
    if (script == null) return;

    // Skip beats belonging to the outcome the last gate did not have.
    while (_weTryCursor < script.beats.length) {
      final candidate = script.beats[_weTryCursor];
      final matches = switch (candidate.when) {
        WeTryWhen.always => true,
        WeTryWhen.onPass => _weTryLastPassed,
        WeTryWhen.onFail => !_weTryLastPassed,
      };
      if (matches) break;
      _weTryCursor++;
    }
    if (_weTryCursor >= script.beats.length) {
      _finishWeTry();
      return;
    }

    final beat = script.beats[_weTryCursor++];
    var settle = Duration.zero;

    switch (beat) {
      case WeTryEnd():
        _finishWeTry();
        return;
      case WeTryGate():
        _openWeTryGate(beat);
        return;
      case WeTrySay():
        ref.narration.say(beat.text, cueId: 'wetry:${beat.cueId}');
        settle = narrationSpokenEstimate(beat.text);
      case WeTryDo():
        _applyWeTryAction(beat);
    }
    _scheduleNextWeTryBeat(settle);
  }

  /// The next beat waits for its authored gap or for the current line to
  /// finish, whichever is longer.
  void _scheduleNextWeTryBeat(Duration settle) {
    final script = _runtime!.weTry.script;
    final next = script.beats.length > _weTryCursor
        ? script.beats[_weTryCursor].delay
        : Duration.zero;
    _weTryBeatTimer?.cancel();
    _weTryBeatTimer = Timer(next > settle ? next : settle, _runWeTryBeat);
  }

  /// Scene changes during We-Try. Halo actions are handled here because the
  /// halo is this phase's own affordance; everything else goes to the same
  /// applier the I-Show uses, so a lesson does not have to author its scene
  /// twice to have it move in both phases.
  void _applyWeTryAction(WeTryDo beat) {
    final named = <String>[
      if (beat.params['target'] is String) beat.params['target'] as String,
      for (final t in beat.params['targets'] as List<dynamic>? ?? const [])
        if (t is String) t,
    ];
    if (beat.action.startsWith('halo')) {
      // `halo-pulse-next-vertex` and friends name no target: "next" is
      // whatever is still missing. Resolving that here rather than making the
      // content spell it out keeps the choreography readable and, more to the
      // point, keeps it correct after she has placed a piece in an order the
      // author did not predict.
      _scene.halo(
        named.isNotEmpty ? named : _scene.nextUnplacedFramePiece(beat.action),
      );
      return;
    }
    // `pointer-auto-*` is the system finishing what she started - the content
    // asks for it by name in nine lessons ("system completes the rest"). The
    // halo comes off with it: nothing is being asked of her while it runs.
    //
    // It has to be something she can *watch*. This used to light every named
    // target at once, in one frame, with no hand and without honouring the
    // `spacingSec` the content asks for - so from the player's side two fawns
    // she had been told to touch lit up by themselves and the lesson moved
    // on. That was the first thing reported from a real session, and the word
    // for it was "jarring". The demonstrator's hand is already how this game
    // says "watch me" - the I-Show uses it for exactly this - so the takeover
    // uses it too, one target at a time, at the authored pace.
    if (beat.action.startsWith('pointer-auto')) {
      _scene.autoCompleteFrame(beat.action);
      _walkTheHand(named, beat.params);
      return;
    }
    if (beat.action == 'frame-solidify') {
      _scene.completeFrame();
      return;
    }
    _scene.apply(
      AnimationStep(at: '0s', action: beat.action, params: beat.params),
    );
  }

  /// Touch each of [targets] in turn, with the hand visible, at the pace the
  /// content asked for.
  ///
  /// Nothing here waits on her, so it schedules rather than gating: the beat
  /// after this one is already timed off the narration, and a walk that ran
  /// longer than its own line would collide with it. Anything past the time
  /// the content allowed is dropped rather than rushed - which is why the
  /// spacing is clamped rather than trusted.
  void _walkTheHand(List<String> targets, Map<String, dynamic> params) {
    _cancelWeTryDemo();
    if (targets.isEmpty) return;
    final spacing = Duration(
      milliseconds: (((params['spacingSec'] as num?)?.toDouble() ?? 0.9) * 1000)
          .round()
          .clamp(400, 2000),
    );
    for (var i = 0; i < targets.length; i++) {
      final id = targets[i];
      // Reach for it, then touch it. Two beats rather than one because the
      // hand animates between the two positions, and the movement is the part
      // that reads as somebody doing it.
      _weTryDemoTimers.add(
        Timer(spacing * i, () {
          if (mounted) _scene.reachFor(id);
        }),
      );
      _weTryDemoTimers.add(
        Timer(spacing * i + spacing * 0.55, () {
          if (mounted) _scene.touch(id);
        }),
      );
    }
    _weTryDemoTimers.add(
      Timer(spacing * targets.length, () {
        if (mounted) _scene.handAway();
      }),
    );
  }

  void _cancelWeTryDemo() {
    for (final t in _weTryDemoTimers) {
      t.cancel();
    }
    _weTryDemoTimers.clear();
  }

  void _openWeTryGate(WeTryGate gate) {
    setState(() {
      _weTryGate = gate;
      _weTryWaiting = true;
      _weTryUrgent = false;
    });
    if (gate.targets.isNotEmpty) _scene.halo(gate.targets);
    // The same three rungs as everywhere else: `adaptive-scaffolding.md` says
    // highlight, then a word, then demonstration, and `HintLadder` runs that
    // ladder in every round. The We-Try used to do something different and
    // much sharper - the `auto-complete` rule resolved the gate outright at
    // the threshold, so five seconds of a five-year-old looking at the screen
    // ended her turn without a word and without anything visibly happening.
    // Five seconds is a long time to an adult watching and no time at all to
    // a child deciding which fawn is the first one.
    //
    // What the rule's two spellings now choose is what the *last* rung does:
    // `auto-complete` finishes the step with the hand, `highlight-target`
    // resolves it quietly and moves the halo on. Neither of them fires before
    // she has had the highlight and the nudge.
    final rule = _runtime!.weTry.script.hesitation;
    _weTryHesitationTimer?.cancel();
    _weTryHesitationTimer = Timer(rule.after, () {
      if (!mounted || !_weTryWaiting) return;
      setState(() => _weTryUrgent = true);
    });
    _weTryNudgeTimer?.cancel();
    _weTryNudgeTimer = Timer(rule.after * 2, () {
      if (!mounted || !_weTryWaiting) return;
      ref.read(feedbackEngineProvider).hint();
      ref.narration.say(warmHintLine(2), cueId: 'we-try:hesitation-nudge');
    });
    _weTryRescueTimer?.cancel();
    _weTryRescueTimer = Timer(rule.after * 3, () {
      if (!mounted || !_weTryWaiting) return;
      final gate = _weTryGate;
      if (rule.autoCompletes && gate != null) {
        _walkTheHand(_weTryTargets(gate).take(1).toList(), const {});
      }
      _resolveWeTryGate(passed: true, byHer: false);
    });
  }

  /// What her touch was about.
  ///
  /// Most gates name a target. The habitat ones name only a gesture
  /// ("drag-clay-to-vertex", any vertex acceptable) because the author did not
  /// want to fix an order - so the thing she was asked about is the thing that
  /// was lit when she was asked. Reading it off the halo also keeps the two in
  /// step by construction: she cannot be told she missed something the screen
  /// never showed her.
  List<String> _weTryTargets(WeTryGate gate) =>
      gate.targets.isNotEmpty ? gate.targets : _scene.haloed.toList();

  /// A touch anywhere on the stage while a gate is open.
  void _onWeTryTouch(Offset globalPosition) {
    final gate = _weTryGate;
    if (!_weTryWaiting || gate == null) return;
    _resolveWeTryGate(
      passed: _targets.hits(_weTryTargets(gate), globalPosition),
      byHer: true,
    );
  }

  void _resolveWeTryGate({required bool passed, required bool byHer}) {
    final gate = _weTryGate;
    if (gate == null) return;
    _weTryHesitationTimer?.cancel();
    _weTryNudgeTimer?.cancel();
    _weTryRescueTimer?.cancel();
    final settling = _weTryTargets(gate);
    setState(() {
      _weTryWaiting = false;
      _weTryGate = null;
      _weTryUrgent = false;
      _weTryLastPassed = passed;
    });
    _scene.settleGate(settling, byHer: byHer);

    if (byHer) {
      // The same warm pop whether or not she landed on the target, and never
      // `FeedbackEngine.wrong()`. A touch that went somewhere else is not a
      // wrong answer here - the phase has none - and answering it with the
      // sound the You-Do uses for a miss would teach her it was one. The
      // corrective line is the correction, and it names the right place
      // rather than asking her again.
      ref.read(feedbackEngineProvider).correct();
    }

    var settle = Duration.zero;
    // Falling back across the pair rather than saying nothing. Several lessons
    // author only a passCue, because their passCondition has no failure in it
    // ("any drag onto a valid target passes") - and a beat that answers her
    // touch with silence is the exact thing this phase exists to stop.
    final line = passed
        ? (gate.passText ?? gate.failText)
        : (gate.failText ?? gate.passText);
    if (line != null) {
      ref.narration.say(line, cueId: 'wetry:gate');
      settle = narrationSpokenEstimate(line);
    }
    _scheduleNextWeTryBeat(settle);
  }

  void _finishWeTry() {
    _weTryBeatTimer?.cancel();
    _weTryHesitationTimer?.cancel();
    _weTryNudgeTimer?.cancel();
    _weTryRescueTimer?.cancel();
    _cancelWeTryDemo();
    _goToYouDo();
  }

  /// Lessons whose body already contains its own guided practice, and which
  /// must therefore not also run the generic We-Try.
  ///
  /// K.G.4 has a hand-built one - `kg4_sort_by_attribute_lesson_layer.dart`
  /// is literally `enum _Beat { iShow, weTry, done }`, halo on the target bin,
  /// auto-complete on hesitation. K.G.3 ends each pairing with a sort round
  /// the kid plays, and K.G.2 runs nine intro-then-find rounds. Handing any of
  /// the three a second practice beat would ask her to do the same thing twice
  /// in a row and, for K.G.2, would do it after the celebration.
  ///
  /// `lesson_wetry_test.dart` pins this set in both directions: a lesson in it
  /// must have its own interactive body, and every lesson out of it must reach
  /// the generic phase.
  static const Set<String> _bespokePracticeConcepts = {
    'K.G.2',
    'K.G.3',
    'K.G.4',
  };

  /// End of the demonstration. Her turn, unless this lesson does its own.
  void _afterIShow() {
    final runtime = _runtime;
    if (runtime == null) return;
    if (_bespokePracticeConcepts.contains(runtime.conceptId) ||
        !runtime.weTry.script.hasGate) {
      _goToYouDo();
      return;
    }
    _startWeTry(runtime);
  }

  void _goToYouDo() {
    final runtime = _runtime;
    if (runtime == null) return;
    ref.narration.clear();
    final subMode = widget.subModeOverride ?? runtime.youDo.subMode;
    context.goActivity(
      runtime.youDo.activityId,
      ActivityLaunch(
        subModeId: subMode,
        fromLessonId: widget.lessonId,
        roundParameters: runtime.youDo.roundParameters,
      ),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _weTryBeatTimer?.cancel();
    _weTryHesitationTimer?.cancel();
    _weTryNudgeTimer?.cancel();
    _weTryRescueTimer?.cancel();
    _cancelWeTryDemo();
    // Only if it was actually claimed. The claim happens from build(), once a
    // runtime has loaded, so a lesson closed before that never took one — and
    // SfxEngine counts claims, so releasing without claiming would give away
    // the next screen's music instead.
    if (_musicClaimed) _sfxForDispose?.releaseMusicBed();
    _scene.dispose();
    super.dispose();
  }

  /// Background asset chosen per concept. Shape Garden gets the garden art;
  /// Counting Parade (default) keeps the meadow.
  String _backgroundAsset(LessonRuntime? runtime) {
    switch (runtime?.conceptId) {
      case 'K.G.2':
      case 'K.G.3':
      case 'K.G.4':
        return AssetPaths.shapeGardenBackground;
      default:
        return AssetPaths.countingParadeMeadow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundAsset(_runtime),
            fit: BoxFit.cover,
          ),
          FutureBuilder<LessonRuntime>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white70,
                    child: Text('Lesson load failed: ${snap.error}'),
                  ),
                );
              }
              final runtime = snap.requireData;
              _runtime ??= runtime;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _claimMusicOnce(runtime);
                _speakKeeperIntroOnce(runtime);
              });

              if (_phase == _LessonPhase.keeperIntro) {
                return KeeperIntroOverlay(
                  dialog: _keeperIntroDialog(runtime),
                  startLabel: _keeperIntroStartLabel(runtime),
                  startButtonKey: const ValueKey('lesson-keeper-start-button'),
                  onStart: _onKeeperStartPressed,
                );
              }

              if (_phase == _LessonPhase.shapeIntro &&
                  _currentShapeIdx < kShapeIntroSequence.length) {
                final kind = kShapeIntroSequence[_currentShapeIdx];
                return ShapeIntroLayer(
                  key: ValueKey('shape-intro-$kind'),
                  shapeKind: kind,
                  onComplete: _onShapeIntroComplete,
                );
              }

              if (_phase == _LessonPhase.shapeFindDemo &&
                  _currentShapeIdx < kShapeIntroSequence.length) {
                final kind = kShapeIntroSequence[_currentShapeIdx];
                return ShapeFindDemo(
                  key: ValueKey('shape-find-demo-$kind'),
                  targetKind: kind,
                  onComplete: _onShapeFindDemoComplete,
                );
              }

              if (_phase == _LessonPhase.shapeFindRound &&
                  _currentShapeIdx < kShapeIntroSequence.length) {
                final kind = kShapeIntroSequence[_currentShapeIdx];
                final previousKinds =
                    kShapeIntroSequence.sublist(0, _currentShapeIdx);
                return ShapeFindRound(
                  key: ValueKey('shape-find-$kind'),
                  targetKind: kind,
                  previousKinds: previousKinds,
                  onComplete: _onShapeFindRoundComplete,
                );
              }

              if (_phase == _LessonPhase.shapesDone) {
                return const ShapesDoneCelebration();
              }

              if (_phase == _LessonPhase.flatOrSolidLesson) {
                return Kg3FlatOrSolidLessonLayer(
                  key: const ValueKey('kg3-flat-or-solid-layer'),
                  onComplete: _onFlatOrSolidLessonComplete,
                );
              }

              if (_phase == _LessonPhase.sortByAttributeLesson) {
                return Kg4SortByAttributeLessonLayer(
                  key: const ValueKey('kg4-sort-by-attribute-layer'),
                  onComplete: _onSortByAttributeLessonComplete,
                );
              }

              // Fawn / iShow path — K.CC.4a-style lessons.
              switch (runtime.conceptId) {
                case 'K.CC.1':
                  return LessonClusterStage(
                    badgeValue: _scene.badgeValue,
                    targets: _targets,
                  );
                case 'K.CC.2':
                  return LessonCountOnStage(
                    badgeValue: _scene.badgeValue,
                    targets: _targets,
                  );
                case 'K.G.5':
                case 'K.G.6':
                  return HabitatLessonStage(
                    blueprint: kHabitatBlueprints[0],
                    // K.G.6 opens on the frame the kid just laid in K.G.5 -
                    // "the frame is the base, we add shapes on top" - so its
                    // sticks and clay start down rather than as ghosts.
                    placedCorners: runtime.conceptId == 'K.G.6' &&
                            _phase != _LessonPhase.weTry
                        ? <int>{0, 1, 2}
                        : _scene.placedCorners,
                    placedEdges: runtime.conceptId == 'K.G.6' &&
                            _phase != _LessonPhase.weTry
                        ? <int>{0, 1, 2}
                        : _scene.placedEdges,
                    placedRoof: _scene.placedRoof,
                    showRoof: _phase == _LessonPhase.weTry
                        ? runtime.weTry.showsRoof
                        : runtime.conceptId == 'K.G.6',
                    carrying: _scene.carrying,
                    handVisible: _scene.handVisible,
                    pointerTarget: _scene.handTarget,
                    fawnHome: _scene.fawnHome,
                    targets: _targets,
                  );
                case 'K.G.1':
                  return ClearingLessonStage(
                    landmarkIds: _phase == _LessonPhase.weTry
                        ? runtime.weTry.landmarkIds
                        : runtime.iShow.landmarkIds,
                    facingLandmarkId: _scene.facingLandmarkId,
                    spot: _scene.buddySpot,
                    pointerVisible: _scene.pointerVisible,
                    targets: _targets,
                    zoneIds:
                        _phase == _LessonPhase.weTry ? _scene.haloed : const {},
                  );
              }
              // Anything that reaches here draws three fawns in a meadow, and
              // that is right for exactly the counting lessons it was built
              // for. `lesson_scene_test.dart` holds the line: a lesson whose
              // scene is not made of creatures must not land here.
              return LessonFawnStage(
                sparkled: _scene.sparkled,
                badgeValue: _scene.badgeValue,
                pointerVisible: _scene.pointerVisible,
                pointerTargetId: _scene.pointerTargetId,
                handAtTarget: _scene.handAtTarget,
                pokeCounter: _scene.pokeCounter,
                burstCounters: _scene.burstCounters,
                count: _phase == _LessonPhase.weTry
                    ? runtime.weTry.creatureCount
                    : runtime.iShow.creatureCount,
                targets: _targets,
              );
            },
          ),
          // Her turn. Above every stage so all five families get the same
          // affordance from one widget, and below the captions and the
          // back-out button so neither is ever swallowed by the gate.
          if (_phase == _LessonPhase.weTry)
            Positioned.fill(
              child: WeTryHaloLayer(
                key: const ValueKey('we-try-layer'),
                registry: _targets,
                targets: _scene.haloed,
                urgent: _weTryUrgent,
                onTouch: _weTryWaiting ? _onWeTryTouch : null,
              ),
            ),
          const CaptionOverlay(),
          // Persistent back-to-Sanctuary affordance — kids can bail from
          // any phase.
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: RoundBackButton(
                onPressed: () {
                  ref.narration.clear();
                  context.go(Routes.sanctuary);
                },
              ),
            ),
          ),
          if (_phase == _LessonPhase.iShow && _skipEnabled && !_continueEnabled)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: LessonPillButton(
                  onPressed: _goToYouDo,
                  label: kLabelIveGotThis,
                ),
              ),
            ),
          if ((_phase == _LessonPhase.iShow ||
                  _phase == _LessonPhase.shapesDone) &&
              _continueEnabled)
            Positioned(
              right: 32,
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: Center(
                  child: NextArrowButton(
                    key: const ValueKey('lesson-continue-arrow'),
                    idleHintEnabled: true,
                    onPressed:
                        _phase == _LessonPhase.iShow ? _afterIShow : _goToYouDo,
                    label: kLabelContinue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
