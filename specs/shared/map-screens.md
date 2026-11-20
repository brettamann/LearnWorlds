# Map Screens (Home Map → Region Map → Activity)

> The "tap a place on this picture to go there" pattern. The Mystical Island home map, the three region maps (Mystic Sanctuary, Wundletown, Mathopolis), the Foundry yard, and every portal world all use the same MapScreen widget with normalized clickable regions. This doc captures the contract so a new map drops in with the rectangles and the routing, nothing else.

References: `specs/shared/asset-paths.md`, `specs/shared/ui-affordances.md`, `app/lib/ui/widgets/map_screen.dart`.

---

## The navigation grammar

```
HomeMapScreen (/) ─── Mystic Sanctuary ──→ SanctuaryMapScreen (/sanctuary) ──→ /lesson/:id or /activity/:id
                ├──── Foundry            (not yet wired)
                ├──── Portals            (not yet wired)
                └──── Home               (not yet wired)
```

Every region map has:

- A back arrow in its AppBar that returns to `/` (the home map).
- A TTS toggle in its AppBar actions (so the kid can silence narration anywhere).
- A clickable region per child destination.

Disabled regions stay on the map. They render with a faint dim overlay (per `MapRegion(enabled: false)`) and ignore taps — kids learn "this is here, just not yet" rather than "this place doesn't exist."

---

## The MapScreen widget

`app/lib/ui/widgets/map_screen.dart` is the engine. It takes:

- `imageAsset` — the backdrop PNG path.
- `aspectRatio` — `width / height` of the backdrop. **Required**: the rectangles position against this aspect-correct box, so the regions stay lined up at any screen size.
- `regions` — a `List<MapRegion>` with `id`, `label`, normalized `Rect`, `enabled`, and `onTap`.
- `appBar` — optional but conventional.
- `showHitOutlines` — debug flag; flip true to visualize the hit boxes when authoring a new map.

The widget centers the backdrop in an `AspectRatio` box; regions are `Positioned` inside the same box using `rect.left * width`, `rect.top * height`, etc. `Image.asset` uses `BoxFit.fill` because the AspectRatio already does the letterboxing — the image and the regions then share the same coordinate system exactly.

### Why normalized rects (and not pixel rects)

A rect of `Rect.fromLTWH(0.62, 0.32, 0.30, 0.36)` works at 320 px wide and 2048 px wide. Authoring against the source PNG dimensions (in pixels) would require re-tuning when the art ships at a different resolution; normalized coordinates survive every re-encode.

---

## Authoring a new map

1. **Drop the PNG** at `app/assets/maps/{slug}.png` (during placeholder phase) or `assets/maps/{slug}.png` once we wire repo-root asset sync. Record its pixel dimensions; the aspect ratio is `width / height`.
2. **Add an AssetPaths constant** in `lib/data/asset_paths.dart` so the path lives in one place.
3. **List the asset** in `app/pubspec.yaml` under the existing `assets/maps/` block.
4. **Write the screen** as a small ConsumerWidget that returns `MapScreen(...)` with regions:

   ```dart
   MapRegion(
     id: 'mystic-sanctuary',
     label: 'Mystic Sanctuary',
     rect: const Rect.fromLTWH(0.62, 0.32, 0.30, 0.36),
     onTap: () => context.go('/sanctuary'),
   ),
   ```

5. **Tune rects** by passing `showHitOutlines: true` to MapScreen, hot-reloading, and adjusting until the green outlines match the art. Then remove the flag.
6. **Wire the route** in `lib/app.dart`'s `_appRouterProvider`.
7. **Add a back button** in the AppBar pointing at the parent map (`context.go('/')` for region maps, deeper for sub-region maps once we have them).

---

## Region behavior

| Property | Effect |
|---|---|
| `enabled: true` (default) | Region is transparent and tappable. `MouseRegion` sets a click cursor on hover. |
| `enabled: false` | Region renders a 18% black overlay (the art behind it dims) and ignores taps. Semantics flag drops `button: true` so screen readers skip it. |
| `label` | Used as the Semantics label (VoiceOver + the AppBar tests' `find.bySemanticsLabel`). Kids never read it, but parents and tests do. |
| `id` | Stable id for analytics + future deep-linking. Not displayed. |

---

## Coexistence with the ScaffoldEngine

The Sanctuary map's lesson buttons still route through the existing ScaffoldEngine: on first encounter the kid is sent to `/lesson/:id`, on subsequent encounters to `/activity/:id`. The map is a *navigation surface*; pedagogy stays where it lives (`adaptive-scaffolding.md`).

When the round completes, the round-complete sheet's `NextArrowButton` returns the kid to **`/sanctuary`**, not `/` — they pick up exactly where they were on the map.

---

## Things NOT to do

- **Don't bake hit boxes into the PNG.** Use `Rect.fromLTWH(...)` in code so the art and the routing live separately.
- **Don't hide unimplemented regions.** Render them with `enabled: false` so kids learn the map's shape early and the addition of content feels like things "opening up."
- **Don't reach for a custom button widget** for a map destination. The whole point is one tap target per region; the art carries the affordance.
- **Don't skip the `aspectRatio`.** Without it the stack can size to zero in tests and on edge browsers, and `tester.tap` will return `Offset(NaN, NaN)`.
- **Don't wrap MapScreen in a Scaffold.** It builds its own — pass `appBar` instead.
- **Don't put a control a child has to find in the app bar.** Pass a `MapSideRail` as `rail` instead. Four 24px icons in the top-right corner is the least reachable place on the screen for a five-year-old, and playtest bore that out: a quarter of the game (decorate, cards, shop) was effectively undiscoverable. The rail sits in the column the centred map already leaves empty on a landscape screen, so it costs the map nothing — and it must stay outside the `AspectRatio`, because region rects are normalised against the *image* and widening the image drags every hit box off the artwork it was authored against.
- **Don't add a picker option without a sprite and a label in `sub_mode_picker_data.dart`.** The card falls back to a grey `?` over the raw sub-mode id, which to a pre-reader is indistinguishable from a broken tile — and the label is spoken now, so the fallback also reads a hyphenated id aloud in the browser's synth voice. `sub_mode_picker_test.dart` walks the registry and forbids it.
- **Don't leave a map screen silent.** Wrap it in `MusicBedScope`. Every claim on the music bed used to live inside an activity runner, so the hub a child returns to after every sub-mode — and the screen the app opens on — were the two screens with no music at all.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-06-06 | Initial draft — HomeMap (`/`) + SanctuaryMap (`/sanctuary`) replacing the old grid HubScreen. Foundry, Portals, Home regions placeheld. | |
| 2026-09-02 | **The Sanctuary map can be decorated, and the decor layer has a fixed depth.** A tray toggled from the app bar sells eight objects and lets her drag them anywhere on the map; placements are normalised (0..1) against the square map box, not pixels, so a position saved on a touchscreen monitor means the same thing on an iPad. `SanctuaryDecorLayer` renders ABOVE the fog and BELOW the parchment banner pass, and neither half of that is arbitrary: above the fog, because a decoration that vanishes into a cloud the moment she lets go reads as the app eating it; below the banners, because the banner is the tappable half of every lesson node, so decor can never swallow the tap that starts a lesson. Outside decorate mode the whole layer is `IgnorePointer`, so a decorated map is never a harder map to play. | |
| 2026-09-03 | **Map controls moved to a side rail, and map screens claim the music bed.** `MapScreen` gained a `rail` slot and `MapSideRail` / `MapRailButton` landed as the shared shape: 84px circular buttons down the right-hand edge, in the space the centred map already leaves. Both maps use it — the Sanctuary's four controls and the island's settings gear all came out of the app bar, which now holds nothing but the back arrow. `MapRailButton` takes `caption:`, not `label:`, because on a map screen a label is a place name and place names are spoken; rail captions never are. Both maps also wrap in `MusicBedScope`. | |
| 2026-09-03 | **The Sanctuary path dead-ended at node three, and unbuilt nodes now say so out loud.** A node is revealed when the node before it is *completed*, and completion means finishing its sub-modes, which needs a runner. Position three of eleven is Ten-Frame Pond, which has none — so the path stopped there permanently and Build-a-Habitat (four) and Where's Buddy (eight) sat in the fog, both finished, both narrated, both with clips rendered. Half the built game was unreachable in ordinary play, which is a fair share of why it felt repetitive. `isSanctuaryNodeVisible` in `sanctuary_sequence.dart` now walks back to the nearest node that can *be* completed, so a place nobody has built is never a wall; the reveal is still one lesson at a time. Unbuilt nodes stay drawn, per the rule above, but are drawn as asleep — greyscale plus fade, a crescent moon instead of the lesson number (a lock says "not earned", and nothing here is earned) — and a tap speaks `kSanctuaryAsleepNodeLine` rather than doing nothing or routing to a blank screen reading `Activity "ten-frame-pond" lands in a later sprint.` Four of the eleven are not in the activity registry at all and had been showing their raw id on the parchment; they get a title-cased name. The set of activities that actually have a runner is `kPlayableActivities`, checked against what `activity_screen.dart` dispatches so the two cannot drift. | |
| 2026-09-04 | **The sub-mode picker was silent, and it is the busiest screen in the game.** From her second visit to an activity onwards this sheet stands between every tap on a node and the game behind it, and it was made entirely of text - a question, an activity name and a caption under each sprite - in front of a child who cannot read. The sprites are stop-gaps that mostly do not depict their sub-mode (the three Where's Buddy options are a toucan, a phoenix and a unicorn), so there was nothing on it she could decode; her only strategy was to tap one and find out what it was. It speaks now in the two beats the rest of the app already uses: the question once as the sheet arrives, and an option's name on the tap that opens it, via `ReadAloudGate`. Naming it on the acting tap does not help her choose *that* time - it is how she learns which sprite is which, so that next time she can. The words live in `sub_mode_picker_data.dart` alongside the sprites, which is what lets the renderer see them; four labels were reworded on the way (`Sort by attribute` -> `Sort them out`, `Two-attribute hunt` -> `Two things at once`, `Count out` -> `Count out that many`, `Two friends` -> `In the middle`) because they had been written to be read, not heard. The sprites are still the open half of this: art that depicts the mode is what would make the choice decodable on the first visit rather than the third. | |
| 2026-09-05 | **The tap target is the badge, and it is measured out of the art.** The island map is a painting with four medallions drawn into it - a flat cyan disc, a heavy black ring, a picture in the middle - and to a child who navigates entirely by picture the medallion *is* the button, because it is the only thing on that screen shaped like one. The four `MapRegion` rectangles had been authored against the scenery instead: the upper-left mountains for the Foundry, the peaks for the Portals. Every one of the four ended up sitting above its own badge. The Portals spiral did not overlap its tap region at all; the factory overlapped by a sliver at the top; the dragon by its top quarter; the house, the best of them, by about half. So on the first screen of the game she pressed the middle of a big round button with a house on it and nothing happened, three times in four. This is invisible from the code - the numbers look perfectly reasonable - and invisible from a screenshot until you draw the hit boxes over it, which is how it was found. The rectangles are now measured from `home_screen_map.png` by flood-filling the flat disc colour, and `tools/scripts/check-map-regions.mjs` re-measures them in CI, so replacing the placeholder art fails there rather than quietly on the first screen a child sees. `MapRegion` gained a `shape`, because a rounded-square dim-out over a circular badge reads as a smudge on the painting rather than as a place that is closed; the hit area stays rectangular, since a slightly generous target is the right way to be wrong for a five-year-old's aim. |  |
| 2026-09-24 | **Every Sanctuary node is awake, and the banners were re-sided so they fit together.** With seven places asleep the map rarely showed all eleven names at once; with all of them built, Counting Parade's banner ran over Shape Garden's node, and on a 1366x1024 window Storyteller's Pond's ran off the screen. A banner takes taps (it speaks the name), so an overlap is a tap that says the wrong place. F1 is now `above`, F7 `right`; `sanctuary_banners_test.dart` measures every banner at two window sizes. The asleep-node machinery stays for the next region and is held by tests against the four-activity map (`kFourActivitySanctuary`). | |
