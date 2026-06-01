# Activity Spec — Scribe's Tower

> The K activity that introduces **reading and writing numerals 0–20** (K.CC.3). The canonical home of the **number-writing modes** in K — heavy use of Mode 1 (Trace) with Mode 2 (Prompted free-write) emerging as the kid grows. Each numeral has a small character that comes to life when written correctly.

References: `specs/shared/stylus-mechanics.md`, `specs/shared/number-writing-modes.md`, `specs/shared/math-notebook.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/reward-economy.md`, `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activity-spec-template.md`.

---

## Header

| Field | Value |
|---|---|
| Activity name | Scribe's Tower |
| Activity slug | `scribes-tower` |
| Region | Sanctuary |
| Grade | K |
| Standards | K.CC.3 |
| Status | Draft |
| Last updated | 2026-05-30 |

---

## Setting & Tone

- **Scene** — A small round writing tower at the edge of the Sanctuary. Inside: shelves lined with magical scrolls, quill pens, ink wells of glowing colors, and **numerals floating in the air** like little airborne characters (each numeral has a personality — the "1" walks tall and proud, the "2" swims, the "3" sprouts tiny wings, the "5" is bouncy, etc.). A **central writing desk** dominates the lower-center, where the kid writes.
- **Atmosphere** — Warm late-morning sunlight through stained-glass windows; music bed is the Sanctuary string-and-flute palette with a soft "studious quill scratching" texture layered subtly. Palette anchors: parchment-cream, ink-purple, gold-leaf, soft green.
- **Buddy presence** — Per `k-activity-patterns.md`: Buddy at lower-left on a small reading cushion, occasionally peeking at the writing desk. Reacts to each correctly-written numeral with a small celebratory hop.
- **Narrator** — Sanctuary warm naturalist.

---

## Standards Coverage

| Standard | What the kid does | Telemetry event | Mastery threshold |
|---|---|---|---|
| **K.CC.3** (read and write 0–20) | **Writing**: traces numerals (Mode 1) and writes them from prompts (Mode 2). **Reading**: matches a displayed numeral to one of 2–3 quantity options. | `scribe.numeral_traced` (payload: `numeral`, `score`, `mode: "trace"`), `scribe.numeral_written` (payload: `numeral`, `confidence`, `mode: "prompted"`), `scribe.numeral_matched` (payload: `displayedNumeral`, `selectedQuantity`, `correct`) | 5/3/3 standard, **per numeral** (each of 0–20 has its own mastery state) |

### Per-numeral mastery

Unlike most K activities (where mastery is concept-wide), Scribe's Tower tracks mastery **per numeral** (21 distinct mastery states: 0, 1, 2, …, 20). The kid earns a stamp for each numeral mastered. K.CC.3's overall standard mastery rolls up when all 21 numerals are mastered.

---

## Concepts: Introduced vs Exercised

| Concept | Role | Lesson | Notes |
|---|---|---|---|
| **K.CC.3** (read and write 0–20) — granularity: **per-instance**, instanceKeys: `["0", "1", ..., "20"]` | Introduces | `specs/lessons/k-cc-3-write-numerals.md` | First lesson covers **writing one numeral** (the "5") as a worked example of the trace mechanic. The other 20 numerals follow the same procedure; the lesson teaches *how*, the activity provides the practice. **Per-instance mastery** (one state per numeral) per `adaptive-scaffolding.md`'s Mastery Granularity rule. |

### Registry impact

- `K.CC.3.introducedBy = scribes-tower`

---

## Sub-Modes

### Sub-mode: `trace-numeral` (default)

- **Standards targeted** — K.CC.3 (writing)
- **What the kid does** — A dotted/ghost outline of a numeral appears on the writing desk surface, with **stroke order indicators** (tiny "1, 2, 3" badges marking the start of each sub-stroke). The kid traces the numeral with their stylus. Number-writing **Mode 1** (Trace) — geometric scoring, no ML.
- **Pass condition** — Trace score ≥ 80% within the tolerance band (per `number-writing-modes.md` Mode 1 spec).
- **Visual reward**: on pass, the numeral **comes to life** — the "1" walks across the desk; the "5" bounces; the "10" splits visually into a "1" and a "0" then re-joins. The numeral character then climbs up into the air and joins the other floating numerals on the shelves.
- **Fail behavior** — Retry up to standard threshold; on persistent fail, drop to **Assisted Trace** (path glows wider, magnet effect) per `number-writing-modes.md`.

### Sub-mode: `write-from-cue` (Mode 2 prompted free-write)

Two variants that rotate within this sub-mode:

#### Variant: `quantity-cue`
- **Standards targeted** — K.CC.3 (writing) + reinforces K.CC.4b (cardinality, by association)
- **What the kid does** — The desk shows a quantity (e.g., 7 sparkling fireflies in a loose cluster). The narrator says: "Write the number." Kid free-writes the matching numeral. Number-writing **Mode 2**.
- **Pass condition** — Digit classifier confidence ≥ 0.70 AND matches expected numeral.
- **Fail behavior** — Per Mode 2 fallback chain: 2 fails → drop to Mode 1 Trace for the same numeral.

#### Variant: `audio-cue`
- **Standards targeted** — K.CC.3 (writing)
- **What the kid does** — Desk is empty. Narrator says: "Write *twelve*." Kid free-writes. Number-writing **Mode 2**.
- **Pass condition** — Same as `quantity-cue`.
- **Fail behavior** — Same fallback chain.

### Sub-mode: `match-numeral` (reading)

- **Standards targeted** — K.CC.3 (reading)
- **What the kid does** — A numeral appears prominently on the desk (e.g., "8"). Below it, 2–3 quantity options appear (e.g., 6 dots, 8 dots, 10 dots). Kid taps the matching quantity.
- **Pass condition** — Correct tap.
- **Fail behavior** — Wrong tap → soft "no," correct option glows for a moment. After 2 wrong taps, narrator: "Eight — count the dots: 1, 2, 3, 4, 5, 6, 7, 8." Highlight the correct option.

### Sub-mode: `audio-only-teens` *(challenge variant)*

- **Standards targeted** — K.CC.3 at the harder end of the range
- **What the kid does** — Same as `audio-cue` variant but **only teen numbers** (11–20). Audio-only prompt, no visible quantity.
- **Pass condition** — Same Mode 2 threshold.
- **Reward bump** — Challenge chest with rare ink-color collectibles guaranteed.

---

## Visual Layout

```
+--------------------------------------------------------+
| [exit]                              [coins: 12]        |
|                                                        |
|   <Scribe's Tower interior — shelves of floating       |
|    numerals, stained-glass light>                     |
|                                                        |
|     🔢   🔢   🔢                                       |
|     <floating numeral characters on shelves>          |
|                                                        |
|                                                        |
|     +----------------------+                          |
|     |   [writing desk]     |   <central writing       |
|     |                      |    surface; trace        |
|     |    [ghost numeral    |    target appears here>  |
|     |     or write zone]   |                          |
|     +----------------------+                          |
|                                                        |
|             [stamp poster preview: 5 of 21]           |
|                                                        |
|  [Buddy reading]                       [notebook >]    |
|                                                        |
|                  [ done? ]                             |
+--------------------------------------------------------+
```

- **Persistent scene anchors** — tower interior, shelves with previously-mastered numeral characters visible, Buddy on cushion.
- **Interactive elements**:
  - **Writing desk** — the active surface. In `trace-numeral`: ghost numeral. In `write-from-cue`: empty zone with optional visible quantity above. In `match-numeral`: numeral + tap options.
  - **Stamp poster** — visible in the corner of the tower; updates when a numeral is mastered.
- **Math notebook tab** — collapsed by default. **The writing desk IS the recognition zone** for this activity; the notebook is rarely needed as a side scratch surface. Optional notebook bonus still applies.
- **Floating shelf numerals** — non-interactive decoration; show the kid's progress (numerals mastered float on the shelves and animate idly).

---

## State Machine

```
[idle/intro] → narrator opens with the round's prompt
   ↓
[setup] → desk configured per sub-mode (ghost numeral, quantity cue, audio cue, or read prompt)
   ↓
[active] → kid traces, writes, or taps depending on sub-mode
   ↓
[evaluating] → check trace score / classifier output / tap target
   ↓
[round_passed]                       [round_failed]
   ↓                                    ↓
[reward + numeral comes to life]    [warm narrator + Mode fallback or demonstration]
   ↓                                    ↓
[stamp update if numeral mastered]  [retry per Mode fallback chain]
   ↓
[next round queued]
```

**Exit conditions** — standard per K patterns.

---

## Stylus Interactions

| Mechanic | Where used | Local overrides |
|---|---|---|
| **Trace** | `trace-numeral` sub-mode (Mode 1 number-writing) | Standard tolerance band (12 pt Pencil / 18 pt touch). Stroke order indicators visible at Concrete and Pictorial layers; hidden at Abstract. |
| **Free-Write** | `write-from-cue` sub-mode (Mode 2 number-writing) | Standard. End-of-input timeout 1.2 s. Classifier confidence threshold 0.70. |
| **Tap-Pick** (selection semantic) | `match-numeral` sub-mode (reading) | Standard. Tap on a non-target quantity is a soft no-op per the selection semantic. |

---

## Number-Writing Modes

This activity is the **canonical exerciser** of the number-writing modes spec. Sub-modes map to modes:

| Sub-mode | Mode used |
|---|---|
| `trace-numeral` | **Mode 1 — Trace** |
| `write-from-cue` (both variants) | **Mode 2 — Prompted free-write** |
| `match-numeral` | None (reading, not writing) |
| `audio-only-teens` (challenge) | **Mode 2 — Prompted free-write** (audio-only prompt) |

**Mode 3 — Blind free-write** is **not used** in Scribe's Tower. There's no problem-solving here; the kid is always transcribing a known quantity into a numeral form. Mode 3 lives in activities where the kid must *compute* the answer (e.g., 1st-grade Tenforge's later You-Do rounds).

**Per-grade mode mix for Scribe's Tower at K**: ~70% Mode 1 trace, ~30% Mode 2 prompted free-write — matches the grade default in `number-writing-modes.md`.

---

## Audio Cues

> **Runtime source**: narration cues live in [`content/strings/en-US/activities/scribes-tower.json`](../../../content/strings/en-US/activities/scribes-tower.json). The prose below is the design-time reference; the JSON is the authoritative source the TTS pipeline and runtime consume.

### Narrator lines (Sanctuary warm naturalist)

#### `trace-numeral`
- **Round start**: "Let's write the number {five}."
- **Mid-progress (kid mid-trace)**: (no narration; the trace is doing the work)
- **Round pass**: "{Five}! Look at that — well done." *(numeral comes to life)*
- **Round fail (low score)**: "Almost. Try again — follow the dotted line."
- **3rd consecutive trace fail**: "Let me help — the line will glow brighter." *(Assisted Trace activates)*

#### `write-from-cue` (quantity variant)
- **Round start**: "How many fireflies? Write the number." *(Q fireflies sparkle on the desk)*
- **Round pass (correct)**: "{Seven}! Yes — there were {seven} fireflies."
- **Round pass (low-confidence)**: "I think I see a {7}. Is that right?" *(kid confirms; if yes, pass; if no, retry)*
- **Round fail (wrong digit, high confidence)**: "That's a {6}. There were {7} fireflies. Try again."

#### `write-from-cue` (audio variant)
- **Round start**: "Write *twelve*."
- **Round pass**: "{Twelve} — perfect."
- **Round fail**: same as quantity variant.

#### `match-numeral`
- **Round start**: "This is {eight}. Tap the picture with {eight}."
- **Round pass**: "{Eight} — yes."
- **Round fail (wrong tap)**: "Eight — count the dots: 1, 2, 3, 4, 5, 6, 7, 8." *(correct option glows)*

#### `audio-only-teens` (challenge)
- **Round start**: "Write *fourteen* — no peeking at fireflies this time."
- **Round pass**: "{Fourteen}! Big number."

### SFX

| Event | SFX |
|---|---|
| Pen-on-paper trace | Subtle quill-scratching sound layered with the music bed |
| Numeral comes to life | Sparkle + numeral-specific cue (footsteps for "1", swim splash for "2", etc.) |
| Numeral climbs to shelf | Soft "whoosh" up |
| Stamp earned | Brief "stamp" sound + chime |
| Mode fallback (trace → assisted, free-write → trace) | Gentle "switch" cue (not a failure sound) |
| Round pass | Sanctuary chime stinger |
| Round fail | Soft sad-but-warm chord |

### Music

- Sanctuary scholastic bed: gentle strings + harp + soft brass + the quill-scratch texture, ~75 BPM (slower than other K activities — this is a contemplative activity).
- Slight intensity bump when a numeral comes to life.

---

## Scaffolding Triggers

Uses `ScaffoldQuery` per round, including `firstEncounterLesson` for K.CC.3 routing.

| Trigger | Response |
|---|---|
| **5 s of no stroke after trace setup** | Stroke-order indicators pulse more brightly. |
| **10 s of no stroke** | Narrator: "Start at the {1} — follow the dotted line." (or appropriate first-stroke prompt) |
| **Trace score < 50% over 3 attempts** | Drop to **Assisted Trace** (per `number-writing-modes.md`). |
| **Free-write low confidence 2× in a row** | Drop to **Mode 1 Trace** for the same numeral (per Mode 2 fallback chain). |
| **Tile fallback used** | Logged for dashboard; lesson advances but flags numeral as "tile-needed" for the teacher. |
| **2 consecutive round failures** | Apply the **staggered demotion** rule from `adaptive-scaffolding.md`: demote CPA layer first. If already at Concrete, demote sub-mode (`audio-only-teens` → `write-from-cue audio` → `write-from-cue quantity` → `trace-numeral` → `match-numeral`). |

---

## CPA Progression

Scribe's Tower's CPA is about **how much support the kid gets during writing**.

| Layer | What it looks like |
|---|---|
| **Concrete** | In `trace-numeral`: bright dotted outline + **stroke order indicators** (small "1, 2, 3" badges marking sub-stroke starts) + the numeral name spelled out above the desk. In `write-from-cue`: visible quantity + audio cue + the numeral name spelled out. |
| **Pictorial** | Stroke order indicators removed (kid knows where strokes start). In `write-from-cue`: visible quantity OR audio cue (one removed). |
| **Abstract** | Trace path becomes faint (Mode 1 still works, just less visual). In `write-from-cue`: minimal cues. |

- **Default starting layer (K, fresh kid)** — Concrete.
- **Promotion conditions** — 3 consecutive passes at the current layer **per numeral** (Scribe's Tower's per-numeral mastery means CPA is also per-numeral).
- **Demotion conditions** — 2 consecutive failures at the current layer per numeral.

### Per-numeral CPA state

Because mastery is per numeral, the CPA layer is also tracked per numeral. The kid may be at Abstract for "1" and "2" (easy numerals they've practiced often) while still at Concrete for "8" or "13" (newer or harder). This is intentional — the activity respects that some numerals are easier than others.

---

## Reward Emissions

| Event | Trigger | Reward (per `reward-economy.md`) |
|---|---|---|
| `round.passed` | Round passes | +2 coins |
| `round.notebook_bonus` | Notebook had ≥3 strokes during round | +1 coin (rare here — the writing desk substitutes) |
| `streak.session_3` / `_5` / `_10` | Standard | Per shared spec |
| `milestone.problems_25` / `_100` | Lifetime in this activity | Per shared spec |
| `mastery.standard_practicing` / `_mastered` | Mastery rolls up when all 21 numerals are mastered | Per shared spec |
| **`scribe.numeral_mastered`** | A single numeral reaches mastery (5/3/3 per-numeral threshold) | **Stamp added to the Hub poster**; small celebratory animation in the tower |
| `challenge.completed` | `audio-only-teens` round passes | Challenge chest (rare ink-color collectible guaranteed) |

### Activity-specific collectibles
- **Numeral Stamps** — one per mastered numeral (21 stamps for 0–20). Displayed on a **stamp poster** in the Hub. Each stamp is a tiny illustrated character matching the numeral's personality.
- **Ink Colors** — earned through play and challenge completion. The kid can change their writing ink color (cosmetic, doesn't affect recognition). ~8 ink colors at launch.
- Complete the stamp set (all 21 numerals) for a Hub trophy: the **Scribe's Atlas** (a fancy bound book on the kid's Hub desk).

---

## Telemetry Events

(Beyond shared `scaffold.*`, `economy.*`, `lesson.*` events. Mode-specific events delegate to `number-writing-modes.md`.)

| Event | Payload |
|---|---|
| `scribe.round_started` | `subMode`, `targetNumeral`, `presentationLayer`, `mode` (Mode 1/2) |
| `scribe.numeral_traced` | `numeral`, `score`, `attempts`, `assistedTraceUsed: Bool` |
| `scribe.numeral_written` | `numeral`, `confidence`, `attempts`, `modeFallbackUsed: Bool` |
| `scribe.numeral_matched` | `displayedNumeral`, `selectedQuantity`, `correct`, `latencyMs` |
| `scribe.numeral_mastered` | `numeral`, `attemptsToMastery`, `daysToMastery` |
| `scribe.tile_fallback_used` | `numeral`, `attemptsBefore` (flagged for teacher dashboard) |
| `scribe.ink_color_changed` | `newColor` |

---

## Challenge Variant

**Audio-Only Teens** — Mode 2 prompted free-write with audio cue only, limited to 11–20.

- **What changes** — No visible quantity. Audio prompt only. Number range 11–20 (the harder end of K.CC.3).
- **Entry point** — "Master Scribe!" banner appears on Scribe's Tower's tile in the Sanctuary 1× per day at launch (tunes post-launch).
- **Reward bump** — Challenge chest with rare ink-color collectible guaranteed.

---

## Edge Cases & Error Handling

- **Kid traces in wrong stroke order** — at Concrete layer, the system gently steers (next-stroke indicator pulses; trace from a wrong start doesn't count as on-path). At Abstract layer, stroke order isn't enforced beyond the geometric scoring — if the kid's strokes happen to land on the path regardless of order, they pass. (Strict stroke order enforcement is an Open Question.)
- **Kid writes a numeral that the classifier confidently reads as a different number** (e.g., writes "7" when the prompt was "1") — that's a kid error, not a recognition error. Treated per the normal fail flow with the warm narrator reveal.
- **Kid writes the right number but very sloppily** — low confidence prompt fires ("I think I see a 7..."); kid confirms; round passes.
- **Multi-digit numbers (11–20)** — written via the **side-by-side single-digit cell strategy** from `math-notebook.md`. Two cells appear for teens: tens-digit cell on the left (always "1" for 11–19, "2" for 20), ones-digit cell on the right. Each cell runs single-digit recognition.
- **Numeral characters animating on the shelf** — must be subtle enough not to distract the kid mid-trace. Confirm in playtest; if distracting, pause shelf animations during active trace.
- **Stamp poster prominence** — small enough not to compete with the writing desk, big enough that the kid sees their progress. Suggest corner placement at ~10% of screen area.
- **Stylus disconnect mid-trace** — current trace cancels; ghost outline remains; kid resumes on reconnect.
- **App backgrounded mid-trace** — pause and persist; restore stroke-in-progress within 5 minutes.
- **Audio muted** — `audio-cue` variant is unplayable without audio. The activity should detect mute state and rotate to `quantity-cue` variants only, with a small "audio is off" indicator (audio = on by default for K).

---

## Open Questions

- **Lesson scope: one numeral or several?** — K.CC.3's lesson is proposed to cover one numeral ("5") as the worked example of the trace procedure + numeral-quantity correspondence. The other 20 numerals are practiced without further lessons. Alternative: cover 2 numerals (e.g., "1" and "5") to show that the procedure generalizes. Suggest 1 at launch; expand if playtest shows kids confused by the jump to unfamiliar numerals.
- **Per-numeral mastery vs. concept-wide mastery** — current spec: per-numeral (21 mastery states). Pros: granular dashboard, kids see specific numerals as "done." Cons: more complex data model; concept-wide mastery only fires when all 21 are mastered, which is a long road. Confirm this trade-off is right for the dashboard.
- **Strict stroke order at Abstract layer** — current spec: not enforced at Abstract (geometric scoring only). Alternative: always enforce stroke order. Strict enforcement helps with handwriting habits but may frustrate. Defer to playtest.
- **Teen numerals 11–20 in trace mode** — does each teen numeral get its own dotted target, or is the kid expected to write two single digits side-by-side from the start? Suggest trace mode shows teens as **one combined ghost** (the kid traces "12" as a single shape) for visual continuity with the numeral character. Free-write modes use the side-by-side cell strategy.
- **Numeral personalities** — 21 distinct character designs is a lot of art. Confirm feasibility with art direction; consider that some numerals (0, 7, 11) might have simpler personalities than others.
- **Ink colors as cosmetic reward** — 8 at launch. Confirm 8 is enough variety to feel like a collection.

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical across phases. **Stylus input** flows through `StylusInputProvider` so trace mode works in both phases without modification.


```
ScribesTowerView
├── TowerBackgroundLayer (parallax shelves, stained-glass light)
├── BuddyView (idle, reading-cushion behaviors)
├── ShelfView (floating numeral characters; one per mastered numeral)
├── WritingDeskView (the central interactive surface)
│    ├── TraceTargetView (ghost numeral with stroke order indicators) — for trace-numeral mode
│    ├── WriteZoneView (recognition zone) — for write-from-cue mode
│    └── MatchOptionsView (numeral + 2-3 quantity tap options) — for match-numeral mode
├── StampPosterView (corner display; updates on mastery)
├── DoneButtonView
├── HUDView
└── NotebookTab (collapsed; rarely used)
```

### Reusable opportunities surfaced by this spec

- **Per-numeral mastery state** — first activity to use per-instance mastery. Generalizes to 1st-grade Crystal Bundler (per-place-value mastery? maybe overkill), and to 2nd-grade activities that track per-arithmetic-fact mastery (e.g., Fluency Within 20 might track per-fact mastery for the 36 single-digit addition facts).
- **Numeral character animation system** — "numeral comes to life" pattern could be reused as a generic "symbol-to-character" animation library for future activities (e.g., letter animations if we ever expand to literacy, or symbol animations in 2nd-grade Strategy Explainer).
- **Stamp poster pattern** — collection display that updates on mastery. Reusable for any per-instance mastery activity.

### Performance considerations

- 0–21 numeral characters on the shelves with idle animations. Use sprite atlases.
- Trace evaluation runs on stylus-stroke samples; per `number-writing-modes.md` Mode 1, this is geometric (no ML). Should be cheap.
- Digit classifier inference runs at end-of-input timeout (1.2 s after last stroke); per `math-notebook.md`, target <5 ms on iPad A12+.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first K activity to heavily exercise `number-writing-modes.md` (Mode 1 + Mode 2); introduces **per-numeral mastery** as a new mastery-tracking pattern | |
| 2026-05-30 | K.CC.3 MicroLesson authored and linked. Activity is now lesson-complete and ready-to-build | |
