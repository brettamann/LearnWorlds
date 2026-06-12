// Shape-find placement helper — generates the immutable scatter for one
// "tap all the X" beat. Used by the K.G.2 lesson's ShapeFindRound (3
// internal rounds) and the Shape Garden activity's per-round body (one
// round per shape). Centralising the layout logic here keeps both surfaces
// in lockstep on what a "round" looks like.
//
// The board:
//   - N target sprites (default 3) — variants of the target kind, rotated
//     subtly so the kid sees the K.G.2 invariance message (rotation /
//     material doesn't change a triangle into something else).
//   - M distractor sprites (default 4) — drawn from the supplied pool of
//     other already-introduced kinds.
//   - K decor sprites (butterflies / frogs / watering can) topped up so
//     the round always has a healthy mix. On the very first round of the
//     sequence — when the kid hasn't met any other shape kind yet — decor
//     stands in for the entire distractor section.
//
// Scatter: 4-column × 3-row grid with per-slot jitter, seeded by the
// caller. Reproducible for tests + a re-watch lands the kid in the same
// layout for a given (kind, seed).

import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'asset_paths.dart';

/// Identifier-less variant table per kind. Mirrors the table the lesson's
/// intro layer uses so a triangle painted yellow in the intro lands as the
/// same yellow triangle in the find round (recognition transfer).
const Map<String, List<String>> kShapeFindVariants = {
  'circle': ['sunflower', 'daisy', 'violet'],
  'triangle': ['leaf', 'petal', 'yellow'],
  'triangle-right': ['blue', 'green'],
  'square': ['brown', 'gray', 'green'],
  'rectangle': ['stone', 'sand', 'wood', 'stem', 'cement'],
  'pentagon': ['starfruit', 'orange'],
  'hexagon': ['honeycomb', 'terracotta'],
  'semicircle_half': ['brown', 'green'],
  'semicircle_quarter': ['brown', 'green'],
};

/// One placed sprite. Immutable — consumers track tap state separately
/// (typically a `Set<String>` of placement ids).
class ShapeFindPlacement {
  const ShapeFindPlacement({
    required this.id,
    required this.kind,
    required this.assetPath,
    required this.center,
    required this.isTarget,
    required this.isDecor,
    this.rotationDegrees = 0,
  });

  /// Stable, unique-within-a-board id. Used as the key for tap-state
  /// tracking and per-placement burst counters.
  final String id;

  /// Canonical shape kind (`triangle`, `circle`, ...) or the literal
  /// `'decor'` for non-shape sprites.
  final String kind;

  final String assetPath;

  /// Center position normalized to the play area (0..1 in each axis).
  final Offset center;

  final bool isTarget;
  final bool isDecor;

  /// Small visual jitter — reinforces K.G.2 invariance (rotation doesn't
  /// change kind) without making the board feel chaotic.
  final double rotationDegrees;
}

/// Pool of decor assets used for non-shape distractors. Returned in a
/// stable order; callers shuffle with their own seed.
List<String> _decorPool() => <String>[
      AssetPaths.shapeGardenButterfly('blue'),
      AssetPaths.shapeGardenButterfly('pink'),
      AssetPaths.shapeGardenButterfly('purple'),
      AssetPaths.shapeGardenButterfly('yellow'),
      AssetPaths.shapeGardenFrog('green'),
      AssetPaths.shapeGardenFrog('orange'),
      AssetPaths.shapeGardenFrog('red'),
      AssetPaths.shapeGardenFrog('teal'),
      AssetPaths.shapeGardenWateringCan,
    ];

/// Builds a one-round scatter of placements. The whole thing is
/// seedable — pass the same `seed` and the layout is identical.
List<ShapeFindPlacement> buildShapeFindPlacements({
  required String targetKind,
  required List<String> distractorKindPool,
  required int seed,
  int targetCount = 3,
  int distractorCount = 4,
  int decorTopUp = 2,
}) {
  final rnd = math.Random(seed);
  final targetVariants =
      kShapeFindVariants[targetKind] ?? const <String>['leaf'];

  final out = <ShapeFindPlacement>[];
  for (var i = 0; i < targetCount; i++) {
    final variant = targetVariants[i % targetVariants.length];
    final rotation = (rnd.nextDouble() - 0.5) * 30;
    out.add(
      ShapeFindPlacement(
        id: 'target-$targetKind-$i',
        kind: targetKind,
        assetPath: AssetPaths.shapeGarden2dSprite(targetKind, variant),
        center: Offset.zero, // assigned below
        isTarget: true,
        isDecor: false,
        rotationDegrees: rotation,
      ),
    );
  }

  // Pool of shape-kind distractors — anything in the pool that isn't the
  // target kind. The runner controls which kinds the kid has already met.
  final eligibleKinds =
      distractorKindPool.where((k) => k != targetKind).toList();
  final shapeDistractorCount = math.min(
    distractorCount,
    eligibleKinds.length * 2,
  );
  for (var i = 0; i < shapeDistractorCount; i++) {
    final kind = eligibleKinds[i % eligibleKinds.length];
    final variants = kShapeFindVariants[kind] ?? const <String>['leaf'];
    final variant = variants[(i ~/ eligibleKinds.length) % variants.length];
    final rotation = (rnd.nextDouble() - 0.5) * 40;
    out.add(
      ShapeFindPlacement(
        id: 'distractor-$kind-$i',
        kind: kind,
        assetPath: AssetPaths.shapeGarden2dSprite(kind, variant),
        center: Offset.zero,
        isTarget: false,
        isDecor: false,
        rotationDegrees: rotation,
      ),
    );
  }

  // Decor top-up: keep the round visually mixed; on the first round of a
  // sequence (no eligible distractor kinds) decor *is* the entire
  // distractor section.
  final decorNeeded = distractorCount - shapeDistractorCount + decorTopUp;
  final decor = _decorPool()..shuffle(rnd);
  for (var i = 0; i < decorNeeded && i < decor.length; i++) {
    out.add(
      ShapeFindPlacement(
        id: 'decor-$i',
        kind: 'decor',
        assetPath: decor[i],
        center: Offset.zero,
        isTarget: false,
        isDecor: true,
      ),
    );
  }

  // Scatter onto a 4-col × 3-row grid with a small per-slot jitter. With
  // up to ~9 sprites this gives enough breathing room for 144-px targets.
  out.shuffle(rnd);
  const cols = 4;
  const rows = 3;
  final slots = List<int>.generate(cols * rows, (i) => i)..shuffle(rnd);
  final placed = <ShapeFindPlacement>[];
  for (var i = 0; i < out.length; i++) {
    final slot = slots[i % slots.length];
    final col = slot % cols;
    final row = slot ~/ cols;
    final jitterX = (rnd.nextDouble() - 0.5) * 0.06;
    final jitterY = (rnd.nextDouble() - 0.5) * 0.06;
    final cx = (col + 0.5) / cols + jitterX;
    final cy = (row + 0.5) / rows + jitterY;
    placed.add(
      ShapeFindPlacement(
        id: out[i].id,
        kind: out[i].kind,
        assetPath: out[i].assetPath,
        center: Offset(cx, cy),
        isTarget: out[i].isTarget,
        isDecor: out[i].isDecor,
        rotationDegrees: out[i].rotationDegrees,
      ),
    );
  }
  return placed;
}
