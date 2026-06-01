# Activity Spec — Shape Garden

> The K activity that introduces **shape recognition independent of orientation/size**, the **2D-vs-3D distinction**, and **attribute-based sorting**. Three sub-modes, each tied to one Utah standard. Different mechanic profile from the counting/composition activities: tap-select and drag-to-bin.

References: `specs/shared/stylus-mechanics.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/reward-economy.md`, `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activity-spec-template.md`.

---

## Header

| Field | Value |
|---|---|
| Activity name | Shape Garden |
| Activity slug | `shape-garden` |
| Region | Sanctuary |
| Grade | K |
| Standards | K.G.2, K.G.3, K.G.4 |
| Status | Draft |
| Last updated | 2026-05-30 |

---

## Setting & Tone

- **Scene** — An enchanted garden along a winding path. Flowers and plants *are* 2D shapes: circular dahlias, triangular ferns, square herb planters, hexagonal honeycomb cells where tiny bees hover, star-shaped jasmine. To the right of the path, a small **reflecting pond** holds 3D-shape creatures: sphere jelly-bubbles drifting on the water, cube turtles sunning themselves, cone-hatted mushroom gnomes, cylinder lanterns bobbing gently.
- **Atmosphere** — Late-morning Sanctuary light; gentle breeze animates leaves. Music bed is the warm Sanctuary string-and-flute palette. Distant birdsong. Palette anchors: deep garden green, terra-cotta path, lily-white plant accents, water-blue pond.
- **Buddy presence** — Per `k-activity-patterns.md`: Buddy on a small grassy mound at lower-left, watching the garden. Idle: sniffs at flowers, occasional tail flick.
- **Narrator** — Sanctuary warm naturalist (consistent K voice).

---

## Standards Coverage

| Standard | What the kid does | Telemetry event | Mastery threshold |
|---|---|---|---|
| **K.G.2** (name shapes regardless of orientation/size) | In `find-shape` sub-mode: taps all instances of a named shape, regardless of rotation or scale | `shape.find_target_completed` (payload: `targetShape`, `foundCount`, `missedCount`, `falsePositives`) | 5/3/3 standard |
| **K.G.3** (2D vs 3D distinction) | In `flat-or-solid` sub-mode: drags mixed shapes into a "flat" bin or "solid" bin | `shape.flat_solid_sorted` (payload: `itemShape`, `kidChose`, `correct`) | Same |
| **K.G.4** (analyze, compare, sort by attribute) | In `sort-by-attribute` sub-mode: sorts shapes into 2–3 bins by a specified attribute (number of sides, curves vs straights, color paired with shape) | `shape.attribute_sort_completed` (payload: `attribute`, `bins`, `accuracy`) | Same |

---

## Concepts: Introduced vs Exercised

| Concept | Role | Lesson | Notes |
|---|---|---|---|
| **K.G.2** (shape recognition, rotation/size invariant) | Introduces | `specs/lessons/k-g-2-shape-recognition.md` | First lesson played here. The "rotation invariance" insight is the conceptual move — *a triangle is still a triangle even sideways or tiny*. |
| **K.G.3** (flat vs solid / 2D vs 3D) | Introduces | `specs/lessons/k-g-3-flat-or-solid.md` | Fires on first entry to `flat-or-solid` sub-mode. Uses the reflecting pond as the visual cue: shapes that "live in water" rotate, shapes on the path stay paper-flat. |
| **K.G.4** (sort by attribute) | Introduces | `specs/lessons/k-g-4-sort-by-attribute.md` | Fires on first entry to `sort-by-attribute` sub-mode. The lesson uses "number of sides" as the canonical attribute; other attributes (curves, color-paired) appear in later rounds. |

### Registry impact

- `K.G.2.introducedBy = shape-garden`
- `K.G.3.introducedBy = shape-garden`
- `K.G.4.introducedBy = shape-garden`

---

## Sub-Modes

### Sub-mode: `find-shape`

- **Standards targeted** — K.G.2
- **What the kid does** — A target shape is announced (e.g., "Find all the triangles in the garden"). The garden displays 8–12 shapes, **mixed kinds, mixed sizes, mixed rotations**. The kid taps every triangle. Non-target shapes don't respond (taps on them are soft no-ops).
- **Pass condition** — All target instances tapped. Auto-fires "done" after 3 s of stillness once all targets are found (per K patterns); Done button is also available.
- **Fail behavior** — Kid taps Done with missed targets → warm narrator + demonstration highlights the missed ones, then a new round.

### Sub-mode: `flat-or-solid`

- **Standards targeted** — K.G.3
- **What the kid does** — A row of 5–8 mixed shapes appears at the top of the screen. Two bins at the bottom: a **"flat" bin** (icon: a paper-flat square) and a **"solid" bin** (icon: a small 3D cube). The kid drags each shape into the correct bin.
- **Pass condition** — All shapes correctly sorted; kid taps Done (or auto-fires after 3 s of stillness with all shapes binned).
- **Fail behavior** — Wrong-bin drops return the shape to its starting row position with a soft "no" puff (no penalty per-drop). Round only fails if kid taps Done with mis-sorted items; warm demonstration corrects.
- **Visual differentiation**: 3D shapes **gently rotate in place** to make their three-dimensionality visible; 2D shapes stay flat. This is part of how a kid can tell.

### Sub-mode: `sort-by-attribute`

- **Standards targeted** — K.G.4
- **What the kid does** — An attribute is named (e.g., "Sort by number of sides"). 2–3 bins appear, each labeled with the relevant attribute value. Kid drags shapes into the matching bin.
- **Attributes that rotate** across rounds:
  - **Number of sides**: bins are "3 sides," "4 sides," "5+ sides"
  - **Curves vs straights**: bins are "curvy" and "straight"
  - **Color + shape** (paired, never color alone — accessibility): bins are "red triangles," "blue circles," "yellow squares," etc.
- **Pass condition** — All shapes correctly sorted.
- **Fail behavior** — Same as `flat-or-solid`: wrong drops return softly; Done with mis-sorts triggers demonstration.

### Sub-mode: `two-attribute-hunt` *(challenge variant)*

- **Standards targeted** — K.G.4 extended to compound attribute reasoning
- **What the kid does** — Two attributes specified simultaneously ("Find shapes that are 4-sided AND blue"). Kid taps every shape matching both.
- **Pass condition** — All matching shapes tapped, no false positives.
- **Reward bump** — Challenge chest per `reward-economy.md`.

---

## Visual Layout

### `find-shape` layout

```
+--------------------------------------------------------+
| [exit]                              [coins: 12]        |
|                                                        |
|   <enchanted garden background — soft path, sky>      |
|                                                        |
|   ▲ ●   ◆ ▲   ★ ● ■    ▲ ◆    ●                       |
|   <10 shape-plants on the path, mixed sizes/rotations>|
|                                                        |
|                                                        |
|             [found: 3 of 5 triangles]                 |
|                                                        |
|  [Buddy idle]                          [notebook >]    |
|                                                        |
|                  [ done? ]                             |
+--------------------------------------------------------+
```

### `flat-or-solid` layout

```
+--------------------------------------------------------+
| [exit]                              [coins: 12]        |
|                                                        |
|   ▲   ● <cube>   ◆   <cone>   ■   <sphere>            |
|   <row of mixed 2D + 3D shapes at top>                |
|                                                        |
|                                                        |
|     +--------------+         +--------------+         |
|     |     flat     |         |    solid     |         |
|     |   [paper]    |         |  [cube icon] |         |
|     +--------------+         +--------------+         |
|                                                        |
|             [sorted: 2 of 6]                          |
|                                                        |
|  [Buddy idle]                          [notebook >]    |
|                                                        |
|                  [ done? ]                             |
+--------------------------------------------------------+
```

### `sort-by-attribute` layout

```
+--------------------------------------------------------+
|   ▲   ●   ◆   ★   ■   ⬢                              |
|   <row of mixed shapes>                               |
|                                                        |
|   +-------+   +-------+   +-------+                   |
|   |3 sides|   |4 sides|   |5+ sides|                  |
|   +-------+   +-------+   +-------+                   |
|                                                        |
|             [sorted: 4 of 6]                          |
+--------------------------------------------------------+
```

- **Persistent scene anchors** — garden background, Buddy at lower-left, HUD per K convention.
- **Interactive elements**:
  - **Shape-plants** in `find-shape`: tappable (Tap-Pick mechanic, selection semantic).
  - **Shapes in source row** for the bin sub-modes: draggable (Drag-and-Drop snap-to-target).
  - **Bins**: drop targets; light up on hover.
- **Progress badge** (replaces count badge for non-counting activity): "found N of M" or "sorted N of M."

---

## State Machine

```
[idle/intro] → narrator announces sub-mode goal
   ↓
[setup] → shapes spawn per sub-mode; progress badge starts at "0 of M"
   ↓
[active] → kid taps or drags; progress badge ticks
   ↓ (kid taps Done OR auto-fires after 3 s of stillness when all done)
[evaluating] → check found-set vs target / sort accuracy
   ↓
[round_passed]                       [round_failed]
   ↓                                    ↓
[reward + visual flourish:           [warm narrator + demonstrate]
 found shapes celebrate]                ↓
   ↓                                  [retry at current layer]
[next round queued]                     ↓
                                     [if 2 consecutive fails: demote per scaffolding]
```

**Exit conditions** — standard per K patterns.

---

## Stylus Interactions

| Mechanic | Where used | Local overrides |
|---|---|---|
| **Tap-Pick** (selection semantic) | `find-shape` sub-mode and `two-attribute-hunt` challenge | **Tap on a non-target shape**: no selection occurs (no mark, no error). Plays a soft "no" SFX. Logged as `falsePositive` in telemetry per the mechanic's selection-semantic behavior. **Each target can be tapped at most once per round** (standard Tap-Pick debounce). |
| **Drag-and-Drop (snap-to-target)** | `flat-or-solid` and `sort-by-attribute` sub-modes | **Drop on the wrong bin**: shape returns to its starting position with a soft "no" puff. No round-level penalty. **Drop in empty space**: same — return. |

No other mechanics. The notebook tab is available but rarely used in this activity.

---

## Number-Writing Modes

**Not used.** Shape Garden does not ask the kid to write numerals. Progress badges show numerals; no kid writing required.

---

## Audio Cues

> **Runtime source**: narration cues live in [`content/strings/en-US/activities/shape-garden.json`](../../../content/strings/en-US/activities/shape-garden.json). The prose below is the design-time reference; the JSON is the authoritative source the TTS pipeline and runtime consume.

### Narrator lines (Sanctuary warm naturalist)

#### `find-shape`
- **Round start**: "Find all the {shape_plural} in the garden."
- **Mid-progress hesitation (5 s)**: (visual hint only, no narration)
- **Mid-progress hesitation (10 s)**: "Look around — there are more {shape_plural}."
- **Round pass**: "{N}! You found all {N} {shape_plural}."
- **Round fail (missed targets)**: "I see a few more {shape_plural} hiding. Let me show you."
- **Round fail (false positive — kid keeps tapping non-targets)**: not a fail state on its own; logged for telemetry.

#### `flat-or-solid`
- **Round start**: "Some of these are flat. Some are solid. Put them in the right baskets."
- **Mid-progress (correct drop)**: (no line; SFX only)
- **Mid-progress (wrong drop)**: gentle "Try the other basket" if it's the kid's 2nd consecutive wrong drop.
- **Round pass**: "All sorted! Flat ones in the flat basket, solid ones in the solid basket."
- **Round fail**: "Some are in the wrong basket. Watch — I'll show you which is which."

#### `sort-by-attribute`
- **Round start**: "Sort these by {attribute}." (e.g., "by number of sides," "by curvy or straight")
- **Round pass**: "Nicely done. {N} sorted by {attribute}."
- **Round fail**: "A few are in the wrong basket. Let me show you."

#### `two-attribute-hunt` (challenge)
- **Round start**: "Detective hunt! Find shapes that are {attribute1} *and* {attribute2}."
- **Round pass**: "{N}! Every one of them is {attribute1} and {attribute2}."

### SFX

| Event | SFX |
|---|---|
| Tap on target shape | Soft "yes" chime + sparkle |
| Tap on non-target shape | Soft "no" puff (very gentle — not a punishment sound) |
| Drag start | "Pluck" (like picking a flower) |
| Drag drop on correct bin | "Plop" + soft chime |
| Drag drop on wrong bin / empty space | Soft "no" puff |
| Round pass | Sanctuary chime stinger (per K patterns) |
| Round fail | Soft sad-but-warm chord |
| 3D shape rotation idle | Subtle "shimmer" loop when 3D shapes are visible |

### Music

- Sanctuary mid-morning bed (same as Ten-Frame Pond): gentle strings + harp, ~85 BPM.
- Slight pause/intensity shift when sub-mode changes.

---

## Scaffolding Triggers

Uses `ScaffoldQuery` per round, including `firstEncounterLesson` for K.G.2, K.G.3, K.G.4 routing.

| Trigger | Response |
|---|---|
| **5 s of no input** | Highlight one un-acted shape (target in `find-shape`, any unsorted shape in bin sub-modes) for 1.5 s. |
| **10 s of no input** | Narrator: "Look around — there are more shapes to find." or "Drag a shape to a basket." |
| **Kid taps non-target shape repeatedly** (≥3× in a round) | Narrator gently restates the target: "We're looking for *triangles* this time." |
| **Kid drops a shape on the wrong bin** | Shape returns to source; logged but no narration unless it's the 2nd consecutive wrong drop. |
| **Kid taps Done with errors** | Round fails; warm demonstration animates the correct answer. |
| **2 consecutive round failures at current sub-mode** | Demote sub-mode complexity per `k-activity-patterns.md`: `sort-by-attribute` → `flat-or-solid` → `find-shape`. Stay simpler until 2 successes. |
| **2 consecutive failures within `find-shape`** | Reduce the number of shape-plants on screen (e.g., 12 → 8 → 6). |
| **2 consecutive failures within `sort-by-attribute`** | Switch to a simpler attribute (e.g., "number of sides" → "curvy vs straight"). |

---

## CPA Progression

Shape Garden's CPA isn't about the scene; it's about how much **shape-name scaffolding** the kid gets.

| Layer | What it looks like |
|---|---|
| **Concrete** | Each shape-plant is labeled with its name underneath ("triangle," "circle," "square"). A reference key in the corner shows all shape names. |
| **Pictorial** | Shape-plant labels removed. Reference key in the corner remains. |
| **Abstract** | No labels, no reference key. Kid identifies shapes from form alone. |

- **Default starting layer (K, fresh kid)** — Concrete.
- **Promotion conditions** — 3 consecutive passes at the current layer.
- **Demotion conditions** — 2 consecutive failures at the current layer.

### Bin-sub-mode label simplification by layer

For `sort-by-attribute`:
- **Concrete**: bins show both visual icon (e.g., "▲ 3 sides" with three dots) and text label.
- **Pictorial**: bins show text label only ("3 sides").
- **Abstract**: bins show the **categorical name** ("triangles") rather than the attribute description.

This is the Shape Garden analog of the count-badge rendering rule from `k-activity-patterns.md`.

---

## Reward Emissions

| Event | Trigger | Reward (per `reward-economy.md`) |
|---|---|---|
| `round.passed` | Round passes | +2 coins |
| `round.notebook_bonus` | Notebook had ≥3 strokes during round | +1 coin |
| `streak.session_3` / `_5` / `_10` | Standard | Per shared spec |
| `milestone.problems_25` / `_100` | Lifetime in this activity | Per shared spec |
| `mastery.standard_practicing` / `_mastered` | Adaptive scaffolding emits | Per shared spec |
| `challenge.completed` | Two-Attribute Hunt round passes | Challenge chest (rare plant card guaranteed) |

### Activity-specific collectibles
- **Garden Plant Cards** — 16 species at launch, one per recognizable shape-plant variant (circular dahlia, triangular fern, hexagonal honeycomb, etc.). Drops at ~1 in 4 round-pass events, weighted toward unseen.
- **Pond Creature Cards** — 6 species, specific to the 3D-shape creatures (sphere jelly-bubble, cube turtle, etc.). Drop only in `flat-or-solid` rounds.
- Complete sets earn a Hub trophy: the **Sanctuary Garden Atlas**.

---

## Telemetry Events

(Beyond the shared `scaffold.*`, `economy.*`, and `lesson.*` events.)

| Event | Payload |
|---|---|
| `shape.round_started` | `subMode`, `presentationLayer`, `targetShape` *(find-shape only)*, `attribute` *(sort-by-attribute only)* |
| `shape.shape_tapped` | `shapeKind`, `isTarget`, `latencyMs` |
| `shape.shape_dragged` | `shapeKind`, `fromZone`, `toZone`, `isCorrect`, `latencyMs` |
| `shape.find_target_completed` | `targetShape`, `foundCount`, `missedCount`, `falsePositives` |
| `shape.flat_solid_sorted` | `items`: list of `{shape, kidChose, correct}` |
| `shape.attribute_sort_completed` | `attribute`, `accuracy` (fraction correct), `binCounts` |
| `shape.round_completed` | `success`, `subMode`, `attemptsThisRound`, `hintsFired` |
| `shape.collectible_dropped` | `cardId`, `setProgress`, `cardType` (plant or pond) |

---

## Challenge Variant

**Two-Attribute Hunt** (combinatorial extension of K.G.4).

- **What changes** — Two attributes named simultaneously; kid taps shapes matching both.
- **Entry point** — A "Detective Hunt!" banner appears on Shape Garden's tile in the Sanctuary 1× per day at launch (tunes post-launch per the Counting Parade precedent).
- **Reward bump** — Challenge chest on completion (rare plant card guaranteed).

---

## Edge Cases & Error Handling

- **Kid taps a shape during a drag (`flat-or-solid` / `sort-by-attribute`)** — tap is ignored while a drag is in progress.
- **Multi-touch attempted (kid drags two shapes at once)** — only one drag honored at a time; the second touch is ignored until the first drop completes.
- **Color-blind accessibility** — `sort-by-attribute` *never* sorts by color alone. Color-based rounds always pair color with shape (e.g., "red triangles" not just "red") so the shape disambiguates. Confirm with art that the palette uses color-blind-safe pairings.
- **Small shape rendering** — shapes must be visually distinct at all rendered sizes. Tiny triangles shouldn't read as wedges or arrows. Specify minimum rendered size (e.g., 40 pt × 40 pt) in art guidelines.
- **3D shape rotation** — 3D shape sprites use a slow continuous rotation (~0.2 rev/s) to show their three-dimensionality. Confirm this isn't visually overwhelming if multiple 3D shapes are visible at once.
- **Reflecting pond ambient motion** — the pond is decorative; tapping the water has no effect. The 3D shapes within it are part of the playfield only in `flat-or-solid` mode.
- **Kid drags a 2D shape into the pond** — pond is not a drop target; shape returns to its source.
- **Stylus disconnect mid-drag** — drag cancels; shape returns to source; round state preserved.
- **App backgrounded** — pause and persist (per K patterns).
- **Audio muted** — visual cues (sparkles on tap, bin glow on drop, progress badge) carry the full information.

---

## Open Questions

- **Plant species count and design** — 16 plant species at launch is a working number. Confirm during art direction. The 16 should cover all 6 standard 2D shapes (circle, triangle, square, rectangle, pentagon, hexagon) with multiple variants each, plus a couple of irregular/star shapes for variety in the `find-shape` distractor pool.
- **Pond creature design** — 6 species mapped to 4 standard 3D shapes (sphere, cube, cone, cylinder). Should sphere/cube each have multiple variants (e.g., sphere jelly-bubble + sphere ball-flower)? Defer to art.
- **`two-attribute-hunt` attribute pairings** — which combinations work pedagogically? "4-sided AND blue" is the canonical example; "curvy AND large" and "3-sided AND red" are likely. Avoid combinations where one attribute trivially implies the other.
- **Tap-select vs tap-tap accessibility fallback for sort modes** — current spec uses drag for bin sorting. Some kids with motor differences may prefer tap-shape-then-tap-bin. Add as accessibility option in v1.1 (per the accessibility-in-v1.1 decision).
- **K.G.4 attribute "color + shape" pairing** — should this combination ever appear *alone* in `sort-by-attribute` (e.g., kid sorts by color where each color happens to be a different shape too)? Or only as the compound `two-attribute-hunt`? Suggest: in `sort-by-attribute`, "color paired with shape" presents bins like "red triangles, blue circles" but the kid is matching the whole combination — the activity isn't testing color recognition. Confirm pedagogical intent.
- **Reference key visibility in Pictorial layer** — a corner key showing all shape names. Should the key be tappable to highlight a specific shape? Useful or distracting? Suggest non-tappable at launch.

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical across phases.


```
ShapeGardenView
├── GardenBackgroundLayer (parallax garden + sky)
├── BuddyView (idle behaviors)
├── ShapeFieldView (the playfield; varies by sub-mode)
│    ├── FindShapeLayout (scattered shape-plants)
│    ├── FlatOrSolidLayout (source row + 2 bins + pond)
│    └── SortByAttributeLayout (source row + 2-3 bins)
├── ShapeItem (reusable: tap- or drag-capable depending on sub-mode)
├── BinTarget (drop target)
├── PondView (decorative; holds 3D creatures in flat-or-solid mode)
├── ProgressBadgeView ("found 3 of 5", "sorted 4 of 6")
├── DoneButtonView
├── HUDView
└── NotebookTab
```

### Reusable opportunities surfaced by this spec

- **`ShapeItem`** with tap/drag mode switching is reusable for Tangram Builder (1st-grade Rune Builder) and Shape Detective (2nd grade).
- **`BinTarget`** is reusable anywhere sorting is needed (Care Pantry / Sorting Bins, Wundle Census, Buddy System hero-pair sorting in Mathopolis).
- **3D rotation sprite** generalizes for any activity that contrasts 2D vs 3D representation.
- **Reference-key UI** (a corner palette of named items) generalizes for vocabulary-supportive scaffolding in many K activities.

### Performance considerations

- 10–15 shapes on screen max in `find-shape`. Sprites are simple geometry. Low overhead.
- 3D shape rotation: use a single shared rotation transform per sprite; don't allocate per shape.
- Pond ambient ripple shader runs continuously when pond is visible; budget appropriately.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft | |
| 2026-05-30 | Updated Tap-Count → Tap-Pick references per the renamed mechanic in `stylus-mechanics.md`; the selection-semantic non-target tap handling is now part of the canonical mechanic | |
| 2026-05-30 | All three MicroLessons authored and linked (K.G.2, K.G.3, K.G.4). Activity is now lesson-complete and ready-to-build | |
