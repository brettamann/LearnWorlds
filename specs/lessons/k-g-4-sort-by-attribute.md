# MicroLesson — Sort by Attribute (K.G.4)

> "Shapes have parts you can count and group by." Shapes with the same number of sides go together, regardless of size, orientation, or color. The first time a kid thinks about a shape's *attributes* as something separable from its identity.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/shape-garden.md`, `specs/lessons/k-g-2-shape-recognition.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-g-4-sort-by-attribute` |
| Concept ID | `K.G.4` |
| Standard | K.G.4 — Analyze, compare, and sort 2D and 3D shapes using informal language to describe similarities, differences, and other attributes |
| Region | Sanctuary |
| Introducing activity | Shape Garden |
| Sub-mode | `sort-by-attribute` |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 65 s |
| Status | Draft |
| Prerequisite | K.G.2 lesson completed (kid recognizes shape kinds) |

---

## Setting

Shape Garden's standard scene reconfigured for sorting. The garden path holds a **source row of mixed shape-plants** at the top — 6 shapes covering 3, 4, and 5+ sides each. Below the source row, **three bins** labeled with the attribute values:

- "**3 sides**" bin (small ▲ icon + text)
- "**4 sides**" bin (small ■ icon + text)
- "**5+ sides**" bin (small ⬠ icon + text)

For this lesson, all shapes are the same color (deep garden green) — so the only relevant feature is sides. (Other attributes — color, curves, etc. — come in later rounds.)

---

## Phase 1 — I-Show (≈25 s)

The kid watches. The phase demonstrates that shapes with the *same number of sides* go in the *same bin*, regardless of how the shapes themselves differ.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. 6 shapes in source row at top: 2 triangles (different sizes and orientations), 2 squares (one rotated 45° to a diamond), 2 pentagons. Three bins visible below. Music bed in. |
| 0:02 | Narrator opens. |
| 0:05 | Glowing pointer drifts to the **upright triangle**. Touch → lifts. Narrator: "Three sides." Pointer drags to **3-sides bin**. Soft "plop." |
| 0:09 | Pointer drifts to the **square**. Touch → lifts. Narrator: "Four sides." Drags to **4-sides bin**. |
| 0:13 | Pointer drifts to the **pentagon**. Touch → lifts. Narrator: "Five sides." Drags to **5+ sides bin**. |
| 0:17 | Pointer drifts to the **second triangle** (different size from the first). Touch → lifts. Narrator: "Three sides — same as before." Drags to **3-sides bin**. |
| 0:21 | Pointer fades. Three bins now hold 1, 1, 1 shapes (with 2 source shapes remaining unsorted). |
| 0:22 | Narrator delivers the insight. |
| 0:25 | "I've got this" button has been visible since 0:18. I-Show ends. |

### Narration script

> *(0:02)* "Let's group these shapes by how many sides they have."
>
> *(0:05)* "Three sides." *(drop into 3-sides bin)*
>
> *(0:09)* "Four sides." *(drop into 4-sides bin)*
>
> *(0:13)* "Five sides." *(drop into 5+ sides bin)*
>
> *(0:17)* "Three sides — same as before." *(drop second triangle into 3-sides bin)*
>
> *(0:22)* "Shapes with the same number of sides go together, no matter their size."

### Notes for the narrator
- The repetition of "Three sides" / "Four sides" / "Five sides" is the foundation. Each delivered the same way — *the attribute is the thing*.
- "Same as before" on the second triangle is the conceptual punchline within the I-Show: the kid sees that two visually different triangles share the same attribute and go together.
- "No matter their size" extends to "no matter their color, orientation, position" — but for the first lesson we stick to "size" as the most visible variation.

---

## Phase 2 — We-Try (≈22 s)

The kid drags shapes into the bins.

### Setup

| Element | State |
|---|---|
| Scene | Fresh source row at top — 6 shapes (different specific shapes from I-Show, same kinds): 2 triangles, 2 squares, 2 pentagons. Different sizes, some rotated. |
| Bins | Same three: 3 sides / 4 sides / 5+ sides |
| Progress badge | Hidden until first drop |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Sort by how many sides." |
| 0:03 | First shape (a triangle) gets a soft halo. |
| → kid drags | Kid drags the triangle. If dropped on **3-sides** → snap, badge `sorted: 1 of 6`, narrator: "Three sides." If dropped on wrong bin → shape returns, narrator: "Triangles have three sides. Try the 3-sides basket." |
| +0.5 s | Second shape (a square) gets a halo. |
| → kid drags | Same flow. |
| +0.5 s | Remaining 4 shapes auto-complete with pointer animation. Narrator names each: "Three sides. Four sides. Five sides. Five sides." |
| +1.5 s | Narrator: "Six shapes sorted. Two in each basket." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no drag activity, the system highlights the next un-sorted shape AND glows the correct bin briefly. Narrator: "Drag the shape to the basket with the matching number." After another 5 s, system auto-drags.

### Pass condition
Any kid drag onto any bin passes (correct steers; incorrect corrects). The lesson advances regardless of accuracy on the kid's specific drops.

### Narration script

> *(start)* "Your turn. Sort by how many sides."
>
> *(after correct drop)* "{N} sides."
>
> *(after incorrect drop)* "{Shapes plural} have {N} sides. Try the {N}-sides basket."
>
> *(auto-completing)* "Three sides. Four sides. Five sides. Five sides."
>
> *(closing)* "Six shapes sorted. Two in each basket."

---

## Phase 3 — You-Do (one round of Shape Garden)

Hand off to the activity's `sort-by-attribute` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `sort-by-attribute`
- **Attribute**: "**number of sides**" (matches the lesson)
- **Bins**: 3 sides, 4 sides, 5+ sides
- **Shape count**: 6 mixed shapes (2 of each side-count)
- **CPA layer**: Concrete (bins show icon + text labels per `shape-garden.md`)
- **Max attempts**: **3** per first-encounter forgiveness
- **Hints**: enabled

### Pass outcome
- Kid sorts all 6 shapes correctly.
- Activity announces "All sorted! Six shapes by number of sides."
- `mastery.standard_practicing` fires for K.G.4.
- Library entry created.
- `firstEncounter` for K.G.4 flips to `false`.
- **Subsequent rounds** rotate through other attributes (curves vs straights; color paired with shape) — but those don't re-fire this lesson; they're exercises of the same K.G.4 concept.

### Fail outcome (all 3 attempts miss)
- Library entry filed.
- `firstEncounter` flips to `false`.
- Mastery status stays `Introduced`.
- Dashboard flag.

---

## Library Entry

| Field | Value |
|---|---|
| Surface (Sanctuary) | Stamp Wall stamp |
| Surface (Wundletown) | Spell Book page |
| Surface (Mathopolis) | Casebook clip |
| Thumbnail | Three small bins in a row labeled "3", "4", "5+" with appropriate shapes nestled into each (a triangle, a square, a pentagon) |
| Short label | "Sorting by sides" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~65 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `attribute: "sides"`, `bins: [3, 4, "5+"]`, `iShowShapeCount: 6` |
| `lesson.wetry_drop` | `shape`, `bin`, `correct: Bool`, `wasCorrection: Bool` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `attribute`, `correctSorts`, `incorrectSorts` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.G.4
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid tries to drag a shape outside any bin** — shape returns to source row. No narration unless second consecutive miss.
- **Diamond (rotated square)** — counts as 4 sides. The system narrates "Four sides" regardless of orientation, reinforcing K.G.2's invariance principle within the K.G.4 context. Worth noting in art: rotated squares should still be clearly squares (not visually ambiguous with diamonds-as-distinct-shapes).
- **Hexagon vs pentagon in 5+ bin** — both go in the same bin in this lesson (5+ groups them). Later rounds may split into "5 sides" and "6 sides" bins for finer discrimination.
- **Source row layout** — 6 shapes in a single row; on small screens, may need to wrap or scroll. Art/UX to confirm minimum target sizes per `shape-garden.md` (40 pt × 40 pt).

---

## Open Questions

- **Bin count: 3 vs 2** — three bins (3 / 4 / 5+) is the canonical sides setup. For curves-vs-straights, two bins suffice. For color-paired-with-shape, 3–4 bins. Bin count is per-attribute, decided at round-time by activity logic.
- **5+ bin merging** — hexagons and pentagons both 5+. Confirm this is appropriate for K (the standard mentions "hexagons" as a named shape but doesn't require separating them from pentagons by side-count). Suggest 5+ bin at launch; later activities (2nd grade Shape Detective) can refine.
- **Color in this lesson** — all shapes are deep garden green to remove color as a confound. Confirm this doesn't make the source row visually monotonous. Suggest mild brightness variation if needed without introducing color.
- **Lesson length 65 s** — slightly over the 60 s target. The four I-Show drops (3 sides, 4, 5, and the repeat-3) justify the extra time. If playtest shows attention drops, consider removing the repeat-3 (rely on the punchline narration alone).

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft | |
