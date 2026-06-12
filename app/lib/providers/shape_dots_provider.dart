// Scans the magenta side-locator dots out of a `*-example` shape sprite and
// exposes them to the K.G.2 intro layer. Keyed by canonical shape kind
// (`triangle`, `triangle-right`, `circle`, ...). FutureProvider.family caches
// per kind so the PNG decode runs once per app session even if the same
// shape is introduced more than once in a lesson sequence.
//
// A failed/empty scan returns an empty `ShapeDots`. The intro layer treats
// an empty dot list as "no sides" (circle path) or falls back to algorithmic
// regular-polygon positions for polygons whose example file is missing.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/asset_paths.dart';
import '../data/example_dot_scanner.dart';

/// `kind` is the canonical shape key as used by AssetPaths.shapeGarden2dSprite
/// (`triangle`, `triangle-right`, `circle`, `square`, `rectangle`, `pentagon`,
/// `hexagon`, `semicircle_half`, `semicircle_quarter`).
final shapeDotsProvider = FutureProvider.family<ShapeDots, String>(
  (ref, kind) async {
    final path = AssetPaths.shapeGarden2dExample(kind);
    return const ExampleDotScanner().scan(path);
  },
);
