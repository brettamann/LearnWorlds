# Activity Spec — Picnic Baskets

> The K activity that introduces **comparing two groups of objects** (K.CC.6) and **comparing two written numerals** (K.CC.7). Two related-but-distinct comparison concepts presented through a picnic spread with creature treats. Validates the **Draw-Line** stylus mechanic in production.

References: `specs/shared/stylus-mechanics.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/reward-economy.md`, `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activity-spec-template.md`.

---

## Header

| Field | Value |
|---|---|
| Activity name | Picnic Baskets |
| Activity slug | `picnic-baskets` |
| Region | Sanctuary |
| Grade | K |
| Standards | K.CC.6, K.CC.7 |
| Status | Draft |
| Last updated | 2026-05-30 |

---

## Setting & Tone

- **Scene** — A Sanctuary glade at midday with a **picnic blanket spread on the grass**. Two **woven baskets** sit on the blanket — one labeled with a unicorn icon, one with a hatchling dragon icon. The baskets hold creature treats (apple slices for the unicorns, sparkleberries for the hatchling dragons). Wildflowers nod in the foreground.
- **Atmosphere** — Bright midday light dappled by tree shadows. Music bed is the warm Sanctuary string-and-flute palette with a relaxed "picnic" texture (acoustic-guitar fingerpicking layered low). Palette anchors: blanket-red, basket-tan, grass-green, sun-yellow.
- **Buddy presence** — Per `k-activity-patterns.md`: Buddy at lower-left on a small pillow on the blanket, watching the picnic. Reacts to comparisons with attentive head-tilts. Hops on round-pass.
- **Narrator** — Sanctuary warm naturalist.

---

## Standards Coverage

| Standard | What the kid does | Telemetry event | Mastery threshold |
|---|---|---|---|
| **K.CC.6** (compare groups by matching or counting, ≤10) | In `match-by-line` sub-mode: draws lines between items in the two baskets. In `count-and-compare` sub-mode: taps to count both groups, then identifies the larger/smaller/equal. | `picnic.matching_compare_completed` (payload: `groupA`, `groupB`, `result`), `picnic.counting_compare_completed` | 5/3/3 standard |
| **K.CC.7** (compare two numerals 1–10) | In `numeral-compare` sub-mode: drags one of three symbol tiles (`>`, `<`, `=`) between two displayed numerals. | `picnic.numeral_compare_completed` (payload: `leftN`, `rightN`, `symbolChosen`, `correct`) | Same |

---

## Concepts: Introduced vs Exercised

| Concept | Role | Lesson | Granularity | Notes |
|---|---|---|---|---|
| **K.CC.6** (compare groups) | Introduces | `specs/lessons/k-cc-6-compare-by-matching.md` | concept-wide | First lesson here demonstrates the matching strategy (drawing lines between groups) and counting strategy. |
| **K.CC.7** (compare numerals) | Introduces | `specs/lessons/k-cc-7-compare-numerals.md` | concept-wide | Fires on first entry to the `numeral-compare` sub-mode (per the default queue rule — no intra-round chain needed because the sub-modes are not structurally inseparable within a round). |

### Registry impact

- `K.CC.6.introducedBy = picnic-baskets`
- `K.CC.7.introducedBy = picnic-baskets`

**No intra-round lesson chain.** K.CC.6 and K.CC.7 are related concepts but their activity sub-modes are independent — the kid plays many matching/counting rounds before hitting numeral-compare. The lessons queue across rounds per the default rule.

---

## Sub-Modes

### Sub-mode: `match-by-line` (default)

- **Standards targeted** — K.CC.6 (matching strategy)
- **What the kid does** — Two baskets open on the blanket, each spilling out a small group of treats (e.g., basket A: 4 apples; basket B: 3 sparkleberries). The kid uses the **Draw-Line** stylus mechanic to draw a line between each apple and one sparkleberry. Items left un-matched indicate which group has more.
- **Pass condition** — All possible matches drawn, kid taps the **larger / smaller / equal** indicator (or auto-detected from un-matched items + the kid confirms).
- **Fail behavior** — Wrong indicator tap → warm narrator + demonstration: highlight the un-matched item visually, narrator says "Basket A has 4, Basket B has 3 — A has more." Retry.

### Sub-mode: `count-and-compare`

- **Standards targeted** — K.CC.6 (counting strategy)
- **What the kid does** — Two baskets each contain a group of treats. The kid taps each item in basket A to count, then each in basket B. Counts shown in the badges. The kid then taps `more` / `less` / `equal` to declare A's relationship to B.
- **Pass condition** — Correct declaration.
- **Fail behavior** — Warm narrator + demonstration showing the counts side-by-side. Retry.

### Sub-mode: `numeral-compare`

- **Standards targeted** — K.CC.7
- **What the kid does** — Two large numeral cards appear on the picnic blanket (e.g., "7" on the left, "4" on the right). Three symbol tiles (`>`, `<`, `=`) appear at the bottom. The kid drags the correct symbol into the gap between the numerals.
- **Pass condition** — Correct symbol dropped between the numerals.
- **Fail behavior** — Wrong symbol drop → symbol returns to tile row. After 2 wrong drops, narrator scaffolds: "Look — 7 is bigger than 4. The big-side of the symbol points to the bigger number."

### Sub-mode: `three-way-compare` *(challenge variant)*

- **Standards targeted** — K.CC.6 + K.CC.7 stretched
- **What the kid does** — Three baskets on the blanket. The kid identifies which has the most and which has the least using matching or counting, then orders them on a podium (least → middle → most). Same podium pattern as Care Pantry's Phase 2.
- **Pass condition** — All three baskets correctly ordered.
- **Reward bump** — Challenge chest per `reward-economy.md`.

---

## Visual Layout

### `match-by-line` layout

```
+--------------------------------------------------------+
| [exit]                              [coins: 12]        |
|                                                        |
|   <Sanctuary glade — picnic blanket, wildflowers>     |
|                                                        |
|   ┌─basket A (🦄)─┐        ┌─basket B (🐉)─┐         |
|   │ 🍎 🍎 🍎 🍎  │        │ ✨ ✨ ✨    │           |
|   └────────────────┘        └─────────────┘           |
|                                                        |
|       🍎 — ✨                                          |
|       🍎 — ✨                                          |
|       🍎 — ✨                                          |
|       🍎                  (un-matched — A has more)   |
|                                                        |
|             [A has more]  [equal]  [B has more]       |
|                                                        |
|  [Buddy on pillow]                     [notebook >]   |
|                                                        |
|                  [ done? ]                             |
+--------------------------------------------------------+
```

### `numeral-compare` layout

```
+--------------------------------------------------------+
|                                                        |
|   <picnic blanket scene>                              |
|                                                        |
|                                                        |
|              ┌────┐    ┌──┐    ┌────┐                  |
|              │ 7  │    │ ? │    │ 4  │                 |
|              └────┘    └──┘    └────┘                  |
|              (large numerals; gap for symbol)         |
|                                                        |
|                                                        |
|              [ > ]    [ < ]    [ = ]                  |
|              (draggable symbol tiles)                 |
|                                                        |
+--------------------------------------------------------+
```

- **Persistent scene anchors** — picnic blanket, baskets, Buddy at lower-left.
- **Interactive elements (match-by-line)** — items in each basket are **anchor points** for the Draw-Line mechanic. Larger / smaller / equal indicators are tap targets.
- **Interactive elements (count-and-compare)** — items are tappable for counting; indicators are tap targets.
- **Interactive elements (numeral-compare)** — numeral cards are static. Symbol tiles are draggable to the gap.

---

## State Machine

```
[idle/intro] → narrator opens with the round's prompt
   ↓
[setup] → baskets / numerals appear per sub-mode
   ↓
[active] → kid matches lines, counts taps, or drags symbol
   ↓ (kid completes the matching/counting/symbol drop)
[evaluating] → check kid's input against expected
   ↓
[round_passed]                       [round_failed]
   ↓                                    ↓
[reward + visual flourish]           [warm narrator + demonstration]
   ↓                                    ↓
[next round queued]                  [retry per Mode fallback chain]
                                        ↓
                                     [if 2 consecutive fails: demote per staggered rule]
```

**Exit conditions** — standard per K patterns.

---

## Stylus Interactions

| Mechanic | Where used | Local overrides |
|---|---|---|
| **Draw-Line** | `match-by-line` sub-mode — line connects an item in basket A to an item in basket B | Standard per `stylus-mechanics.md`. Anchor tolerance 20 pt. Stroke must connect two anchors (one in each basket); strokes that end in empty space dissolve. |
| **Tap-Pick** (counting semantic) | `count-and-compare` sub-mode | Standard. Tap each item to count. |
| **Tap-Pick** (selection semantic) | `match-by-line` and `count-and-compare` — tapping the larger/smaller/equal indicator | Standard. |
| **Drag-and-Drop (snap-to-target)** | `numeral-compare` sub-mode — drag `>`, `<`, `=` symbol into the gap | Snap radius 30 pt (gap target is generous). Wrong-symbol drops return to tile row. |
| **Drag-and-Drop (snap-to-target)** | `three-way-compare` challenge — drag baskets to ordinal podium positions | Same as Care Pantry's podium drop targets. |

---

## Number-Writing Modes

**Not used.** Picnic Baskets doesn't ask the kid to write numerals. The numeral-compare sub-mode uses tile-based symbols.

---

## Audio Cues

> **Runtime source**: narration cues live in [`content/strings/en-US/activities/picnic-baskets.json`](../../../content/strings/en-US/activities/picnic-baskets.json). The prose below is the design-time reference; the JSON is the authoritative source the TTS pipeline and runtime consume.

### Narrator lines (Sanctuary warm naturalist)

#### `match-by-line`
- **Round start**: "Match the {treat_A} to the {treat_B} — one to one."
- **Mid-progress (no draw)**: (visual hint via item glow)
- **Mid-progress (10 s hesitation)**: "Draw a line from a {treat_A} to a {treat_B}."
- **All matches drawn**: "Which basket has more? Tap the answer."
- **Round pass**: "Yes — basket {larger_basket} has more. {countA} {treat_A_plural} and {countB} {treat_B_plural}."
- **Round fail**: "Look — basket {actual} has more. Let me show you."

#### `count-and-compare`
- **Round start**: "Count the {treat_A} in basket A, then the {treat_B} in basket B."
- **Round pass**: "Yes — {countA} is {comparison} {countB}."

#### `numeral-compare`
- **Round start**: "Put the right symbol between {leftN} and {rightN}."
- **Round pass**: "Yes — {leftN} is {comparison} {rightN}."
- **Round fail (after 2 wrong)**: "Look — {leftN} is {comparison} {rightN}. The wide side of the symbol points to the bigger number."

#### `three-way-compare` (challenge)
- **Round start**: "Three baskets today. Put them in order from least to most."
- **Round pass**: "Right — {least_basket} has the fewest, {most_basket} has the most."

### SFX

| Event | SFX |
|---|---|
| Item tap (count) | Soft "tick" |
| Draw-line trail | Subtle "pencil-on-paper" |
| Line connects two anchors | Light "chime" |
| Symbol drag | "Pick up" cue |
| Symbol snap into gap | Warm "settle" chime |
| Wrong drop / wrong tap | Soft "nope" puff |
| Round pass | Sanctuary chime stinger |
| Round fail | Soft sad-but-warm chord |

### Music

- Sanctuary midday picnic bed: gentle strings + fingerpicked guitar + occasional wind chime, ~80 BPM.
- Round-pass stinger over the bed.

---

## Scaffolding Triggers

Uses `ScaffoldQuery` per round, including `firstEncounterLesson` for K.CC.6 and K.CC.7 routing.

| Trigger | Response |
|---|---|
| **5 s of no input** | An item or anchor pulses softly to draw attention. |
| **10 s of no input** | Narrator gives a sub-mode-specific prompt. |
| **Kid draws line ending in empty space** (match-by-line) | Line dissolves with soft "nope"; no penalty. |
| **Kid tries to match same item twice** | Soft no-op; the system tracks "matched" state per item. |
| **Kid drops wrong symbol** (numeral-compare) | Symbol returns to tile row; gentle correction narration after 2nd wrong. |
| **2 consecutive round failures** | Apply the **staggered demotion** rule from `adaptive-scaffolding.md`. Sub-mode demotion order: `three-way-compare` → `numeral-compare` → `count-and-compare` → `match-by-line`. |

---

## CPA Progression

| Layer | What it looks like in Picnic Baskets |
|---|---|
| **Concrete** | In `match-by-line` and `count-and-compare`: items are visible distinct creatures (apples and sparkleberries), counts visible on baskets. Indicator buttons show numerals AND labels ("4 < 5", "A has more"). In `numeral-compare`: small **dot patterns appear beneath each numeral** as a scaffold (visual quantity reference). |
| **Pictorial** | Items still visible; counts hidden. Indicator buttons show only labels ("A has more"). In `numeral-compare`: dot patterns removed. |
| **Abstract** | Items reduced to abstract icons (small uniform shapes); counts hidden. Indicator buttons use only symbols (`>`, `<`, `=`). In `numeral-compare`: pure numeral comparison. |

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
| `challenge.completed` | `three-way-compare` round passes | Challenge chest (rare picnic-themed collectible guaranteed) |

### Activity-specific collectibles
- **Picnic Food Items** — small decorative foods (a slice of berry pie, a tiny cheese wheel, a flower-shaped pastry) earned by completing rounds. ~12 items at launch. Drops at ~1 in 4 round-pass events.
- **Picnic Decor** — blanket patterns, basket designs, picnic accessories for the Hub home. ~6 items at launch. Drops at ~1 in 8 round-pass events.
- Complete the food set for a Hub trophy: the **Picnic Feast Spread**.

---

## Telemetry Events

(Beyond shared `scaffold.*`, `economy.*`, `lesson.*` events.)

| Event | Payload |
|---|---|
| `picnic.round_started` | `subMode`, `presentationLayer`, `leftCount`, `rightCount` |
| `picnic.line_drawn` | `fromAnchor`, `toAnchor`, `latencyMs` |
| `picnic.line_dissolved` | `reason` (e.g., "empty-target") |
| `picnic.indicator_tapped` | `indicator` (more / less / equal), `correct: Bool` |
| `picnic.numeral_compare_completed` | `leftN`, `rightN`, `symbolChosen`, `correct` |
| `picnic.matching_compare_completed` | `groupA`, `groupB`, `linesDrawn`, `result` |
| `picnic.counting_compare_completed` | `groupA`, `groupB`, `result` |
| `picnic.round_completed` | `success`, `subMode`, `attemptsThisRound`, `hintsFired` |
| `picnic.collectible_dropped` | `itemId`, `setProgress` |

---

## Challenge Variant

**Three-Way Compare** — `three-way-compare` sub-mode (order three baskets by count using a least/middle/most podium).

- **Entry point** — A "Big Picnic!" banner appears on Picnic Baskets' tile in the Sanctuary 1× per day at launch (tunes post-launch).
- **Reward bump** — Challenge chest (rare picnic-themed collectible guaranteed).

---

## Edge Cases & Error Handling

- **Kid draws a line connecting two items in the same basket** (in match-by-line) — line dissolves; valid matches are A-to-B only.
- **Kid draws lines diagonally across baskets** — Draw-Line mechanic accepts curves up to standard tolerance; the line connects the start and end anchors regardless of path shape.
- **Kid taps the same item twice** (count-and-compare) — counted once per Tap-Pick debounce; logged for telemetry.
- **Equal counts in match-by-line** — all items matched, no leftovers; kid taps "equal" indicator.
- **Numeral-compare with equal numerals** (e.g., "5" and "5") — kid drags `=` between them.
- **Tied counts in three-way-compare challenge** — same handling as Care Pantry's tied-count case; either ordering accepted.
- **Stylus disconnect mid-line-draw** — line cancels; kid retries.
- **App backgrounded** — pause and persist (per K patterns).
- **Audio muted** — visual cues (item glow, indicator labels at Concrete layer) carry the prompt without audio dependency.

---

## Decisions Needed

*(None at launch — activity is structurally clear.)*

---

## Notes for Later

- **Equal-count handling in `match-by-line`** — when all items are matched with no leftovers, the "equal" indicator should activate as the natural choice. Confirm in playtest the kid recognizes this without explicit narration.
- **Numeral-compare scaffolding** — dot patterns beneath numerals at Concrete layer. Confirm dot arrangement aesthetic; consider using dice-pip pattern for instant recognition.
- **Three-way-compare difficulty** — challenge variant. Tune count ranges and tied-count frequency based on playtest.
- **Picnic blanket aesthetic variants** — could unlock different blanket patterns as decor; ties to the picnic decor collectible set.

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical across phases.


```
PicnicBasketsView
├── GladeBackgroundLayer (parallax grass + wildflowers + sky)
├── BuddyView (on pillow; idle behaviors)
├── PicnicBlanketView (the central spread)
├── BasketsLayer (varies by sub-mode: 2 or 3 baskets)
│    └── BasketView (with items, count badge, anchor points for Draw-Line)
├── NumeralCardsLayer (numeral-compare sub-mode: 2 large cards + gap)
├── SymbolTileRow (>, <, = draggable tiles)
├── IndicatorButtonsRow (more / less / equal — for match-by-line and count-and-compare)
├── PodiumSlotsView (three-way-compare challenge)
├── DrawLineLayer (renders drawn match lines)
├── DoneButtonView
├── HUDView
└── NotebookTab (collapsed)
```

### Reusable opportunities

- **Draw-Line mechanic** — first production use. Validates the spec in `stylus-mechanics.md`. Pattern reusable in any matching activity (potentially 1st-grade Wundle Census's category matching, 2nd-grade Data Lab if matching surfaces).
- **OrdinalPodium** — second activity to use the podium (after Care Pantry). Confirms the pattern generalizes.
- **NumeralCard** — large displayed numeral component. Generalizes for any read-the-number activity (Scribe's Tower's match-numeral sub-mode already uses similar; consider sharing).
- **SymbolTileRow** — `>`, `<`, `=` tiles. May reuse for 1st-grade Number Bonds Lab's True/False equation handling.

### Performance

- Up to ~20 items + 3 baskets on screen in three-way-compare. Sprite atlases recommended.
- Draw-Line rendering uses simple bezier strokes; cheap.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first production use of the **Draw-Line** stylus mechanic; second activity to use the **ordinal podium** pattern (after Care Pantry) | |
