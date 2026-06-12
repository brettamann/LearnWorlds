// FlatOrSolidRound — one round of K.G.3 "drag the shapes into the right
// basket." Used by both the K.G.3 lesson's "you-do" beat (kid sorts 2–3
// shapes solo before the lesson hands off) and the Shape Garden activity's
// flat-or-solid sub-mode (5+ rounds of 4–6 shapes each).
//
// Drag mechanic: each shape is a `Draggable<FlatOrSolidShape>`. Both bins
// accept any drop (so we can narrate a corrective on a wrong-bin attempt)
// and check the shape's `isFlat` flag against the bin in
// `onAcceptWithDetails`:
//   - correct → shape disappears from the pool, glitter pops at the bin,
//     narrator says "Triangle — flat!" (or similar)
//   - wrong   → shape returns to source on the next rebuild; narrator
//     redirects ("That's solid — try the other basket!")
//
// When every shape is sorted, the runner waits a short beat then fires
// `onComplete`. The host (lesson layer or activity runner) controls what
// happens next — another round, an interstitial, or the hand-off.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/flat_or_solid_shapes.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'glitter_burst.dart';

/// Narration style for a per-shape correct drop.
///
/// `shapeName` — "Triangle — flat!" / "Cube — solid!". The default; used
/// when the round is a shape-recognition practice (activity sub-mode).
///
/// `count` — spelled-out running total per bin: "One flat shape.", "Two
/// solid shapes.", etc. Used by the K.G.3 lesson to weave counting into
/// the sorting practice (per the lesson spec — "reinforce counting").
enum FlatOrSolidNarrationStyle { shapeName, count }

class FlatOrSolidRound extends ConsumerStatefulWidget {
  const FlatOrSolidRound({
    super.key,
    required this.shapes,
    required this.onComplete,
    required this.cueIdPrefix,
    this.headerPrompt = 'Sort the shapes — flat or solid?',
    this.spokenPrompt =
        'Sort the shapes! Flat ones in the flat basket. Solid ones in the solid basket.',
    this.shapeSize = 110,
    this.narrationStyle = FlatOrSolidNarrationStyle.shapeName,
  });

  /// Shapes to sort this round. The widget treats them as a stable pool —
  /// it doesn't add or remove from this list, just tracks per-shape sort
  /// state internally.
  final List<FlatOrSolidShape> shapes;

  /// Fires after the last shape lands in its correct bin (+ a short
  /// celebratory beat).
  final VoidCallback onComplete;

  /// Cue-id namespace so narration replays across rounds don't collide
  /// (e.g. `kg3-lesson:try`, `garden:r3`).
  final String cueIdPrefix;

  final String headerPrompt;
  final String spokenPrompt;

  /// Side length of the unsorted-pool sprite boxes. The mini icons inside
  /// the bins scale to a fixed 36 px regardless.
  final double shapeSize;

  /// Per-drop narration mode. See `FlatOrSolidNarrationStyle`.
  final FlatOrSolidNarrationStyle narrationStyle;

  @override
  ConsumerState<FlatOrSolidRound> createState() => _FlatOrSolidRoundState();
}

class _FlatOrSolidRoundState extends ConsumerState<FlatOrSolidRound> {
  final Set<String> _sortedIds = <String>{};
  final Map<String, int> _binBurstCounters = <String, int>{
    'flat': 0,
    'solid': 0,
  };
  // Running per-bin totals so count-style narration can spell out the
  // sortedSoFar each time a shape lands in the right basket.
  int _flatCount = 0;
  int _solidCount = 0;
  bool _promptSpoken = false;
  bool _completed = false;
  Timer? _completionTimer;

  static const List<String> _kSpelled = <String>[
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

  String _spelledCount(int n) =>
      n >= 0 && n < _kSpelled.length ? _kSpelled[n] : n.toString();

  @override
  void dispose() {
    _completionTimer?.cancel();
    super.dispose();
  }

  void _speak(String text, String cueId) {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(text: text, cueId: cueId),
        );
  }

  void _maybeSpeakPrompt() {
    if (_promptSpoken) return;
    _promptSpoken = true;
    _speak(widget.spokenPrompt, '${widget.cueIdPrefix}:prompt');
  }

  void _handleDrop(FlatOrSolidShape shape, {required bool binIsFlat}) {
    if (_completed) return;
    if (_sortedIds.contains(shape.id)) return;
    final correct = shape.isFlat == binIsFlat;
    if (correct) {
      setState(() {
        _sortedIds.add(shape.id);
        final binKey = binIsFlat ? 'flat' : 'solid';
        _binBurstCounters[binKey] = (_binBurstCounters[binKey] ?? 0) + 1;
        if (binIsFlat) {
          _flatCount += 1;
        } else {
          _solidCount += 1;
        }
      });
      final hitText = switch (widget.narrationStyle) {
        FlatOrSolidNarrationStyle.shapeName =>
          '${_capitalize(shape.displayName)} — ${binIsFlat ? 'flat' : 'solid'}!',
        FlatOrSolidNarrationStyle.count => () {
            final n = binIsFlat ? _flatCount : _solidCount;
            final side = binIsFlat ? 'flat' : 'solid';
            final noun = n == 1 ? 'shape' : 'shapes';
            return '${_spelledCount(n)} $side $noun.';
          }(),
      };
      _speak(hitText, '${widget.cueIdPrefix}:hit-${shape.id}');
      if (_sortedIds.length == widget.shapes.length) {
        _completed = true;
        _speak(
          'Nicely done! You sorted them all.',
          '${widget.cueIdPrefix}:done',
        );
        _completionTimer = Timer(const Duration(milliseconds: 1800), () {
          if (!mounted) return;
          widget.onComplete();
        });
      }
    } else {
      final correctSide = shape.isFlat ? 'flat' : 'solid';
      final wrongSide = binIsFlat ? 'flat' : 'solid';
      _speak(
        "That's $correctSide, not $wrongSide. Try the other basket.",
        '${widget.cueIdPrefix}:miss-${shape.id}-$wrongSide',
      );
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeSpeakPrompt();
    });

    final unsorted = widget.shapes
        .where((s) => !_sortedIds.contains(s.id))
        .toList(growable: false);
    final sortedFlat = widget.shapes
        .where((s) => _sortedIds.contains(s.id) && s.isFlat)
        .toList(growable: false);
    final sortedSolid = widget.shapes
        .where((s) => _sortedIds.contains(s.id) && !s.isFlat)
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          // Prompt banner.
          Container(
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
            child: Text(
              widget.headerPrompt,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Unsorted pool — Wrap so the row reflows if the kid has lots of
          // shapes left or the screen is narrow.
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    for (final s in unsorted)
                      _DraggableShape(
                        shape: s,
                        size: widget.shapeSize,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Bins row.
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: _Bin(
                    binIsFlat: true,
                    label: 'Flat',
                    sortedShapes: sortedFlat,
                    burstCounter: _binBurstCounters['flat'] ?? 0,
                    onAccept: (s) => _handleDrop(s, binIsFlat: true),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _Bin(
                    binIsFlat: false,
                    label: 'Solid',
                    sortedShapes: sortedSolid,
                    burstCounter: _binBurstCounters['solid'] ?? 0,
                    onAccept: (s) => _handleDrop(s, binIsFlat: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggableShape extends StatelessWidget {
  const _DraggableShape({required this.shape, required this.size});

  final FlatOrSolidShape shape;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sprite = Image.asset(
      shape.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    return Draggable<FlatOrSolidShape>(
      data: shape,
      // Feedback follows the finger. Material wrap is required for shadows
      // to render correctly above the source tree during the drag.
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: size,
          height: size,
          child: sprite,
        ),
      ),
      childWhenDragging: SizedBox(width: size, height: size),
      child: sprite,
    );
  }
}

class _Bin extends StatelessWidget {
  const _Bin({
    required this.binIsFlat,
    required this.label,
    required this.sortedShapes,
    required this.burstCounter,
    required this.onAccept,
  });

  final bool binIsFlat;
  final String label;
  final List<FlatOrSolidShape> sortedShapes;
  final int burstCounter;
  final ValueChanged<FlatOrSolidShape> onAccept;

  @override
  Widget build(BuildContext context) {
    final binAsset =
        binIsFlat ? AssetPaths.shapeGardenBin2d : AssetPaths.shapeGardenBin3d;
    return DragTarget<FlatOrSolidShape>(
      // Accept any drag so we can narrate a corrective on wrong-bin tries.
      // The actual correctness check happens in `onAcceptWithDetails`.
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.all(hovering ? 6 : 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: hovering ? 0.55 : 0.25),
                borderRadius: BorderRadius.circular(24),
                boxShadow: hovering
                    ? const [
                        BoxShadow(
                          color: Colors.amberAccent,
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.asset(binAsset, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 4),
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
            ),
            // Mini icons of sorted shapes overlaid in the bin's "mouth".
            Positioned(
              bottom: 56,
              left: 16,
              right: 16,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final s in sortedShapes)
                    Image.asset(
                      s.assetPath,
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                    ),
                ],
              ),
            ),
            // Glitter burst on a successful drop into this bin.
            if (burstCounter > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: GlitterBurst(
                    key: ValueKey('bin-${binIsFlat ? 'flat' : 'solid'}-burst-$burstCounter'),
                    maxRadius: 110,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
