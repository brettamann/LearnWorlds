// GlitterBurst — one-shot star/sparkle particle effect that radiates outward
// from a centered point. Use it to mark impact moments (a demo hand poking a
// fawn, a kid's correct answer, a chest-pull, etc.) without needing a separate
// "with rays" sprite version of the actor.
//
// The widget self-runs to completion. Caller controls when it fires by keying
// it on a generation counter — bumping the key spawns a fresh burst:
//
//   GlitterBurst(key: ValueKey('burst-$fawnIndex-${counters[fawnIndex]}'))
//
// Size: takes the full size of the parent, so wrap in a SizedBox or position
// it within a Stack such that its bounds equal the actor's bounds.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class GlitterBurst extends StatefulWidget {
  const GlitterBurst({
    super.key,
    this.particleCount = 8,
    this.maxRadius = 80,
    this.duration = const Duration(milliseconds: 750),
    this.color = const Color(0xFFFFE08A),
  });

  final int particleCount;
  final double maxRadius;
  final Duration duration;
  final Color color;

  @override
  State<GlitterBurst> createState() => _GlitterBurstState();
}

class _GlitterBurstState extends State<GlitterBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..forward();
    final rnd = math.Random();
    _particles = List<_Particle>.generate(widget.particleCount, (i) {
      // Even angular distribution with a small jitter so it doesn't look
      // mechanically regular.
      final base = (i / widget.particleCount) * math.pi * 2;
      final jitter = (rnd.nextDouble() - 0.5) * 0.6;
      final angle = base + jitter;
      final radius = widget.maxRadius * (0.55 + rnd.nextDouble() * 0.45);
      final size = 16.0 + rnd.nextDouble() * 14.0;
      return _Particle(angle: angle, radius: radius, size: size);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Fade in over the first 12% of the animation, then fade out over
          // the back half so the burst feels punchy on arrival.
          final fade = t < 0.12 ? t / 0.12 : (1 - t) / 0.88;
          final radial = Curves.easeOut.transform(t);
          final shrink = Curves.easeIn.transform(t);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              for (final p in _particles)
                Transform.translate(
                  offset: Offset(
                    math.cos(p.angle) * p.radius * radial,
                    math.sin(p.angle) * p.radius * radial,
                  ),
                  child: Opacity(
                    opacity: fade.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1.0 - shrink * 0.4,
                      child: Icon(
                        Icons.star,
                        size: p.size,
                        color: widget.color,
                        shadows: const [
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black38,
                          ),
                        ],
                      ),
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

class _Particle {
  const _Particle({
    required this.angle,
    required this.radius,
    required this.size,
  });

  final double angle;
  final double radius;
  final double size;
}
