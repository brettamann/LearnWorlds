// NextArrowButton — the canonical "you finished, go to the next thing" CTA.
// A big, kid-thumb-sized circular button with a right-facing arrow, a soft
// pulsing glow, and a gentle side-to-side wiggle so a K-grader sees it
// without being told.
//
// USE THIS for any "the activity / lesson / round is done, advance" moment:
//   - Lesson Continue (after iShow finishes).
//   - Round-complete sheet ("Back to the Sanctuary" / next round).
//   - Sub-mode end screens, foundry-creation confirmation, daily-quest finish.
//
// DO NOT USE for in-progress actions like "Let's count!" (those are
// activity-specific calls-to-action and shouldn't share the same affordance
// as "I'm done, proceed"). See specs/shared/ui-affordances.md.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class NextArrowButton extends StatefulWidget {
  const NextArrowButton({
    super.key,
    required this.onPressed,
    this.size = 96,
    this.label,
    this.color = const Color(0xFFFFC53D),
  });

  final VoidCallback onPressed;

  /// Diameter of the circular button.
  final double size;

  /// Optional caption rendered beneath the button. Kept short ("Continue",
  /// "Next round"). Null hides the caption — the arrow speaks for itself.
  final String? label;

  /// Body / glow tint. Default is a warm sanctuary-amber.
  final Color color;

  @override
  State<NextArrowButton> createState() => _NextArrowButtonState();
}

class _NextArrowButtonState extends State<NextArrowButton>
    with TickerProviderStateMixin {
  late final AnimationController _wiggle;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _wiggle = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _glow = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wiggle.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label ?? 'Next',
      child: AnimatedBuilder(
        animation: Listenable.merge([_wiggle, _glow]),
        builder: (context, _) {
          // Wiggle: sine wave between -1..1, scaled to ~±5°.
          final wiggleT =
              math.sin(_wiggle.value * 2 * math.pi - math.pi / 2);
          final angle = wiggleT * 0.085; // ~4.9°
          // Glow: pulsing intensity 0.55..1.0 with shadow blur/spread varying.
          final glowT = _glow.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: angle,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color
                            .withValues(alpha: 0.55 + glowT * 0.35),
                        blurRadius: 22 + glowT * 14,
                        spreadRadius: 2 + glowT * 4,
                      ),
                      BoxShadow(
                        color: Colors.amber
                            .withValues(alpha: 0.25 + glowT * 0.25),
                        blurRadius: 40 + glowT * 20,
                        spreadRadius: 6 + glowT * 6,
                      ),
                    ],
                  ),
                  child: Material(
                    shape: const CircleBorder(),
                    color: widget.color,
                    elevation: 6,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onPressed,
                      child: SizedBox(
                        width: widget.size,
                        height: widget.size,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: widget.size * 0.6,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.label != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.label!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
