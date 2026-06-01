# Content Templates

> The schema for activity content that gets templated and slot-filled at round-time. Covers **story templates** (narrated word problems), **problem templates** (math problems with declared structure), and references the **lesson templates** in `micro-lessons.md`.

References: `specs/shared/micro-lessons.md` (lesson templates), `specs/shared/bar-model.md` (problem visualizations), `specs/shared/adaptive-scaffolding.md` (concept declarations).

---

## Purpose

Many activities present rounds that follow a **template** — a structural shape with slot-filled variables. Templating lets us:

- Author once, render many rounds with varied numbers/creatures/contexts.
- Localize cleanly (slot fills work in any language).
- Validate content against schemas at load time.
- Reuse the same template across grade-appropriate rounds (a put-together template works for K with N ≤ 10 and for 1st with N ≤ 20).

---

## Three Template Kinds

| Kind | Purpose | Example activity |
|---|---|---|
| **Story template** | Narrated word problem with scripted visual flow | Storyteller's Pond, Wundle Tales, Hero Missions |
| **Problem template** | Math problem with declared structure (no story) | Tenforge, Tens Parade challenge, Casebook arithmetic |
| **Lesson template** | I-Show / We-Try / You-Do structure (see `micro-lessons.md`) | All MicroLessons |

This doc covers the first two in detail. Lesson templates are specified in `micro-lessons.md`.

---

## Common Header Fields

All template kinds share these fields:

```jsonc
{
  "id": "add-to-ducks-1",
  "kind": "story",                     // story | problem | lesson
  "version": 1,                        // schema version
  "status": "draft|reviewed|live",
  "concepts": ["K.OA.2", "K.OA.1"],    // concepts this template touches
  "primaryConcept": "K.OA.2",          // which concept's mastery this primarily updates
  "regionScope": ["sanctuary"],        // regions this template appears in (most are single-region)
  "gradeScope": ["K"],                 // grades this template targets
  "difficulty": "concrete|pictorial|abstract",  // optional CPA hint
  "telemetryId": "pond.add-to-ducks-1" // canonical id for analytics
}
```

---

## Story Template Schema

A story template defines a **narrated word problem with scripted visual flow**.

```jsonc
{
  // Common header fields (above)
  "id": "add-to-ducks-1",
  "kind": "story",
  "primaryConcept": "K.OA.2",
  "gradeScope": ["K"],

  // Story-specific
  "subMode": "add-to",                 // matches activity sub-mode key
  "creature": "duck",                  // slot-fill key for visuals
  "narrationTemplate": "{startN} ducks are in the pond. {changeN} more swim in. How many altogether?",
  "narrationSlots": {
    "startN": 5,
    "changeN": 2
  },
  "expectedAnswer": 7,                 // computed from the math; redundant but validated
  "answerFormat": "numeral",           // numeral | tile-select | multi-digit-cell
  "tileOptions": null,                 // if answerFormat = tile-select, list of options
  
  "visualSteps": [
    { "at": "0s", "action": "spawn",      "count": 5, "position": "pond-center" },
    { "at": "3s", "action": "spawn-sequence", "count": 2, "interval": "1s", "from": "off-screen-left", "to": "pond-edge" }
  ],
  "barModel": {
    "type": "add-to",
    "parts": [5, 2],
    "result": 7
  },
  
  "narratorVoice": "sanctuary-warm-naturalist",  // optional override
  "narratorCharacter": "storyteller-turtle"      // optional; for activities with visible narrator
}
```

### Slot-fill language

The `narrationTemplate` uses **curly-brace placeholders** for slot fills:

- `{startN}`, `{changeN}`, `{resultN}` — numeric values from `narrationSlots`
- `{creature_plural}`, `{creature_singular}` — language-aware noun forms derived from `creature`
- `{leave_verb}`, `{arrive_verb}` — creature-appropriate motion verbs (ducks swim, dragonflies fly)
- Custom slots can be defined per template

The slot-fill engine resolves these against:
1. `narrationSlots` for direct numeric values.
2. A **localization dictionary** for noun forms and verbs (`creature_plural[duck] = "ducks"`).
3. Computed slots from the activity's runtime state.

### Visual steps

`visualSteps` defines the **scripted animation** that plays alongside the narration:

```jsonc
{
  "at": "3s",                      // timestamp relative to story start
  "action": "spawn-sequence",      // see Action Library below
  "count": 2,                      // how many sprites
  "interval": "1s",                // delay between each in a sequence
  "from": "off-screen-left",       // start position
  "to": "pond-edge",               // end position
  "sprite": "duck",                // optional; defaults to story's creature
  "easing": "ease-out"             // optional
}
```

### Action Library (visual step actions)

| Action | Effect |
|---|---|
| `spawn` | Sprites appear at a position |
| `spawn-sequence` | Sprites appear one at a time with interval |
| `move` | Sprites move from one position to another |
| `despawn` | Sprites leave (animated exit) |
| `group-merge` | Two groups visually combine |
| `group-split` | One group visually divides |
| `highlight` | Sprites or zones pulse to draw attention |
| `pause` | No action; wait for narration to catch up |

Additional actions can be added per activity; document additions in the activity spec.

### Validation rules

- `expectedAnswer` must equal the math result of the slot values (e.g., for `add-to`: `startN + changeN`).
- All slot placeholders in `narrationTemplate` must resolve from `narrationSlots`, the localization dictionary, or runtime state.
- `visualSteps` timestamps must monotonically increase.
- Total narration duration must fit within the activity's round time budget (typically ≤ 30 s for K word problems).

---

## Problem Template Schema

A problem template defines a **math problem without a story wrapper** — used for activities like Tenforge, Crystal Bundler, Casebook arithmetic.

```jsonc
{
  // Common header fields
  "id": "make-ten-from-8",
  "kind": "problem",
  "primaryConcept": "K.OA.4",
  "gradeScope": ["K"],

  // Problem-specific
  "subMode": "make-ten",                // matches activity sub-mode key
  "problemType": "make-target",         // categorization
  "given": { "startCount": 8, "target": 10 },
  "expectedAnswer": 2,                  // what the kid needs to produce
  "answerFormat": "numeral",
  
  "prompt": "We have {startCount}. Make {target}.",
  "promptSlots": {
    "startCount": 8,
    "target": 10
  },
  
  "scaffolding": {
    "barModel": null,                   // not all problems use bar models
    "tenFrameVisualization": true        // activity-specific scaffolding flag
  }
}
```

Problem templates are simpler than story templates — they're about the math, not the narrative.

---

## Lesson Templates

Lesson templates live in `specs/lessons/*.md` and follow the structure documented in `micro-lessons.md`. They share the common header fields above:

```jsonc
{
  "id": "lesson-k-cc-4a-one-to-one",
  "kind": "lesson",
  "concepts": ["K.CC.4a"],
  "primaryConcept": "K.CC.4a",
  "gradeScope": ["K"],
  "regionScope": ["sanctuary"],
  
  // Lesson-specific fields per micro-lessons.md
  "phases": {
    "iShow": { /* ... */ },
    "weTry": { /* ... */ },
    "youDo": { /* ... */ }
  }
}
```

---

## Localization

Templates are **language-ready by design**:

- All narration is slot-filled from a localization dictionary.
- Noun forms (`creature_plural`), verbs, and idiomatic phrasings come from per-language tables.
- Numeric slots (`{startN}`) are language-agnostic.
- Number names ("twelve") come from the language's number-name table.

Launch language: English. The schema supports adding additional languages later without re-authoring templates.

---

## Authoring Workflow

Templates are authored as **JSON or YAML files** in `data/templates/`:

```
data/templates/
├── stories/
│   ├── add-to-ducks-1.json
│   ├── add-to-ducks-2.json
│   ├── take-from-frogs-1.json
│   └── ...
├── problems/
│   ├── make-ten-from-8.json
│   ├── make-ten-from-7.json
│   └── ...
└── lessons/
    ├── lesson-k-cc-4a-one-to-one.json
    └── ...
```

(Markdown lesson files in `specs/lessons/` are the **design source**; the JSON files in `data/templates/lessons/` are the **runtime form** generated from those specs. The pipeline TBD.)

### Template authoring conventions

- **One template per file.** No multi-template files.
- **ID equals filename stem.** `add-to-ducks-1.json` → `id: "add-to-ducks-1"`.
- **IDs are kebab-case.** Activity prefix optional but encouraged for clarity (`pond-add-to-ducks-1`).
- **Templates are append-only after `status: live`.** Changes go to new template IDs (e.g., `add-to-ducks-1-v2`) to preserve telemetry continuity.

---

## Template Selection by the Activity

Activities select templates at round-time based on:

- **Sub-mode** of the current round
- **CPA layer** of the kid for the round's concept
- **Number range** appropriate to the layer (e.g., Concrete may use lower number ranges)
- **Recency** (avoid showing the same template back-to-back)
- **Mastery state** (a kid who's mastered some templates may not see them again)

The selection logic is part of the activity's session-design code, not the template itself.

---

## Validation at Load Time

A **content validation pipeline** runs at template load:

1. **Schema conformance** — fields are present, types are correct.
2. **Math validity** — `expectedAnswer` matches the computed math.
3. **Slot resolution** — all `{placeholders}` resolve.
4. **Concept reference** — `concepts` reference valid registry entries.
5. **Asset references** — `creature`, `sprite`, etc. resolve to known assets.

Templates that fail validation are logged and excluded from rotation; the activity uses fallback templates (or surfaces a warning to the dashboard).

---

## Examples

### Story template — Storyteller's Pond add-to round
See the schema above. Full file would live at `data/templates/stories/add-to-ducks-1.json`.

### Problem template — Tenforge make-a-ten round
```jsonc
{
  "id": "tenforge-make-ten-from-8",
  "kind": "problem",
  "concepts": ["1.OA.6"],
  "primaryConcept": "1.OA.6",
  "gradeScope": ["1"],
  "regionScope": ["wundletown"],
  "subMode": "make-a-ten-spell",
  "problemType": "decompose-to-ten",
  "given": { "sumA": 8, "sumB": 5 },
  "expectedAnswer": 13,
  "answerFormat": "numeral",
  "prompt": "{sumA} + {sumB} = ?",
  "promptSlots": { "sumA": 8, "sumB": 5 },
  "scaffolding": {
    "spellAnimation": "make-a-ten",
    "moteVisualization": true
  }
}
```

### Lesson template — see micro-lessons.md for the full lesson schema

---

## Open Questions

- **Markdown spec → JSON template pipeline** — currently lesson specs live as markdown in `specs/lessons/`; the runtime form (JSON in `data/templates/lessons/`) would be generated. How does the generation work? Defer to the D phase when we codify the data model and tooling.
- **Story template count per activity** — Storyteller's Pond proposes ~22 templates at launch (~5 per sub-mode + challenge). What's the right count for 1st-grade Wundle Tales and 2nd-grade Hero Missions? Defer to content authoring estimation.
- **Localization timeline** — launch is English-only. The schema supports localization but the dictionary tables aren't authored yet. Defer.
- **Template versioning** — `version: 1` field but no migration story. If schema changes between launch and v1.1, how do live templates get updated? Defer to v1.1 planning.
- **Per-template difficulty hints vs activity-managed CPA** — `difficulty` field is optional. Should activities respect it, or always compute the right layer from kid state? Suggest activity-managed at launch; template hints are advisory only.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — formalizes the templating system observed in Storyteller's Pond (story templates) and previewed for problem templates (Tenforge, Casebook, etc.) | |
