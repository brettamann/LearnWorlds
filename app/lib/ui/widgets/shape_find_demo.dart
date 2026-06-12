// ShapeFindDemo — one-shot tutorial that plays before the kid's *first*
// find round (circles). Lays out a mock board of 3 circle targets plus a
// couple of decor distractors, then runs the demo hand pointer through
// the targets one at a time while the narrator explains the mechanic:
//
//   "Now I'll show you how to find them! I'm looking for circles..."
//   pointer glides to circle #1 → poke + glitter → "There's one!"
//   pointer glides to circle #2 → poke + glitter → "And another!"
//   pointer glides to circle #3 → poke + glitter → "Got them all!"
//   "Now it's your turn — try and find them yourself."
//
// The board uses the same placement helpers as ShapeFindRound so the kid
// sees a believable preview of the real round that follows. Decor (a
// butterfly + a frog) is included so the demo can show the hand
// deliberately *avoiding* a wrong tap — "not the butterfly! Looking for
// circles."
//
// The widget is read-only: tapping anything is a no-op until the demo
// concludes and `onComplete` fires. The LessonScreen swaps to the real
// ShapeFindRound right after.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'animated_shape.dart';
import 'glitter_burst.dart';
import 'lesson_hand_pointer.dart';
import 'shape_find_round.dart' show kFindRoundVariantsByKind;
import 'shape_intro_layer.dart'
    show kShapeDisplayName, kShapeDisplayPlural;

class ShapeFindDemo extends ConsumerStatefulWidget {
  const ShapeFindDemo({
    super.key,
    required this.targetKind,
    required this.onComplete,
  });

  /// Shape kind the demo will hunt for. Always `circle` in the current
  /// sequence (the demo only runs once, before the very first find round),
  /// but the widget takes it as a parameter so we can repurpose later.
  final String targetKind;

  /// Fired after the wrap-up "Now it's your turn" line plays. The
  /// LessonScreen swaps in the real ShapeFindRound.
  final VoidCallback onComplete;

  @override
  ConsumerState<ShapeFindDemo> createState() => _ShapeFindDemoState();
}

class _ShapeFindDemoState extends ConsumerState<ShapeFindDemo> {
  static const double _spriteSize = 144;
  static const double _spriteSizeDecor = 120;

  // Demo cadence — kept generous so a 5-year-old can absorb each step.
  static const int _introMs = 800;
  static const int _firstTapMs = 2600;
  static const int _stepMs = 2200;
  static const int _wrapupGapMs = 1200;
  static const int _completeGapMs = 2200;

  late final List<_DemoPlacement> _placements;
  final List<Timer> _timers = [];
  final Map<String, int> _burstCounters = <String, int>{};
  int? _activeTargetIndex; // index into _targets
  int _pokeCounter = 0;
  bool _pointerVisible = false;

  String get _targetDisplay =>
      kShapeDisplayName[widget.targetKind] ?? widget.targetKind;
  String get _targetPlural =>
      kShapeDisplayPlural[widget.targetKind] ?? '${_targetDisplay}s';

  List<_DemoPlacement> get _targets =>
      _placements.where((p) => p.isTarget).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _placements = _buildPlacements();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleDemo();
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

  /// Builds a small mock board — 3 targets + 2 decor distractors arranged
  /// across the available area. Hand-tuned positions (not seeded scatter)
  /// so the demo always lands in a clean, predictable layout the narrator
  /// can rely on.
  List<_DemoPlacement> _buildPlacements() {
    final variants = kFindRoundVariantsByKind[widget.targetKind] ??
        const <String>['leaf'];
    return <_DemoPlacement>[
      _DemoPlacement(
        id: 'demo-target-0',
        assetPath: AssetPaths.shapeGarden2dSprite(
          widget.targetKind,
          variants[0 % variants.length],
        ),
        center: const Offset(0.22, 0.46),
        isTarget: true,
        isDecor: false,
        rotationDegrees: -8,
      ),
      _DemoPlacement(
        id: 'demo-decor-0',
        assetPath: AssetPaths.shapeGardenButterfly('blue'),
        center: const Offset(0.42, 0.30),
        isTarget: false,
        isDecor: true,
      ),
      _DemoPlacement(
        id: 'demo-target-1',
        assetPath: AssetPaths.shapeGarden2dSprite(
          widget.targetKind,
          variants[1 % variants.length],
        ),
        center: const Offset(0.52, 0.62),
        isTarget: true,
        isDecor: false,
        rotationDegrees: 10,
      ),
      _DemoPlacement(
        id: 'demo-decor-1',
        assetPath: AssetPaths.shapeGardenFrog('green'),
        center: const Offset(0.68, 0.32),
        isTarget: false,
        isDecor: true,
      ),
      _DemoPlacement(
        id: 'demo-target-2',
        assetPath: AssetPaths.shapeGarden2dSprite(
          widget.targetKind,
          variants[2 % variants.length],
        ),
        center: const Offset(0.82, 0.50),
        isTarget: true,
        isDecor: false,
        rotationDegrees: -4,
      ),
    ];
  }

  /// Lays out the whole tutorial timeline up front. Re-running it on
  /// rebuild is guarded by the init-once post-frame callback above.
  void _scheduleDemo() {
    final targets = _targets;

    _schedule(_introMs, () {
      _speak(
        "Watch — I'll show you how to find them! I'm looking for $_targetPlural.",
        'find-demo:${widget.targetKind}:intro',
      );
      setState(() {
        _pointerVisible = true;
        _activeTargetIndex = 0;
      });
    });

    const hitLines = <String>[
      "There's one!",
      'And another!',
      'And the last one!',
    ];

    for (var i = 0; i < targets.length; i++) {
      final tapAt = _firstTapMs + i * _stepMs;
      // Pre-glide to the next target one glide-duration before the tap so
      // the poke + glitter + narration land together.
      if (i > 0) {
        _schedule(
          tapAt - handPointerGlideDuration.inMilliseconds,
          () => setState(() => _activeTargetIndex = i),
        );
      }
      _schedule(tapAt, () {
        final id = targets[i].id;
        setState(() {
          _burstCounters[id] = (_burstCounters[id] ?? 0) + 1;
          _pokeCounter++;
          targets[i].tapped = true;
        });
        _speak(
          hitLines[i.clamp(0, hitLines.length - 1)],
          'find-demo:${widget.targetKind}:hit-$i',
        );
      });
    }

    final lastTapAt = _firstTapMs + (targets.length - 1) * _stepMs;
    final wrapupAt = lastTapAt + _wrapupGapMs;
    _schedule(wrapupAt, () {
      setState(() {
        _pointerVisible = false;
        _activeTargetIndex = null;
      });
      _speak(
        "Now it's your turn — try and find the $_targetPlural yourself.",
        'find-demo:${widget.targetKind}:wrapup',
      );
    });
    _schedule(wrapupAt + _completeGapMs, widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    const handSize = 96.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        Offset handTarget;
        final idx = _activeTargetIndex;
        if (!_pointerVisible || idx == null || idx >= _targets.length) {
          handTarget = Offset(-handSize - 80, h * 0.4);
        } else {
          final p = _targets[idx];
          final cx = p.center.dx * w;
          final cy = p.center.dy * h;
          handTarget = Offset(cx - handSize * 0.4, cy - handSize * 0.85);
        }

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Header banner — same shape language as ShapeFindRound, marked
            // "Watch" so the kid knows this is a demo not a tap-fest.
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Watch — find the $_targetPlural!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Demo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            for (final p in _placements)
              Positioned(
                left: p.center.dx * w -
                    (p.isDecor ? _spriteSizeDecor : _spriteSize) / 2,
                top: p.center.dy * h -
                    (p.isDecor ? _spriteSizeDecor : _spriteSize) / 2 +
                    24,
                width: p.isDecor ? _spriteSizeDecor : _spriteSize,
                height: p.isDecor ? _spriteSizeDecor : _spriteSize,
                child: IgnorePointer(
                  child: p.isDecor
                      ? Image.asset(
                          p.assetPath,
                          fit: BoxFit.contain,
                        )
                      : AnimatedShape(
                          spriteAsset: p.assetPath,
                          active: p.tapped,
                          pose: ShapePose(
                            rotationDegrees: p.rotationDegrees,
                          ),
                          size: _spriteSize,
                        ),
                ),
              ),
            for (final entry in _burstCounters.entries)
              if (entry.value > 0)
                Builder(
                  builder: (_) {
                    final placement = _placements.firstWhere(
                      (p) => p.id == entry.key,
                    );
                    final size = placement.isDecor
                        ? _spriteSizeDecor
                        : _spriteSize;
                    return Positioned(
                      left: placement.center.dx * w - size / 2 - 22,
                      top: placement.center.dy * h - size / 2 + 24 - 22,
                      width: size + 44,
                      height: size + 44,
                      child: GlitterBurst(
                        key: ValueKey(
                          'find-demo-burst-${entry.key}-${entry.value}',
                        ),
                      ),
                    );
                  },
                ),
            LessonHandPointer(
              visible: _pointerVisible,
              target: handTarget,
              pokeKey: _pokeCounter,
              size: handSize,
            ),
          ],
        );
      },
    );
  }
}

class _DemoPlacement {
  _DemoPlacement({
    required this.id,
    required this.assetPath,
    required this.center,
    required this.isTarget,
    required this.isDecor,
    this.rotationDegrees = 0,
  });

  final String id;
  final String assetPath;
  final Offset center;
  final bool isTarget;
  final bool isDecor;
  final double rotationDegrees;
  bool tapped = false;
}
