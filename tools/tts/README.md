# CritMath TTS Pipeline

Tooling for generating all kid-facing voice narration via TTS. See `specs/shared/voice-pipeline.md` for the design.

This package implements **Stage 1 (Harvester)** of the pipeline. Future stages (Canonicalizer, CacheChecker, TTSGenerator, ManifestUpdater, PreviewBundle) will be added as the project progresses.

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

## What's not yet here

**Future stages** of the pipeline per `voice-pipeline.md`:

1. ✅ **Harvester** — this tool (Stage 1)
2. ⏳ **Canonicalizer** — slot-fill expansion, SSML normalization
3. ⏳ **CacheChecker** — text-hash sidecars, skip-if-unchanged logic
4. ⏳ **TTSGenerator** — ElevenLabs API calls, ffmpeg MP3→AAC, file output
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
