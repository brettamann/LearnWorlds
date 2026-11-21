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
// Each phase is graded once, as it ends: the frame with `c.grade('K.G.5')`,
// the roof by finishing the round, whose concept is K.G.6 (K.G.5 in
// frame-only, where the frame *is* the round). The lifecycle around it is
// SanctuaryRoundShell's; the words are in `habitat_words.dart`.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/build_a_habitat_blueprints.dart';
import '../../data/habitat_words.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../ui/common/glitter_burst.dart';
import '../../ui/common/target_hint.dart';
import '../../ui/common/touch_here_halo.dart';
import '../../ui/common/touch_target.dart';
import '../../ui/round/sanctuary_round_shell.dart';
import '../activity_ids.dart';
import '../sub_mode_ids.dart';

class BuildAHabitatRunner extends StatelessWidget {
  const BuildAHabitatRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
    this.subMode = BuildAHabitatModes.simpleShelter,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;
  final String subMode;

  @override
  Widget build(BuildContext context) {
    final rounds = <HabitatBlueprint>[
      for (final id in habitatBlueprintIdsFor(subMode))
        kHabitatBlueprints.firstWhere((b) => b.id == id),
    ];
    final frameOnly = habitatSkipsRoof(subMode);
    return SanctuaryRoundShell(
      activityId: ActivityIds.buildAHabitat,
      roundCount: rounds.length,
      conceptIdFor: (_) => frameOnly ? 'K.G.5' : 'K.G.6',
      introLine: kHabitatIntro,
      keeperLineFor: (i) => rounds[i].keeperLine,
      finalLine: kHabitatFinal,
      skipIntro: skipIntro,
      onSequenceComplete: onSequenceComplete,
      celebrationHold: const Duration(seconds: 1),
      background: Image.asset(
        AssetPaths.buildAHabitatBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) => HabitatRoundBody(
        blueprint: rounds[c.index],
        frameOnly: frameOnly,
        c: c,
      ),
    );
  }
}

/// The piece the hint ladder points at: ('corner'|'edge'|'roof', index).
typedef _Piece = (String, int);

/// One habitat: the frame, then (unless frame-only) the roof.
class HabitatRoundBody extends ConsumerStatefulWidget {
  const HabitatRoundBody({
    super.key,
    required this.blueprint,
    required this.frameOnly,
    required this.c,
  });

  final HabitatBlueprint blueprint;

  /// Skip the roof: the round ends, and is graded K.G.5, when the frame does.
  final bool frameOnly;
  final RoundContext c;

  @override
  ConsumerState<HabitatRoundBody> createState() => _HabitatRoundBodyState();
}

class _HabitatRoundBodyState extends ConsumerState<HabitatRoundBody> {
  final Set<int> _corners = <int>{};
  final Set<int> _edges = <int>{};
  final Set<int> _roof = <int>{};

  /// False while building the frame, true once raising the roof.
  bool _raising = false;
  bool _done = false;

  /// Sticks laid before both endpoints had clay. This is the wrong answer
  /// K.G.5 actually cares about — the whole point is corners first, sides
  /// between.
  int _outOfOrderTaps = 0;

  /// The one piece the hint ladder is pointing at. Null while she is getting
  /// on with it.
  _Piece? _hinted;

  HintLadder? _hints;

  HabitatBlueprint get _bp => widget.blueprint;
  bool get _open => !_done && !widget.c.locked;
  bool get _frameDone =>
      _corners.length == _bp.corners.length &&
      _edges.length == _bp.edges.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.c.say(habitatBuildPrompt(_bp.id));
      _startHints();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  void _startHints() {
    _hints?.dispose();
    _hints = HintLadder(onLevel: _onHint)..start();
  }

  /// Escalating help for a stalled builder.
  ///
  /// The instruction is three sentences long, spoken once, to a child who
  /// cannot read the replay button; losing the thread is the expected case.
  /// The ring goes on exactly one piece, and always the next legal one: every
  /// empty corner and side already wears a ghost outline, so "everything is
  /// glowing" is the state she is stuck in. The hint is which.
  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final next = _nextPiece();
    if (next == null) return;
    answerTargetHint(
      level,
      ring: () => setState(() => _hinted = next),
      chime: ref.read(feedbackEngineProvider).hint,
      say: (line) => widget.c.say(line, replay: false),
      demonstrate: () => _place(next),
    );
  }

  void _place(_Piece piece) {
    final (kind, index) = piece;
    switch (kind) {
      case 'corner':
        _onCornerTap(index, fromHint: true);
      case 'edge':
        _onEdgeTap(index, fromHint: true);
      default:
        _onRoofTap(index, fromHint: true);
    }
  }

  /// The next piece she could legally place, in the order the standard cares
  /// about: corners before the sides between them.
  _Piece? _nextPiece() {
    if (!_raising) {
      for (var i = 0; i < _bp.corners.length; i++) {
        if (!_corners.contains(i)) return ('corner', i);
      }
      for (var i = 0; i < _bp.edges.length; i++) {
        if (_edges.contains(i)) continue;
        final e = _bp.edges[i];
        if (_corners.contains(e[0]) && _corners.contains(e[1])) {
          return ('edge', i);
        }
      }
      return null;
    }
    for (var i = 0; i < _bp.roof.length; i++) {
      if (!_roof.contains(i)) return ('roof', i);
    }
    return null;
  }

  /// Queued, not spoken, when the ladder placed the piece, so it does not cut
  /// off the demonstration's own line. See HintLadder.
  void _sayPiece(String line, {required bool fromHint}) =>
      widget.c.say(line, replay: false, queue: fromHint);

  void _onCornerTap(int idx, {bool fromHint = false}) {
    if (!_open || _corners.contains(idx)) return;
    if (!fromHint) _hints?.poke();
    setState(() {
      _corners.add(idx);
      _hinted = null;
    });
    // Corners climb the scale, so a triangle's three corners sound like
    // three and a pentagon's five sound like five.
    ref.read(feedbackEngineProvider).countStep(_corners.length);
    _sayPiece(kHabitatCornerLine, fromHint: fromHint);
  }

  void _onEdgeTap(int idx, {bool fromHint = false}) {
    if (!_open || _edges.contains(idx)) return;
    if (!fromHint) _hints?.poke();
    // Sticks can only be placed once both endpoints have clay balls —
    // K.G.5's pedagogy depends on "corners first, then sides between."
    final endpoints = _bp.edges[idx];
    if (!_corners.contains(endpoints[0]) || !_corners.contains(endpoints[1])) {
      setState(() => _outOfOrderTaps += 1);
      ref.read(feedbackEngineProvider).wrong();
      widget.c.say(habitatStickBlockedLine(_outOfOrderTaps), replay: false);
      return;
    }
    setState(() {
      _edges.add(idx);
      _hinted = null;
    });
    // Two sounds, in this order: the thing landing, then the answer being
    // right.
    ref.read(feedbackEngineProvider)
      ..drop()
      ..correct();
    _sayPiece(kHabitatStickLine, fromHint: fromHint);
    if (_frameDone) _finishFrame();
  }

  void _finishFrame() {
    // Three sticks laid before their corners means she is not building the
    // frame in order, which is the K.G.5 idea itself.
    final result = gradeRound(
      misses: _outOfOrderTaps,
      helped: (_hints?.hintsUsed ?? 0) > 0,
    );
    if (widget.frameOnly) {
      _done = true;
      _hints?.pause();
      widget.c.finish(result);
      return;
    }
    widget.c.grade('K.G.5', result);
    setState(() {
      _raising = true;
      _hinted = null;
    });
    // Queued behind "Stick.", which it used to cut off.
    widget.c.say(kHabitatRaisePrompt, queue: true);
    // A fresh ladder, not a poke: the two phases grade separate concepts, so
    // help taken on one must not be charged to the other.
    _startHints();
  }

  void _onRoofTap(int idx, {bool fromHint = false}) {
    if (!_open || !_raising || _roof.contains(idx)) return;
    if (!fromHint) _hints?.poke();
    setState(() {
      _roof.add(idx);
      _hinted = null;
    });
    ref.read(feedbackEngineProvider)
      ..drop()
      ..correct();
    _sayPiece(habitatRoofLine(_bp.roof[idx].kind), fromHint: fromHint);
    if (_roof.length == _bp.roof.length) {
      // Every ghost is a correct target — there is nothing wrong to tap in
      // this phase — so the only thing that can make it less than clean is
      // the game having placed a piece for her.
      _done = true;
      _hints?.pause();
      widget.c.finish(gradeRound(helped: (_hints?.hintsUsed ?? 0) > 0));
    }
  }

  static const double _kClayDiameterFraction = 0.10;
  static const double _kStickThicknessFraction = 0.045;

  @override
  Widget build(BuildContext context) {
    final open = _open;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final shortest = math.min(w, h);
        final clayD = shortest * _kClayDiameterFraction;
        final stickT = shortest * _kStickThicknessFraction;
        return Stack(
          children: [
            // Edges first so corners (which sit *over* the endpoints) draw on
            // top.
            for (var i = 0; i < _bp.edges.length; i++)
              _EdgeWidget(
                key: ValueKey('habitat-edge-$i'),
                edge: _bp.edges[i],
                corners: _bp.corners,
                placed: _edges.contains(i),
                canvasW: w,
                canvasH: h,
                stickThickness: stickT,
                enabled: open,
                hinted: _hinted == ('edge', i),
                onTap: () => _onEdgeTap(i),
              ),
            for (var i = 0; i < _bp.corners.length; i++)
              _CornerWidget(
                key: ValueKey('habitat-corner-$i'),
                position: _bp.corners[i],
                placed: _corners.contains(i),
                canvasW: w,
                canvasH: h,
                diameter: clayD,
                enabled: open,
                hinted: _hinted == ('corner', i),
                onTap: () => _onCornerTap(i),
              ),
            if (_raising)
              for (var i = 0; i < _bp.roof.length; i++)
                _RoofPieceWidget(
                  key: ValueKey('habitat-roof-$i'),
                  piece: _bp.roof[i],
                  placed: _roof.contains(i),
                  canvasW: w,
                  canvasH: h,
                  enabled: open,
                  hinted: _hinted == ('roof', i),
                  onTap: () => _onRoofTap(i),
                ),
          ],
        );
      },
    );
  }
}

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
