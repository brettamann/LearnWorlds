// HomeMapScreen — the island overview. Four regions are drawn on the
// placeholder art (Home, Foundry, Portals, Mystic Sanctuary); only the
// Mystic Sanctuary is wired up while the K vertical slice is the only
// region with real content. The disabled regions are intentionally kept
// on the map so the layout, art, and pattern are exercised end-to-end
// before more content lands.
//
// Region rectangles are normalized 0..1 coordinates relative to the rendered
// image. See specs/shared/map-screens.md for the authoring guidance.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/asset_paths.dart';
import '../widgets/map_screen.dart';

class HomeMapScreen extends ConsumerWidget {
  const HomeMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MapScreen(
      imageAsset: AssetPaths.homeScreenMap,
      // PNG is 860x699.
      aspectRatio: 860 / 699,
      appBar: AppBar(
        title: const Text('Mystical Island'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      regions: [
        MapRegion(
          id: 'home',
          label: 'Home',
          rect: const Rect.fromLTWH(0.18, 0.38, 0.22, 0.30),
          enabled: false,
          onTap: () {},
        ),
        MapRegion(
          id: 'foundry',
          label: 'Foundry',
          rect: const Rect.fromLTWH(0.04, 0.08, 0.22, 0.30),
          enabled: false,
          onTap: () {},
        ),
        MapRegion(
          id: 'portals',
          label: 'Portals',
          rect: const Rect.fromLTWH(0.42, 0.02, 0.24, 0.28),
          enabled: false,
          onTap: () {},
        ),
        MapRegion(
          id: 'mystic-sanctuary',
          label: 'Mystic Sanctuary',
          rect: const Rect.fromLTWH(0.62, 0.32, 0.30, 0.36),
          onTap: () => context.go('/sanctuary'),
        ),
      ],
    );
  }
}
