# Voice Pipeline

> Programmatic text-to-speech generation for all kid-facing narration. Authoring writes scripts; a pipeline turns them into audio. No human voice actors at launch; ElevenLabs (or equivalent) generates everything, regenerates on script changes, and ships pre-rendered `.m4a` files in the app bundle.

References: `specs/shared/localization.md`, `specs/shared/asset-paths.md`, `specs/shared/k-activity-patterns.md` (region narrator convention), all lesson runtime JSONs (narration scripts).

---

## Why TTS instead of voice actors

| Factor | TTS | Voice actors |
|---|---|---|
| **Iteration speed** | Re-render a line in 5 seconds | Re-record a line in days/weeks |
| **Cost** | ~$22–99/month for full coverage | $1,000s per region narrator + per-revision pickups |
| **Consistency** | Identical voice across thousands of lines | Drift between sessions; pickup costs to match |
| **Localization** | Generate new language in hours | Re-cast and re-record entire script |
| **Solo-dev friendly** | Pipeline + API key | Casting + scheduling + studio time |
| **Quality ceiling at K (warm, character-driven)** | ElevenLabs is genuinely good; some "uncanny" risk in long emotional beats | Always higher than TTS for emotional range |

**Decision:** TTS at launch. If playtest shows specific lines feeling flat, those individual lines can be re-recorded by a human and dropped in (same file path, same naming). Hybrid is fine.

---

## Provider selection

### Primary: ElevenLabs

- **Voice character control** — Voice cloning + Voice Design lets us craft and lock distinct voices per region narrator. Each voice has a consistent ID we use across all generations.
- **SSML support** — `<break>`, `<emphasis>`, prosody control for pacing.
- **Quality** — best-in-class for warm, character-driven narration at the K age range.
- **Cost (2026 tiers — verify before commit)** — Creator $22/mo for ~100K characters; Pro $99/mo for ~500K characters.
- **Output** — MP3 / WAV; we convert to AAC `.m4a` at 96 kbps mono in the build pipeline.
- **Licensing** — commercial use OK on paid tiers; verify TOS at sign-up.

### Fallback options

| Provider | When to consider | Trade-off |
|---|---|---|
| **Azure Neural TTS** | If ElevenLabs cost grows past Pro tier | ~$16 per million chars; voices are good but less character-flexible |
| **OpenAI TTS** | Quick prototyping | $15 per million chars; only 6 fixed voices; less character distinction |
| **Google Cloud TTS** | If we already use GCP for other services | ~$16 per million chars (Wavenet); similar to Azure |
| **Resemble.ai / Play.ht** | If we need rapid voice-clone iteration | Comparable to ElevenLabs; slightly less polished |

The pipeline is provider-agnostic — switching is changing the adapter, not the architecture.

---

## Voice character map

Each character/narrator gets a locked **Voice Profile** consisting of:
- A ElevenLabs voice ID (cloned, designed, or selected from library)
- Per-character default model (`eleven_turbo_v2_5` for fast, `eleven_multilingual_v2` for highest quality)
- Per-character default stability + similarity slider settings
- Per-character SSML prosody defaults

| Character | Voice profile | Use |
|---|---|---|
| **Sanctuary warm naturalist** | warm, mid-pitch, unhurried; female or non-binary feel; like an older sibling | K activities, lessons, hub narration when in Sanctuary |
| **Wundletown frazzled wizard** | slightly higher pitch, comedic timing, exasperated affection; could be voiced through the visible wizard characters | 1st-grade activities, lessons, hub narration when in Wundletown |
| **Mathopolis radio announcer** | bright, slightly stylized "newsreel" energy, hero-narrator vibe; could lean masculine | 2nd-grade activities, lessons, hub narration when in Mathopolis |
| **Buddy** | small, charming, no fixed gender; bright but not chirpy; the same voice across all regions | Cross-region: short reactions, treat-jar moments, party cues |
| **Storyteller turtle** (visible narrator) | uses the **Sanctuary warm naturalist** voice profile, no change — the turtle is the visual presence; voice is unchanged | Storyteller's Pond only |
| **Lord Layerton** (2nd-grade recurring villain) | hammy, theatrical, cake-obsessed; clearly comedic, never menacing | Mathopolis storylines, Cake Caper portal arc |

### Voice ID locking process

For each character:
1. Browse ElevenLabs voice library + Voice Design for candidates.
2. Generate 3–5 sample lines per candidate using actual scripted lines from the K spec (e.g., the K.CC.4a lesson opening: *"Let's count these fawns together. Watch how each one gets one touch."*).
3. Pick the winner.
4. Lock the Voice ID + settings into `content/voice-profiles.json` (see below).
5. Never regenerate that voice profile after launch unless playtest forces it (we want voice identity to feel like a known character).

---

## Voice profiles config

```jsonc
// content/voice-profiles.json
{
  "$schema": "../schemas/voice-profiles.schema.json",
  "locked": true,
  "lastLockedAt": "2026-06-01",
  "profiles": {
    "sanctuary-warm-naturalist": {
      "provider": "elevenlabs",
      "voiceId": "XXXX_LOCKED_AT_KICKOFF",
      "model": "eleven_multilingual_v2",
      "settings": { "stability": 0.55, "similarityBoost": 0.85, "style": 0.20, "useSpeakerBoost": true },
      "defaultProsody": { "rate": "medium", "pitch": "+0st" }
    },
    "wundletown-frazzled-wizard": { /* ... */ },
    "mathopolis-radio-announcer": { /* ... */ },
    "buddy": { /* ... */ },
    "lord-layerton": { /* ... */ }
  }
}
```

The `locked: true` flag means the build pipeline rejects requests to swap voice IDs without an explicit unlock + changelog entry.

---

## Pipeline architecture

```
[Source: narration scripts in markdown + lesson runtime JSON]
                  ↓
[1. ScriptHarvester]
   Walks specs/lessons/*.md, specs/activities/*/*.md,
   data/lesson-runtime/*.json, content/strings/*/*.json
   Extracts every {voiceProfile, cueId, locale, text} tuple
                  ↓
[2. ScriptCanonicalizer]
   Resolves slot-fills (e.g., {creature_plural} → "fawns")
   Strips markdown emphasis but preserves SSML hints
                  ↓
[3. CacheChecker]
   Per (voiceProfile, cueId, locale, text-hash):
     - If file exists AND text-hash matches saved hash → skip
     - Else → enqueue for generation
                  ↓
[4. TTSGenerator]
   For each enqueued line:
     - Call ElevenLabs API with text + voiceId + settings + SSML
     - Receive MP3
     - Convert to AAC .m4a (96 kbps mono) via ffmpeg
     - Save to assets/.../{cueId}.m4a
     - Save text-hash sidecar (.hash file)
                  ↓
[5. ManifestUpdater]
   Updates assets/.../manifest.json with new files + checksums
                  ↓
[6. PreviewBundle (optional)]
   Generates an HTML preview page with text + audio player for QA review
```

The pipeline is a Node.js / Python / Dart script run from the dev's machine. Output is checked into the repo (or stored in a cloud asset bucket).

---

## File layout (matches `asset-paths.md`)

```
assets/
  lessons/
    {lesson-slug}/
      narration/
        en-US/
          {cueId}.m4a              # the rendered audio
          {cueId}.hash             # text hash for cache invalidation
  activities/
    {activity-slug}/
      narration/
        en-US/
          {cueId}.m4a
          {cueId}.hash
  shared/
    region-narrators/
      en-US/
        sanctuary-warm-naturalist/
          {cueId}.m4a              # cross-activity prompts (e.g., round-pass)
        wundletown-frazzled-wizard/
        mathopolis-radio-announcer/
        buddy/
        lord-layerton/
```

Per `localization.md`, the `{locale}` segment lets us regenerate the same scripts in another language later.

---

## Cue ID convention

Narration cues are addressed by **namespace + path**:

```
lesson:k-cc-4a-one-to-one:iShow.intro
lesson:k-cc-4a-one-to-one:weTry.prompt-1
activity:counting-parade:round-pass-pattern
shared:region-narrator:sanctuary:hesitation-prompt-5s
shared:buddy:round-pass-wiggle
```

The pipeline resolves `lesson:k-cc-4a-one-to-one:iShow.intro` → `assets/lessons/k-cc-4a-one-to-one/narration/en-US/iShow.intro.m4a`.

---

## SSML conventions

ElevenLabs supports a subset of SSML. We use a small consistent vocabulary:

| Tag | Use | Example |
|---|---|---|
| `<break time="500ms"/>` | Pause for emphasis | `"Ten! <break time="300ms"/> That's ten fawns."` |
| `<emphasis level="moderate">word</emphasis>` | Light emphasis on a math term | `"<emphasis>Above</emphasis> the well."` |
| `<prosody rate="slow">phrase</prosody>` | Slow down for a punchline | `"The last number you say <prosody rate="slow">tells you how many</prosody>."` |
| `<say-as interpret-as="cardinal">5</say-as>` | Force numeral pronunciation | Rare; numerals usually fine without |

Authoring rule: SSML stays minimal. Most lines need none. Use only when narrator pacing matters pedagogically.

---

## Canonicalizer render strategies (Stage 2 output)

After slot vocabulary classification, each expanded cue gets one of these strategies (per `tools/tts/canonicalize.mjs`):

| Strategy | What gets rendered | Runtime behavior |
|---|---|---|
| `full-render` | The cue text with all slots substituted | Play the `.m4a` straight |
| `digit-stitched-template` | The cue text with `<break time="500ms"/>` markers where digit-stitched slots go | Play the cue `.m4a`, overlay numeral `.m4a` from the digit library during the break |
| `digit-stitched+runtime-template` | Same as digit-stitched-template plus runtime-only placeholders still in the text | Same as above, plus runtime substitutes user-entered text (e.g., Buddy name) |
| `runtime-template` | The text with `{slot}` placeholders intact | Not rendered to audio at all; runtime calls live TTS or substitutes display text |

The **digit library** is a separate set of `.m4a` files: one per numeral 0–N per voice profile per locale, rendered once and shared across all digit-stitched cues. For K with one voice and range 0–100: ~100 files per voice.

This means digit-stitched slots do NOT multiply the cue count, even when several appear in one cue. A cue like `"{biggest_count} {biggest_category}, {next_count} {next_category}, {least_count} {least_category}"` (Care Pantry round-pass) expands to 64 variants (4³ for the categories) rather than 64,000 (with counts).

---

## Slot-fill conventions

Many lines are templated:

```
"How many {creature_plural} altogether?"
```

These resolve at **script-harvest time**, not at runtime. The pipeline:

1. Reads the narration template.
2. Reads the activity's slot vocabulary (per content templates).
3. Generates **one .m4a per slot value combination** that's actually used.

For "ducks" / "frogs" / "dragonlings" — three audio files:
```
assets/activities/storytellers-pond/narration/en-US/howmany-ducks.m4a
assets/activities/storytellers-pond/narration/en-US/howmany-frogs.m4a
assets/activities/storytellers-pond/narration/en-US/howmany-dragonlings.m4a
```

The runtime looks up the right one based on round state. No mid-line text-to-speech in the running app.

---

## Cost estimate

### Per-character coverage (English at launch)

Approximate counts (rough order of magnitude):

| Source | Lines | Avg chars | Total chars |
|---|---|---|---|
| 21 K lessons (5 voices) | ~150 lines × 21 = 3,150 | ~50 | 158K |
| 11 K activity narration | ~30 lines × 11 = 330 | ~60 | 20K |
| Shared region narrator cues | ~80 lines | ~40 | 3K |
| Dashboard + onboarding | ~50 lines | ~80 | 4K |
| Slot-fill expansions (3× multiplier on activity narration) | — | — | +40K |
| **K total** | | | **~225K chars** |
| 1st & 2nd grade (estimate, when added) | | | +400K each |

### ElevenLabs tier mapping

- **K launch only** — 225K characters → **Creator tier ($22/mo)** for ongoing tweaks, or burst to Pro tier for initial generation
- **K + 1st + 2nd grade** — ~1M characters total → **Pro tier ($99/mo)** for steady ongoing

### Initial generation budget

Full-app initial generation: ~$22 (one month of Creator tier covers it). Subsequent iterations: per-line regeneration is cheap.

---

## Iteration workflow

### Day-to-day: script change

1. Author edits a narration line in a lesson markdown file or activity spec.
2. Author updates the corresponding string in `content/strings/{locale}/...json` (per `localization.md`).
3. Run `npm run tts:generate` (or equivalent).
4. Pipeline detects hash change for that one line and regenerates only that file.
5. Commit the new `.m4a` + `.hash` to the repo (or push to asset bucket).

Total iteration: **~10 seconds** for a single line change.

### Larger changes: new lesson

1. Author writes the lesson markdown + runtime JSON.
2. Author populates the string table entries.
3. Run `npm run tts:generate`.
4. Pipeline generates all new cues for the lesson.
5. Author reviews via the HTML preview bundle (audio player for each cue with the text alongside).
6. If unsatisfied: tweak SSML or text, re-run.
7. Commit.

Total iteration for a fresh lesson: **~2 minutes** of pipeline time + however long the author needs to review.

---

## Quality control

### Pre-flight checks

- **Pronunciation** — math terms ("decompose," "ten-frame," "cardinality") should pronounce naturally. The pipeline ships with a per-term pronunciation override list (`content/pronunciation-overrides.json`) injected as SSML when needed.
- **Voice consistency** — same Voice ID + settings across all lines for a given character. Pipeline enforces.
- **Length sanity** — flag any rendered cue >15s or <0.3s for manual review (likely a script error).
- **Silence detection** — flag cues that render as silence or near-silence (TTS sometimes glitches).

### Manual review milestones

- **Initial generation** — listen to every cue at least once (HTML preview bundle makes this easy: ~225K chars / ~150 wpm = ~25 minutes of listening to review the full K bank).
- **Pre-launch** — full second-pass review with a parent or two as fresh ears.
- **Post-launch** — telemetry on `narration.line_replayed` (kid hit replay) flags cues that may need re-generation.

---

## Mouth-sync (Storyteller turtle)

The Storyteller turtle has visible mouth-sync animation. Per `localization.md`:

- ElevenLabs returns audio + (optionally) a character-level timing JSON.
- The pipeline saves the timing JSON alongside the `.m4a`.
- The runtime uses the timing to drive the turtle's mouth-shape sequence.
- Mouth shapes are 5 generic positions (closed, slightly-open, wide, round-vowel, narrow-vowel) — language-agnostic.

If ElevenLabs doesn't return timing data, the pipeline runs a forced-alignment pass (whisper-cpp word-level timestamps) to generate it.

---

## Backup / regeneration policy

- All `.m4a` outputs are checked into the repo (or stored in a versioned asset bucket).
- The `.hash` sidecar lets us regenerate any single file deterministically.
- If voice profiles ever unlock (e.g., we move from ElevenLabs to a different provider), the pipeline can regenerate the entire bank in one batch (~$22 cost burst).

---

## Localization migration

Per `localization.md`, adding a second language is:
1. Translate string tables.
2. Pick voice profiles for that language (ElevenLabs supports many languages; voice profiles per language).
3. Run the pipeline against the new locale.
4. Ship the new `.m4a` files in `assets/.../narration/{new-locale}/`.

No code changes required.

---

## Open Questions

- **ElevenLabs vs Azure Neural for production** — ElevenLabs is the recommended default for warmth. Confirm after generating 10 sample lines and listening; if Azure sounds equivalent at half the price, switch.
- **Voice cloning ethics** — if we clone a real human voice (e.g., the founder's voice for one of the narrators), ensure proper consent + ElevenLabs IVC policy compliance. Suggest using ElevenLabs library voices or Voice Design (synthetic) at launch to avoid ambiguity.
- **Per-line SSML budget** — overuse of SSML hurts naturalness. Cap at ~3 SSML tags per cue. Confirm in QA.
- **Pronunciation override list** — start empty, build during first review pass. Terms likely needed: "ten-frame," "decompose," numeral-as-name vs numeral-as-quantity disambiguation.
- **Lord Layerton's "hammy" register** — TTS may not pull off comedic-villainous theatricality. Consider a human voice actor for Lord Layerton specifically if the lines feel flat in TTS.
- **Buddy's "no fixed gender, bright not chirpy"** — Voice Design synthesis can produce this; library voices may not have it. Plan for Voice Design.

---

## Implementation notes

### Pipeline as offline tooling (Node + optional Dart mirror)

The TTS pipeline runs offline — the rendered `.m4a` files ship in the app bundle. The pipeline tooling does NOT run in the Flutter app, so it doesn't need to be Dart. As of 2026-06-01, the **canonical implementation is Node.js** (`tools/tts/*.mjs`), runnable on Windows without any extra SDK install. The original spec called for Dart; that's still acceptable for parts that need to share data structures with the app, but Node is the primary tooling.

Folder structure:

```
tools/tts/
├── verify-harvest.mjs       # Stage 1: harvest narration cues  (✅ implemented)
├── canonicalize.mjs         # Stage 2: expand slots, replace digit-stitched with breaks  (✅ implemented)
├── (TBD)                    # Stage 3: CacheChecker (hash sidecars)
├── (TBD)                    # Stage 4: TTSGenerator (ElevenLabs API + ffmpeg)
├── (TBD)                    # Stage 5: ManifestUpdater
├── (TBD)                    # Stage 6: PreviewBundle
├── harvester.dart           # Dart mirror of Stage 1 (canonical reference; not run automatically)
└── lib/                     # Dart library code
```

If the Dart project skeleton (`app/`) ever needs to consume the pipeline's output at runtime in a structured way, the Dart `lib/` mirror gives a reference implementation. Most consumers will just read the JSON manifests.

### Original recommendation (preserved for reference): Pipeline as a Dart CLI

Since the original launch stack was Flutter-first with a planned native swap, the pipeline was specced to live in `tools/tts/` as a Dart CLI:

```
tools/tts/
├── bin/generate.dart       # entry point
├── lib/
│   ├── harvester.dart      # walks specs + JSON
│   ├── canonicalizer.dart  # slot-fill + SSML normalization
│   ├── elevenlabs_client.dart
│   ├── ffmpeg_runner.dart  # MP3 → AAC conversion
│   └── manifest_writer.dart
└── test/
    └── pipeline_smoke_test.dart
```

`dart run tools/tts/bin/generate.dart --voice all --locale en-US` runs the full pipeline.

### CI integration

A pre-merge check verifies:
- Every `cueId` referenced in narration scripts has an audio file.
- Every audio file has a corresponding hash that matches its current source text.
- No orphan audio files (cues that no spec references).

The check fails the PR if there's drift, so production audio always matches production scripts.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-31 | Initial draft — ElevenLabs-first programmatic TTS pipeline; voice profile locking; SSML conventions; slot-fill resolution at harvest time; cost estimates; iteration workflow; CI guardrails | |
| 2026-06-01 | Stage 2 (Canonicalizer) implemented. Render strategy enum locked: `full-render`, `digit-stitched-template`, `digit-stitched+runtime-template`, `runtime-template`. Digit library introduced (per-voice numeral-as-word `.m4a`s rendered once, concatenated at runtime). Cross-platform durability reframe: pipeline tooling is Node.js primary, Dart mirror optional. | |
