// Kg3FlatOrSolidLessonLayer — the K.G.3 lesson body. Restructured per the
// design note: each shape pairing gets its own intro (flat example → 3D
// outline → themed creature, cross-faded with narration), then a sort
// round practicing that pairing alongside any shapes the kid has already
// met.
//
// Outer flow per pairing:
//   1. Kg3PairingIntroLayer — 3-stage cross-fade (~16 s)
//   2. (first pairing only) sort demo — hand pointer auto-drags a triangle
//      into the flat bin then a sphere into the solid bin (~10 s)
//   3. FlatOrSolidRound in `count` narration mode — kid sorts a mix of
//      2 flat + 3 solid of the focus pairing plus a few previously-met
//      shapes; the narrator counts each drop ("One flat shape." "Two
//      solid shapes.") to reinforce K.CC counting alongside K.G.3.
//
// After the last pairing's round, `onComplete` fires and the LessonScreen
// hands off to the activity in `flat-or-solid` sub-mode.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/flat_or_solid_shapes.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'flat_or_solid_round.dart';
import 'glitter_burst.dart';
import 'kg3_pairing_intro_layer.dart';
import 'lesson_hand_pointer.dart';

enum _LessonBeat { pairingIntro, sortDemo, sortRound, done }

class Kg3FlatOrSolidLessonLayer extends ConsumerStatefulWidget {
  const Kg3FlatOrSolidLessonLayer({
    super.key,
    required this.onComplete,
  });

  /// Fires after the last pairing's sort round completes. The
  /// LessonScreen routes from here to the Shape Garden activity in
  /// `flat-or-solid` sub-mode.
  final VoidCallback onComplete;

  @override
  ConsumerState<Kg3FlatOrSolidLessonLayer> createState() =>
      _Kg3FlatOrSolidLessonLayerState();
}

class _Kg3FlatOrSolidLessonLayerState
    extends ConsumerState<Kg3FlatOrSolidLessonLayer> {
  int _pairingIdx = 0;
  _LessonBeat _beat = _LessonBeat.pairingIntro;
  bool _demoShown = false;

  void _onPairingIntroComplete() {
    if (!mounted) return;
    setState(() {
      _beat = _demoShown ? _LessonBeat.sortRound : _LessonBeat.sortDemo;
    });
  }

  void _onSortDemoComplete() {
    if (!mounted) return;
    setState(() {
      _demoShown = true;
      _beat = _LessonBeat.sortRound;
    });
  }

  void _onSortRoundComplete() {
    if (!mounted) return;
    final next = _pairingIdx + 1;
    if (next >= kFlatSolidPairings.length) {
      setState(() => _beat = _LessonBeat.done);
      widget.onComplete();
      return;
    }
    setState(() {
      _pairingIdx = next;
      _beat = _LessonBeat.pairingIntro;
    });
  }

  /// Shapes for the round following the just-introduced pairing.
  /// Composition matches the design spec: ≥2 flat of focus, ≥3 solid of
  /// focus, plus a couple of previously-introduced shapes. Capped at 8
  /// total so the screen stays readable.
  List<FlatOrSolidShape> _buildShapesForRound(int pairingIdx) {
    final focus = kFlatSolidPairings[pairingIdx];
    final shapes = <FlatOrSolidShape>[];
    for (var i = 0; i < 2; i++) {
      shapes.add(flatShapeFromPairing(focus, i));
    }
    for (var i = 0; i < 3; i++) {
      shapes.add(solidShapeFromPairing(focus, i));
    }
    // One flat + one solid from each previous pairing — iterating most
    // recent first so a hard cap doesn't starve the just-prior pairing.
    // (Without this, round 5 would skip the pairing immediately before it
    // and only include older pairings.) High instance numbers keep these
    // ids distinct from any focus-set ids.
    for (var i = pairingIdx - 1; i >= 0 && shapes.length < 8; i--) {
      shapes.add(
        flatShapeFromPairing(kFlatSolidPairings[i], 100 + pairingIdx),
      );
      if (shapes.length >= 8) break;
      shapes.add(
        solidShapeFromPairing(kFlatSolidPairings[i], 100 + pairingIdx),
      );
    }
    return shapes;
  }

  @override
  Widget build(BuildContext context) {
    switch (_beat) {
      case _LessonBeat.pairingIntro:
        final pairing = kFlatSolidPairings[_pairingIdx];
        return Kg3PairingIntroLayer(
          key: ValueKey('kg3-intro-${pairing.id}'),
          pairing: pairing,
          onComplete: _onPairingIntroComplete,
        );
      case _LessonBeat.sortDemo:
        return _SortDemoBody(
          key: const ValueKey('kg3-sort-demo'),
          onComplete: _onSortDemoComplete,
        );
      case _LessonBeat.sortRound:
        final shapes = _buildShapesForRound(_pairingIdx);
        final pairing = kFlatSolidPairings[_pairingIdx];
        return FlatOrSolidRound(
          key: ValueKey('kg3-lesson-r$_pairingIdx'),
          shapes: shapes,
          cueIdPrefix: 'kg3-lesson:r$_pairingIdx',
          headerPrompt:
              'Round ${_pairingIdx + 1}: sort the ${pairing.flatName}s '
              'and ${pairing.solidName}s!',
          spokenPrompt: _pairingIdx == 0
              ? 'Now you try! Drag the shapes into the right baskets.'
              : "Let's sort again. Flat ones in the flat basket.",
          narrationStyle: FlatOrSolidNarrationStyle.count,
          onComplete: _onSortRoundComplete,
        );
      case _LessonBeat.done:
        // Parent has been notified; nothing more to draw.
        return const SizedBox.shrink();
    }
  }
}

// ============================================================================
// One-shot sort demo — bins + auto-walk hand pointer dragging one of each
// shape into the right basket. Plays only before the first sort round.
// ============================================================================

enum _DemoStep {
  idle,
  pickFlat,
  carryFlat,
  dropFlat,
  pickSolid,
  carrySolid,
  dropSolid,
  wrapUp,
}

class _SortDemoBody extends ConsumerStatefulWidget {
  const _SortDemoBody({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<_SortDemoBody> createState() => _SortDemoBodyState();
}

class _SortDemoBodyState extends ConsumerState<_SortDemoBody> {
  static const double _shapeSize = 110;
  static const double _handSize = 96;

  final List<Timer> _timers = [];

  _DemoStep _step = _DemoStep.idle;
  bool _pointerVisible = false;
  int _pokeCounter = 0;
  Offset _carriedShapePos = const Offset(0.5, 0.35);
  bool _flatVisible = true;
  bool _solidVisible = true;
  int _flatBinBurst = 0;
  int _solidBinBurst = 0;

  static const String _flatAsset =
      'assets/activities/shape-garden/shape_2d_triangle-yellow.png';
  String get _solidAsset =>
      AssetPaths.shapeGarden3dCreature('sphere', 'jellyfish');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleTimeline();
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _schedule(int ms, VoidCallback action) {
    _timers.add(
      Timer(Duration(milliseconds: ms), () {
        if (!mounted) return;
        action();
      }),
    );
  }

  void _speak(String text, String cueId) {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(text: text, cueId: cueId),
        );
  }

  void _scheduleTimeline() {
    // Beat 0 — intro.
    _schedule(300, () {
      _speak(
        "Watch — I'll show you how to sort. The flat shapes go in the "
        'flat basket, the solid shapes in the solid basket.',
        'kg3-demo:intro',
      );
    });
    // Beat 1 — hand glides to the flat triangle, picks it up.
    _schedule(2400, () {
      setState(() {
        _pointerVisible = true;
        _step = _DemoStep.pickFlat;
        _carriedShapePos = const Offset(0.30, 0.38);
      });
      _pokeCounter += 1;
    });
    _schedule(2900, () {
      _speak('Triangle.', 'kg3-demo:flat-name');
    });
    // Beat 2 — carry to flat bin.
    _schedule(3800, () {
      setState(() {
        _step = _DemoStep.carryFlat;
        _carriedShapePos = const Offset(0.25, 0.78);
      });
    });
    _schedule(5000, () {
      setState(() {
        _step = _DemoStep.dropFlat;
        _flatVisible = false;
        _flatBinBurst += 1;
        _pokeCounter += 1;
      });
      _speak('One flat shape!', 'kg3-demo:flat-drop');
    });
    // Beat 3 — hand glides to the solid sphere.
    _schedule(6400, () {
      setState(() {
        _step = _DemoStep.pickSolid;
        _carriedShapePos = const Offset(0.70, 0.38);
      });
      _pokeCounter += 1;
    });
    _schedule(6900, () {
      _speak('Sphere.', 'kg3-demo:solid-name');
    });
    // Beat 4 — carry to solid bin.
    _schedule(7800, () {
      setState(() {
        _step = _DemoStep.carrySolid;
        _carriedShapePos = const Offset(0.75, 0.78);
      });
    });
    _schedule(9000, () {
      setState(() {
        _step = _DemoStep.dropSolid;
        _solidVisible = false;
        _solidBinBurst += 1;
        _pokeCounter += 1;
      });
      _speak('One solid shape!', 'kg3-demo:solid-drop');
    });
    // Beat 5 — wrap up + hand off.
    _schedule(10400, () {
      setState(() {
        _step = _DemoStep.wrapUp;
        _pointerVisible = false;
      });
      _speak('Now you try!', 'kg3-demo:wrapup');
    });
    _schedule(12000, widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Source slots — where the unsorted shapes initially appear.
        const flatSlot = Offset(0.30, 0.38);
        const solidSlot = Offset(0.70, 0.38);
        const flatBinCenter = Offset(0.25, 0.85);
        const solidBinCenter = Offset(0.75, 0.85);
        const binSize = 200.0;

        // Hand follows whatever the carried shape's current position is
        // (for both pick-up and carry steps); during wrapUp it parks off
        // to the side.
        final handCarryAnchor = _carriedShapePos;
        final handTarget = Offset(
          handCarryAnchor.dx * w - _handSize * 0.4,
          handCarryAnchor.dy * h - _handSize * 0.85,
        );

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Prompt banner.
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Watch — how to sort flat vs solid!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            // Bins.
            _DemoBin(
              center: Offset(flatBinCenter.dx * w, flatBinCenter.dy * h),
              size: binSize,
              assetPath: AssetPaths.shapeGardenBin2d,
              label: 'Flat',
              burstCount: _flatBinBurst,
            ),
            _DemoBin(
              center: Offset(solidBinCenter.dx * w, solidBinCenter.dy * h),
              size: binSize,
              assetPath: AssetPaths.shapeGardenBin3d,
              label: 'Solid',
              burstCount: _solidBinBurst,
            ),
            // Flat shape — either at its source slot or "carried" with the
            // hand.
            if (_flatVisible)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOutCubic,
                left: (_step == _DemoStep.carryFlat ||
                            _step == _DemoStep.dropFlat
                        ? _carriedShapePos.dx
                        : flatSlot.dx) *
                        w -
                    _shapeSize / 2,
                top: (_step == _DemoStep.carryFlat ||
                            _step == _DemoStep.dropFlat
                        ? _carriedShapePos.dy
                        : flatSlot.dy) *
                        h -
                    _shapeSize / 2,
                width: _shapeSize,
                height: _shapeSize,
                child: Image.asset(_flatAsset, fit: BoxFit.contain),
              ),
            // Solid shape.
            if (_solidVisible)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOutCubic,
                left: (_step == _DemoStep.carrySolid ||
                            _step == _DemoStep.dropSolid
                        ? _carriedShapePos.dx
                        : solidSlot.dx) *
                        w -
                    _shapeSize / 2,
                top: (_step == _DemoStep.carrySolid ||
                            _step == _DemoStep.dropSolid
                        ? _carriedShapePos.dy
                        : solidSlot.dy) *
                        h -
                    _shapeSize / 2,
                width: _shapeSize,
                height: _shapeSize,
                child: Image.asset(_solidAsset, fit: BoxFit.contain),
              ),
            // Hand pointer.
            LessonHandPointer(
              visible: _pointerVisible,
              target: handTarget,
              pokeKey: _pokeCounter,
              size: _handSize,
            ),
          ],
        );
      },
    );
  }
}

class _DemoBin extends StatelessWidget {
  const _DemoBin({
    required this.center,
    required this.size,
    required this.assetPath,
    required this.label,
    required this.burstCount,
  });

  final Offset center;
  final double size;
  final String assetPath;
  final String label;
  final int burstCount;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (burstCount > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: GlitterBurst(
                  key: ValueKey('kg3-demo-bin-$label-$burstCount'),
                  maxRadius: 110,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
