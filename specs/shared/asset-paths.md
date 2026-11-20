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
| 2026-08-18 | **SFX ship as `.wav`, an exception to the `.m4a` rule above.** AAC decoding in `just_audio_web` is browser-dependent (Firefox especially), the clips are small, and WAV decodes everywhere including Flutter web. Narration is unaffected and still targets `.m4a`. Placeholder SFX live under `app/assets/audio/` and are generated by `tools/audio/generate_placeholder_sfx.py`; unlike `assets/data` and `assets/content` they are NOT mirrored from a repo-root tree, so `scripts/sync-assets.ps1` does not touch them. | |
| 2026-08-21 | **New tree: `assets/audio/narration/`, holding recorded narration as 16-bit PCM WAV.** One flat directory, one file per cueId, filename = the cueId with every character outside `[A-Za-z0-9._-]` replaced by an underscore (colons are the reason — they appear in nearly every runtime cueId and are illegal in Windows filenames). WAV rather than the `.m4a` this spec mandates for the same reason the SFX layer ships `.mp3`: browser decoding. The browser recorder produces webm/opus, which Safari and iOS cannot decode, and WAV is the one format that plays everywhere without a transcode step in the owner's loop. Revisit when the ElevenLabs pipeline comes back. Like `assets/audio/sfx/`, this tree is NOT mirrored from a repo-root source and `scripts/sync-assets.sh` does not touch it. | |
| 2026-08-22 | **Narration filenames are derived from the line's text, superseding the cueId scheme recorded yesterday.** Same flat `assets/audio/narration/` tree and same 16-bit PCM WAV; only the stem changes, to `slug48 + '__' + fnv1a32(utf8(collapseWhitespace(text)))`. The cueId scheme was unsound — see the `text-and-tts-deferral.md` row of the same date — and no clips had been recorded under it, so there is nothing to migrate. The slug half keeps a folder of two hundred takes browsable by eye; the hash half makes collisions impossible. The transform lives in `narrationClipKey()` and is reimplemented in `tools/tts/record/index.html`, with shared vectors pinned in `app/test/narration_script_test.dart` and `tools/tts/record/check.mjs` so a drift fails loudly instead of writing files the app never opens. | |
| 2026-09-01 | **Narration clips ship as 64 kbps mono MP3, superseding the WAV assumption for machine-rendered lines.** Same flat `assets/audio/narration/` tree and same `narrationClipKey` stem; only the container changes, and `narrationClipsFrom` already keys on the stem and ignores the extension, so both formats work side by side. Measured on the longest line in the script - 10.3s of 24 kHz 16-bit mono - WAV is 483 KB and MP3 is 81 KB; across the ~16 minutes of speech in the full script that is ~46 MB against ~8 MB, and `parade-intro` alone accounts for 31 MB of the WAV figure. 46 MB of narration is a bad first load for a Flutter web build. Human takes from `tools/tts/record/` stay 16-bit PCM WAV, which is why the loader had to stop caring about the extension. Note that kokoro-js's own `save()` writes **32-bit float** WAV (format tag 3); that is deliberately not used, because browser support for float WAV is uneven and Safari/iOS is the target that matters. | |
| 2026-09-02 | **Both music beds ended in 1.2 seconds of digital silence.** `build_music` in `tools/audio/generate_placeholder_sfx.py` folds the tail of the loop into the head so the seam is inaudible, then zeroed the tail — and never shortened the buffer. A correct crossfade, right up to the point of dropping the frames it had just folded away. The bed played 15.6s of music and 1.2s of nothing, on repeat, for the length of every session: long enough for a child to notice, short enough that nobody reading the code would think to check a WAV. The fold now returns a truncated buffer (`fold_tail_into_head`), and the two shipped WAVs were trimmed in place by exactly the crossfade length — their heads already carried the blend, so only the dead tail had to go. `test/music_bed_loop_test.dart` reads the shipped audio rather than trusting the tool, because a generator fix nobody re-runs leaves the broken file on disk, which is the state this repo was in. | |
| 2026-09-02 | **The Sanctuary Creature Cards set is complete: 15 new cards drawn through tools/artgen.** The set has been authored as 24 items since the first sprint and ran as nine, so two thirds of the album was a silhouette a child could never turn over. All fifteen carry `speciesId: null` like the Cloud Unicorn - card art rather than parade cast - and live in `assets/activities/counting-parade/sprites/` beside it. Two references rather than one: `fawn.png` for anything that stands on the ground, `toucan_baby.png` for anything with wings, because a moth edited against a fawn fights the whole silhouette. No reframe (each is alone on a card face and in one album tile, so BoxFit.contain sizes it) and `maxSize: 512`, which is 4.6 MB for the whole sprite folder. Rarity spread ends at 10 common / 9 uncommon / 5 rare: cardRarityWeight makes a common four times likelier than a rare, so the album fills quickly at first and keeps a few hard faces in it. Cost 17.6c. | |
| 2026-09-02 | **artgen `probe.mjs` reported a live service as dead.** It detected the auth scheme by calling `/api/generations?limit=1`, a listing route the ImageGen service has since removed - it now 404s for everyone, authorised or not, so every scheme "failed" and the probe advised that the token had been rotated. It had not. Detection moved to `/api/models`, which is authenticated (401 without a token, 200 with one) and is therefore an actual discriminator; `/api/health` is not, because it answers 200 to anybody and would call a dead token good. `client.mjs.probe()` dropped the same route. | |
| 2026-09-02 | **The Sanctuary map and album play music, and the map's controls moved off the app bar.** Every claim on the music bed lived inside an activity runner, so the hub screen a child returns to after every sub-mode was silent - as was the cutscene and the card album. New `MusicBedScope` makes a claim a one-line wrap instead of a stateful widget plus two lifecycle overrides, which is exactly why those screens never got one; the runners still claim by hand and can migrate whenever. Separately the map's four controls were 24px icons in the top-right of the app bar and are now an 84px rail down the right-hand side, in the column of unused space the centred square map leaves on a landscape screen. Node positions are painted into the artwork, so the map does not stretch into that space. | |
| 2026-09-02 | **Music bed default drops 0.35 to 0.33, and an old default in a save is adopted forward.** The number now lives once, as kDefaultMusicVolume in sfx_catalog.dart, read by the settings provider, the save blob and the engine seed. The migration matters more than the number: the whole audio settings block is persisted the first time a round resolves, so every save that has ever played carries a musicVolume whether or not anyone touched the slider - which means a retune would have reached only players who had never played. A stored value matching a superseded default (kSupersededMusicVolumes) is treated as the old default written down rather than a choice, and moves forward; anything else is left alone. test/music_volume_default_test.dart pins both halves, including that a stored 0.0 survives, since silence is a choice and the loudest one to get wrong. | |
| 2026-09-02 | **Renderer-only pronunciation lexicon: `tools/tts/kokoro/lexicon.mjs`.** Kokoro phonemises with eSpeak-NG before synthesising, and eSpeak reads "gryphon" as ɡɹˈɪfɑːn (GRIFF-ahn, wanted ɡɹˈɪfɪn) and "toucan" as tˈuːkən (TOO-kuhn, wanted tˈuːkæn) - 64 and 52 lines respectively. The lexicon maps each word to a spelling eSpeak reads correctly ("griffin", "toucann") and applies it **only** to the text handed to the synthesiser: the clip key is still `narrationClipKey` over the real sentence, and the script, captions and cue log are untouched, so the game never learns the misspelling. Because that decouples what is said from what is written, `rendered.json` now stores the words each clip was actually spoken from and `render` treats a clip as stale when the lexicon would say something different - entries predating the lexicon are backfilled from their recorded text, which is exactly what they were rendered from, so nothing re-renders for nothing. New `phonemes.mjs` prints the IPA for a candidate spelling, which is what makes an entry a measurement instead of a guess. | |
| 2026-09-02 | **The Mystic Sanctuary bed is a real recording, and it is now owned by the engine rather than by whichever screen is mounted.** `assets/audio/music/forest-mystical.mp3` replaces the generated `sanctuary-low.wav`, which is no longer written by `generate_placeholder_sfx.py` and has been deleted; the challenge bed stays a generated WAV. MP3 rather than the WAV the SFX use because the track is four minutes long and 16-bit PCM would be 42 MB - it ships at 320 kbps stereo exactly as delivered (9.25 MB), minus a 366 KB ID3v2 block that was carrying cover art into a web build. It has no LAME gapless header, so the loop seam costs a few tens of milliseconds of decoder padding; at four minutes most sessions never reach it, and `music_bed_loop_test.dart` guards the length so a short MP3 cannot be swapped in without the gapless treatment the WAVs get. `sanctuary-low` and `sanctuary-picnic` deliberately resolve to the same file, and SfxEngine keys the bed on the resolved **asset** rather than the variant name, so a lesson asking for the picnic bed mid-visit does not restart the music. | |
| 2026-09-02 | **`write()` in the placeholder generator ran `fade_tail` over the music beds, which is exactly wrong for a loop.** fade_tail exists to kill the click a hard cut leaves at the end of a one-shot; on a loop it ramps the last 20 ms down to silence, lands that ramp on the loop point, and undoes the 1.2-second crossfade `build_music` just constructed. The beds shipped correct only because the previous fix trimmed them by hand afterwards, so the tool's own output was broken and the next person to re-run it would have quietly shipped the click - which is what happened, and what the seam assertion in `music_bed_loop_test.dart` caught. `write()` takes `fade=False` for anything that loops. | |
| 2026-09-02 | **The counting tones were missing for the first seconds of every session.** The autoplay unlock awaited AudioPlayer.play() once per player to claim the browser grant - but play() completes when playback ENDS, not when it starts, so each bless waited out the whole clip. Sequentially, over 42 players: 11.7 seconds of sound effects before the pass even reached the counting ladder, then the twelve notes blessed one every 0.55s, and finally the music bed, whose play() under LoopMode.one never completes - so the pass never finished at all. The child heard the rising tone arrive partway through a round, seemingly at random, with nothing logged and nothing thrown. Fixed by not awaiting play() (SfxEngine._bless), blessing in parallel, decoding the ladder first because it is the only sound tied to her first taps, and having AudioUnlockScope offer every pointer-down until the engine reports success rather than spending its one gesture on players that had not finished decoding. NarrationAudio.unlock had the identical bug. test/sfx_unlock_test.dart fakes the real play() contract, so a regression hangs the suite instead of passing quietly. | |
| 2026-09-03 | **The music bed stopped a few seconds into every screen the child walked to, and the grace window was hiding it rather than fixing it.** Releasing the bed scheduled an unconditional stop, on the assumption that a route change goes release-then-claim and the incoming screen's claim would cancel it. Navigation is the other way round: Flutter mounts the incoming route and disposes the outgoing one as the transition finishes, so the engine sees claim(new) then release(old), and that release scheduled a stop with nothing after it to cancel. Five seconds later the music died on a screen that was actively asking for it — which is the "played at the beginning of the lesson, stopped once the taps started" report, and it survived the first round of continuity work because every test rehearsed the order the code assumed. SfxEngine now counts claims and only stops when the last one is given back; `switchMusicBed` re-points an existing claim (MusicBedScope's bed changing) without taking a second. That makes an *unmatched* release harmful — it gives away somebody else's claim — so the thirteen hand-written claims moved out of `addPostFrameCallback((_) { if (!mounted) return; ... })` and up beside the engine reference kept for dispose, making both ends of every pair unconditional. `music_bed_handoff_test.dart` drives a real GoRouter rather than a hand-written call sequence, and `music_bed_claim_balance_test.dart` lints the source for the shape that caused it. | |
| 2026-09-03 | **Every kid-reachable screen now claims the bed, and the volume controls exist.** The island map, the Buddy shop / character creator and Settings were the last silent screens; the island map is the one the app opens on, so the game's first impression was no sound until the child was two screens deep. Settings claims it for a specific reason rather than for consistency: it now carries music and effect level sliders, and a music slider tuned against silence is not a control. Those levels had been wired end to end since the audio layer landed — engine, providers, save blob, live listeners — with no UI, so `kDefaultMusicVolume = 0.33` was reachable only by editing Dart and rebuilding. | |
| 2026-09-04 | **Where's Buddy has its own background, and its own landmark sprites.** `wheresBuddyBackground` had been an alias for `shapeGardenBackground` "until a dedicated Sanctuary-clearing scene ships", which was the right aesthetic and the wrong *shape*: two thirds of the courtyard is sky and treeline and the ground is a strip across the bottom. Invisible while landmarks were text, which floats anywhere; not invisible once they were a pond and a cottage, half of them standing in the clouds. Pushing the landmarks down instead does not work - the band that is both on grass and still leaves room for the above/below vectors is about 0.16 of the playfield, and six landmarks inside it cannot satisfy the two rules "between" depends on (a pair more than 0.4 apart, and a midpoint that does not land on a third landmark), so the geometry was right and the ground was wrong. The new clearing is grass from a high horizon down and deliberately empty in the middle. `AssetPaths.wheresBuddyLandmarks` maps each landmark id to its sprite; three of the six point into `sanctuary/decor`, which is a deliberate share rather than a stop-gap. Build-a-Habitat still aliases the courtyard, which suits it - it builds on a flat surface. | |
