# CritMath TTS Pipeline

Tooling for generating all kid-facing voice narration via TTS. See `specs/shared/voice-pipeline.md` for the design.

**All 6 stages are implemented:**

| Stage | Script | Purpose |
|---|---|---|
| 1 Harvester | `verify-harvest.mjs` (Node), `bin/harvest.dart` (Dart canonical) | Walks lesson runtime JSONs + activity narration JSONs; produces `harvest-manifest.json` |
| 2 Canonicalizer | `canonicalize.mjs` | Expands slot placeholders per vocabulary; produces `canonical-manifest.json` |
| 3 CacheChecker | `check-cache.mjs` | Compares against `.hash` sidecars; produces `render-plan.json` |
| 4 TTSGenerator | `generate.mjs` | Calls ElevenLabs API; writes `.mp3` (or `.m4a` with `--aac` + ffmpeg) + `.hash` sidecars |
| 5 ManifestUpdater | `build-manifests.mjs` | Walks rendered audio; writes per-folder `manifest.json`s + global `assets/narration-manifest.json` |
| 6 PreviewBundle | `build-preview.mjs` | Generates `preview-bundle/index.html` — browseable QA review with filters + audio players |
| Voice picker (helper) | `sample-voices.mjs` | Renders representative lines through multiple candidate voice IDs into a side-by-side HTML preview |

## Prerequisites

- **Dart SDK ≥ 3.0** ([install instructions](https://dart.dev/get-dart))
  - Windows: `choco install dart-sdk` (via Chocolatey), or grab the installer
  - macOS: `brew tap dart-lang/dart && brew install dart`
- The CritMath repository checked out

You do **not** need Flutter for the tooling — pure Dart SDK is enough.

## First-time setup

From the repo root:

```bash
cd tools/tts
dart pub get
```

This fetches the small dependency set (`args`, `path`, `test`).

## Run the harvester

From inside `tools/tts/`:

```bash
dart run bin/harvest.dart
```

Or with options:

```bash
dart run bin/harvest.dart --repo-root ../.. --out harvest-manifest.json --locale en-US -v
```

The harvester walks:

- `data/lesson-runtime/*.json` — every K lesson's narration script

It emits:

- `harvest-manifest.json` — the full manifest of every cue (cueId, voice profile, locale, text, source, slot placeholders)
- A console summary (total cues, totals per voice, per-lesson breakdown, warnings, errors)

## What's in the manifest

Each cue:

```json
{
  "cueId": "lesson:lesson-k-cc-4a-one-to-one:iShow:t1s",
  "voiceProfile": "sanctuary-warm-naturalist",
  "locale": "en-US",
  "text": "Let's count these fawns together. Watch how each one gets one touch.",
  "source": "lesson-runtime/k-cc-4a-one-to-one.json"
}
```

Cues with slot placeholders (`{slot}` patterns) include a `slotPlaceholders` array. These need slot-fill expansion at the next pipeline stage (Canonicalizer).

The manifest also reports:

- Total cue count + character count (for cost estimation against ElevenLabs tiers)
- Per-voice character counts
- Per-source category breakdown
- Per-lesson cue counts
- Duplicate cue IDs (a unique cueId is a pipeline invariant; any duplicates are bugs to fix)
- Warnings (recoverable; e.g., a single malformed entry was skipped)
- Errors (fatal-ish; e.g., a whole file failed to parse)

## CLI options

| Flag | Default | Description |
|---|---|---|
| `--repo-root PATH` | `../..` | Path to CritMath repo root |
| `--out PATH` | `harvest-manifest.json` | Manifest output file |
| `--locale CODE` | `en-US` | Locale to harvest for |
| `-v`, `--verbose` | off | Print each walked file |
| `-h`, `--help` | — | Show usage |

## Exit codes

- `0` — Success (warnings allowed)
- `1` — Errors (at least one file failed; manifest still written for inspection)
- `2` — Bad CLI arguments

## End-to-end run (dry-run)

```bash
cd tools/tts

# Stage 1: harvest
node verify-harvest.mjs
# → harvest-manifest.json (~456 cues)

# Stage 2: canonicalize
node canonicalize.mjs
# → canonical-manifest.json (~2,900 expanded cues + digit library)

# Stage 3: check cache
node check-cache.mjs
# → render-plan.json (enumerates what would be rendered)

# Stage 4: dry-run generator
node generate.mjs --max 5 -v
# → prints first 5 entries it WOULD render; no API call
```

## End-to-end run (live)

```bash
# 1. Pick your ElevenLabs voice IDs first using the sampler:
export ELEVENLABS_API_KEY="sk_..."
node sample-voices.mjs --voices voiceA,voiceB,voiceC --profile sanctuary-warm-naturalist
# → open voice-samples/index.html and listen

# 2. Lock chosen voice IDs into voice-profiles.json (set "locked": true, fill voiceId fields)

# 3. Run the pipeline live:
node verify-harvest.mjs
node canonicalize.mjs
node check-cache.mjs
node generate.mjs --live --max 10  # render 10 entries to validate
node generate.mjs --live           # render everything else

# 4. Build manifests + preview bundle for QA:
node build-manifests.mjs           # writes assets/narration-manifest.json
node build-preview.mjs             # writes preview-bundle/index.html
# → open preview-bundle/index.html in a browser, click through every cue
```

## Output format: MP3 by default

`generate.mjs` writes `.mp3` directly from the ElevenLabs API. Flutter's `just_audio` plays MP3 natively.

If you want `.m4a` AAC instead (per the original `asset-paths.md` recommendation): install ffmpeg (`choco install ffmpeg` on Windows) and pass `--aac`. The generator runs ffmpeg to convert each MP3 → AAC `.m4a` and only writes the `.m4a` file.

## Safety: dry-run is the default

`generate.mjs --live` is required to actually call the ElevenLabs API. Without `--live`, the generator prints what it WOULD render. There's also a pre-flight check that fails fast if:
- `ELEVENLABS_API_KEY` is missing
- Any voice profile still has `voiceId: "REPLACE_WITH_REAL_VOICE_ID"`

These guards prevent burning ElevenLabs credits on a misconfigured run.

## What's not yet here

All 6 pipeline stages are implemented:

1. ✅ **Harvester** (Stage 1)
2. ✅ **Canonicalizer** (Stage 2)
3. ✅ **CacheChecker** (Stage 3)
4. ✅ **TTSGenerator** (Stage 4)
5. ✅ **ManifestUpdater** (Stage 5)
6. ✅ **PreviewBundle** (Stage 6)

**Other sources** the harvester will eventually walk:

- `content/strings/{locale}/lessons/*.json` — once the localization rollout migrates inline text to string-table refs (per `localization.md`)
- `content/strings/{locale}/activities/*.json` — activity narrator prompts (currently described only in activity spec prose)
- `content/strings/{locale}/shared/narrator-cues.json` — shared narrator round-pass / hesitation prompts
- `content/strings/{locale}/onboarding.json` and `dashboard.json`

These data files don't exist yet. The harvester gracefully reports zero cues from missing sources; it doesn't fail.

## Project layout

```
tools/tts/
├── pubspec.yaml
├── README.md          (this file)
├── bin/
│   └── harvest.dart   (CLI entry)
└── lib/
    └── harvester.dart (Harvester library — walker + Cue + HarvestResult)
```

## Development

Run the test suite (none yet; placeholder structure):

```bash
dart test
```

Format code:

```bash
dart format .
```

Analyze:

```bash
dart analyze
```

---

## The voice you actually get today: `kokoro/`

**Start here.** `kokoro/` renders the entire narration script with Kokoro-82M,
locally, for free, in about ten minutes. It is Apache-2.0 and runs on the CPU,
so re-rendering after a wording change costs nothing but the wait.

```
cd tools/tts/kokoro && npm install
node render.mjs status
node render.mjs render
```

That is the whole setup. No app code changes - `NarrationPlayer` already
prefers a bundled clip over system TTS, so a rendered clip is picked up because
it is in the folder under the right name.

`record/` below is still the path for lines you want in your own voice.
Rendering never overwrites an existing clip in any format, so a hand-recorded
`.wav` always wins and the machine fills in everything around it. The two are
complementary rather than alternatives, and the practical division is: record
the handful of lines that carry the most warmth, let Kokoro speak the other
two hundred.

See `kokoro/README.md` for voices, formats and the reuse rules.

---

## Recording the voice yourself (`record/`)

The ElevenLabs pipeline above is deferred (`specs/shared/text-and-tts-deferral.md`),
which left every line in the OS text-to-speech voice. `record/index.html` is the
way around that without un-deferring anything: a browser harness that shows you
the script, records you reading it, and writes each line under the filename the
app looks for.

The app plays a recorded clip when one exists and speaks the line through system
TTS when one doesn't, so **recording is incremental and never blocks a build**.
Zero clips is a valid state; so is a hundred.

### Clips are keyed by the words, not by the cueId

This is the thing to understand before recording anything.

A cueId names a *slot* — `parade:tap-r0-3` is "the third tap of round one". It is
the wrong key for a recording, for two reasons:

- **The same sentence occupies dozens of slots.** `parade:tap-r0-3` through
  `parade:tap-r4-7` are twenty-five cueIds whose text is only ever some number
  word. Keyed by cueId you would record "Three." over and over under different
  names.
- **A slot does not say the same thing twice.** Species are seeded per session,
  so `parade:counting-prompt-r2` is "Touch each fawn…" today and "Touch each baby
  dragon…" tomorrow. A clip filed under that cueId would eventually speak the
  wrong creature to a child, and nothing would report an error.

So a clip's filename is derived from its sentence: a readable slug of the first
48 characters, then `__`, then FNV-1a over the UTF-8 bytes of the whitespace-
normalised text.

```
"Seven."                                       -> seven__<hash>.wav
"Touch each fawn — and count out loud with me!" -> touch-each-fawn-and-count-out-loud-with-me__4a5087aa.wav
```

Two consequences worth knowing:

- **Recordings are shared.** All five counting activities speak the same hundred
  number words, so one take of "Seven." serves Counting Parade, Count On By Ones,
  Count Forward From N, Count Out N and the challenge layer at once.
- **Rewording a line orphans its clip, on purpose.** The recording says the old
  words. The export reports orphans so you know what to re-cut.

The transform lives in `narrationClipKey()` in
`app/lib/platform/narration_audio.dart` and is implemented independently in
`record/index.html`. Shared vectors are pinned in
`app/test/narration_script_test.dart` and in `record/check.mjs`, so a drift on
either side fails loudly rather than producing files the app never opens.

### Getting the script

Most of it needs no playthrough. `app/lib/data/narration_script.dart` walks the
same catalogs and calls the same line-building functions the runners call, so it
can enumerate every line the game is able to compose — 253 of them across eight
batches.

The remainder is assembled from lesson JSON and only appears once the lesson that
owns it has been played. `NarrationCueLog` records those as they are heard and
**persists across sessions**, so that half fills in as the game gets used rather
than demanding one heroic playthrough.

**Settings → Copy recording script** puts both halves on the clipboard, together
with a coverage count and the orphan list.

### Recording

1. Serve the harness — the mic and the folder picker both need a secure context,
   and `file://` is not one:
   `npx serve tools/tts/record` or `python -m http.server -d tools/tts/record`.
2. Paste the script, **Load script**.
3. **Choose output folder** → `app/assets/audio/narration/`. Takes are then
   written straight in. Without it they download one at a time, which for the
   100-line counts batch is not a workflow.
4. Pick a batch. They are ordered most-heard first, so recording straight down
   the list makes the game warmer fastest per minute at the microphone.
5. **Continuous take** (the default): hit record once, read the whole batch top
   to bottom leaving about a second of silence between lines, then stop. The take
   is split on those silences and each piece is named for you.

   The header says how many segments it found against how many it expected. If
   those disagree, adjust the **threshold** and **gap** sliders — re-splitting is
   instant and does not need another take. Only when they match will it save.
6. **One at a time** for anything the split got wrong: `space` records and stops,
   `enter` saves and advances. Clicking any line in the list jumps to it.
7. Rebuild. There is no manifest step — the app discovers clips from Flutter's own
   asset manifest at boot, so `build-manifests.mjs` is not part of this path.

Each clip is downmixed to mono, trimmed, peak-normalised to −1 dBFS and written as
16-bit PCM WAV. WAV rather than the browser's native webm/opus because Safari and
iOS cannot decode webm and the iPad is the eventual target.

Run `node tools/tts/record/check.mjs` after touching the harness.

### What to record first

The batches are already in that order. Concretely:

| Batch | Lines | Why |
|---|---:|---|
| `counts` | 100 | One sounds on **every tap in five activities**. Nothing else in the game comes close. |
| `warm-miss` | 4 | Heard on every wrong answer. |
| `warm-hint` | 3 | Heard whenever she stalls. |
| `parade-prompt` | 8 | Opens every parade round. |
| `parade-reward` | 6 | The coin payout. |
| `parade-final` | 64 | The last-round wrap-up, per count per species. |
| `parade-intro` | 64 | The longest line and the first she hears each visit. Skippable. |
| `parade-transition` | 4 of 1792 | **Sampled deliberately — see below.** |

Read to a five-year-old, not to a microphone: warm, unhurried, smiling. For the
`counts` batch, count the way you would count objects *with* a child rather than
reading a list — the game plays a rising musical note under each one, and a flat
read fights it.

### The one family that stays synthetic

`paradeTransitionLine` names the count, the species just finished **and** the
species coming next. That is 1,792 combinations, of which a session speaks four.
It is marked incomplete in the script and left to system TTS on purpose; the
harness shows four as a sample so you can hear how it would sound.

If it ever matters enough to record, the fix is upstream: stop naming the next
species in that line, which collapses the family to 64.
