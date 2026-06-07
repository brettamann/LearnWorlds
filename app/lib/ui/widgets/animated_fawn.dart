// AnimatedFawn — fawn sprite with a one-shot squash/stretch/hop animation that
// fires when `active` transitions from false to true.
//
// Used in two places:
//   - CountingParadeRunner — `active` = the fawn was tapped this round.
//   - LessonScreen iShow — `active` = the sparkle/pointer-touch animation step
//     fired for this fawn's index in the lesson timeline.
//
// Animation arc (~520ms total):
//   1. Squash (anticipation) — vertical compress
//   2. Stretch + lift        — extend vertically, translate up (the jump)
//   3. Land squash           — compress on touchdown
//   4. Settle                — elastic-out back to rest

import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';

class AnimatedFawn extends StatefulWidget {
  const AnimatedFawn({
    super.key,
    required this.active,
    this.spriteAsset = AssetPaths.countingParadeFawn,
    this.pointed = false,
    this.width = 128,
    this.height = 160,
    this.hopHeight = 50,
  });

  /// Whether the creature is in its "tapped/counted" state. Flipping
  /// false → true plays the hop animation; flipping true → false snaps to rest.
  final bool active;

  /// Which sprite to draw. Defaults to the original fawn — the same widget
  /// drives every creature in the Counting Parade sequence (gryphons,
  /// dragons, unicorns, etc.) and any future Sanctuary tap-counter.
  final String spriteAsset;

  /// Soft glow only (used in lesson-iShow to highlight the about-to-be-tapped
  /// creature). No animation; just a visual hint.
  final bool pointed;

  final double width;
  final double height;

  /// How far up the creature rises at the apex of the hop.
  final double hopHeight;

  @override
  State<AnimatedFawn> createState() => _AnimatedFawnState();
}

class _AnimatedFawnState extends State<AnimatedFawn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleY;
  late final Animation<double> _scaleX;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    );

    _scaleY = TweenSequence<double>([
      // Squash (anticipation).
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.72)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      // Stretch + launch.
      TweenSequenceItem(
        tween: Tween(begin: 0.72, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      // Apex: drift back to neutral.
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      // Land squash.
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      // Settle.
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    _scaleX = TweenSequence<double>([
      // Inversely compresses while scaleY squashes — volume-preserving.
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    _translateY = TweenSequence<double>([
      // Stay grounded during anticipation.
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 15),
      // Lift off.
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -widget.hopHeight)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      // Fall to ground.
      TweenSequenceItem(
        tween: Tween(begin: -widget.hopHeight, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      // Stay grounded for land + settle.
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 20),
    ]).animate(_controller);

    if (widget.active) {
      // Skip the animation if mounted into an already-active state (e.g.
      // returning to a round mid-progress in a future sprint).
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedFawn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0.0);
    } else if (!widget.active && oldWidget.active) {
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateY.value),
          child: Transform.scale(
            scaleY: _scaleY.value,
            scaleX: _scaleX.value,
            // Anchor the squash at the ground so the fawn looks like it's
            // pressing into the meadow, not floating.
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Glow disc behind the sprite; fades in/out gently with state.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: widget.active
                  ? 1.0
                  : widget.pointed
                      ? 0.6
                      : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.active
                              ? Colors.amber
                              : Colors.amberAccent)
                          .withValues(alpha: 0.7),
                      blurRadius: widget.active ? 28 : 18,
                      spreadRadius: widget.active ? 4 : 1,
                    ),
                  ],
                ),
              ),
            ),
            Image.asset(
              widget.spriteAsset,
              fit: BoxFit.contain,
            ),
            if (widget.active)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.amber,
                  size: 28,
                  shadows: [
                    Shadow(blurRadius: 6, color: Colors.black54),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
