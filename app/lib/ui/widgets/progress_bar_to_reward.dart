// ProgressBarToReward — the canonical "how far through this practice am I?"
// affordance: a horizontal bar with an amber fill that animates rightward,
// and a gold coin pinned at the right end. When `celebrate` flips to true,
// the coin bounces excitedly for the caller-specified duration.
//
// USE THIS for every multi-round activity in the game (Counting Parade,
// Ten-Frame Pond, Shape Garden, Picnic Baskets, etc.). The kid learns once
// that the bar fills with progress and the coin at the end means "reward
// for finishing." Per-activity reward authoring is consistent, and kids see
// effort → progress → reward in the same shape everywhere.
//
// Pattern doc: specs/shared/activity-progress-bar.md.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class ProgressBarToReward extends StatefulWidget {
  const ProgressBarToReward({
    super.key,
    required this.progress,
    this.celebrate = false,
    this.barHeight = 22,
    this.coinSize = 56,
    this.fillDuration = const Duration(milliseconds: 500),
  });

  /// Sequence completion, 0.0..1.0. The widget animates the fill smoothly
  /// to whatever value is passed (TweenAnimationBuilder owns the easing).
  final double progress;

  /// Flip to true to start the coin's bounce loop; flip back to false to
  /// stop it. Typical usage: hold true for ~2 s after the last round, then
  /// flip false when the keeper interstitial takes over.
  final bool celebrate;

  final double barHeight;
  final double coinSize;
  final Duration fillDuration;

  @override
  State<ProgressBarToReward> createState() => _ProgressBarToRewardState();
}

class _ProgressBarToRewardState extends State<ProgressBarToReward>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    if (widget.celebrate) _bounce.repeat();
  }

  @override
  void didUpdateWidget(ProgressBarToReward oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebrate && !oldWidget.celebrate) {
      _bounce.repeat();
    } else if (!widget.celebrate && oldWidget.celebrate) {
      _bounce.stop();
      _bounce.value = 0;
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedProgress = widget.progress.clamp(0.0, 1.0);
    return SizedBox(
      height: widget.coinSize + 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bar track + amber fill — runs full width minus the coin's radius
          // so the coin sits visually at the bar's end.
          Positioned(
            left: 0,
            right: widget.coinSize / 2,
            top: (widget.coinSize - widget.barHeight) / 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.barHeight / 2),
              child: Container(
                height: widget.barHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(widget.barHeight / 2),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: clampedProgress),
                  duration: widget.fillDuration,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFE08A),
                              Color(0xFFFFC53D),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Coin at the right end of the track. Bounces when `celebrate`.
          Positioned(
            right: 0,
            top: 0,
            child: AnimatedBuilder(
              animation: _bounce,
              builder: (context, child) {
                // 4 bumps over 2 s — feels "excited" without being chaotic.
                final t = math.sin(_bounce.value * 4 * math.pi).abs();
                final scale = widget.celebrate ? 1.0 + t * 0.22 : 1.0;
                final dy = widget.celebrate ? -t * 18 : 0.0;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: widget.coinSize,
                height: widget.coinSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC53D).withValues(alpha: 0.55),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.monetization_on,
                  size: widget.coinSize,
                  color: const Color(0xFFFFC53D),
                  shadows: const [
                    Shadow(color: Colors.black38, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
