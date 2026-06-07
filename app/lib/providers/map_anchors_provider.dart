// Scans the Sanctuary map PNG once at app start and exposes the magenta
// anchor positions to anyone who needs them. Other regions (Wundletown,
// Mathopolis) will add their own provider instances via this same family.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/asset_paths.dart';
import '../data/map_anchor_scanner.dart';

final mapAnchorsProvider = FutureProvider.family<MapAnchors, String>(
  (ref, assetPath) async => const MapAnchorScanner().scan(assetPath),
);

/// Convenience accessor for the Sanctuary map's anchors.
final sanctuaryAnchorsProvider = FutureProvider<MapAnchors>(
  (ref) => ref.watch(mapAnchorsProvider(AssetPaths.mysticSanctuaryMap).future),
);
