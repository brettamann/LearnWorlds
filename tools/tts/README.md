# CritMath TTS Pipeline

Tooling for generating all kid-facing voice narration via TTS. See `specs/shared/voice-pipeline.md` for the design.

**Stages 1–4 are implemented:**

| Stage | Script | Purpose |
|---|---|---|
| 1 Harvester | `verify-harvest.mjs` (Node), `bin/harvest.dart` (Dart canonical) | Walks lesson runtime JSONs + activity narration JSONs; produces `harvest-manifest.json` |
| 2 Canonicalizer | `canonicalize.mjs` | Expands slot placeholders per vocabulary; produces `canonical-manifest.json` |
| 3 CacheChecker | `check-cache.mjs` | Compares against `.hash` sidecars; produces `render-plan.json` |
| 4 TTSGenerator | `generate.mjs` | Calls ElevenLabs API; writes `.mp3` (or `.m4a` with `--aac` + ffmpeg) + `.hash` sidecars |
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

**Future stages** of the pipeline per `voice-pipeline.md`:

1. ✅ **Harvester** (Stage 1)
2. ✅ **Canonicalizer** (Stage 2)
3. ✅ **CacheChecker** (Stage 3)
4. ✅ **TTSGenerator** (Stage 4)
5. ⏳ **ManifestUpdater** — asset folder manifests + checksums
6. ⏳ **PreviewBundle** — HTML page for QA review of all rendered cues

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
