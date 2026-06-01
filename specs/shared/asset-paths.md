# Asset Paths & Naming Conventions

> The canonical directory structure for art, audio, font, and other binary assets. Lesson runtime JSONs and activity specs already reference asset paths like `assets/lessons/k-cc-4a/thumbnail.png`; this file is the source-of-truth for what that path should resolve to and how new assets should be named.

References: `specs/shared/lesson-runtime-actions.md`, `specs/shared/localization.md`, `data/lesson-runtime/*.json`.

---

## Top-level directory structure

```
assets/
  activities/              # per-activity art + audio
    {activity-slug}/
      backgrounds/
      sprites/
      music/
      sfx/
      ui/
  lessons/                 # per-lesson art + audio
    {lesson-slug}/
      thumbnail.png        # library entry icon
      iShow/
        scene/
        sprites/
      weTry/
        scene/
        sprites/
      narration/
        {locale}/          # see localization.md
          {cueId}.m4a
  shared/                  # cross-activity assets
    buddy-parts/           # customizable Buddy components
    avatar-parts/          # customizable Avatar components
    home-styles/
      cottage/
      castle/
      treehouse/
      sci-fi-base/
    region-narrators/
      {locale}/
        sanctuary-warm-naturalist/    # voice line manifests
        wundletown-frazzled-wizard/
        mathopolis-radio-announcer/
        buddy/
    region-music/
      sanctuary/
      wundletown/
      mathopolis/
    ui/                    # generic UI elements (HUD, buttons, etc.)
    fonts/
    stingers/              # round-pass chimes, phase transitions
  hub/                     # the kid's home interior
    {home-style}/
      interior/
      decor-slots/
  foundry/                 # parts catalog
    frames/
    parts/
    paints/
    creations/
  portals/                 # each portal world's assets
    pirate-planet/
    dino-dig/
    atlantis/
    corona-castle/
    gooblon/
    bakery/
    port/
    botanical-garden/
    farmers-market/
    factory/
    insect-biosphere/
  rewards/                 # collectibles, chests, trophies, milestones
    {region}/
      {category}/
```

---

## Naming conventions

### File names
- **Lowercase, hyphenated**: `apple-slice.png`, not `AppleSlice.png` or `apple_slice.png`.
- **Singular**: `fawn.png`, not `fawns.png` (the activity decides how many to render).
- **Per-state suffix** when needed: `buddy-idle.png`, `buddy-hop.png`, `buddy-wiggle.png`.
- **Per-frame** for sprite atlases: numeric suffix `_001.png`, `_002.png`, indexed from 1.

### Folder names
- **Lowercase, hyphenated** — match the slug.
- **Match the activity slug exactly** — `counting-parade/`, not `counting_parade/` or `parade/`.

### Resolution variants
- Provide `@1x`, `@2x`, `@3x` for static images (Apple convention).
- Spine/Lottie/JSON-animated assets ship as their native format.

### Color-blind palette
- Color-blind-safe versions of color-dependent art live alongside in a `cb/` subfolder when v1.1 accessibility ships. Asset loader switches based on accessibility setting.

---

## How specs reference assets

### Lesson runtime JSON
- `libraryEntry.thumbnail`: `"assets/lessons/k-cc-4a/thumbnail.png"` — relative to the asset root.
- Scene objects in lesson JSONs reference sprite names but not full paths. The lesson runner resolves `{ "creatures": { "species": "fawn", "count": 3 } }` to `assets/activities/counting-parade/sprites/fawn.png` (or its sprite-atlas equivalent).

### Activity specs
- Activity specs describe scenes in prose ("a grassy clearing on a winding path"). The art direction document (TBD) maps these descriptions to concrete asset slots.

### Audio cue references
- Narration script entries reference `cueId`s, not audio file paths. The audio loader resolves `cueId: "we-try-start"` to `assets/lessons/{lesson-slug}/narration/{locale}/we-try-start.m4a`.
- SFX action names (per `lesson-runtime-actions.md`) similarly resolve via a SFX catalog mapping action names to audio files.

---

## Asset manifest

Each `assets/{category}/{thing}/` folder may contain a `manifest.json`:

```jsonc
{
  "version": 1,
  "assets": [
    { "id": "fawn-idle", "files": ["fawn-idle@1x.png", "fawn-idle@2x.png", "fawn-idle@3x.png"], "type": "static-sprite" },
    { "id": "fawn-walk", "files": ["fawn-walk.json", "fawn-walk_001.png", "fawn-walk_002.png", ...], "type": "spine-animation" }
  ]
}
```

Manifests are optional for simple folders; mandatory for folders with > 10 assets to help the loader.

---

## Pre-launch authoring TODOs

Per the K review, many assets are unspecified. Specific lists per activity:

### Counting Parade
- 24 creature species sprites (per `data/reward-catalog/kindergarten.json:sanctuary-creature-cards-set`)
- Background: sunlit grassy clearing (parallax: 3 layers)
- HUD: count badge, exit, coin counter, Done button

### Ten-Frame Pond
- ~20 fish species sprites
- ~6 rare reef fish (per `sanctuary-reef-cards-set`)
- Pond background + ripple shader
- Ten pearl shimmer particle

### Scribe's Tower
- 21 numeral character designs (0–20 with personalities)
- Tower interior (shelves, stained-glass light)
- Stamp poster
- Quill + ink-color variants (8 colors)

### Storyteller's Pond
- ~15 pond creature species
- Storyteller turtle character (with mouth-sync animation)
- ~30 story memento art

### Build-a-Habitat
- Sticks + clay-balls sprites
- ~5 cube/cone/cylinder/sphere variants
- ~12 habitat layouts + ~12 creature thank-yous

### Shape Garden
- 16 plant species (mapped to 6 shape kinds)
- 6 pond creatures (mapped to 4 3D shape kinds)
- Garden background

### Where's Buddy?
- 5 landmark sprites (tree, well, mushroom, rock-cluster, cottage)
- 8 hide-and-seek hat variants for the Buddy
- 6 hideout decoration items

### Build-a-Habitat
- Already covered above.

### Care Pantry
- ~30 supply items (with multi-attribute tags)
- Pantry background (supply hut interior)

### Picnic Baskets
- 2 basket sprites (unicorn, hatchling-dragon icons)
- ~12 picnic food items + ~6 blanket patterns

### Caretaker's Bench
- ~20 objects with attributes (feather, glow-stone, rock, etc.)
- Balance scale + measuring stick sprites
- 8+ attribute word tags (typography-driven, also illustrated icons at Concrete)
- 10 caretaker tool collectibles

### Fluency Within 5
- Chalkboard + tile sprites
- Buddy mat (sized larger than usual)
- 10 Buddy treat sprites
- 8 Buddy emote animations
- Treat jar shelf UI

### Hub interiors
- 4 home styles × interior layouts × decor slots

### Foundry
- TBD parts catalog (mechs, sky-ships, etc.) — substantial pre-launch scope

---

## Audio pre-launch TODOs

Per `localization.md`, all narration scripts route through a string + audio table. For English at launch:

### Per-region narrator recording
- Sanctuary warm naturalist: ~500 lines (activity narration, lesson scripts, round-pass cues)
- Wundletown frazzled wizard (1st grade — pending 1st-grade specs)
- Mathopolis radio announcer (2nd grade — pending 2nd-grade specs)
- Buddy voice: cross-region, ~50 short cues

### Per-activity SFX library
- ~30 SFX per activity × 11 K activities = ~330 SFX at K alone
- Common SFX library (chimes, stingers, taps): ~50 reusable cues

### Music
- Per K activity music bed (per `k-activity-patterns.md` audio variation table)
- Per region bed
- Round-pass stinger per region

---

## Asset versioning

When an asset changes (e.g., new Buddy design), bump the asset's `version` in its manifest. The lesson runner uses asset versions to invalidate caches.

Major art revisions: bump per-activity manifest version + announce in changelog.

---

## Storage and bundling

- App bundle ships with all launch-essential assets (≤ 500 MB target).
- Portal-world assets may ship as on-demand resources:
  - **Phase 1 (Flutter)**: bundle as Flutter asset packs; download on first portal entry via `flutter_downloader` or similar.
  - **Phase 2 (native iPadOS)**: switch to Apple's On-Demand Resources mechanism for tighter integration with iOS storage management.
- Audio files: AAC `.m4a`, 96 kbps mono for narration / 128 kbps stereo for music. **Same files in both phases** — Flutter's `just_audio` and iOS's `AVFoundation` both consume `.m4a` natively.

---

## Open Questions

- **Sprite atlas strategy** — per-activity atlases vs cross-activity shared atlases? Per-activity is simpler at K scale; revisit if memory pressure surfaces at higher grades.
- **Spine vs Lottie vs custom** for animations — defer to art direction. The asset loader should support all three.
- **Hub home assets as separate bundles** for non-default home styles (saves install size)? Maybe v1.1.
- **Color-blind palette swap** — at launch (per accessibility commitment) or v1.1? Plan says v1.1; confirm.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — directory structure, naming conventions, pre-launch authoring TODOs by activity, audio scope, bundling strategy | |
