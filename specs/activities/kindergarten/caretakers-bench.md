# Activity Spec — Caretaker's Bench

> The K activity that introduces **describing measurable attributes** (K.MD.1) and **directly comparing two objects by an attribute** (K.MD.2). A Sanctuary workbench cluttered with everyday objects and magical ones, an attribute-word library, a balance scale, and a measuring stick. Drag-Tool stylus mechanic gets its first production use.

References: `specs/shared/stylus-mechanics.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/reward-economy.md`, `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activity-spec-template.md`.

---

## Header

| Field | Value |
|---|---|
| Activity name | Caretaker's Bench |
| Activity slug | `caretakers-bench` |
| Region | Sanctuary |
| Grade | K |
| Standards | K.MD.1, K.MD.2 |
| Status | Draft |
| Last updated | 2026-05-30 |

---

## Setting & Tone

- **Scene** — A wooden workbench in a corner of the Sanctuary, lit by a small overhead lantern. The bench surface is cluttered with everyday objects mixed with magical ones: a feather, a glow-stone, an apple, a wooden spoon, a dragon scale, a tiny rock, a length of ribbon. A **balance scale** sits on the right side of the bench. A **measuring stick** hangs from a peg above. **Attribute word tags** float gently in the air near the bench like leaves catching light — small wooden cards labeled "long," "short," "heavy," "light," "smooth," "rough," "shiny," "dull."
- **Atmosphere** — Soft afternoon light filtered through trees outside; the workbench feels like a quiet study nook. Music bed is the Sanctuary palette with a subtle "workshop" texture (gentle clinking, brushing sounds layered low). Palette anchors: wood-brown, lantern-gold, ribbon-red, glow-stone-teal.
- **Buddy presence** — Per `k-activity-patterns.md`: Buddy at lower-left on a small overturned crate. Watches the kid examine objects with attentive head-tilts. Hops on round-pass.
- **Narrator** — Sanctuary warm naturalist.

---

## Standards Coverage

| Standard | What the kid does | Telemetry event | Mastery threshold |
|---|---|---|---|
| **K.MD.1** (describe measurable attributes) | In `describe-attributes` sub-mode: drags attribute word tags onto an object that matches the attribute. Single object, multiple attributes can apply. | `bench.attribute_described` (payload: `object`, `attributeWord`, `correct`) | 5/3/3 standard |
| **K.MD.2** (compare two by attribute) | In `compare-two` sub-mode: positions two objects on the measuring stick (length) or balance scale (weight), then declares which has more of the attribute. | `bench.compare_two_completed` (payload: `objectA`, `objectB`, `attribute`, `declared`, `correct`) | Same |

---

## Concepts: Introduced vs Exercised

| Concept | Role | Lesson | Granularity | Notes |
|---|---|---|---|---|
| **K.MD.1** (describe attributes) | Introduces | `specs/lessons/k-md-1-describe-attributes.md` | concept-wide | First lesson here demonstrates dragging attribute words onto an object (a feather described as "light," "soft"). |
| **K.MD.2** (compare two by attribute) | Introduces | `specs/lessons/k-md-2-compare-attributes.md` | concept-wide | Fires on first entry to `compare-two` sub-mode. Uses the balance scale as the visual hook for weight comparison; measuring stick for length. |

### Registry impact

- `K.MD.1.introducedBy = caretakers-bench`
- `K.MD.2.introducedBy = caretakers-bench`

**No intra-round lesson chain.** K.MD.1 and K.MD.2 are related but their sub-modes are structurally independent (describing is one round shape; comparing is another). Default queue rule handles lesson firing across rounds.

---

## Sub-Modes

### Sub-mode: `describe-attributes` (default)

- **Standards targeted** — K.MD.1
- **What the kid does** — A single object appears at the center of the bench (e.g., a feather). Attribute word tags float nearby — some apply to the feather (`light`, `smooth`, `soft`), some don't (`heavy`, `rough`). The kid drags the *applicable* attribute words onto the object. After all valid attributes are placed, the round completes.
- **Pass condition** — Kid has placed at least **2 correct attribute words** on the object (per K.MD.1: "describe several measurable attributes"). Misses are tolerated — the kid doesn't need to place every applicable word, just demonstrate that several attributes apply.
- **Fail behavior** — If the kid drops a non-applicable word (e.g., "heavy" on a feather), the tag returns with a soft "nope" puff. After 3 wrong drops on the same object, narrator gently scaffolds: "Feathers aren't heavy — they're light. Try the light tag."

### Sub-mode: `compare-two`

- **Standards targeted** — K.MD.2
- **What the kid does** — Two objects appear on the bench (e.g., a feather and a rock). The narrator asks: "Which is heavier?" (or "Which is longer?"). The kid uses one of two tools:
  - **Balance scale** (weight): drags both objects onto the scale's pans. The scale tips toward the heavier object visually. The kid taps the heavier object to confirm.
  - **Measuring stick** (length): drags both objects against the stick, aligning their ends. The stick shows the length difference. The kid taps the longer object to confirm.
- **Pass condition** — Correct identification of the heavier/longer object.
- **Fail behavior** — Wrong tap → soft "no," narrator scaffolds: "Look at the scale — it tips toward the {actual_heavier}. The {actual_heavier} is heavier."

### Sub-mode: `describe-three-attributes` *(challenge variant)*

- **Standards targeted** — K.MD.1 stretched
- **What the kid does** — Single object; kid must place at least **3 correct attributes** before the round completes. (Higher than the default's 2.) Tougher because it requires the kid to think more comprehensively about the object's properties.
- **Reward bump** — Challenge chest per `reward-economy.md`.

### Sub-mode: `order-three-by-length` *(alternate challenge variant)*

- **Standards targeted** — K.MD.2 stretched
- **What the kid does** — Three objects of varying lengths appear. Kid drags them against the measuring stick and orders them shortest → longest (using a podium pattern like Care Pantry / Picnic Baskets).
- **Reward bump** — Challenge chest.

**Challenge rotation**: the activity alternates between the two challenge variants daily (or per kid preference). Both are valid stretch experiences for K.MD.1 / K.MD.2.

---

## Visual Layout

### `describe-attributes` layout

```
+--------------------------------------------------------+
| [exit]                              [coins: 12]        |
|                                                        |
|   <Sanctuary workbench — wooden, lantern-lit>         |
|                                                        |
|                                                        |
|                  🪶 <feather>                          |
|              <central object>                          |
|                                                        |
|                                                        |
|    [light]  [smooth]  [heavy]  [rough]  [soft]        |
|    <floating attribute word tags>                     |
|                                                        |
|             [described: 2 attributes]                 |
|                                                        |
|  [Buddy on crate]                      [notebook >]   |
|                                                        |
|                  [ done? ]                             |
+--------------------------------------------------------+
```

### `compare-two` layout (weight)

```
+--------------------------------------------------------+
|                                                        |
|   <workbench>                                          |
|                                                        |
|       🪶 <feather>      🪨 <rock>                       |
|       <two objects on the bench surface>              |
|                                                        |
|                                                        |
|              ┌──────────────────┐                      |
|              │   ⚖️ <balance>   │                      |
|              │ [pan A] [pan B]  │                      |
|              └──────────────────┘                      |
|                                                        |
|             [which is heavier?]                       |
|                                                        |
+--------------------------------------------------------+
```

### `compare-two` layout (length)

```
+--------------------------------------------------------+
|                                                        |
|   <workbench>                                          |
|                                                        |
|       🪶              🎀                                |
|       <feather>       <ribbon>                         |
|                                                        |
|                                                        |
|   ┌──────────────────────────────────┐                 |
|   │ ──────── measuring stick ─────── │                 |
|   └──────────────────────────────────┘                 |
|   (objects drag onto here, aligned at left end)       |
|                                                        |
|             [which is longer?]                        |
|                                                        |
+--------------------------------------------------------+
```

- **Persistent scene anchors** — workbench background, attribute word tags floating, Buddy lower-left.
- **Interactive elements (describe)** — central object (static; drop target for word tags). Word tags (draggable; snap to "applied" zones near the object).
- **Interactive elements (compare-two, weight)** — two objects (draggable to balance pans). Balance scale (visual feedback only — tips automatically). Tap the heavier object after the scale settles.
- **Interactive elements (compare-two, length)** — two objects (draggable onto the measuring stick). Stick auto-aligns objects at the left end. Tap the longer object to confirm.

---

## State Machine

```
[idle/intro] → narrator opens with the round's goal
   ↓
[setup] → object(s) + tools appear per sub-mode
   ↓
[active] → kid drags tags / objects; tools update
   ↓ (kid completes the required interactions)
[evaluating] → check correctness
   ↓
[round_passed]                       [round_failed]
   ↓                                    ↓
[reward + Buddy approval]            [warm narrator + demonstration]
   ↓                                    ↓
[next round queued]                  [retry at current layer]
                                        ↓
                                     [if 2 consecutive fails: demote per staggered rule]
```

**Exit conditions** — standard per K patterns.

---

## Stylus Interactions

| Mechanic | Where used | Local overrides |
|---|---|---|
| **Drag-and-Drop (snap-to-target)** | `describe-attributes`: drag word tags onto the object's "applied attributes" zone. `compare-two`: drag objects onto balance pans or onto the measuring stick. | Snap radius 30 pt (forgiving). Wrong-bin drops (irrelevant attribute, object on wrong pan) return with soft "nope." |
| **Drag-Tool** | `compare-two`: the balance scale and measuring stick are draggable tools the kid positions, but in this activity they're **fixed in position** by default. Drag-Tool's full positioning behavior unlocks at higher CPA layers where the kid moves the tool onto the objects. | Tools auto-align at Concrete (kid just drags objects to fixed tool positions). At Pictorial+, kid drags the tool onto the objects (full Drag-Tool behavior). |
| **Tap-Pick** (selection semantic) | `compare-two`: tap the heavier / longer object after the tool's visual feedback. `order-three-by-length` challenge: tap objects in order, or drag to podium positions. | Standard. |

This activity is the **first production use of the Drag-Tool stylus mechanic** (defined in `stylus-mechanics.md`).

---

## Number-Writing Modes

**Not used.** Caretaker's Bench is vocabulary-based and tool-based, not numeral-based.

---

## Audio Cues

> **Runtime source**: narration cues live in [`content/strings/en-US/activities/caretakers-bench.json`](../../../content/strings/en-US/activities/caretakers-bench.json). The prose below is the design-time reference; the JSON is the authoritative source the TTS pipeline and runtime consume.

### Narrator lines (Sanctuary warm naturalist)

#### `describe-attributes`
- **Round start**: "Look at the {object}. Find the words that describe it."
- **Mid-progress (5 s hesitation)**: (visual hint via word-tag glow)
- **Mid-progress (10 s hesitation)**: "Pick a word and drag it to the {object}."
- **Correct drop**: "Yes — {object_plural} are {attribute}."
- **Wrong drop**: "Not quite — {object_plural} aren't {attribute}."
- **Round pass**: "{N} attributes for the {object}. Well described."

#### `compare-two` (weight)
- **Round start**: "Which is heavier — the {objectA} or the {objectB}? Put them on the scale."
- **After both on scale**: "Look — the scale tips toward the heavier one."
- **Round pass**: "Yes — the {actual_heavier} is heavier."
- **Round fail**: "Look at the scale — it tips toward the {actual_heavier}."

#### `compare-two` (length)
- **Round start**: "Which is longer — the {objectA} or the {objectB}? Line them up on the measuring stick."
- **After both on stick**: "See how one reaches farther? That one is longer."
- **Round pass**: "Yes — the {actual_longer} is longer."

#### `describe-three-attributes` (challenge)
- **Round start**: "This {object} has many features. Find at least three."
- **Round pass**: "Three or more — that's a thorough description."

#### `order-three-by-length` (challenge)
- **Round start**: "Three things, three different lengths. Order them shortest to longest."
- **Round pass**: "Shortest to longest — done."

### SFX

| Event | SFX |
|---|---|
| Word tag drag | Light "rustle" (papery) |
| Word tag drops on object (correct) | Soft "yes" chime |
| Word tag drops on object (wrong) | Gentle "nope" puff |
| Object drag onto balance pan | "Thunk" |
| Balance scale tips | Mechanical "tilt-creak" |
| Object drag onto measuring stick | "Slide" |
| Tap on heavier/longer object (correct) | Warm "tick" + sparkle on object |
| Round pass | Sanctuary chime stinger |
| Round fail | Soft sad-but-warm chord |

### Music

- Sanctuary workshop bed: gentle strings + soft brush percussion + subtle wood-tapping texture, ~85 BPM.
- Round-pass stinger over the bed.

---

## Scaffolding Triggers

Uses `ScaffoldQuery` per round, including `firstEncounterLesson` for K.MD.1 and K.MD.2 routing.

| Trigger | Response |
|---|---|
| **5 s of no input** | Highlight a relevant word tag (describe) or the appropriate tool (compare) with a soft glow. |
| **10 s of no input** | Narrator gives a sub-mode-specific prompt. |
| **Kid drops wrong attribute word** | Tag returns with soft "nope." After 3 wrong drops on same object, scaffolding narration. |
| **Kid drops object outside any tool zone** (compare-two) | Object returns to bench surface. |
| **Kid taps the wrong object as heavier/longer** | Visual: scale or stick re-pulses the correct answer. Narrator narrates the truth. Retry. |
| **2 consecutive round failures** | Apply the **staggered demotion** rule. Sub-mode demotion order: challenge variants → `compare-two` → `describe-attributes`. |

---

## CPA Progression

| Layer | What it looks like in Caretaker's Bench |
|---|---|
| **Concrete** | Word tags show **icon + text** (e.g., a feather icon for "light"). The balance scale tips dramatically and shows the difference numerically (e.g., "2x heavier"). The measuring stick shows tick marks and labels the lengths. |
| **Pictorial** | Word tags show **text only** (no icon). Scale tips but doesn't show a number — just direction. Measuring stick shows tick marks (no labels). |
| **Abstract** | Word tags shown as text on plain wooden cards (small). Scale tips subtly; the kid must observe carefully. Measuring stick has no tick marks; pure visual length comparison. |

- **Default starting layer (K, fresh kid)** — Concrete.
- **Promotion conditions** — 3 consecutive passes at the current layer.
- **Demotion conditions** — 2 consecutive failures at the current layer (staggered rule applies).

---

## Reward Emissions

| Event | Trigger | Reward (per `reward-economy.md`) |
|---|---|---|
| `round.passed` | Round passes | +2 coins |
| `round.notebook_bonus` | Notebook had ≥3 strokes (rare) | +1 coin |
| `streak.session_3` / `_5` / `_10` | Standard | Per shared spec |
| `milestone.problems_25` / `_100` | Lifetime in this activity | Per shared spec |
| `mastery.standard_practicing` / `_mastered` | Adaptive scaffolding emits | Per shared spec |
| `challenge.completed` | Challenge variant round passes | Challenge chest (rare Caretaker tool collectible guaranteed) |

### Activity-specific collectibles
- **Caretaker Tools** — small magical tools the Caretaker collects (a tiny magnifying glass, a brass scale, a velvet measuring tape, a glowing tweezer). ~10 items at launch. Drops at ~1 in 4 round-pass events.
- **Workshop decor** — wooden shelves, lanterns, hanging tools for the Hub. ~8 items at launch.
- Complete the tool set for a Hub trophy: the **Caretaker's Apprentice Kit**.

---

## Telemetry Events

(Beyond shared `scaffold.*`, `economy.*`, `lesson.*` events.)

| Event | Payload |
|---|---|
| `bench.round_started` | `subMode`, `presentationLayer`, `object(s)` |
| `bench.attribute_described` | `object`, `attributeWord`, `correct`, `attemptsForThisObject` |
| `bench.tool_used` | `tool` (balance / measuring-stick), `latencyToFirstObjectPlaced` |
| `bench.compare_two_completed` | `objectA`, `objectB`, `attribute`, `declared`, `correct` |
| `bench.round_completed` | `success`, `subMode`, `attemptsThisRound`, `hintsFired` |
| `bench.collectible_dropped` | `itemId`, `setProgress` |

---

## Challenge Variants

Two challenge variants rotate daily. Both per `reward-economy.md` challenge chest.

- **Three-Attribute Describe** — 3+ attributes required to describe an object.
- **Order Three by Length** — three objects ordered shortest → longest using the ordinal podium pattern (shared with Care Pantry and Picnic Baskets).

Entry frequency: alternating; each appears every other day. The "Examiner's Challenge!" banner cycles between the two.

---

## Edge Cases & Error Handling

- **Object has more applicable attributes than tags shown** — fine; the kid only needs to find 2 (default) or 3 (challenge). Comprehensive coverage isn't required.
- **An attribute that's "subjective"** (e.g., "pretty," "fluffy") — avoid in launch tags. Stick to measurable / observable attributes per the standard ("length," "weight" are the main ones; size, texture also work).
- **Equal lengths / equal weights** in compare-two — for K, equal-attribute pairs are out of scope at launch (the standard says "see which has *more of*/less of*"). The activity ensures pairs are visually distinguishable.
- **Kid drops object on the floor** (off-screen / off-bench) — object snaps back to its original bench position. No penalty.
- **Two objects on same balance pan** — the second object replaces the first (only one per pan). Or the system rejects (depending on UX testing).
- **Stylus disconnect mid-drag** — drag cancels; item returns.
- **App backgrounded** — pause and persist.
- **Audio muted** — visual cues (scale tip, stick length difference, tag icons at Concrete layer) carry the comparison.

---

## Decisions Needed

- **Equal-attribute handling for K.MD.2** — current spec: avoid equal pairs at launch. Alternative: include equal pairs as a third indicator option ("equal"). The standard arguably implies the kid should be able to recognize equality (matching K.CC.6's "equal" indicator). Suggest adding equal at launch for consistency with K.CC.6's match-by-line; remove this from Decisions Needed once confirmed.

---

## Notes for Later

- **Tag icon design** — small object-illustrations matching the attribute (a feather icon for "light," a brick for "heavy"). Confirm with art.
- **Balance scale animation** — physically tips. Animation should feel weighty (mass + slight bounce). Tune in playtest.
- **Measuring stick tick marks at Concrete vs Pictorial** — labels vs unlabeled ticks. Confirm legibility at K.
- **Object roster** — ~20 objects at launch with multi-attribute tags. Author the full list before launch; the K.MD.1 lesson uses one specific object as worked example.

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical across phases.


```
CaretakersBenchView
├── WorkbenchBackgroundLayer (parallax wood + lantern light + tree shadows)
├── BuddyView (on crate; idle behaviors)
├── WorkbenchSurfaceView (the central work area)
│    ├── ObjectsLayer (varies by sub-mode: 1, 2, or 3 objects)
│    ├── AttributeWordTagsLayer (floating tags; describe-attributes sub-mode)
│    ├── BalanceScaleView (compare-two weight)
│    └── MeasuringStickView (compare-two length)
├── PodiumSlotsView (order-three-by-length challenge)
├── ProgressIndicator (e.g., "described: 2 attributes" / "select the heavier")
├── DoneButtonView
├── HUDView
└── NotebookTab (collapsed; rarely used)
```

### Reusable opportunities

- **Drag-Tool mechanic** — first production use. The balance scale and measuring stick are both "tools the kid positions." Validates the spec in `stylus-mechanics.md`. Pattern reusable in 2nd-grade Workshop with Rulers (similar tool-positioning workflow).
- **Attribute word tags** — floating draggable text labels. Could generalize for any "label/classify" activity. Possibly reusable in 1st-grade Wundle Census (label data categories) or 2nd-grade Shape Detective (label shape attributes).
- **OrdinalPodium** — third activity to use the podium (after Care Pantry and Picnic Baskets). Pattern is now well-established.
- **BalanceScale visual** — generic enough for any weight-comparison need; potentially reusable in 1st-grade Garden Plots if weight comparisons surface.

### Performance

- ~6-10 objects + 8 word tags + 1 tool on screen at any time. Low overhead.
- Balance scale animation uses physics-style spring damping; lightweight.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first production use of the **Drag-Tool** stylus mechanic; third K activity to use the ordinal podium pattern (Care Pantry, Picnic Baskets, Caretaker's Bench challenge) | |
