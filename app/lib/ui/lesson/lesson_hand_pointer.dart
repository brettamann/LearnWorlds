// LessonHandPointer — the demo hand sprite used in iShow phases to indicate
// "the system is touching this target for you." Glides between targets and
// pokes (a quick scale-down + translate-down + recovery) when it arrives.
//
// Owner widget passes a `target` Offset (in the parent stack's local coords)
// and a `pokeKey`. When `pokeKey` changes, the hand plays its poke animation
// in place; when `target` changes, AnimatedPositioned glides the hand there.
//
// See specs/shared/lesson-demonstration.md for the broader pattern this
// pointer participates in (hand glide → poke + glitter → fawn hops).

import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';

/// How long the hand takes to glide between targets. Exposed at module level
/// so the LessonScreen can pre-schedule the glide to start
/// `handPointerGlideDuration` before each `pointer-touch` step — that's what
/// keeps the poke + glitter + actor hop + narration in sync at the touch
/// moment instead of arriving 650ms late.
const Duration handPointerGlideDuration = Duration(milliseconds: 450);

class LessonHandPointer extends StatefulWidget {
  const LessonHandPointer({
    super.key,
    required this.visible,
    required this.target,
    required this.pokeKey,
    this.size = 96,
    this.glideDuration = handPointerGlideDuration,
    this.pokeDuration = const Duration(milliseconds: 220),
  });

  /// Whether the hand should be drawn at all (fades in/out on changes).
  final bool visible;

  /// Top-left position the hand should glide to, in the parent stack's
  /// local coordinates.
  final Offset target;

  /// Bumping this value plays the poke animation once. Use any value type;
  /// equality is what triggers the animation (e.g. an int counter).
  final Object pokeKey;

  final double size;
  final Duration glideDuration;
  final Duration pokeDuration;

  @override
  State<LessonHandPointer> createState() => _LessonHandPointerState();
}

class _LessonHandPointerState extends State<LessonHandPointer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _poke;
  late final Animation<double> _pokeOffset;
  late final Animation<double> _pokeScale;

  @override
  void initState() {
    super.initState();
    _poke = AnimationController(
      duration: widget.pokeDuration,
      vsync: this,
    );
    // Poke: thrust down ~18px and back, with a slight scale-down on impact.
    _pokeOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 18.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 18.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
    ]).animate(_poke);
    _pokeScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
    ]).animate(_poke);
  }

  @override
  void didUpdateWidget(LessonHandPointer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pokeKey != oldWidget.pokeKey) {
      _poke.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _poke.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: widget.glideDuration,
      curve: Curves.easeInOutCubic,
      left: widget.target.dx,
      top: widget.target.dy,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 280),
          opacity: widget.visible ? 1.0 : 0.0,
          child: AnimatedBuilder(
            animation: _poke,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _pokeOffset.value),
                child: Transform.scale(
                  scale: _pokeScale.value,
                  child: child,
                ),
              );
            },
            child: Image.asset(
              AssetPaths.demoHandPointer,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
