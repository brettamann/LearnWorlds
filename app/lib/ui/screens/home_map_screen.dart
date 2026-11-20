// HomeMapScreen — the island overview. Four regions are drawn on the
// placeholder art (Home, Foundry, Portals, Mystic Sanctuary); only the
// Mystic Sanctuary is wired up while the K vertical slice is the only
// region with real content. The disabled regions are intentionally kept
// on the map so the layout, art, and pattern are exercised end-to-end
// before more content lands.
//
// Region rectangles are normalized 0..1 coordinates relative to the rendered
// image. See specs/shared/map-screens.md for the authoring guidance.
//
// This is the first screen of every session and the crossroads of all the
// others, so it carries the same two fixes the Sanctuary map needed: the
// controls come down a side rail at kid size instead of sitting as 24px icons
// in the app bar, and the screen claims the music bed so the track starts at
// boot rather than at the first activity.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/asset_paths.dart';
import '../../data/map_labels.dart';
import '../../navigation/routes.dart';
import '../widgets/coin_hud.dart';
import '../widgets/map_screen.dart';
import '../widgets/map_side_rail.dart';
import '../widgets/music_bed_scope.dart';

class HomeMapScreen extends ConsumerWidget {
  const HomeMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MusicBedScope(
      // The island plays the Sanctuary's bed because it is the only calm one
      // that exists. It is also why the music now runs unbroken from boot to
      // the end of a lesson: SfxEngine claims by resolved *asset*, so every
      // screen between here and a round asks for the same file and the player
      // is simply never told to stop. An island-specific track would be a
      // catalog entry and this argument, not new code.
      child: MapScreen(
        imageAsset: AssetPaths.homeScreenMap,
        // PNG is 860x699.
        aspectRatio: 860 / 699,
        appBar: AppBar(title: const Text('Mystical Island')),
        rail: MapSideRail(
          children: [
            const CoinHud(),
            MapRailButton(
              icon: Icons.settings,
              caption: kRailSettingsLabel,
              onPressed: () => context.go(Routes.settings),
            ),
          ],
        ),
        // WHERE THESE RECTANGLES COME FROM
        // --------------------------------
        // Each one is the medallion in the painted map - the cyan disc with
        // the heavy black ring and a picture in it - measured out of
        // `home_screen_map.png` by flood-filling the flat disc colour, plus a
        // ring's width of margin. They are not eyeballed and should not be
        // nudged by eye: re-measure if the art changes.
        //
        // They used to be drawn over the *scenery* instead - the upper-left
        // mountains for the Foundry, the peaks for the Portals - which put
        // every one of the four targets above its own badge. The Portals
        // spiral did not overlap its tap region at all; the factory overlapped
        // by a sliver at the very top; the dragon by its top quarter; the
        // house, the best of them, by about half. So on the first screen of
        // the game, a child who navigates entirely by picture pressed the
        // middle of a big round button with a house on it and nothing
        // happened, three times out of four.
        regions: [
          MapRegion(
            shape: MapRegionShape.circle,
            id: 'home',
            label: kHomeRegionLabel,
            rect: const Rect.fromLTWH(0.174, 0.582, 0.162, 0.199),
            // Home hosts the Buddy character creator — picked here as the
            // first usable inhabitant of the Hub before furniture / avatar
            // work lands.
            onTap: () => context.go(Routes.characterCreator),
          ),
          MapRegion(
            shape: MapRegionShape.circle,
            id: 'foundry',
            label: kFoundryRegionLabel,
            rect: const Rect.fromLTWH(0.016, 0.342, 0.162, 0.199),
            enabled: false,
            onTap: () {},
          ),
          MapRegion(
            shape: MapRegionShape.circle,
            id: 'portals',
            label: kPortalsRegionLabel,
            rect: const Rect.fromLTWH(0.482, 0.299, 0.162, 0.199),
            enabled: false,
            onTap: () {},
          ),
          MapRegion(
            shape: MapRegionShape.circle,
            id: 'mystic-sanctuary',
            label: kMysticSanctuaryRegionLabel,
            rect: const Rect.fromLTWH(0.678, 0.624, 0.162, 0.199),
            onTap: () => context.go(Routes.sanctuary),
          ),
        ],
      ),
    );
  }
}
