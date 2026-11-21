// ShapeScatterBoard - "tap all the triangles" over a scatter of shapes.
//
// The board behind both the K.G.2 lesson's find rounds and Shape Garden's
// finding sub-mode. They were two line-for-line copies, and had drifted: only
// the garden kept its sprites clear of the caption band, which is the bug
// PlayfieldArea's header describes.
//
// Stateless: the owner keeps what has been tapped and decides what a tap
// means. This only draws the banner, the scatter, the shakes and the bursts.

import 'package:flutter/material.dart';

import '../../data/shape_find_placements.dart';
import '../../theme/app_decor.dart';
import '../characters/animated_shape.dart';
import '../common/answer_feedback.dart';
import '../common/glitter_burst.dart';

class ShapeScatterBoard extends StatelessWidget {
  const ShapeScatterBoard({
    super.key,
    required this.keyPrefix,
    required this.targetPlural,
    required this.roundLabel,
    required this.placements,
    required this.tappedIds,
    required this.burstCounters,
    required this.wrongTokens,
    required this.onTap,
    this.hintedId,
    this.inputLocked = false,
  });

  /// Prefixes each sprite's and burst's key, so tests can find them.
  final String keyPrefix;

  final String targetPlural;

  /// The small chip beside the prompt, e.g. "Round 2 of 8".
  final String roundLabel;

  final List<ShapeFindPlacement> placements;
  final Set<String> tappedIds;

  /// Placement id -> how many bursts it has had; a new count replays it.
  final Map<String, int> burstCounters;

  /// Placement id -> wrong taps on it. Drives the shake.
  final Map<String, int> wrongTokens;

  final ValueChanged<ShapeFindPlacement> onTap;

  /// Placement the hint ladder wants glowed, or null.
  final String? hintedId;

  /// True while the board is on screen but must not take a tap (under a
  /// celebration or the keeper's aside).
  final bool inputLocked;

  // Big enough to tap comfortably with a fingertip and for the outline to
  // read at a glance.
  static const double spriteSize = 144;
  static const double decorSize = 120;

  /// Keeps every sprite out from under the caption band. A placement is a
  /// *centre*, and a 144-pixel shape hangs 72 pixels past it in every
  /// direction; on a small window that pushed the bottom row under the band.
  static const double _margin = decorSize / 2 + 24;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        double sizeOf(ShapeFindPlacement p) =>
            p.isDecor ? decorSize : spriteSize;
        double left(ShapeFindPlacement p) => p.center.dx * w - sizeOf(p) / 2;
        double top(ShapeFindPlacement p) =>
            _margin + p.center.dy * (h - _margin * 2) - sizeOf(p) / 2 + 24;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(child: _Banner(targetPlural, roundLabel)),
            ),
            for (final p in placements)
              Positioned(
                left: left(p),
                top: top(p),
                width: sizeOf(p),
                height: sizeOf(p),
                child: IgnorePointer(
                  ignoring: inputLocked,
                  child: GestureDetector(
                    key: ValueKey('$keyPrefix-${p.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(p),
                    // The burst is drawn separately below, so only the wrong
                    // reaction is wanted here.
                    child: AnswerFeedback(
                      wrongToken: wrongTokens[p.id] ?? 0,
                      child: p.isDecor
                          ? Image.asset(p.assetPath, fit: BoxFit.contain)
                          : AnimatedShape(
                              spriteAsset: p.assetPath,
                              active: tappedIds.contains(p.id),
                              pointed: hintedId == p.id,
                              pose: ShapePose(
                                rotationDegrees: p.rotationDegrees,
                              ),
                              size: spriteSize,
                            ),
                    ),
                  ),
                ),
              ),
            for (final entry in burstCounters.entries)
              if (entry.value > 0)
                Builder(
                  builder: (_) {
                    final p = placements.firstWhere((q) => q.id == entry.key);
                    return Positioned(
                      left: left(p) - 22,
                      top: top(p) - 22,
                      width: sizeOf(p) + 44,
                      height: sizeOf(p) + 44,
                      child: GlitterBurst(
                        key: ValueKey(
                          '$keyPrefix-burst-${entry.key}-${entry.value}',
                        ),
                      ),
                    );
                  },
                ),
          ],
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.targetPlural, this.roundLabel);

  final String targetPlural;
  final String roundLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: AppDecor.card(radius: 18, shadow: AppShadows.soft),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tap all the $targetPlural!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              roundLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
