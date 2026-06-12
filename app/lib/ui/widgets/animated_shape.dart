// AnimatedShape — Shape Garden's tap-target sprite. Used by the K.G.2
// lesson stage today and (eventually) the Shape Garden activity rounds.
//
// Same idea as AnimatedFawn:
//   - Renders the sprite at an authored rotation + scale (encodes the
//     lesson runtime's "variant" like `point-down` / `rotated-45`).
//   - Optional soft halo when `pointed` is true (lesson pointer-touch beat).
//   - One-shot squash/stretch/hop on `active` flipping false → true (the
//     same arc the fawn uses).
//
// `pose` carries the rotation + scale derived from the runtime's variant
// string. The renderer that builds these widgets translates the variant —
// AnimatedShape just receives the final transform.

import 'package:flutter/material.dart';

class ShapePose {
  const ShapePose({this.rotationDegrees = 0, this.scale = 1.0});

  /// 0 = upright. 180 = upside-down. 45 = rotated clockwise 45°.
  final double rotationDegrees;

  /// Multiplier on the base sprite size. Use ~0.7 for small, ~1.2 for large.
  final double scale;

  double get rotationRadians => rotationDegrees * 3.14159265 / 180;
}

class AnimatedShape extends StatefulWidget {
  const AnimatedShape({
    super.key,
    required this.spriteAsset,
    required this.active,
    this.pose = const ShapePose(),
    this.pointed = false,
    this.size = 100,
    this.hopHeight = 28,
  });

  /// The shape sprite to draw (e.g. triangle-leaf, circle-sunflower).
  final String spriteAsset;

  /// One-shot hop fires when this flips false → true.
  final bool active;

  /// Rotation + scale captured at authoring time.
  final ShapePose pose;

  /// Subtle halo glow used by the lesson pointer to mark the upcoming target.
  final bool pointed;

  /// Display side length of the unrotated sprite box.
  final double size;

  /// Apex of the hop on `active` flip.
  final double hopHeight;

  @override
  State<AnimatedShape> createState() => _AnimatedShapeState();
}

class _AnimatedShapeState extends State<AnimatedShape>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hop;
  late final Animation<double> _scaleY;
  late final Animation<double> _scaleX;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _hop = AnimationController(
      duration: const Duration(milliseconds: 480),
      vsync: this,
    );

    _scaleY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.75)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.75, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 15,
      ),
    ]).animate(_hop);

    _scaleX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 0.9)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 15,
      ),
    ]).animate(_hop);

    _translateY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 18),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -widget.hopHeight)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -widget.hopHeight, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 15),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 15),
    ]).animate(_hop);

    if (widget.active) _hop.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedShape old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _hop.forward(from: 0);
    } else if (!widget.active && old.active) {
      _hop.value = 0;
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = widget.size * widget.pose.scale;
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: AnimatedBuilder(
        animation: _hop,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _translateY.value),
            child: Transform.scale(
              scaleX: _scaleX.value,
              scaleY: _scaleY.value,
              alignment: Alignment.bottomCenter,
              child: Transform.rotate(
                angle: widget.pose.rotationRadians,
                child: child,
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Halo behind the sprite — fades in on pointed / active.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: widget.active
                  ? 1.0
                  : widget.pointed
                      ? 0.6
                      : 0.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.active
                              ? Colors.amber
                              : Colors.amberAccent)
                          .withValues(alpha: 0.7),
                      blurRadius: widget.active ? 26 : 16,
                      spreadRadius: widget.active ? 3 : 1,
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
                top: 0,
                right: 0,
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.amber,
                  size: 24,
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
