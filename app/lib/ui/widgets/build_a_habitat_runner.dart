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

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/build_a_habitat_blueprints.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'continue_arrow_shelf.dart';
import 'glitter_burst.dart';
import 'keeper_intro_overlay.dart';
import 'next_arrow_button.dart';
import 'progress_bar_to_reward.dart';
import 'replay_demo_button.dart';

const String kBuildAHabitatSubModeSimpleShelter = 'simple-shelter';
const String kBuildAHabitatSubModeCreatureHome = 'creature-home';
const String kBuildAHabitatSubModeGrandHabitat = 'grand-habitat';
const String kBuildAHabitatSubModeFrameOnly = 'frame-only';

enum _Phase {
  intro,
  cornersAndSticks,
  raiseHabitat,
  celebrating,
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

class _BuildAHabitatRunnerState
    extends ConsumerState<BuildAHabitatRunner> {
  late _Phase _phase =
      widget.skipIntro ? _Phase.cornersAndSticks : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Set<int> _placedCorners = <int>{};
  Set<int> _placedEdges = <int>{};
  Set<int> _placedRoof = <int>{};
  Timer? _celebrationTimer;
  Timer? _interstitialTimer;

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

  bool get _skipRaisePhase =>
      widget.subMode == kBuildAHabitatSubModeFrameOnly;

  HabitatBlueprint get _currentRound => _rounds[_roundIndex];
  bool get _isLastRound => _roundIndex == _rounds.length - 1;
  double get _progress => _completedRounds / _rounds.length;

  bool get _allCornersPlaced =>
      _placedCorners.length == _currentRound.corners.length;
  bool get _allEdgesPlaced =>
      _placedEdges.length == _currentRound.edges.length;
  bool get _frameDone => _allCornersPlaced && _allEdgesPlaced;
  bool get _allRoofPlaced =>
      _placedRoof.length == _currentRound.roof.length;

  String get _introDialog =>
      "Let's build a habitat together! Clay balls go in the corners, "
      'sticks go along the sides — then we add shapes on top to make '
      "the roof. Ready? Let's start.";

  String get _phase1Prompt =>
      'Tap each glowing corner to place a clay ball. Then tap each '
      'side to lay a stick. Build ${_currentRound.displayName}!';

  String get _phase2Prompt =>
      'Now raise the habitat — tap each ghost shape to drop the '
      'matching piece in place.';

  String get _finalKeeperLine =>
      'Every habitat is built! The Sanctuary feels cosy and safe.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_phase == _Phase.cornersAndSticks) _speakPhase1Prompt();
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    _interstitialTimer?.cancel();
    super.dispose();
  }

  void _speakPhase1Prompt() {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: _phase1Prompt,
            cueId: 'habitat:r$_roundIndex:phase1-prompt',
          ),
        );
  }

  void _speakPhase2Prompt() {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: _phase2Prompt,
            cueId: 'habitat:r$_roundIndex:phase2-prompt',
          ),
        );
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.cornersAndSticks);
    _speakPhase1Prompt();
  }

  void _onCornerTap(int idx) {
    if (_placedCorners.contains(idx)) return;
    setState(() => _placedCorners.add(idx));
    _speak(
      'Clay corner.',
      'habitat:r$_roundIndex:corner-${_placedCorners.length}',
    );
  }

  void _onEdgeTap(int idx) {
    if (_placedEdges.contains(idx)) return;
    // Sticks can only be placed once both endpoints have clay balls —
    // K.G.5's pedagogy depends on "corners first, then sides between."
    final endpoints = _currentRound.edges[idx];
    final bothClayed = _placedCorners.contains(endpoints[0]) &&
        _placedCorners.contains(endpoints[1]);
    if (!bothClayed) {
      _speak(
        'Place clay in both corners first, then the stick.',
        'habitat:r$_roundIndex:edge-block-$idx',
      );
      return;
    }
    setState(() => _placedEdges.add(idx));
    _speak(
      'Stick.',
      'habitat:r$_roundIndex:edge-${_placedEdges.length}',
    );
    if (_frameDone) _finishPhase1();
  }

  void _finishPhase1() {
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'build-a-habitat',
          conceptId: 'K.G.5',
          success: true,
        );
    if (_skipRaisePhase) {
      // Frame-only: skip K.G.6 and go to the interstitial directly.
      _enterInterstitial();
      return;
    }
    setState(() => _phase = _Phase.raiseHabitat);
    _speakPhase2Prompt();
  }

  void _onRoofTap(int idx) {
    if (_placedRoof.contains(idx)) return;
    final piece = _currentRound.roof[idx];
    setState(() => _placedRoof.add(idx));
    _speak(
      'A ${piece.kind}. It goes on top.',
      'habitat:r$_roundIndex:roof-${_placedRoof.length}',
    );
    if (_allRoofPlaced) _finishPhase2();
  }

  void _finishPhase2() {
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'build-a-habitat',
          conceptId: 'K.G.6',
          success: true,
        );
    _enterInterstitial();
  }

  void _enterInterstitial() {
    setState(() => _phase = _Phase.celebrating);
    _celebrationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _completedRounds += 1;
        _phase = _Phase.interstitial;
      });
      final line =
          _isLastRound ? _finalKeeperLine : _currentRound.keeperLine;
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: line,
              cueId: 'habitat:r$_roundIndex:interstitial',
              speaker: 'sanctuary-keeper-mystic',
            ),
          );
    });
  }

  void _advanceFromInterstitial() {
    if (_isLastRound) {
      widget.onSequenceComplete();
      return;
    }
    setState(() {
      _roundIndex += 1;
      _placedCorners = <int>{};
      _placedEdges = <int>{};
      _placedRoof = <int>{};
      _phase = _Phase.cornersAndSticks;
    });
    _speakPhase1Prompt();
  }

  void _speak(String text, String cueId) {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(text: text, cueId: cueId),
        );
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
      _Phase.celebrating =>
        _BuildLayer(
          blueprint: _currentRound,
          placedCorners: _placedCorners,
          placedEdges: _placedEdges,
          placedRoof: _placedRoof,
          showRoof: _phase != _Phase.cornersAndSticks,
          inputLocked: _phase == _Phase.celebrating,
          onCornerTap: _onCornerTap,
          onEdgeTap: _onEdgeTap,
          onRoofTap: _onRoofTap,
          replayPrompt: _phase == _Phase.cornersAndSticks
              ? _phase1Prompt
              : _phase2Prompt,
          replayCueId: 'habitat:replay-r$_roundIndex-${_phase.name}',
          allDone: _phase == _Phase.celebrating,
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _isLastRound ? _finalKeeperLine : _currentRound.keeperLine,
          startLabel: _isLastRound ? 'Continue' : 'Next habitat!',
          startButtonKey: const ValueKey('habitat-interstitial-next'),
          onStart: _advanceFromInterstitial,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AssetPaths.buildAHabitatBackground, fit: BoxFit.cover),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: ProgressBarToReward(
                  progress: _progress,
                  celebrate: _phase == _Phase.celebrating,
                ),
              ),
              Expanded(child: phaseContent),
            ],
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
                      label: 'Nice!',
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
  });

  final Offset position;
  final bool placed;
  final double canvasW;
  final double canvasH;
  final double diameter;
  final bool enabled;
  final VoidCallback onTap;

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
  });

  final List<int> edge;
  final List<Offset> corners;
  final bool placed;
  final double canvasW;
  final double canvasH;
  final double stickThickness;
  final bool enabled;
  final VoidCallback onTap;

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
    return Positioned(
      left: mid.dx - length / 2,
      top: mid.dy - stickThickness / 2,
      width: length,
      height: stickThickness,
      child: Transform.rotate(
        angle: angle,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled && !placed ? onTap : null,
          child: placed
              ? Image.asset(
                  AssetPaths.buildAHabitatStick,
                  fit: BoxFit.fill,
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.20),
                    border: Border.all(
                      color:
                          Colors.amber.shade400.withValues(alpha: 0.85),
                      width: 2,
                    ),
                    borderRadius:
                        BorderRadius.circular(stickThickness / 2),
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
  });

  final HabitatRoofPiece piece;
  final bool placed;
  final double canvasW;
  final double canvasH;
  final bool enabled;
  final VoidCallback onTap;

  /// Map kind → creature theming used in the existing 3D pool so the
  /// roof reuses the Shape Garden 3D assets without new art.
  static const Map<String, String> _kCreatureByKind = <String, String>{
    'cube': 'turtle',
    'sphere': 'jellyfish',
    'cylinder': 'golem',
    'cone': 'gnome',
    'pyramid': 'fish',
  };

  @override
  Widget build(BuildContext context) {
    final shortest = math.min(canvasW, canvasH);
    final size = shortest * piece.size;
    final cx = piece.position.dx * canvasW;
    final cy = piece.position.dy * canvasH;
    final creature = _kCreatureByKind[piece.kind] ?? 'turtle';
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
            if (!placed)
              Image.asset(
                AssetPaths.shapeGarden3dOutline(piece.kind),
                fit: BoxFit.contain,
              ),
            if (placed)
              Image.asset(
                AssetPaths.shapeGarden3dCreature(piece.kind, creature),
                fit: BoxFit.contain,
              ),
            if (placed)
              const Positioned.fill(
                child: IgnorePointer(
                  child: GlitterBurst(maxRadius: 60),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
