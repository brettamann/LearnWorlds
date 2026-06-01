# Slot Vocabulary

> Templated narration like "How many {creature_plural}?" needs a way to know what `{creature_plural}` resolves to. This spec defines the slot identifier hierarchy, vocabulary structure, and resolution rules. Inputs to the TTS Canonicalizer (Stage 2) and the activity runtime's at-speak-time slot fill.

References: `specs/shared/voice-pipeline.md`, `specs/shared/system-architecture.md` (SlotResolver), `specs/shared/localization.md`, `data/slot-vocabulary/en-US.json`.

---

## Why this exists

Narration scripts use placeholder syntax:

```json
{ "text": "How many {creature_plural} altogether?" }
```

Without a vocabulary, we have two problems:
1. **TTS pipeline (offline)** — when do we render `.m4a`? Per-template (1 file with `{creature_plural}` baked in)? Per-value (1 file per "ducks" / "frogs" / etc.)? Neither works without knowing the value set.
2. **Runtime (online)** — at speak-time, what string does `{creature_plural}` become for this specific round?

The slot vocabulary is the single source of truth for both. It lists every slot identifier the system uses, the data type, the value set (or range), and the resolution rule.

---

## Slot identifier hierarchy

Slot identifiers are dotted-path strings with a stable namespace prefix.

| Prefix | Meaning | Lifetime | Examples |
|---|---|---|---|
| `kid.*` | Belongs to the active kid profile | Kid scope (per `system-architecture.md`) | `kid.buddyName`, `kid.avatarName`, `kid.homeName` |
| `round.*` | Belongs to the in-flight round | Session scope | `round.startN`, `round.target`, `round.creatureSpeciesPlural` |
| `activity.*` | Belongs to the activity definition | App scope (static) | `activity.displayName`, `activity.regionDisplayName` |
| `system.*` | Belongs to the running app / device | App scope (semi-static) | `system.currentDate`, `system.season`, `system.weatherLabel` |

The runtime's `SlotResolver` reads the prefix to know which scope to query.

---

## Vocabulary file structure

One file per locale: `data/slot-vocabulary/{locale}.json`.

```jsonc
{
  "$schema": "../../schemas/slot-vocabulary.schema.json",
  "locale": "en-US",
  "lastUpdated": "2026-05-31",
  "vocabularies": {
    "round.creatureSpecies": {
      "type": "string",
      "description": "Singular species name for the creature population in this round.",
      "values": ["fawn", "duck", "frog", "dragonling", "baby-gryphon", "unicorn", "koi", "goat"]
    },
    "round.creatureSpeciesPlural": {
      "type": "string",
      "description": "Plural form of round.creatureSpecies.",
      "derivedFrom": "round.creatureSpecies",
      "values": {
        "fawn": "fawns",
        "duck": "ducks",
        "frog": "frogs",
        "dragonling": "dragonlings",
        "baby-gryphon": "baby gryphons",
        "unicorn": "unicorns",
        "koi": "koi",
        "goat": "goats"
      }
    },
    "round.startN": {
      "type": "integer",
      "description": "Starting count for the round (varies by activity / sub-mode).",
      "range": { "min": 0, "max": 20 },
      "spokenAs": "numeral-as-word"
    },
    "kid.buddyName": {
      "type": "string",
      "description": "Kid's name for their Math Buddy. Free-form; user-entered.",
      "valueSet": "user-supplied",
      "ttsExpansionStrategy": "runtime-only"
    }
    ...
  }
}
```

### Vocabulary entry fields

| Field | Required | Meaning |
|---|---|---|
| `type` | yes | `string`, `integer`, `number`, `boolean`, `enum`, `template` |
| `description` | yes | Designer-readable explanation |
| `values` | conditional | The enumerated value set. For derived slots, this is a `from→to` map |
| `range` | conditional | For numeric types, the min/max bounds |
| `derivedFrom` | optional | Another slot whose value this one is computed from (e.g., plural from singular) |
| `spokenAs` | optional | How the slot's value is rendered in audio: `literal` (default), `numeral-as-word` (e.g., 5 → "five"), `ordinal-as-word` (e.g., 3 → "third"), `time-of-day` |
| `valueSet` | optional | `enumerated` (default), `user-supplied` (kid-entered free-form text), `system-derived` (computed at runtime) |
| `ttsExpansionStrategy` | optional | How the TTS Canonicalizer handles this slot. See below. |

### TTS expansion strategies

When the Canonicalizer encounters a template like `"How many {creature_plural} altogether?"`, it needs to know whether to:

| Strategy | Behavior | Use when |
|---|---|---|
| `expand-per-value` *(default for enumerated)* | Render one `.m4a` per value in the vocabulary (e.g., `howmany-ducks.m4a`, `howmany-frogs.m4a`). Runtime picks the right file at speak time. | Small enumerated vocabulary (≤ ~20 values). The common case. |
| `runtime-only` | Don't render TTS. The runtime calls live TTS or skips the slot. | User-supplied free-form text (kid's Buddy name, etc.) — can't be pre-rendered. |
| `digit-stitched` | Render only "the number". Pre-rendered `0.m4a` through `99.m4a` (separate from sentence audio). The runtime concatenates "How many ducks altogether? <pause>" + `numeral.m4a`. | Numeric slots with wide ranges. Avoids combinatorial explosion. |
| `concatenated` | Pre-render small fragments and concatenate at runtime (e.g., color + shape: "red triangle" = `red_.m4a` + `_triangle.m4a`). | Compound enumerated slots. Rare. |

The Canonicalizer reads each slot's strategy and generates the right number of `.m4a` files.

---

## Universal slots used across K activities

These are referenced in the current activity narration JSONs. Each must be defined in `data/slot-vocabulary/en-US.json`.

### Kid-scope slots

| Slot | Type | Strategy | Notes |
|---|---|---|---|
| `kid.buddyName` | string | runtime-only | Kid-entered |
| `kid.avatarName` | string | runtime-only | Kid-entered |
| `kid.homeName` | string | runtime-only | Kid-entered |
| `Buddy_name` *(legacy alias)* | string | runtime-only | Alias to `kid.buddyName` |

### Round-scope slots — counting

| Slot | Type | Strategy | Notes |
|---|---|---|---|
| `round.creatureSpecies` | enum | expand-per-value | ~8 K species |
| `round.creatureSpeciesPlural` | enum | derived | plural form per locale |
| `round.targetCount` | integer (1–100) | digit-stitched | wide range |
| `round.finalCount` | integer (1–100) | digit-stitched | |
| `round.startN` | integer (0–20) | digit-stitched | |
| `round.kidCount` | integer (0–20) | digit-stitched | |
| `round.delta` | integer (1–10) | digit-stitched | |
| `round.clusterCount` | integer (2–10) | digit-stitched | for tens-parade |
| `N` *(legacy alias)* | integer | digit-stitched | alias for round.finalCount or round.target |

### Round-scope slots — operations / decomposition

| Slot | Type | Strategy | Notes |
|---|---|---|---|
| `round.startingAmount` | integer (0–10) | digit-stitched | Ten-Frame Pond make-ten |
| `round.target` | integer (1–30) | digit-stitched | |
| `round.extrasNeeded` | integer (1–9) | digit-stitched | ten-plus-n |
| `round.partA` | integer (0–10) | digit-stitched | |
| `round.partB` | integer (0–10) | digit-stitched | |
| `round.resultN` | integer (0–10) | digit-stitched | |
| `round.changeN` | integer (1–10) | digit-stitched | |
| `round.total` | integer (0–20) | digit-stitched | |
| `round.finalN` | integer (0–20) | digit-stitched | two-step story result |
| `round.leaveVerb` | enum | expand-per-value | values: ["swim away", "fly off", "splash out"] |

### Round-scope slots — shapes & sorting

| Slot | Type | Strategy | Notes |
|---|---|---|---|
| `round.targetShape` | enum | expand-per-value | K.G.2 target |
| `round.targetShapePlural` | enum | derived | |
| `round.foundCount` | integer (1–10) | digit-stitched | |
| `round.attributeName` | enum | expand-per-value | "number of sides", "curvy or straight", "color paired with shape" |
| `round.attribute1` / `round.attribute2` | enum | expand-per-value | two-attribute hunt |
| `round.sortedCount` | integer (1–20) | digit-stitched | |

### Round-scope slots — positional

| Slot | Type | Strategy | Notes |
|---|---|---|---|
| `round.positionWord` | enum | expand-per-value | "above", "below", "beside", "in front of", "behind", "next to" |
| `round.referenceLandmark` | enum | expand-per-value | "tree", "well", "mushroom", "rock cluster", "cottage" |
| `round.landmark1` / `round.landmark2` | enum | expand-per-value | relational mode |
| `round.kidDropZone` | enum | expand-per-value | the position the kid actually dropped Buddy on (correction narration) |

### Round-scope slots — habitats

| Slot | Type | Strategy | Notes |
|---|---|---|---|
| `round.residentCreature` | enum | expand-per-value | "fawn", "unicorn", "hatchling-dragon", "baby-gryphon" |
| `round.creatureName` | string | runtime-only | named creature character (e.g., "Pip the fawn") |
| `round.frameShape` | enum | expand-per-value | "triangle", "square", "rectangle", "pentagon", "hexagon" |
| `round.nextPieceType` | enum | expand-per-value | "cube", "cone", "cylinder", "sphere" |
| `round.nextSlotName` | enum | expand-per-value | "body", "roof", "chimney", "doorknob" |

### Round-scope slots — pantry / picnic / bench

| Slot | Type | Strategy | Notes |
|---|---|---|---|
| `round.sortRule` | enum | expand-per-value | "color", "size", "texture" |
| `round.nextItemName` | enum | expand-per-value | depends on activity item set |
| `round.nextCategoryName` | enum | expand-per-value | "treats", "beds", "toys", "grooming" |
| `round.biggestCount` / `round.middleCount` / `round.leastCount` | integer (0–10) | digit-stitched | |
| `round.biggestCategoryName` / `round.middleCategoryName` / `round.leastCategoryName` | enum | expand-per-value | one of category names |
| `round.basketAContent` / `round.basketBContent` | enum | expand-per-value | "apple slices", "sparkleberries", etc. |
| `round.basketAContentPlural` / `round.basketBContentPlural` | enum | derived | |
| `round.basketACount` / `round.basketBCount` | integer (0–10) | digit-stitched | |
| `round.comparisonWord` | enum | expand-per-value | "greater than", "less than", "equal to" |
| `round.leftNumeral` / `round.rightNumeral` | integer (0–10) | digit-stitched | for numeral-compare |
| `round.largerBasketLabel` / `round.leastBasketLabel` / `round.mostBasketLabel` | enum | expand-per-value | "A", "B", "C", or basket name |
| `round.objectName` / `round.objectAName` / `round.objectBName` | enum | expand-per-value | bench objects: feather, glow-stone, rock, etc. |
| `round.objectNamePlural` | enum | derived | |
| `round.tagWord` | enum | expand-per-value | attribute words: "light", "smooth", "shiny", etc. |
| `round.attributesPlaced` | integer (2–5) | digit-stitched | |
| `round.heavierObjectName` / `round.longerObjectName` | enum | expand-per-value | |

### Round-scope slots — scribes / numerals

| Slot | Type | Strategy | Notes |
|---|---|---|---|
| `round.numeralName` | enum | expand-per-value | "zero", "one", ... "twenty" |
| `round.expectedNumeral` | integer (0–20) | digit-stitched | |
| `round.expectedNumeralName` | enum | derived | |
| `round.recognizedNumeralName` | enum | expand-per-value | what the classifier read |
| `round.firstStrokeLabel` | enum | expand-per-value | "the 1", "the dot", "the top" |

### Round-scope slots — fluency

| Slot | Type | Strategy | Notes |
|---|---|---|---|
| `round.factDisplay` | enum | expand-per-value | "2 plus 1", "3 take away 1", etc. — 42 entries (per K.OA.5 instance keys) |
| `round.expectedAnswer` | integer (0–9) | digit-stitched | |
| `round.correctCount` | integer (0–8) | digit-stitched | per round of 8 |
| `round.maxCombo` | integer (1–10) | digit-stitched | |

---

## Resolution rules

At speak-time, the SlotResolver:

1. Receives a cue + the active round's context.
2. For each `{slot}` in the cue text:
   - Resolve the slot identifier using the namespace prefix.
   - Look up the value in the running state.
   - Apply the `spokenAs` transformation if applicable.
   - For `expand-per-value` slots, look up the pre-rendered `.m4a` file.
   - For `runtime-only` slots, either use live TTS (out of scope for launch) or substitute a written display.
   - For `digit-stitched` slots, concatenate the audio fragments.

### Example resolution

Cue: `"How many {creature_plural} altogether?"`

Active round: K.OA.2 in Storyteller's Pond, `creatureSpecies` = "duck"

Resolution:
1. `creature_plural` → vocabulary lookup → `round.creatureSpeciesPlural` (alias) → derived from `round.creatureSpecies` ("duck") → "ducks"
2. Strategy = `expand-per-value` → pre-rendered file = `howmany-ducks.m4a` (or full template: `add-to-question-ducks.m4a` depending on canonicalization granularity)
3. Audio plays.

### Aliases

Legacy slot names from current narration JSONs may differ slightly from canonical identifiers:

| Legacy | Canonical |
|---|---|
| `N` | `round.finalCount` or `round.target` depending on context |
| `Buddy_name` | `kid.buddyName` |
| `creature` | `round.creatureSpecies` |
| `creature_plural` | `round.creatureSpeciesPlural` |
| `startN` | `round.startN` |
| `changeN` | `round.changeN` |
| `resultN` | `round.resultN` |
| `A` | `round.partA` |
| `B` | `round.partB` |

The activity-narration JSONs declare aliases via `slotSource`:

```jsonc
{
  "text": "How many {creature_plural} altogether?",
  "slotSource": { "creature_plural": "round.creatureSpeciesPlural" }
}
```

The harvester uses `slotSource` to map back to the canonical identifier. If `slotSource` is absent, the slot name is assumed to be canonical (no alias).

---

## Cost estimate (TTS rendering)

The number of `.m4a` files generated depends on slot strategies:

For a cue with one `expand-per-value` slot with N values: **N files**.
For a cue with two such slots, M and N values: **M × N files**.

Combinatorial blowup is the risk. The catalog above is designed to **avoid combinatorial cues** at the activity level. Two slot examples in the same cue typically combine an enum + an integer (e.g., `"{N} {creature_plural}"`):

- `round.creatureSpeciesPlural` (8 values) × `round.finalCount` (~10 common values, but digit-stitched) → 8 × 1 = **8 files** (digit-stitch handles the numeral separately at runtime).

This keeps the rendering count tractable. Estimated **800–1,500 .m4a files** for full K coverage post-canonicalization, well within ElevenLabs Creator-tier monthly budgets.

---

## Slot vocabulary completeness check

The harvester (TTS Stage 1) reports cues with slot placeholders. A simple cross-check script verifies every slot in the harvest is defined in `slot-vocabulary/{locale}.json`:

```bash
# CI guardrail (planned)
node tools/tts/check-slots.mjs
# Walks harvest-manifest.json's cues
# For each slotPlaceholder, verifies the canonical slot ID is in the vocabulary
# Exit 1 if any missing
```

This prevents the situation "we shipped a narration line with a slot the vocabulary didn't know about, and the runtime crashes at speak time."

---

## Future: canonicalization (Stage 2)

The TTS Canonicalizer's job (with this spec as input):

1. Read every cue from the harvester's manifest.
2. For each `{slot}` placeholder, look up its strategy.
3. Generate the per-value expansion:
   - `expand-per-value` → render one `.m4a` per value
   - `digit-stitched` → use the shared `numerals/{0-99}.m4a` library
   - `runtime-only` → mark for runtime substitution
   - `concatenated` → render fragments per the slot's combination plan
4. Save each rendered file at the asset path.
5. Write a `narration-manifest.json` that the runtime consumes to look up the right `.m4a` for any `(cueId, slotValues)` tuple.

This is Stage 2 of the pipeline. Spec'd separately when we get there.

---

## Open Questions

- **Universal numeral library** — Should `digit-stitched` use one shared `.m4a` per numeral (0–99), or per-narrator-voice? Suggest **per-narrator-voice** for tonal consistency, accepting the storage cost (~400KB per voice × 100 numerals = ~40MB per region).
- **Plural form authoring** — `derivedFrom` with a map handles English. For inflected languages (Spanish gendered plurals, Russian numeric cases) the vocabulary needs richer rules. Defer until 2nd language ships.
- **Slot defaults** — when a slot is requested but not in the active round's context, should the runtime substitute a default ("a creature") or fail loudly? Suggest **fail loudly in debug, generic fallback in release**.
- **Locale-specific slot vocabularies** — when a new locale is added, do all slot identifiers stay the same? Yes — identifiers are stable; only `values` and pluralization rules change. The canonical identifier `round.creatureSpeciesPlural` exists in every locale; English's "ducks" becomes Spanish's "patos" in `data/slot-vocabulary/es-MX.json`.
- **Naming convention for user-entered slots** — `kid.buddyName` capitalization assumes Title-cased rendering. For locales with different capitalization, the runtime applies locale-appropriate casing.
- **Slot validation in CI** — the planned `check-slots.mjs` should run on every PR that touches narration. Lock in pre-launch.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-31 | Initial draft — namespace hierarchy (kid/round/activity/system), vocabulary file structure, TTS expansion strategies (expand-per-value / runtime-only / digit-stitched / concatenated), full K slot catalog with type/strategy/notes, resolution rules with example, alias mapping for legacy slot names, cost estimate showing combinatorial avoidance, canonicalization preview for Stage 2 | |
