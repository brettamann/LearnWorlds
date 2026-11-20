// BuildAHabitatRunner — K.G.5 ("model and create shapes from
// components") + K.G.6 ("compose simple shapes to form larger shapes")
// — combined into a single intra-round lesson chain per the design
// registry (`intraRoundLessonChain.enabled = true`).
//
// Each round walks through one blueprint:
//
//   Phase 1 — Sticks & Clay (K.G.5):
//     • Glowing corner indicators ask the kid to tap to place a
//       clay ball at each vertex.
//     • Glowing edge indicators ask the kid to tap to lay a stick
//       between two corners.
//     • The frame solidifies once every corner + edge is filled.
//
//   Phase 2 — Raise the Habitat (K.G.6):
//     • Ghost outlines of 3D pieces appear on top of the frame.
//     • The kid taps each ghost to drop the matching 3D piece in
//       place; the resident creature walks in.
//
// Sub-modes (registry):
//   simple-shelter (default) → triangle + 1 cube roof piece
//   creature-home            → square + 3 roof pieces
//   grand-habitat (challenge)→ pentagon + 3 roof pieces
//   frame-only (demotion)    → Phase 1 only, skip K.G.6
//
// Each round resolves through RoundCoordinator twice: once with
// K.G.5 when Phase 1 finishes, once with K.G.6 when Phase 2 finishes.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activities/activity_ids.dart';
import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/build_a_habitat_blueprints.dart';
import '../../data/button_labels.dart';
import '../../data/habitat_words.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../platform/sfx_engine.dart';
import 'buddy_companion.dart';
import 'continue_arrow_shelf.dart';
import 'glitter_burst.dart';
import 'keeper_aside.dart';
import 'keeper_intro_overlay.dart';
import 'next_arrow_button.dart';
import 'playfield_scaffold.dart';
import 'replay_demo_button.dart';
import 'touch_here_halo.dart';
import 'touch_target.dart';

const String kBuildAHabitatSubModeSimpleShelter = 'simple-shelter';
const String kBuildAHabitatSubModeCreatureHome = 'creature-home';
const String kBuildAHabitatSubModeGrandHabitat = 'grand-habitat';
const String kBuildAHabitatSubModeFrameOnly = 'frame-only';

enum _Phase {
  intro,
  cornersAndSticks,
  raiseHabitat,

  /// Keeper speaks over the finished habitat and advances the round
  /// herself. No tap required.
  transition,

  celebrating,

  /// Final beat only — the reward payoff, which is meant to interrupt.
  interstitial,
}

class BuildAHabitatRunner extends ConsumerStatefulWidget {
  const BuildAHabitatRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
    this.subMode = kBuildAHabitatSubModeSimpleShelter,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;
  final String subMode;

  @override
  ConsumerState<BuildAHabitatRunner> createState() =>
      _BuildAHabitatRunnerState();
}

class _BuildAHabitatRunnerState extends ConsumerState<BuildAHabitatRunner> {
  late _Phase _phase =
      widget.skipIntro ? _Phase.cornersAndSticks : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Set<int> _placedCorners = <int>{};
  Set<int> _placedEdges = <int>{};
  Set<int> _placedRoof = <int>{};
  Timer? _celebrationTimer;
  Timer? _interstitialTimer;

  /// Bumped to (re)present the between-round keeper aside.
  int _asideToken = 0;

  /// Sticks laid before both endpoints had clay. This is the wrong answer
  /// K.G.5 actually cares about — the whole point is corners first, sides
  /// between — and until now it produced a spoken line and nothing else.
  int _outOfOrderTaps = 0;
  int _missRotation = 0;

  /// The one piece the hint ladder is pointing at, as ('corner'|'edge'|
  /// 'roof', index). Null while she is getting on with it.
  (String, int)? _hinted;

  HintLadder? _hints;

  /// Read eagerly — `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfxForDispose;

  /// One blueprint per round. Each sub-mode picks a slice of the
  /// blueprint list: `simple-shelter` runs the triangle; `creature-home`
  /// runs all three; `grand-habitat` runs the pentagon; `frame-only`
  /// runs the triangle but skips Phase 2.
  List<HabitatBlueprint> get _rounds {
    switch (widget.subMode) {
      case kBuildAHabitatSubModeCreatureHome:
        return kHabitatBlueprints;
      case kBuildAHabitatSubModeGrandHabitat:
        return <HabitatBlueprint>[kHabitatBlueprints[2]];
      case kBuildAHabitatSubModeFrameOnly:
      case kBuildAHabitatSubModeSimpleShelter:
      default:
        return <HabitatBlueprint>[kHabitatBlueprints[0]];
    }
  }

  bool get _skipRaisePhase => widget.subMode == kBuildAHabitatSubModeFrameOnly;

  HabitatBlueprint get _currentRound => _rounds[_roundIndex];
  bool get _isLastRound => _roundIndex == _rounds.length - 1;
  double get _progress => _completedRounds / _rounds.length;

  bool get _allCornersPlaced =>
      _placedCorners.length == _currentRound.corners.length;
  bool get _allEdgesPlaced => _placedEdges.length == _currentRound.edges.length;
  bool get _frameDone => _allCornersPlaced && _allEdgesPlaced;
  bool get _allRoofPlaced => _placedRoof.length == _currentRound.roof.length;

  String get _introDialog =>
      "Let's build a habitat together! Clay balls go in the corners, "
      'sticks go along the sides — then we add shapes on top to make '
      "the roof. Ready? Let's start.";

  String get _phase1Prompt => habitatBuildPrompt(_currentRound.id);

  String get _phase2Prompt =>
      'Now raise the habitat — tap each ghost shape to drop the '
      'matching piece in place.';

  String get _finalKeeperLine =>
      'Every habitat is built! The Sanctuary feels cosy and safe.';

  @override
  void initState() {
    super.initState();
    _sfxForDispose = ref.read(sfxEngineProvider);
    // Claimed here, not in the post-frame callback below: the release in
    // dispose() is unconditional, so the claim has to be too, or a teardown
    // before the first frame gives back a claim it never took. See
    // SfxEngine.releaseMusicBed for what that costs.
    unawaited(_sfxForDispose!.startMusicBed(kDefaultMusicBed));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedbackEngineProvider).resetRound();
      if (_phase == _Phase.cornersAndSticks) {
        _speakPhase1Prompt();
        _startHints();
      }
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    _celebrationTimer?.cancel();
    _interstitialTimer?.cancel();
    final sfx = _sfxForDispose;
    if (sfx != null) sfx.releaseMusicBed();
    super.dispose();
  }

  void _speakPhase1Prompt() {
    ref.narration
        .say(_phase1Prompt, cueId: 'habitat:r$_roundIndex:phase1-prompt');
  }

  void _speakPhase2Prompt() {
    ref.narration
        .say(_phase2Prompt, cueId: 'habitat:r$_roundIndex:phase2-prompt');
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.cornersAndSticks);
    _speakPhase1Prompt();
    _startHints();
  }

  void _startHints() {
    _hints?.dispose();
    _hints = HintLadder(onLevel: _onHintLevel)..start();
  }

  /// Escalating help for a stalled builder.
  ///
  /// The instruction here is three sentences long - clay in the corners,
  /// sticks along the sides, then shapes on top - spoken once, to a child who
  /// cannot read the replay button. Losing the thread is the expected case,
  /// not the unlucky one, and until this existed losing it meant sitting in
  /// front of a shelter that never got built.
  ///
  /// The ring goes on exactly one piece, and always the next legal one: every
  /// empty corner and every empty side already wears a ghost outline, so
  /// "everything is glowing" is the state she is stuck in. The hint is which.
  void _onHintLevel(HintLevel level) {
    if (!mounted) return;
    if (_phase != _Phase.cornersAndSticks && _phase != _Phase.raiseHabitat) {
      return;
    }
    final next = _nextPiece();
    if (next == null) return;
    final feedback = ref.read(feedbackEngineProvider);
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _hinted = next);
      case HintLevel.point:
        setState(() => _hinted = next);
        feedback.hint();
        ref.narration
            .say(warmHintLine(2), cueId: 'habitat:r$_roundIndex:hint-point');
      case HintLevel.demonstrate:
        feedback.hint();
        ref.narration
            .say(warmHintLine(3), cueId: 'habitat:r$_roundIndex:hint-demo');
        final (kind, index) = next;
        switch (kind) {
          case 'corner':
            _onCornerTap(index, fromHint: true);
          case 'edge':
            _onEdgeTap(index, fromHint: true);
          default:
            _onRoofTap(index, fromHint: true);
        }
    }
  }

  /// The next piece she could legally place, in the order the standard cares
  /// about: corners before the sides between them.
  (String, int)? _nextPiece() {
    if (_phase == _Phase.cornersAndSticks) {
      for (var i = 0; i < _currentRound.corners.length; i++) {
        if (!_placedCorners.contains(i)) return ('corner', i);
      }
      for (var i = 0; i < _currentRound.edges.length; i++) {
        if (_placedEdges.contains(i)) continue;
        final e = _currentRound.edges[i];
        if (_placedCorners.contains(e[0]) && _placedCorners.contains(e[1])) {
          return ('edge', i);
        }
      }
      return null;
    }
    for (var i = 0; i < _currentRound.roof.length; i++) {
      if (!_placedRoof.contains(i)) return ('roof', i);
    }
    return null;
  }

  void _onCornerTap(int idx, {bool fromHint = false}) {
    if (_placedCorners.contains(idx)) return;
    if (!fromHint) _hints?.poke();
    setState(() {
      _placedCorners.add(idx);
      _hinted = null;
    });
    // Corners climb the scale, so a triangle's three corners sound like
    // three and a pentagon's five sound like five — the count is the
    // difference between the blueprints.
    ref.read(feedbackEngineProvider).countStep(_placedCorners.length);
    _speak(
      'Clay corner.',
      'habitat:r$_roundIndex:corner-${_placedCorners.length}',
      fromHint: fromHint,
    );
  }

  void _onEdgeTap(int idx, {bool fromHint = false}) {
    if (_placedEdges.contains(idx)) return;
    if (!fromHint) _hints?.poke();
    // Sticks can only be placed once both endpoints have clay balls —
    // K.G.5's pedagogy depends on "corners first, then sides between."
    final endpoints = _currentRound.edges[idx];
    final bothClayed = _placedCorners.contains(endpoints[0]) &&
        _placedCorners.contains(endpoints[1]);
    if (!bothClayed) {
      setState(() {
        _outOfOrderTaps += 1;
        _missRotation += 1;
      });
      ref.read(feedbackEngineProvider).wrong();
      _speak(
        _missRotation.isOdd
            ? 'Place clay in both corners first, then the stick.'
            : 'A stick needs a corner at each end. Clay first.',
        'habitat:r$_roundIndex:edge-block-$idx-$_outOfOrderTaps',
      );
      return;
    }
    setState(() {
      _placedEdges.add(idx);
      _hinted = null;
    });
    // Two sounds, in this order: the thing landing, then the answer being
    // right. `Sfx.drop` had no call site at all, so three of the game's
    // mechanics are drags in which nothing was ever heard to be put down.
    ref.read(feedbackEngineProvider)
      ..drop()
      ..correct();
    _speak(
      'Stick.',
      'habitat:r$_roundIndex:edge-${_placedEdges.length}',
      fromHint: fromHint,
    );
    if (_frameDone) _finishPhase1();
  }

  void _finishPhase1() {
    // Three sticks laid before their corners means she is not building the
    // frame in order, which is the K.G.5 idea itself.
    final hintsUsed = _hints?.hintsUsed ?? 0;
    final result = gradeRound(misses: _outOfOrderTaps, helped: hintsUsed > 0);
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: ActivityIds.buildAHabitat,
          conceptId: 'K.G.5',
          result: result,
        );
    if (_skipRaisePhase) {
      // Frame-only: skip K.G.6 and go to the interstitial directly.
      _enterInterstitial();
      return;
    }
    setState(() => _phase = _Phase.raiseHabitat);
    _speakPhase2Prompt();
    // A fresh ladder, not a poke: the two phases resolve separate concepts
    // (K.G.5 the frame, K.G.6 the roof), so help taken on one must not be
    // charged to the other.
    _startHints();
  }

  void _onRoofTap(int idx, {bool fromHint = false}) {
    if (_placedRoof.contains(idx)) return;
    if (!fromHint) _hints?.poke();
    final piece = _currentRound.roof[idx];
    setState(() {
      _placedRoof.add(idx);
      _hinted = null;
    });
    // Two sounds, in this order: the thing landing, then the answer being
    // right. `Sfx.drop` had no call site at all, so three of the game's
    // mechanics are drags in which nothing was ever heard to be put down.
    ref.read(feedbackEngineProvider)
      ..drop()
      ..correct();
    _speak(
      'A ${piece.kind}. It goes on top.',
      'habitat:r$_roundIndex:roof-${_placedRoof.length}',
      fromHint: fromHint,
    );
    if (_allRoofPlaced) _finishPhase2();
  }

  void _finishPhase2() {
    // Every ghost is a correct target — there is nothing wrong to tap in
    // this phase — so the only thing that can make it less than clean is the
    // game having placed a piece for her.
    _hints?.pause();
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: ActivityIds.buildAHabitat,
          conceptId: 'K.G.6',
          result: gradeRound(helped: (_hints?.hintsUsed ?? 0) > 0),
        );
    _enterInterstitial();
  }

  void _enterInterstitial() {
    setState(() => _phase = _Phase.celebrating);
    final feedback = ref.read(feedbackEngineProvider);
    if (_isLastRound) {
      feedback.celebrate();
    } else {
      feedback.roundPass();
    }
    _celebrationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _completedRounds += 1;
        _phase = _isLastRound ? _Phase.interstitial : _Phase.transition;
        if (!_isLastRound) _asideToken += 1;
      });
      final line = _isLastRound ? _finalKeeperLine : _currentRound.keeperLine;
      ref.narration.say(
        line,
        cueId: 'habitat:r$_roundIndex:interstitial',
        speaker: kKeeperSpeaker,
        caption: false,
      );
    });
  }

  /// Fired by the keeper aside retiring itself, not by a button.
  void _advanceToNextRound() {
    if (!mounted || _phase != _Phase.transition) return;
    setState(() {
      _roundIndex += 1;
      _placedCorners = <int>{};
      _placedEdges = <int>{};
      _placedRoof = <int>{};
      _outOfOrderTaps = 0;
      _missRotation = 0;
      _hinted = null;
      _phase = _Phase.cornersAndSticks;
    });
    ref.read(feedbackEngineProvider).resetRound();
    _speakPhase1Prompt();
    _startHints();
  }

  void _speak(String text, String cueId, {bool fromHint = false}) {
    // Queued, not spoken, when the ladder placed this piece. See HintLadder.
    final say = ref.narration;
    final line = NarrationLine(text: text, cueId: cueId);
    if (fromHint) {
      say.enqueue(line);
    } else {
      say.speak(line);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: "Let's build!",
          startButtonKey: const ValueKey('habitat-start-button'),
          onStart: _onStartFromIntro,
        ),
      _Phase.cornersAndSticks ||
      _Phase.raiseHabitat ||
      _Phase.celebrating ||
      _Phase.transition =>
        _BuildLayer(
          blueprint: _currentRound,
          placedCorners: _placedCorners,
          placedEdges: _placedEdges,
          placedRoof: _placedRoof,
          showRoof: _phase != _Phase.cornersAndSticks,
          hinted: _hinted,
          inputLocked:
              _phase == _Phase.celebrating || _phase == _Phase.transition,
          onCornerTap: _onCornerTap,
          onEdgeTap: _onEdgeTap,
          onRoofTap: _onRoofTap,
          replayPrompt:
              _phase == _Phase.cornersAndSticks ? _phase1Prompt : _phase2Prompt,
          replayCueId: 'habitat:replay-r$_roundIndex-${_phase.name}',
          allDone: _phase == _Phase.celebrating,
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _finalKeeperLine,
          startLabel: 'Continue',
          startButtonKey: const ValueKey('habitat-interstitial-next'),
          onStart: widget.onSequenceComplete,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AssetPaths.buildAHabitatBackground, fit: BoxFit.cover),
        PlayfieldScaffold(
          progress: _progress,
          celebrate: _phase == _Phase.celebrating,
          child: phaseContent,
        ),
        if (_phase != _Phase.intro && _phase != _Phase.interstitial)
          const BuddyCompanionCorner(),
        if (_phase == _Phase.transition)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: KeeperAside(
              text: _currentRound.keeperLine,
              token: _asideToken,
              onDismissed: _advanceToNextRound,
            ),
          ),
      ],
    );
  }
}

class _BuildLayer extends StatelessWidget {
  const _BuildLayer({
    required this.blueprint,
    required this.placedCorners,
    required this.placedEdges,
    required this.placedRoof,
    required this.showRoof,
    required this.hinted,
    required this.inputLocked,
    required this.onCornerTap,
    required this.onEdgeTap,
    required this.onRoofTap,
    required this.replayPrompt,
    required this.replayCueId,
    required this.allDone,
  });

  final HabitatBlueprint blueprint;
  final Set<int> placedCorners;
  final Set<int> placedEdges;
  final Set<int> placedRoof;
  final bool showRoof;

  /// The single piece the hint ladder is ringing, if any.
  final (String, int)? hinted;

  final bool inputLocked;
  final ValueChanged<int> onCornerTap;
  final ValueChanged<int> onEdgeTap;
  final ValueChanged<int> onRoofTap;
  final String replayPrompt;
  final String replayCueId;
  final bool allDone;

  static const double _kClayDiameterFraction = 0.10;
  static const double _kStickThicknessFraction = 0.045;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            kReplayDemoShelf(
              child: ReplayDemoButton(
                label: replayPrompt,
                cueId: replayCueId,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final shortest = math.min(w, h);
                  final clayD = shortest * _kClayDiameterFraction;
                  final stickT = shortest * _kStickThicknessFraction;
                  return Stack(
                    children: [
                      // Edges first so corners (which sit *over* the
                      // endpoints) draw on top.
                      for (var i = 0; i < blueprint.edges.length; i++)
                        _EdgeWidget(
                          key: ValueKey('habitat-edge-$i'),
                          edge: blueprint.edges[i],
                          corners: blueprint.corners,
                          placed: placedEdges.contains(i),
                          canvasW: w,
                          canvasH: h,
                          stickThickness: stickT,
                          enabled: !inputLocked,
                          hinted: hinted == ('edge', i),
                          onTap: () => onEdgeTap(i),
                        ),
                      // Corners on top of edges so the clay ball
                      // visually anchors the joint.
                      for (var i = 0; i < blueprint.corners.length; i++)
                        _CornerWidget(
                          key: ValueKey('habitat-corner-$i'),
                          position: blueprint.corners[i],
                          placed: placedCorners.contains(i),
                          canvasW: w,
                          canvasH: h,
                          diameter: clayD,
                          enabled: !inputLocked,
                          hinted: hinted == ('corner', i),
                          onTap: () => onCornerTap(i),
                        ),
                      // Roof pieces — only in Phase 2.
                      if (showRoof)
                        for (var i = 0; i < blueprint.roof.length; i++)
                          _RoofPieceWidget(
                            key: ValueKey('habitat-roof-$i'),
                            piece: blueprint.roof[i],
                            placed: placedRoof.contains(i),
                            canvasW: w,
                            canvasH: h,
                            enabled: !inputLocked,
                            hinted: hinted == ('roof', i),
                            onTap: () => onRoofTap(i),
                          ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 24),
            kContinueArrowShelf(
              child: allDone
                  ? const NextArrowButton(
                      key: ValueKey('habitat-done-arrow'),
                      idleHintEnabled: true,
                      onPressed: _noop,
                      label: kLabelNice,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

void _noop() {}

class _CornerWidget extends StatelessWidget {
  const _CornerWidget({
    super.key,
    required this.position,
    required this.placed,
    required this.canvasW,
    required this.canvasH,
    required this.diameter,
    required this.enabled,
    required this.onTap,
    this.hinted = false,
  });

  final Offset position;
  final bool placed;
  final double canvasW;
  final double canvasH;
  final double diameter;
  final bool enabled;
  final VoidCallback onTap;

  /// Ringed by the hint ladder. Every empty corner already glows, so the ring
  /// is what makes one of them *the* one.
  final bool hinted;

  @override
  Widget build(BuildContext context) {
    final cx = position.dx * canvasW;
    final cy = position.dy * canvasH;
    return Positioned(
      left: cx - diameter / 2,
      top: cy - diameter / 2,
      width: diameter,
      height: diameter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled && !placed ? onTap : null,
        child: Stack(
          alignment: Alignment.center,
          // The hint ring is drawn outside this box on purpose; the default
          // hard edge clips it into a rounded square.
          clipBehavior: Clip.none,
          children: [
            // Ghost halo while the corner is empty so the kid sees
            // exactly where to tap.
            if (!placed)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber.shade400.withValues(alpha: 0.85),
                    width: 3,
                  ),
                  color: Colors.amber.withValues(alpha: 0.15),
                ),
              ),
            if (placed)
              Image.asset(
                AssetPaths.buildAHabitatClayBall,
                fit: BoxFit.contain,
              ),
            if (hinted) TouchHereRingOutside(around: Size.square(diameter)),
          ],
        ),
      ),
    );
  }
}

class _EdgeWidget extends StatelessWidget {
  const _EdgeWidget({
    super.key,
    required this.edge,
    required this.corners,
    required this.placed,
    required this.canvasW,
    required this.canvasH,
    required this.stickThickness,
    required this.enabled,
    required this.onTap,
    this.hinted = false,
  });

  final List<int> edge;
  final List<Offset> corners;
  final bool placed;
  final double canvasW;
  final double canvasH;
  final double stickThickness;
  final bool enabled;
  final VoidCallback onTap;

  /// Ringed by the hint ladder.
  final bool hinted;

  @override
  Widget build(BuildContext context) {
    final a = corners[edge[0]];
    final b = corners[edge[1]];
    final ax = a.dx * canvasW;
    final ay = a.dy * canvasH;
    final bx = b.dx * canvasW;
    final by = b.dy * canvasH;
    final mid = Offset((ax + bx) / 2, (ay + by) / 2);
    final length = math.sqrt(math.pow(bx - ax, 2) + math.pow(by - ay, 2));
    final angle = math.atan2(by - ay, bx - ax);
    // The hit box is padded out to `kMinTouchTarget`; the bar drawn inside it
    // keeps its real thickness. A stick is about 28 pixels thick at this
    // canvas size - roughly 6mm on the iPad - and it lies at an angle, so
    // asking a five-year-old to tap one was asking her to hit a thin diagonal
    // strip. The thickness itself cannot simply grow: it is the proportion
    // the round, the K.G.5 lesson and the picker card all draw from
    // `HabitatFrameLayout`, and `habitat_frame_layout_test.dart` pins it.
    final hitHeight = math.max(stickThickness, kMinTouchTarget);
    return Positioned(
      left: mid.dx - length / 2,
      top: mid.dy - hitHeight / 2,
      width: length,
      height: hitHeight,
      child: Transform.rotate(
        angle: angle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled && !placed ? onTap : null,
          child: Center(
            child: SizedBox(
              width: length,
              height: stickThickness,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: placed
                        ? Image.asset(
                            AssetPaths.buildAHabitatStick,
                            fit: BoxFit.fill,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.20),
                              border: Border.all(
                                color: Colors.amber.shade400
                                    .withValues(alpha: 0.85),
                                width: 2,
                              ),
                              borderRadius:
                                  BorderRadius.circular(stickThickness / 2),
                            ),
                          ),
                  ),
                  if (hinted) const Positioned.fill(child: TouchHereRing()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoofPieceWidget extends StatelessWidget {
  const _RoofPieceWidget({
    super.key,
    required this.piece,
    required this.placed,
    required this.canvasW,
    required this.canvasH,
    required this.enabled,
    required this.onTap,
    this.hinted = false,
  });

  final HabitatRoofPiece piece;
  final bool placed;
  final double canvasW;
  final double canvasH;
  final bool enabled;
  final VoidCallback onTap;

  /// Ringed by the hint ladder. Every empty ghost already glows, so the ring
  /// is what makes one of them *the* one.
  final bool hinted;

  @override
  Widget build(BuildContext context) {
    final shortest = math.min(canvasW, canvasH);
    final size = shortest * piece.size;
    final cx = piece.position.dx * canvasW;
    final cy = piece.position.dy * canvasH;
    return Positioned(
      left: cx - size / 2,
      top: cy - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled && !placed ? onTap : null,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (!placed) Image.asset(piece.outlineAsset, fit: BoxFit.contain),
            if (placed) Image.asset(piece.placedAsset, fit: BoxFit.contain),
            if (placed)
              const Positioned.fill(
                child: IgnorePointer(
                  child: GlitterBurst(maxRadius: 60),
                ),
              ),
            if (hinted) TouchHereRingOutside(around: Size.square(size)),
          ],
        ),
      ),
    );
  }
}
