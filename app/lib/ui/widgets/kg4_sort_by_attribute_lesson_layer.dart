// Kg4SortByAttributeLessonLayer — the K.G.4 lesson body. Plays a brief
// I-Show / We-Try sequence built around the "sort by number of sides"
// attribute, mirroring the lesson runtime in
// data/lesson-runtime/k-g-4-sort-by-attribute.json.
//
// Flow:
//   1. I-Show (~16 s) — Six shapes line up; the hand pointer auto-
//      drags a triangle into the "3 sides" bin, a square into "4
//      sides", and a pentagon into "5+ sides". Narrator names each
//      drop. An "I've got this" pill appears partway through so a
//      confident kid can skip ahead.
//   2. We-Try (~12 s) — The kid drags one of the remaining shapes.
//      Halo on the target bin steers them. Hesitate too long and the
//      system auto-completes the remaining sort with the narrator
//      describing what happened.
//   3. Done — onComplete fires; LessonScreen hands off to the
//      sort-by-attribute activity sub-mode.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'glitter_burst.dart';
import 'lesson_hand_pointer.dart';

enum _Beat { iShow, weTry, done }

/// One sortable shape used in the lesson scene.
class _LessonShape {
  const _LessonShape({
    required this.id,
    required this.kind,
    required this.variant,
    required this.targetBin,
    required this.startPos,
  });

  final String id;
  final String kind;
  final String variant;

  /// Bin id this shape belongs in (`bin-3` / `bin-4` / `bin-5plus`).
  final String targetBin;

  /// Initial normalized position in the lesson stage.
  final Offset startPos;
}

class _LessonBin {
  const _LessonBin({
    required this.id,
    required this.label,
    required this.position,
  });

  final String id;
  final String label;

  /// Normalized centre of the bin in the lesson stage.
  final Offset position;
}

/// Six lesson shapes — two per attribute bucket. Layout: a row across
/// the top so they're easy to spot and the hand can sweep along it.
const List<_LessonShape> _kLessonShapes = <_LessonShape>[
  _LessonShape(
    id: 'tri-1',
    kind: 'triangle',
    variant: 'yellow',
    targetBin: 'bin-3',
    startPos: Offset(0.12, 0.26),
  ),
  _LessonShape(
    id: 'sq-1',
    kind: 'square',
    variant: 'green',
    targetBin: 'bin-4',
    startPos: Offset(0.28, 0.26),
  ),
  _LessonShape(
    id: 'pent-1',
    kind: 'pentagon',
    variant: 'starfruit',
    targetBin: 'bin-5plus',
    startPos: Offset(0.44, 0.26),
  ),
  _LessonShape(
    id: 'tri-2',
    kind: 'triangle',
    variant: 'leaf',
    targetBin: 'bin-3',
    startPos: Offset(0.60, 0.26),
  ),
  _LessonShape(
    id: 'rect-1',
    kind: 'rectangle',
    variant: 'stone',
    targetBin: 'bin-4',
    startPos: Offset(0.76, 0.26),
  ),
  _LessonShape(
    id: 'hex-1',
    kind: 'hexagon',
    variant: 'honeycomb',
    targetBin: 'bin-5plus',
    startPos: Offset(0.90, 0.26),
  ),
];

/// Three bins along the bottom of the stage.
const List<_LessonBin> _kLessonBins = <_LessonBin>[
  _LessonBin(id: 'bin-3', label: '3 sides', position: Offset(0.20, 0.78)),
  _LessonBin(id: 'bin-4', label: '4 sides', position: Offset(0.50, 0.78)),
  _LessonBin(
    id: 'bin-5plus',
    label: '5+ sides',
    position: Offset(0.80, 0.78),
  ),
];

class Kg4SortByAttributeLessonLayer extends ConsumerStatefulWidget {
  const Kg4SortByAttributeLessonLayer({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  ConsumerState<Kg4SortByAttributeLessonLayer> createState() =>
      _Kg4SortByAttributeLessonLayerState();
}

class _Kg4SortByAttributeLessonLayerState
    extends ConsumerState<Kg4SortByAttributeLessonLayer> {
  _Beat _beat = _Beat.iShow;
  final List<Timer> _timers = <Timer>[];

  /// Per-shape current position (normalized). Mutated as the hand or
  /// the kid drags a shape into a bin.
  final Map<String, Offset> _positions = <String, Offset>{};

  /// Shapes that have been placed correctly. Their position is locked
  /// to the bin centre and they fade into the bin.
  final Set<String> _placed = <String>{};

  /// Glitter-burst counter per bin id so each drop pops fresh sparkle.
  final Map<String, int> _burstByBin = <String, int>{};

  /// Hand pointer state — drives the I-Show auto-demonstration and the
  /// We-Try auto-complete.
  Offset _handTarget = const Offset(0.5, 0.5);
  bool _handVisible = false;
  int _pokeKey = 0;

  /// Which shapes the kid has been invited to drag in We-Try. Only the
  /// first listed un-placed shape is interactive at a time.
  bool _kidActionInflight = false;

  @override
  void initState() {
    super.initState();
    for (final s in _kLessonShapes) {
      _positions[s.id] = s.startPos;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleIShow();
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _speak(String text, String cueId) {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(text: text, cueId: cueId),
        );
  }

  /// Auto-sort one shape into its target bin with a hand-pointer
  /// glide + poke. Returns the duration it spans so the caller can
  /// chain the next step.
  void _scheduleAutoSort({
    required int startMs,
    required String shapeId,
    required String binId,
    required String narrationText,
    required String narrationCue,
  }) {
    final shape = _kLessonShapes.firstWhere((s) => s.id == shapeId);
    final bin = _kLessonBins.firstWhere((b) => b.id == binId);
    _timers.add(
      Timer(Duration(milliseconds: startMs), () {
        if (!mounted) return;
        setState(() {
          _handVisible = true;
          _handTarget = shape.startPos;
        });
      }),
    );
    _timers.add(
      Timer(Duration(milliseconds: startMs + 600), () {
        if (!mounted) return;
        setState(() {
          // Glide the shape onto the bin alongside the hand.
          _positions[shapeId] = bin.position;
          _handTarget = bin.position;
          _pokeKey += 1;
        });
        _speak(narrationText, narrationCue);
      }),
    );
    _timers.add(
      Timer(Duration(milliseconds: startMs + 1300), () {
        if (!mounted) return;
        setState(() {
          _placed.add(shapeId);
          _burstByBin[binId] = (_burstByBin[binId] ?? 0) + 1;
        });
      }),
    );
  }

  void _scheduleIShow() {
    _speak(
      "Let's group these shapes by how many sides they have.",
      'k-g-4-lesson:ishow-intro',
    );
    _scheduleAutoSort(
      startMs: 2200,
      shapeId: 'tri-1',
      binId: 'bin-3',
      narrationText: 'Three sides.',
      narrationCue: 'k-g-4-lesson:ishow-3',
    );
    _scheduleAutoSort(
      startMs: 5200,
      shapeId: 'sq-1',
      binId: 'bin-4',
      narrationText: 'Four sides.',
      narrationCue: 'k-g-4-lesson:ishow-4',
    );
    _scheduleAutoSort(
      startMs: 8200,
      shapeId: 'pent-1',
      binId: 'bin-5plus',
      narrationText: 'Five sides.',
      narrationCue: 'k-g-4-lesson:ishow-5',
    );
    _timers.add(
      Timer(const Duration(milliseconds: 11200), () {
        if (!mounted) return;
        _speak(
          'Shapes with the same number of sides go together, no matter '
          'their size.',
          'k-g-4-lesson:ishow-closer',
        );
      }),
    );
    _timers.add(
      Timer(const Duration(milliseconds: 15200), () {
        if (!mounted) return;
        setState(() {
          _handVisible = false;
          _beat = _Beat.weTry;
        });
        _speak(
          'Your turn. Sort by how many sides.',
          'k-g-4-lesson:we-try-start',
        );
      }),
    );
  }

  /// First un-placed shape — the one the kid is currently invited to
  /// drag. Null when everything has landed.
  _LessonShape? get _nextKidShape {
    for (final s in _kLessonShapes) {
      if (!_placed.contains(s.id)) return s;
    }
    return null;
  }

  void _scheduleWeTryHesitation() {
    // Auto-complete the round if the kid hesitates for ~6s on the
    // current invited shape. Keeps the lesson moving for a stuck kid
    // without punishing them.
    _timers.add(
      Timer(const Duration(seconds: 6), () {
        if (!mounted || _beat != _Beat.weTry) return;
        _autoCompleteRemaining();
      }),
    );
  }

  void _autoCompleteRemaining() {
    final remaining = _kLessonShapes
        .where((s) => !_placed.contains(s.id))
        .toList(growable: false);
    if (remaining.isEmpty) {
      _finishLesson();
      return;
    }
    var t = 0;
    for (final s in remaining) {
      final bin = _kLessonBins.firstWhere((b) => b.id == s.targetBin);
      _timers.add(
        Timer(Duration(milliseconds: t), () {
          if (!mounted) return;
          setState(() {
            _positions[s.id] = bin.position;
            _placed.add(s.id);
            _burstByBin[bin.id] = (_burstByBin[bin.id] ?? 0) + 1;
            _handVisible = true;
            _handTarget = bin.position;
            _pokeKey += 1;
          });
          final sides = bin.id == 'bin-3'
              ? 'Three sides.'
              : bin.id == 'bin-4'
                  ? 'Four sides.'
                  : 'Five sides.';
          _speak(sides, 'k-g-4-lesson:auto-${s.id}');
        }),
      );
      t += 700;
    }
    _timers.add(
      Timer(Duration(milliseconds: t + 200), () {
        if (!mounted) return;
        _speak(
          'Six shapes sorted. Two in each basket.',
          'k-g-4-lesson:we-try-closer',
        );
      }),
    );
    _timers.add(
      Timer(Duration(milliseconds: t + 2200), () {
        if (!mounted) return;
        setState(() => _handVisible = false);
        _finishLesson();
      }),
    );
  }

  void _finishLesson() {
    if (_beat == _Beat.done) return;
    setState(() => _beat = _Beat.done);
    widget.onComplete();
  }

  void _onShapeDropOnBin({
    required _LessonShape shape,
    required _LessonBin bin,
  }) {
    if (_placed.contains(shape.id)) return;
    if (bin.id != shape.targetBin) {
      // Wrong basket — bounce back to the start position + speak the
      // corrective line.
      setState(() => _positions[shape.id] = shape.startPos);
      _speak(
        bin.id == 'bin-3'
            ? 'That basket is for shapes with three sides. Try another!'
            : bin.id == 'bin-4'
                ? 'That basket is for shapes with four sides. Try another!'
                : 'That basket is for shapes with five or more sides. Try another!',
        'k-g-4-lesson:we-try-corrective-${shape.id}-${bin.id}',
      );
      return;
    }
    setState(() {
      _positions[shape.id] = bin.position;
      _placed.add(shape.id);
      _burstByBin[bin.id] = (_burstByBin[bin.id] ?? 0) + 1;
      _kidActionInflight = false;
    });
    final sides = bin.id == 'bin-3'
        ? 'Three sides.'
        : bin.id == 'bin-4'
            ? 'Four sides.'
            : 'Five sides.';
    _speak(sides, 'k-g-4-lesson:we-try-right-${shape.id}');
    if (_kLessonShapes.every((s) => _placed.contains(s.id))) {
      _timers.add(
        Timer(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          _speak(
            'Six shapes sorted. Two in each basket.',
            'k-g-4-lesson:we-try-closer',
          );
        }),
      );
      _timers.add(
        Timer(const Duration(milliseconds: 2800), _finishLesson),
      );
    } else if (!_kidActionInflight) {
      _scheduleWeTryHesitation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final inviteShape = _beat == _Beat.weTry ? _nextKidShape : null;
        // Schedule the first hesitation timer once we know who the kid
        // is being invited to drag.
        if (_beat == _Beat.weTry &&
            inviteShape != null &&
            !_kidActionInflight) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_kidActionInflight) return;
            _kidActionInflight = true;
            _scheduleWeTryHesitation();
          });
        }
        return Stack(
          children: [
            // Bins along the bottom.
            for (final bin in _kLessonBins)
              _BinTarget(
                bin: bin,
                canvasW: w,
                canvasH: h,
                burstCounter: _burstByBin[bin.id] ?? 0,
                highlighted: inviteShape?.targetBin == bin.id,
                onAccept: (shape) =>
                    _onShapeDropOnBin(shape: shape, bin: bin),
              ),
            // Shapes — placed ones lock to their bin; unplaced ones
            // are draggable in We-Try (only the invited one).
            for (final shape in _kLessonShapes)
              _LessonShapeWidget(
                shape: shape,
                position: _positions[shape.id] ?? shape.startPos,
                canvasW: w,
                canvasH: h,
                placed: _placed.contains(shape.id),
                draggable:
                    _beat == _Beat.weTry && inviteShape?.id == shape.id,
              ),
            // Hand pointer overlay for the I-Show + auto-complete beats.
            if (_handVisible)
              LessonHandPointer(
                visible: true,
                target: Offset(
                  _handTarget.dx * w - 48,
                  _handTarget.dy * h - 48,
                ),
                pokeKey: _pokeKey,
                size: 96,
              ),
          ],
        );
      },
    );
  }
}

class _LessonShapeWidget extends StatelessWidget {
  const _LessonShapeWidget({
    required this.shape,
    required this.position,
    required this.canvasW,
    required this.canvasH,
    required this.placed,
    required this.draggable,
  });

  final _LessonShape shape;
  final Offset position;
  final double canvasW;
  final double canvasH;
  final bool placed;
  final bool draggable;

  static const double _kSize = 96;

  @override
  Widget build(BuildContext context) {
    final cx = position.dx * canvasW;
    final cy = position.dy * canvasH;
    final sprite = Image.asset(
      AssetPaths.shapeGarden2dSprite(shape.kind, shape.variant),
      fit: BoxFit.contain,
      width: _kSize,
      height: _kSize,
    );
    final visual = AnimatedScale(
      duration: const Duration(milliseconds: 280),
      scale: placed ? 0.6 : 1.0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        opacity: placed ? 0.55 : 1.0,
        child: sprite,
      ),
    );
    return AnimatedPositioned(
      key: ValueKey('k-g-4-lesson-shape-${shape.id}'),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      left: cx - _kSize / 2,
      top: cy - _kSize / 2,
      width: _kSize,
      height: _kSize,
      child: draggable
          ? Draggable<_LessonShape>(
              data: shape,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: _kSize,
                  height: _kSize,
                  child: sprite,
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: sprite),
              child: visual,
            )
          : IgnorePointer(child: visual),
    );
  }
}

class _BinTarget extends StatelessWidget {
  const _BinTarget({
    required this.bin,
    required this.canvasW,
    required this.canvasH,
    required this.burstCounter,
    required this.highlighted,
    required this.onAccept,
  });

  final _LessonBin bin;
  final double canvasW;
  final double canvasH;
  final int burstCounter;
  final bool highlighted;
  final ValueChanged<_LessonShape> onAccept;

  static const double _kBinWidth = 200;
  static const double _kBinHeight = 130;

  @override
  Widget build(BuildContext context) {
    final cx = bin.position.dx * canvasW;
    final cy = bin.position.dy * canvasH;
    return Positioned(
      left: cx - _kBinWidth / 2,
      top: cy - _kBinHeight / 2,
      width: _kBinWidth,
      height: _kBinHeight,
      child: DragTarget<_LessonShape>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) => onAccept(details.data),
        builder: (context, candidate, rejected) {
          final hot = highlighted || candidate.isNotEmpty;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: hot ? 0.85 : 0.7,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: hot
                        ? Colors.amber.shade400
                        : const Color(0xFFD8D2C2),
                    width: hot ? 4 : 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      bin.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              if (burstCounter > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: GlitterBurst(
                      key: ValueKey('k-g-4-bin-burst-${bin.id}-$burstCounter'),
                      maxRadius: 110,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
