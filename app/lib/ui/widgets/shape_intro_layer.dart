// ShapeIntroLayer — runs the per-shape intro beat for the K.G.2 sequence.
// For each shape kind (circle, triangle, right-triangle, square, rectangle,
// pentagon, hexagon, half-circle, quarter-circle) we play:
//
//   1. A large, centred example sprite that fades / scales in.
//   2. The narrator delivers a kind-specific intro sentence — vanilla
//      "This is a triangle!" for the basic kinds, plus extra teaching for
//      right triangles ("it's still a triangle because it has three sides")
//      and rectangles ("like a square, but two sides are longer").
//   3. "It has <n> sides! Look —" (or the no-sides / curved-side wording for
//      circles and semicircles).
//   4. A hand pointer touches each side at its painted midpoint; the
//      narrator counts ("One. Two. Three.") with a glitter burst per side.
//   5. The sprite fades out and the layer fires `onComplete`.
//
// Side positions come from the magenta `#FF00F0` dots embedded in the
// `*-example` sprite (see ExampleDotScanner). That means rectangles,
// right triangles, and semicircles all point at their *actual* painted
// sides instead of inscribed-N-gon midpoints. If the dot scan returns
// empty (missing example file), we fall back to a regular-N-gon
// algorithmic position so the lesson still plays.
//
// Circles get the "no sides — smooth all the way around" path and skip
// the counting beats entirely.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/example_dot_scanner.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../providers/shape_dots_provider.dart';
import 'glitter_burst.dart';
import 'lesson_hand_pointer.dart';

/// Side count per shape kind. 0 = treat as "no sides" (the smooth-around
/// path; circle only). Semicircles have a flat + curved count: half = 2,
/// quarter = 3 (two flats + one curve).
const Map<String, int> kIntroSidesByKind = {
  'circle': 0,
  'triangle': 3,
  'triangle-right': 3,
  'square': 4,
  'rectangle': 4,
  'pentagon': 5,
  'hexagon': 6,
  'semicircle_half': 2,
  'semicircle_quarter': 3,
};

// The intro layer used to pick a material variant per kind for the large
// centred sprite. That choice has been replaced with the `*-example` sprite
// in `build()` — those are the same files the dot scanner reads, so the
// hand pointer's per-side positions match the displayed pixels exactly
// (rectangles, right triangles, and semicircles previously had visible
// drift because the example dots described a different outline than the
// material-variant sprite being rendered).

/// Display name used in narration ("This is a <name>!", "Now tap all the
/// <plural>s on the screen!"). Right-triangle and the semicircles get
/// custom phrasing rather than the raw key.
const Map<String, String> kShapeDisplayName = {
  'circle': 'circle',
  'triangle': 'triangle',
  'triangle-right': 'right triangle',
  'square': 'square',
  'rectangle': 'rectangle',
  'pentagon': 'pentagon',
  'hexagon': 'hexagon',
  'semicircle_half': 'half circle',
  'semicircle_quarter': 'quarter circle',
};

const Map<String, String> kShapeDisplayPlural = {
  'circle': 'circles',
  'triangle': 'triangles',
  'triangle-right': 'right triangles',
  'square': 'squares',
  'rectangle': 'rectangles',
  'pentagon': 'pentagons',
  'hexagon': 'hexagons',
  'semicircle_half': 'half circles',
  'semicircle_quarter': 'quarter circles',
};

/// Per-kind opening narration. These run after the sprite fades in. The
/// "Look —" suffix flows into the count narration; circle / no-sides path
/// gets a sentence that stands on its own.
const Map<String, String> _kIntroOpening = {
  'circle':
      "This is a circle! A circle has no sides — it's smooth all the way around.",
  'triangle': 'This is a triangle! A triangle has three sides. Look —',
  // The K.G.2 invariance message: a right triangle still *is* a triangle.
  'triangle-right': 'This is a right triangle. It looks a little different — '
      'but it is still a triangle, because it has three sides. Look —',
  'square':
      'This is a square! A square has four sides — and all four sides are '
          'the same length. Look —',
  // K-level "square vs rectangle" framing — both have four sides, but a
  // rectangle has two long sides and two short sides.
  'rectangle': 'This is a rectangle! A rectangle has four sides, just like a '
      'square. But two of the sides are long, and two of the sides are short. '
      'Look —',
  'pentagon': 'This is a pentagon! A pentagon has five sides. Look —',
  'hexagon': 'This is a hexagon! A hexagon has six sides. Look —',
  'semicircle_half':
      'This is a half circle! It has two sides — one flat side, and one '
          'round side. Look —',
  'semicircle_quarter':
      'This is a quarter circle! It has three sides — two flat sides, and '
          'one round side. Look —',
};

/// Spelled-out cardinals for the narration. Long enough for any future
/// kind we'd realistically introduce at K.
const List<String> _kCountWords = [
  'Zero',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
];

/// Time per counted side. Bigger = slower / more breathing room. Hexagon
/// runs 6 × this + ~3 s of bookend.
const int _kSidePaceMs = 1100;

class ShapeIntroLayer extends ConsumerStatefulWidget {
  const ShapeIntroLayer({
    super.key,
    required this.shapeKind,
    required this.onComplete,
  });

  /// Shape family — matches the keys in `kIntroSidesByKind`.
  final String shapeKind;

  /// Fired once the intro finishes (post fade-out). The LessonScreen
  /// advances its per-shape sequence from here.
  final VoidCallback onComplete;

  @override
  ConsumerState<ShapeIntroLayer> createState() => _ShapeIntroLayerState();
}

class _ShapeIntroLayerState extends ConsumerState<ShapeIntroLayer> {
  final List<Timer> _timers = [];
  bool _shapeVisible = false;
  bool _pointerVisible = false;
  int _pointerPokeCounter = 0;
  int? _currentSideIndex; // null = pointer not active yet
  final Map<int, int> _burstCounters = {};
  bool _timelineStarted = false;
  List<Offset> _resolvedSides = const [];

  int get _sides => kIntroSidesByKind[widget.shapeKind] ?? 0;

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

  /// Kicks the choreography off exactly once after the dot scan resolves
  /// (or the fallback is computed). Re-entry-safe — bail on subsequent
  /// rebuilds.
  void _startTimelineOnce(List<Offset> sides) {
    if (_timelineStarted) return;
    _timelineStarted = true;
    _resolvedSides = sides;
    _scheduleTimeline();
  }

  void _scheduleTimeline() {
    // Beat 1 — sprite fades + scales in.
    _schedule(100, () => setState(() => _shapeVisible = true));

    final opening = _kIntroOpening[widget.shapeKind] ??
        'This is a ${kShapeDisplayName[widget.shapeKind] ?? widget.shapeKind}!';

    // Beat 2 — opening sentence ("This is a ...!").
    _schedule(
      800,
      () => _speak(opening, 'intro:${widget.shapeKind}:opening'),
    );

    if (_sides == 0 || _resolvedSides.isEmpty) {
      // Circle / smooth-around path, or polygon with no dots: no count.
      _schedule(6500, () => setState(() => _shapeVisible = false));
      _schedule(7000, widget.onComplete);
      return;
    }

    // Show the pointer parked over side 0 a moment after the opening
    // settles.
    _schedule(
      3600,
      () => setState(() {
        _currentSideIndex = 0;
        _pointerVisible = true;
      }),
    );

    // Count each side. Pointer pre-glides handPointerGlideDuration before
    // the narration so the hand lands on the beat.
    final sideCount = _resolvedSides.length;
    for (var i = 0; i < sideCount; i++) {
      final countMs = 4200 + i * _kSidePaceMs;
      if (i > 0) {
        _schedule(
          countMs - handPointerGlideDuration.inMilliseconds,
          () => setState(() => _currentSideIndex = i),
        );
      }
      _schedule(countMs, () {
        setState(() {
          _burstCounters[i] = (_burstCounters[i] ?? 0) + 1;
          _pointerPokeCounter++;
        });
        _speak(
          '${_kCountWords[i + 1]}.',
          'intro:${widget.shapeKind}:count-${i + 1}',
        );
      });
    }

    final lastCountMs = 4200 + (sideCount - 1) * _kSidePaceMs;
    _schedule(lastCountMs + 1500, () {
      setState(() {
        _shapeVisible = false;
        _pointerVisible = false;
      });
    });
    _schedule(lastCountMs + 2000, widget.onComplete);
  }

  /// Side midpoints of a regular N-gon inscribed in the sprite's box, in
  /// normalized 0..1 coordinates. Used only as a fallback when the
  /// scanned dot list is empty for a kind that *should* have sides.
  List<Offset> _fallbackSideMidpoints() {
    if (_sides == 0) return const [];
    final result = <Offset>[];
    const center = Offset(0.5, 0.5);
    const radius = 0.38;
    for (var i = 0; i < _sides; i++) {
      final v1Angle = -math.pi / 2 + i * 2 * math.pi / _sides;
      final v2Angle = -math.pi / 2 + (i + 1) * 2 * math.pi / _sides;
      final v1 = Offset(
        center.dx + radius * math.cos(v1Angle),
        center.dy + radius * math.sin(v1Angle),
      );
      final v2 = Offset(
        center.dx + radius * math.cos(v2Angle),
        center.dy + radius * math.sin(v2Angle),
      );
      result.add(Offset((v1.dx + v2.dx) / 2, (v1.dy + v2.dy) / 2));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final dotsAsync = ref.watch(shapeDotsProvider(widget.shapeKind));
    final scanned = dotsAsync.maybeWhen(
      data: (d) => d,
      orElse: () => ShapeDots.empty,
    );
    final sides = scanned.dots.isNotEmpty || _sides == 0
        ? scanned.dots
        : _fallbackSideMidpoints();
    // Aspect ratio of the source PNG. `BoxFit.contain` letterboxes the
    // sprite inside its bounding square — without correcting for that,
    // non-square shapes (half-circle ≈ 2:1, quarter-circle ≈ 1:1 but the
    // painted region only fills the bottom-left quadrant) hand-off into
    // the margin. Use 1 as a safe default when the scan hasn't resolved
    // yet so circles still work first-frame.
    final aspectRatio = scanned.dots.isNotEmpty ? scanned.aspectRatio : 1.0;

    // Kick the timeline once the dot scan resolves (or we've decided we
    // need the fallback). This avoids racing the post-frame callback with
    // the scan future on slow first frames.
    if (!_timelineStarted &&
        (dotsAsync.hasValue || dotsAsync.hasError || _sides == 0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startTimelineOnce(sides);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final shapeBoxSize = math.min(
              constraints.maxWidth,
              constraints.maxHeight,
            ) *
            0.55;
        final shapeBoxLeft = (constraints.maxWidth - shapeBoxSize) / 2;
        final shapeBoxTop = (constraints.maxHeight - shapeBoxSize) / 2;

        // The painted rect inside the bounding square after BoxFit.contain.
        // For a wider-than-tall sprite the painted height shrinks; for a
        // taller-than-wide sprite the painted width shrinks. Dots get
        // mapped into THIS rect, not the full bounding square.
        final double paintedWidth;
        final double paintedHeight;
        if (aspectRatio >= 1) {
          paintedWidth = shapeBoxSize;
          paintedHeight = shapeBoxSize / aspectRatio;
        } else {
          paintedHeight = shapeBoxSize;
          paintedWidth = shapeBoxSize * aspectRatio;
        }
        final paintedLeft =
            shapeBoxLeft + (shapeBoxSize - paintedWidth) / 2;
        final paintedTop =
            shapeBoxTop + (shapeBoxSize - paintedHeight) / 2;

        Offset dotToScreen(Offset normalized) {
          return Offset(
            paintedLeft + normalized.dx * paintedWidth,
            paintedTop + normalized.dy * paintedHeight,
          );
        }

        // Render the same `*-example` sprite the dot scanner reads from so
        // the hand pointer's per-side positions line up with the painted
        // edges exactly.
        final spriteAsset = AssetPaths.shapeGarden2dExample(widget.shapeKind);

        const handSize = 96.0;
        Offset handTarget;
        if (!_pointerVisible ||
            _currentSideIndex == null ||
            _currentSideIndex! >= _resolvedSides.length) {
          handTarget = Offset(-handSize - 80, shapeBoxTop + shapeBoxSize * 0.2);
        } else {
          final mid = dotToScreen(_resolvedSides[_currentSideIndex!]);
          handTarget =
              Offset(mid.dx - handSize * 0.4, mid.dy - handSize * 0.85);
        }

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // The enlarged shape sprite, centred.
            Positioned(
              left: shapeBoxLeft,
              top: shapeBoxTop,
              width: shapeBoxSize,
              height: shapeBoxSize,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: _shapeVisible ? 1.0 : 0.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  scale: _shapeVisible ? 1.0 : 0.5,
                  child: Image.asset(spriteAsset, fit: BoxFit.contain),
                ),
              ),
            ),
            // Glitter bursts at each counted side.
            for (var i = 0; i < _resolvedSides.length; i++)
              if ((_burstCounters[i] ?? 0) > 0)
                Builder(
                  builder: (_) {
                    final pos = dotToScreen(_resolvedSides[i]);
                    return Positioned(
                      left: pos.dx - 70,
                      top: pos.dy - 70,
                      width: 140,
                      height: 140,
                      child: GlitterBurst(
                        key: ValueKey(
                          'intro-burst-${widget.shapeKind}-$i-${_burstCounters[i]}',
                        ),
                      ),
                    );
                  },
                ),
            LessonHandPointer(
              visible: _pointerVisible,
              target: handTarget,
              pokeKey: _pointerPokeCounter,
              size: handSize,
            ),
          ],
        );
      },
    );
  }
}
