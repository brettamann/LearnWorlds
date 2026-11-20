# CritMath app

The Flutter app. See `../specs/shared/platform-architecture.md` and `../specs/shared/system-architecture.md` for the design context.

## Prerequisites

- Flutter SDK ≥ 3.24 stable
- Node 18+ for the tooling under `../tools/` (narration rendering, data validation, art generation)
- Xcode and a Mac **only** for a native iOS build. The web build is the current delivery path and runs on the iPad through Safari — see [Playing it on an iPad](#playing-it-on-an-ipad).

## First-time setup

```bash
cd app
flutter pub get
```

## Run

```bash
flutter run -d chrome      # the usual dev loop
flutter run                # connected device or simulator
```

## Test

```bash
flutter test               # unit + widget tests
flutter analyze
dart format --output=none --set-exit-if-changed .
```

Full gate before committing anything that touches content or audio:

```bash
cd app && flutter test && flutter analyze && dart format --output=none --set-exit-if-changed .
cd .. && node tools/scripts/validate-data.mjs
node tools/tts/kokoro/check.mjs
node tools/tts/kokoro/render.mjs status     # must read N of N rendered
```

If you reword a spoken line, the script has to be re-dumped before the renderer
can see it:

```bash
cd app && dart run tool/dump_narration_script.dart > ../tools/tts/kokoro/script.json
cd .. && node tools/tts/kokoro/render.mjs render
```

### Shared test helpers

Don't copy setup between test files. `test/support/harness.dart` has
`useViewSize`, `testContainer`, `preloadRegistries`, `pumpRouted`,
`pumpFrames` and `unmountAndDrain`; `test/support/fixtures.dart` is the one
place that knows where data lives on disk (`activityRegistryJson()`,
`lessonRuntimeJson()`, `narrationClipFor()`). They already handle the first two
traps below.

### Five traps in widget tests

- **`pumpAndSettle` never returns on several screens.** Anything with a
  `BuddyCompanion` breathes on a repeating controller, and the Sanctuary map
  drifts its fog clouds on another. Pump explicit durations instead.
- **A registry read needs `tester.runAsync`.** `activityRegistryProvider` and
  `conceptRegistryProvider` load JSON out of the asset bundle, and the test
  binding clears that bundle's cache after every test — so from the second test
  in a file onward it is real file I/O, which a fake-async `pump()` can never
  let finish however many frames it runs. Await the `.future` inside
  `tester.runAsync` before pumping. Skipped, the screen renders in its
  registry-missing state and the test fails as whatever that looks like, which
  is rarely "the registry did not load".
- **Two tests in one file cannot mount the same lesson.** Sharper than the
  bundle-cache note above, and worth stating separately because the symptom is
  different: the second `LessonLoader.load()` of the *same* asset key does not
  merely take longer, it never completes. The screen sits in its FutureBuilder
  forever and the test fails on a missing widget, having rendered nothing at
  all - which looks like the screen being broken rather than the load never
  arriving. `rootBundle.loadString` caches by key and the binding drops that
  cache between tests. Give each test a different lesson, and poll for the
  widget you are waiting for rather than guessing a delay. Production is
  unaffected: nothing clears the bundle cache there.
- **A bottom sheet clips its own corners, so `tapAt` near one misses.** A
  Material 3 bottom sheet has a 28-pixel top corner radius and clips to it, so
  a point six pixels in from the sheet's top-left - which `getTopLeft` hands
  you, and which looks like the safest place in the world to tap - is outside
  the sheet entirely and lands on the modal barrier behind it. No warning:
  `tapAt` does not know what it was aiming for. Tap the top *centre* instead,
  or a widget you can name. Cost an hour on the picker's read-through.
- **A sprite has no size until its PNG decodes, so anything measured on the
  first frame is measured against a different layout.** Every stage is built
  out of `Image.asset`, which lays out at zero until the image is available -
  and in a golden test that moment is whenever `precacheImage` happens to run.
  The We-Try halo measured its target once on mount and drew the first ring on
  the keeper's staff, because the keeper's own image had not decoded yet and
  everything to its right shifted when it did. Precache before the thing you
  are measuring, and in production do not trust a single measurement: the halo
  re-measures every frame off a `Ticker`, which is also what keeps it on a
  target that moves.

---

## Playing it on an iPad

> **Open, and worth doing before more design work: nobody has run this on the
> iPad yet.** Everything below is reasoned from how the platforms behave, not
> from watching it — the landscape gate, the audio unlock across a real Safari
> gesture, whether the map's node positions and the new side rail sit right on
> that screen, and how the 9 MB music bed behaves over a LAN fetch. Three
> rounds of playtest notes so far have all come from the desktop touchscreen.
> The open design-canvas question further down should not be decided until
> after an iPad session, because the playfields are already sized for it and
> the monitor is the screen they are wrong on.


The game is built for a touchscreen, and the two screens it has to work on are
a desktop touch monitor and an iPad. Neither needs a native build.

### Fastest loop: serve it on the LAN

No hosting, no certificate, about two minutes:

```bash
cd app
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Then open `http://<your-machine-ip>:8080` on the iPad, on the same Wi-Fi
(`ipconfig` on Windows for the IPv4 address). Windows will ask for a firewall
exception the first time — allow it for **private** networks only.

The part that surprises people: **"Add to Home Screen" works over plain HTTP on
iOS.** Standalone mode is driven by the `apple-mobile-web-app-capable` meta tag
in `web/index.html`, not by HTTPS. So you can get the full no-Safari-chrome,
home-screen-icon experience straight off the LAN URL — it just only works while
the dev server is running and you are on that network.

### Hosting it properly

```bash
cd app
flutter build web --release       # output in build/web
```

Then serve `build/web` as static files. Things that matter:

- **No SPA rewrite rules needed.** The app uses Flutter's default hash URL
  strategy (`/#/sanctuary`), so every request is `index.html` plus a fragment.
  Any static file server will do.
- **Do not cache `index.html` or `flutter_service_worker.js`.** That is how you
  end up watching a child play a build you fixed a week ago.
- **Enable gzip or brotli.** `main.dart.js` compresses hard; the ~23 MB of
  narration MP3s and the PNGs will not.
- The build is ~89 MB on disk but that is **not** the first load. Narration
  clips are fetched on demand as lines are spoken, so the initial payload is the
  engine plus the images actually on screen.
- **Prefer a private path over the public internet.** There is no login, and no
  reason for a stranger with the URL to load a child's game. Tailscale Serve is
  the cleanest answer: a real HTTPS certificate on your tailnet, nothing
  exposed, and a home-screen icon that works from anywhere.

---

## Screen sizes and orientation

### Orientation

The game is landscape in every scene. Three separate mechanisms, because no one
of them covers the platforms we ship on:

| Mechanism | Effect |
|---|---|
| `SystemChrome.setPreferredOrientations` in `main.dart` | A real lock on iOS/Android **native**. A no-op on web. |
| `"orientation": "landscape"` in `web/manifest.json` | Honoured by Chrome on Android. **Ignored by iOS Safari**, including for a page added to the home screen. |
| `ui/widgets/landscape_gate.dart` | Wraps every route. In portrait it shows a rocking tablet icon instead of the game. This is the only thing that works on the iPad. |

`web/index.html` also sets `user-scalable=no`. That one is not cosmetic: a stray
two-finger touch zooming the meadow is not something a five-year-old can undo.

### Building a new activity

The seven Sanctuary places built on 2026-09-24 all share one shape, and a new
one should too:

- **`SanctuaryRoundShell`** owns the lifecycle - music bed, keeper intro,
  progress bar, Buddy's corner, the "?" replay button, `resolveRound`, the
  celebration, the keeper aside between rounds and the blocking finale. The
  round body owns only its mechanic, is rebuilt fresh each round, and reports
  back through `RoundContext.say` / `finish`. Use `say(..., queue: true)` for
  a line that follows a count, or it cuts the count off.
- **Words and rounds in `lib/data/<activity>_words.dart`**, Flutter-free, with
  a `...ScriptLines()` function added as a batch in `narration_script.dart`.
  Never build a sentence by cutting another one apart at runtime -
  `play_it_through_test.dart` plays every activity and fails on any line it
  hears that the script does not contain.
- **Anything in a body's bottom strip starts `kBuddyCornerReserve` in.** Buddy
  takes the touch in that corner; `buddy_corner_test.dart` checks.
- **Numbers come with their quantity** - `NumberCard` / `NumberChoiceRow`
  draw a mini ten-frame of dots under the numeral. Turn the dots off only
  where reading the numeral is the point.
- **Wire it in five places**: the registry
  (`assets/data/activity-registry/`), `kPlayableActivities`, the
  dispatch and default in `activity_screen.dart`, `sub_mode_picker_data.dart`
  (a distinct picture per option), and `playfields()` in
  `playfield_caption_band_test.dart`, which enrols it in the caption-band,
  tap-size, idle-help, Buddy-corner and play-through guards at once.
- **Give it a creature card** (`creature_card_catalog.dart`), so a passed
  round there can find one.
- **Author a pool, not a list.** A visit picks its rounds from a pool a few
  bigger than it with `pickRounds` (`round_pick.dart`), seeded from the
  session, so going back for a card is not the same four rounds again. The
  script function walks the whole pool; `round_variety_test.dart` checks each
  place varies and keeps its shape.
- **Read `RoundContext.layer` if the round has support to fade.** Concrete,
  pictorial and abstract are her layer for the round's concept; a body with
  dots or counters takes them away as she rises and gives one layer back on a
  miss with `supportLayer`. Fluency and Storyteller's Pond are the examples.
- **Render it and look.** Every one of the seven had something only visible
  in a render: a crate hiding its own contents, a scale beam floating above
  its post, a frog under Buddy.

### Names and pictures

The player cannot read. She has the picture and the spoken word, and nothing
else - so a name that argues with its picture is worse than no name at all.
Whether a name argues with a *picture* is not something a test can see, but
whether two catalogs disagree about one sprite is, and both of the real cases
were found that way: "the unicorn fountain" over a fountain with no unicorn,
and "the giant mushroom" over the file the decor tray calls "Toadstools".
`shared_names_test.dart` requires two names for one sprite to share a noun -
"the pond" and "Lily Pond" are fine, "toadstools" and "giant mushroom" are
not.

The other half is the one no test covers: **render the catalog and look at
it.** A contact sheet of every sprite beside the word attached to it takes ten
minutes to throw together and is how the Shape Garden's colour bug surfaced.
Worth doing whenever a catalog gains entries.

### The We-Try does not take her turn

The middle phase of a lesson is guided practice, and the line between "we do
this together" and "the game does it" is where the first real play session
found a bug: she tapped two fawns, the lesson tapped the other two, and it
moved on. She had just been told to do the tapping.

Two rules came out of it, both held by `we_try_handover_test.dart`:

- **A `pointer-auto-*` beat may not name targets.** If the content wants a
  specific object touched, that object gets a `kid-action-expected` and she
  touches it. Auto-completing something the choreography does *not* name is
  fine - that is the frame standing up or the bins sweeping clear, a payoff
  beat rather than her task.
- **Nothing may react as though touched unless a gate asked for it.** Haloing
  something she was not asked for is fine; a halo is context. Sparkling it is
  not - from her side, a thing she was counting counted itself.

The safety net for a child who stalls is `hesitationRule`, and it runs the
same three rungs as `HintLadder`: highlight at the threshold, a spoken nudge
at twice it, a demonstration with the hand at three times. It used to resolve
the gate outright at five seconds, which is no time at all to a five-year-old
deciding which fawn is the first one.

### What happens when she does nothing

`HintLadder` (`engines/scaffolding/hint_ladder.dart`) is the answer, and every
playfield needs one. Standing still is the most likely thing a stuck
five-year-old does and it is the one input the game cannot see, so a playfield
without a ladder is indistinguishable from a frozen app - the same failure the
wrong-answer work was about, in its quieter half.

Two rules for wiring one up:

- **Point at the next legal target, not at everything.** Where the mechanic
  already glows all its open targets - the habitat's corners and sides - the
  hint is *which*, so the ring goes on exactly one. `TouchHereRing` /
  `TouchHereRingOutside` in `touch_here_halo.dart` is the game's one "touch
  here", shared with the lesson's We-Try gate. Use the `Outside` form on
  anything with a sprite under it: the ring is blurred, and drawn on a
  64-pixel shape the blur washes the shape out.
- **Queue the top rung's second line.** `demonstrate` explains and then does
  the thing it explained, and the doing speaks too. `speak` cuts off whatever
  is in flight, so the explanation - the whole content of a demonstration -
  was cut off milliseconds after it started, in every runner that had a
  ladder. The action's line is `enqueue`d when `fromHint` is true and spoken
  normally otherwise, because a child tapping quickly *does* want "Two." to
  interrupt "One.".

`idle_help_test.dart` mounts every playfield, touches nothing for twenty
seconds, and fails if nothing is said - and separately, if two lines land
closer together than the shortest line takes to say.

### Tap targets

`kMinTouchTarget` in `ui/widgets/touch_target.dart` is **60 logical pixels** -
about 12.6mm on the iPad. Apple asks for 44 points and Material for 48; both
are written for adults, and this player is five.

**Grow the hit area, not the drawing.** Three of the four things found under
the floor had a drawn size that was load-bearing: a habitat stick is 28 pixels
thick because that is the proportion `HabitatFrameLayout` gives the round, the
lesson *and* the picker card, and a map node is `shortest * 0.07` because that
is what makes it sit on the path in the painting. The pattern is a
`GestureDetector` wrapping a `Center` + `SizedBox` at the drawn size - note
which way round: a detector *inside* a bigger box is still only as big as
itself, and the space around it does nothing.

App-bar buttons are handled once, in `critMathTheme` in `app.dart`
(`toolbarHeight` and `leadingWidth` both, since the leading slot caps the
button's width whatever its own minimum says). Mount screens under that theme
in tests, or you are measuring a different app.

`touch_target_test.dart` is the check, over every playfield and both maps.

### The caption band

`CaptionOverlay` is an opaque strip 96 logical pixels tall across the bottom of
every activity and lesson screen, and `activity_screen` mounts it over the
runner. **So the box a playfield lays out in is 96 pixels taller than the space
it can put anything in.**

Three separate runners got this wrong before anyone noticed, because the
symptom is never a broken screen - it is a sprite that looks slightly short.
The companion the child designs stood behind a subtitle in eight activities;
Where's Buddy parked the Buddy she has to *pick up* under the band and answered
"below the mushroom" there too; Shape Garden put two of the three circles in
"tap all the circles" behind it, and eighty pixels of each sorting basket.

Two ways to keep clear, depending on how the screen lays out:

- **`PlayfieldScaffold`** - a Column with the progress bar on top. Reserves the
  band for you. Eleven runners had written this scaffold out by hand.
- **`PlayfieldArea`** - for a screen that positions things by fractions of its
  own height. Gives you the visible box to map into. `ClearingGeometry` in
  Where's Buddy is this with the Buddy's size arithmetic on top.

Either way `playfield_caption_band_test.dart` is the check, and it measures the
thing that matters rather than which helper was used: it mounts every playfield
the way the activity screen does and fails if anything touchable reaches into
the band.

### Sizes

The reference size is **1180×820** — iPad Air logical resolution, and what the
widget tests pin with `tester.view.physicalSize`.

The two halves of the game scale differently, on purpose:

- **Maps are fluid and already correct.** Node diameter is `shortest * 0.07`,
  banner size derives from that, lesson anchors come out of the magenta anchor
  PNG as 0–1 coordinates, and decor placements are normalised the same way. A
  node lands on the same spot in the painting at any size. Do not make node
  positions responsive — they are meant to sit on the path in the artwork.
- **Playfields are fixed logical pixels** — creatures 128×160, Buddy 208, the
  Continue arrow 96, the side shelves 72 and 140. On a 1920-wide monitor that
  leaves the scene small in a large frame.

The open question is whether playfields should render into a fixed design canvas
scaled uniformly to fit (rather than reflowing), which would keep the
composition identical across devices — notably keeping the creature `Wrap` from
laying out as one row on a monitor and two on an iPad, which changes what
counting them feels like. Not done yet.

---

## Audio

Two systems, both with a browser autoplay gate to get past.

- `platform/sfx_engine.dart` — pooled, pre-decoded clips plus the counting
  ladder and the music bed.
- `platform/narration_audio.dart` — recorded narration, keyed by the words
  spoken; falls back to system TTS when a clip is missing.

**The music bed belongs to the engine, not to a screen.** A screen *claims* a
bed (`startMusicBed`) and *releases* it (`releaseMusicBed`); a claim is
idempotent by resolved asset, and the bed stops only once the last claim is
given back, and even then after `kMusicBedReleaseGrace`. That is what makes a
visit to the Sanctuary sound like one place: the runner hands off to the lesson
and the lesson to the next runner, each asking for the same file, and the
player is simply never told to stop. Every runner used to call `stopMusicBed()`
in its own dispose, which is why a sub-mode change cut the music and the lesson
in between played silent. Call `stopMusicBed()` directly only where "now" is
genuinely meant — the settings toggle, teardown.

**Claims are counted, and that is not an optimisation.** A route change holds
the bed twice: Flutter mounts the incoming route and disposes the outgoing one
as the transition finishes, so the engine sees `claim(new)` and only then
`release(old)`. When release was an unconditional deferred stop, that release
scheduled the music to die a few seconds into a screen that was still asking
for it, with no later claim to cancel it.

Two consequences for anything new:

- **Claim and release must be an unconditional pair.** An unmatched release
  gives away somebody else's claim and the music stops one screen early,
  somewhere else, with nothing pointing back at the screen that miscounted.
  Wrap the screen in `MusicBedScope` and this is free; if you claim by hand, do
  it beside the engine reference you keep for `dispose`, never inside an
  `addPostFrameCallback` behind an `if (!mounted)`.
- **A screen changing which bed it wants calls `switchMusicBed`**, not
  `startMusicBed` — same claim, new mind.

`music_bed_handoff_test.dart` drives a real `GoRouter` rather than a
hand-written call sequence, because reasoning about that ordering by hand is
what got it wrong the first time.

The music and effect levels live in `audio_settings_provider.dart`, are pushed
into the engine by `AudioUnlockScope`, and are set from **Settings** — music
volume reaches a playing bed live, so the slider is audible while you drag it.

**The one trap to know before touching either:** `AudioPlayer.play()` returns a
Future that completes when playback **ends**, not when it starts. Awaiting it to
"bless" a player against the autoplay gate waits out the whole clip — and never
returns at all on a looping music bed. See `SfxEngine._bless` and
`test/sfx_unlock_test.dart`, which reproduces the real contract so a regression
hangs rather than passing quietly.

`AudioUnlockScope` offers every pointer-down to the engine until it reports
success, rather than firing once: clips may still be decoding on the first touch,
and browsers only honour the grant near a real interaction.

Regenerating placeholder audio:

```bash
python ../tools/audio/generate_placeholder_sfx.py
cd app && flutter test test/music_bed_loop_test.dart
```

That test reads the shipped audio rather than trusting the generator, because a
generator fix nobody re-runs leaves the broken file on disk — and because the
reverse also happened here: a bed that was correct on disk only because someone
had trimmed it by hand, over a generator that would have re-broken it.

The Sanctuary theme (`assets/audio/music/forest-mystical.mp3`) is a real
recording and is not generated. It is the largest single asset in the build at
9.25 MB — 320 kbps stereo, as delivered. Re-encoding to ~112 kbps would take it
under 3.5 MB if the first-load cost ever matters more than the fidelity.

Rendering narration after any wording change:

```bash
cd app && dart run tool/dump_narration_script.dart > ../tools/tts/kokoro/script.json
cd .. && node tools/tts/kokoro/render.mjs render
```

`test/narration_render_test.dart` fails if any scripted line has no clip on
disk — that is the gate that stops a reworded line silently reverting to the
browser synth voice.

A handful of words come out wrong (gryphon as GRIFF-ahn, toucan as TOO-kuhn).
`tools/tts/kokoro/lexicon.mjs` respells them for the synthesiser only — the
clip key, the caption and the script all keep the real spelling. See that
tool's README; `node tools/tts/kokoro/phonemes.mjs <word>` prints the IPA so a
new entry is a measurement rather than a guess.

---

## Content pipeline

`app/assets/data/` and `app/assets/content/` are the single source of truth for
registries, lessons and strings — edit them in place, there is no sync step.
Schemas live in the repo-root `schemas/`; check your edits with:

```bash
node tools/scripts/validate-data.mjs
```

## Folder structure

See `../specs/shared/project-bootstrap.md` for the full layout. Quick reference:

| Folder | Purpose |
|---|---|
| `lib/ui/` | Screens and widgets |
| `lib/coordinators/` | Orchestrate engines for use cases |
| `lib/engines/` | Pure logic (mastery, scaffolding, lesson runner, narration) |
| `lib/data/` | Catalogs, registries, and the words the game speaks |
| `lib/platform/` | Adapters (audio, TTS, haptics) — the swap boundary |
| `lib/models/` | Value classes |
| `lib/providers/` | Riverpod provider definitions, organized by scope |
| `tool/` | Dart-side dev scripts (narration script dump) |

Anything under `lib/data/` must stay free of `package:flutter` if
`narration_script.dart` reaches it — that file has to compile under plain
`dart run`, and a test walks the import graph to enforce it.
