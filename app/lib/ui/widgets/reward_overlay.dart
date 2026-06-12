// RewardOverlay — renders a single reward-track's corner sprite on top of a
// region map, with ambient wiggle, tap-to-read flavour, and the
// stage-advancement fanfare.
//
// Animation sequence on advance:
//   0% → 25%   grow + translate from corner to center; old-stage sprite
//   25% → 50%  shake-shimmer the old sprite at centre
//   50% → 55%  flash overlay; swap sprite from old → new
//   55% → 75%  settle shake on the new sprite
//   75% → 100% shrink + translate back to corner
//
// During the animation the overlay absorbs all pointer events so the kid
// can't tap through to the map; the parent map sees nothing.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reward_track.dart';
import '../../providers/reward_progress_provider.dart';
import '../../providers/save_provider.dart';

class RewardOverlay extends ConsumerStatefulWidget {
  const RewardOverlay({super.key, required this.track});

  final RewardTrack track;

  @override
  ConsumerState<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends ConsumerState<RewardOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _advancement;
  int? _animatingFromStage;
  int? _animatingToStage;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _advancement = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );
    // Check for a pending advancement once we have a frame to size against.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAdvance());
  }

  @override
  void dispose() {
    _ambient.dispose();
    _advancement.dispose();
    super.dispose();
  }

  void _maybeAdvance() {
    if (!mounted) return;
    final progress = ref.read(rewardProgressProvider);
    final trackState = progress[widget.track.id] ?? const RewardTrackState();
    final target = widget.track.computeTargetStage(
      trackState.completedActivities,
    );
    if (target > trackState.lastSeenStage) {
      setState(() {
        _animatingFromStage = trackState.lastSeenStage;
        _animatingToStage = target;
      });
      _advancement.forward(from: 0).then((_) {
        if (!mounted) return;
        ref.read(rewardProgressProvider.notifier).markStageSeen(
              trackId: widget.track.id,
              stage: target,
            );
        ref.read(saveCoordinatorProvider).persist();
        setState(() {
          _animatingFromStage = null;
          _animatingToStage = null;
        });
      });
      return;
    }
    // Final-stage graduation: stage 8 was already seen on a prior mount
    // (lastSeenStage == finalStage) but graduated hasn't been recorded yet.
    // Flip it now and persist — next render shows the hatched sprite.
    if (!trackState.graduated &&
        trackState.lastSeenStage == widget.track.finalStage) {
      ref
          .read(rewardProgressProvider.notifier)
          .markGraduated(trackId: widget.track.id);
      ref.read(saveCoordinatorProvider).persist();
    }
  }

  void _showFlavourMessage(BuildContext context, RewardStage stage) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset(stage.spriteAsset, fit: BoxFit.contain),
                ),
                const SizedBox(height: 18),
                Text(
                  stage.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.35,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// What sprite + ambient should the corner show right now?
  RewardStage? _displayStage(RewardTrackState trackState) {
    final target = widget.track.computeTargetStage(
      trackState.completedActivities,
    );
    if (target == 0) return null; // Nothing earned yet
    if (trackState.graduated) return widget.track.completeStage;
    // Use the last-seen stage (so the corner shows the old sprite while
    // an advancement is queued).
    final displayed =
        trackState.lastSeenStage == 0 ? target : trackState.lastSeenStage;
    return widget.track.stageByNumber(displayed);
  }

  @override
  Widget build(BuildContext context) {
    final trackState =
        ref.watch(rewardProgressProvider)[widget.track.id] ??
            const RewardTrackState();
    final stage = _displayStage(trackState);
    if (stage == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = math.min(constraints.maxWidth, constraints.maxHeight);
        final cornerSize = shortest * 0.16;
        const cornerLeft = 16.0;
        const cornerTop = 16.0;
        final centerSize = shortest * 0.45;
        final centerLeft = (constraints.maxWidth - centerSize) / 2;
        final centerTop = (constraints.maxHeight - centerSize) / 2;

        // Advancement animation overrides ambient when active.
        if (_animatingToStage != null) {
          return _buildAdvancementOverlay(
            cornerLeft: cornerLeft,
            cornerTop: cornerTop,
            cornerSize: cornerSize,
            centerLeft: centerLeft,
            centerTop: centerTop,
            centerSize: centerSize,
          );
        }

        return Stack(
          children: [
            Positioned(
              left: cornerLeft,
              top: cornerTop,
              width: cornerSize,
              height: cornerSize,
              child: _AmbientSprite(
                stage: stage,
                ambient: _ambient,
                onTap: () => _showFlavourMessage(context, stage),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdvancementOverlay({
    required double cornerLeft,
    required double cornerTop,
    required double cornerSize,
    required double centerLeft,
    required double centerTop,
    required double centerSize,
  }) {
    final fromStage = _animatingFromStage ?? 0;
    final toStage = _animatingToStage!;
    // fromStage may be 0 (the very first advance to stage 1) — in that case
    // we don't have an "old sprite". Use the new sprite throughout but
    // delay its first appearance to the flash beat.
    final hasOldSprite = fromStage >= 1;
    final oldSprite =
        hasOldSprite ? widget.track.stageByNumber(fromStage).spriteAsset : null;
    final newSprite = widget.track.stageByNumber(toStage).spriteAsset;

    return AbsorbPointer(
      child: AnimatedBuilder(
        animation: _advancement,
        builder: (context, _) {
          final t = _advancement.value;

          // Phase ranges.
          double phaseT(double start, double end) {
            if (t < start) return 0;
            if (t > end) return 1;
            return (t - start) / (end - start);
          }

          // 0..0.25 grow + travel from corner to centre.
          final growT = Curves.easeOutCubic.transform(phaseT(0, 0.25));
          // 0.5..0.55 swap.
          final swapPhase = phaseT(0.5, 0.55);
          // 0.75..1.0 shrink back to corner.
          final returnT = Curves.easeInCubic.transform(phaseT(0.75, 1));

          // Position + size interp.
          double currentLeft;
          double currentTop;
          double currentSize;
          if (t <= 0.25) {
            currentLeft = cornerLeft + (centerLeft - cornerLeft) * growT;
            currentTop = cornerTop + (centerTop - cornerTop) * growT;
            currentSize = cornerSize + (centerSize - cornerSize) * growT;
          } else if (t >= 0.75) {
            currentLeft = centerLeft + (cornerLeft - centerLeft) * returnT;
            currentTop = centerTop + (cornerTop - centerTop) * returnT;
            currentSize = centerSize + (cornerSize - centerSize) * returnT;
          } else {
            currentLeft = centerLeft;
            currentTop = centerTop;
            currentSize = centerSize;
          }

          // Shake intensity ramps up before the swap and back down after.
          double shakeIntensity = 0;
          if (t > 0.25 && t < 0.75) {
            // 0.25..0.5 ramps up, 0.5..0.55 peaks, 0.55..0.75 fades.
            if (t < 0.5) {
              shakeIntensity = (t - 0.25) / 0.25;
            } else if (t < 0.55) {
              shakeIntensity = 1.0;
            } else {
              shakeIntensity = 1.0 - (t - 0.55) / 0.20;
            }
          }
          final shakeDx =
              (_rng.nextDouble() - 0.5) * 12 * shakeIntensity;
          final shakeDy =
              (_rng.nextDouble() - 0.5) * 12 * shakeIntensity;

          // Which sprite to draw — old or new.
          final showNewSprite = !hasOldSprite || t >= 0.525;
          final spriteAsset = showNewSprite ? newSprite : oldSprite!;

          return Stack(
            children: [
              // Dim the map behind during the centred portion.
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.35 * Curves.easeInOut.transform(
                        phaseT(0.05, 0.25),
                      ) *
                          (1 - phaseT(0.75, 0.95)),
                    ),
                  ),
                ),
              ),
              // The sprite.
              Positioned(
                left: currentLeft + shakeDx,
                top: currentTop + shakeDy,
                width: currentSize,
                height: currentSize,
                child: Image.asset(spriteAsset, fit: BoxFit.contain),
              ),
              // White flash over the sprite during the swap.
              Positioned(
                left: currentLeft,
                top: currentTop,
                width: currentSize,
                height: currentSize,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: swapPhase > 0 && swapPhase < 1
                        ? (1.0 - (swapPhase - 0.5).abs() * 2).clamp(0.0, 1.0)
                        : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.95),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
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

class _AmbientSprite extends StatelessWidget {
  const _AmbientSprite({
    required this.stage,
    required this.ambient,
    required this.onTap,
  });

  final RewardStage stage;
  final AnimationController ambient;
  final VoidCallback onTap;

  /// Translate the discrete ambient level into translate/scale amplitudes.
  /// Tuned so even "energetic" stays comfortably tappable.
  (double translateY, double scaleY) _amplitudes() {
    switch (stage.ambient) {
      case RewardAmbient.still:
        return (0, 0);
      case RewardAmbient.gentle:
        return (3, 0.02);
      case RewardAmbient.moderate:
        return (6, 0.045);
      case RewardAmbient.energetic:
        return (10, 0.08);
      case RewardAmbient.gentleHatched:
        return (4, 0.03);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (yAmp, sAmp) = _amplitudes();
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: ambient,
        builder: (context, child) {
          final t = ambient.value;
          final phase = math.sin(t * 2 * math.pi);
          final dy = phase * yAmp;
          // Subtle volume-preserving squash: vertical and horizontal scales
          // move in opposite directions so the sprite looks alive.
          final scaleY = 1 + phase * sAmp;
          final scaleX = 1 - phase * sAmp * 0.7;
          return Transform.translate(
            offset: Offset(0, -dy.abs()),
            child: Transform.scale(
              scaleX: scaleX,
              scaleY: scaleY,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(stage.spriteAsset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
