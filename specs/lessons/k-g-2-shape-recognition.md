# MicroLesson — Shape Recognition (K.G.2)

> "A triangle is still a triangle — sideways, upside-down, big or small." The conceptual move from "this *one* triangle" to "the *kind* triangle." Rotation and scale invariance. First lesson played in Shape Garden.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/shape-garden.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-g-2-shape-recognition` |
| Concept ID | `K.G.2` |
| Standard | K.G.2 — Correctly name shapes regardless of their orientations or overall sizes |
| Region | Sanctuary |
| Introducing activity | Shape Garden |
| Sub-mode | `find-shape` |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 60 s |
| Status | Draft |
| Prerequisite | None — Shape Garden's first lesson |

---

## Setting

Shape Garden's standard scene: enchanted garden, sunlit path, shape-plants visible. For this lesson, the garden contains **only triangles** (in 4 visible variations: upright small, upright large, point-down, rotated 45°) plus 3 distractor non-triangle shapes (a circle, a square, a hexagon). The visual variety of triangles is the point — same kind, different orientations and sizes.

Per `k-activity-patterns.md`: standard K HUD, Sanctuary narrator, Buddy at lower-left on a grassy mound.

---

## Phase 1 — I-Show (≈22 s)

The kid watches. The phase shows multiple triangles in different orientations and sizes, all named "triangle" by the narrator. The conceptual move — *it's the kind that matters* — is the punchline.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Garden visible with 4 triangles and 3 distractor shapes. Music bed in. |
| 0:02 | Narrator opens. |
| 0:05 | Glowing pointer drifts to the **upright small triangle**. Touch → sparkle, narrator: "Triangle." |
| 0:08 | Pointer drifts to the **point-down triangle**. Touch → sparkle, narrator: "Still a triangle." |
| 0:11 | Pointer drifts to the **upright large triangle**. Touch → sparkle, narrator: "Still a triangle." |
| 0:14 | Pointer drifts to the **45°-rotated triangle**. Touch → sparkle, narrator: "Still a triangle." |
| 0:17 | Pointer fades. All four triangles retain their sparkle; the 3 distractor shapes do not. |
| 0:19 | Narrator delivers the insight. |
| 0:22 | "I've got this" button has been visible since 0:15. I-Show ends. |

### Narration script

> *(0:02)* "Watch the triangles in this garden."
>
> *(0:05)* "Triangle." *(upright small)*
>
> *(0:08)* "Still a triangle." *(point-down)*
>
> *(0:11)* "Still a triangle." *(upright large)*
>
> *(0:14)* "Still a triangle." *(rotated)*
>
> *(0:19)* "Triangles can be big or small, point up or point down. They're all triangles."

### Notes for the narrator
- The repetition of "still a triangle" lands the invariance principle without ever using the word "invariance." Each repetition slightly different in inflection.
- "They're all triangles" closes warmly. Conversational, not lecture-y.

---

## Phase 2 — We-Try (≈20 s)

The kid taps triangles in the garden. System steers and completes.

### Setup

| Element | State |
|---|---|
| Scene | Same garden, but **shapes are re-arranged** (different positions) so the kid isn't memorizing locations |
| Triangles visible | 4 (different orientations and sizes — different set from I-Show to encourage generalization) |
| Distractor shapes | 3 (a circle, a square, a star) |
| Progress badge | Hidden until first tap |
| Glow target | First triangle highlights with a soft halo |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Find a triangle." |
| 0:03 | First triangle (a point-down one — different orientation from I-Show's first) halo pulses. |
| → kid taps | Kid taps any triangle → sparkle, badge `found: 1 of 4`, narrator: "Triangle." |
| +0.5 s | Narrator: "Find another." Second triangle halos. |
| → kid taps | Kid taps another triangle → sparkle, badge `found: 2 of 4`, "Still a triangle." |
| +0.5 s | Remaining 2 triangles highlight together; system auto-completes with pointer animation. Narrator: "Triangle. Triangle." |
| +1.0 s | Narrator: "Four triangles. All different, all triangles." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no tap activity (standard hesitation threshold per `stylus-mechanics.md`), the system pulses the next target triangle more brightly. After another 5 s, the system auto-taps with the pointer. Lesson advances either way.

### Pass condition
Any kid tap on a triangle passes. Even a tap on a non-triangle is a soft no-op (no SFX penalty); the lesson continues steering toward triangles.

### Narration script

> *(start)* "Your turn. Find a triangle."
>
> *(after tap 1)* "Triangle."
>
> *(prompt)* "Find another."
>
> *(after tap 2)* "Still a triangle."
>
> *(auto-completing)* "Triangle. Triangle."
>
> *(closing)* "Four triangles. All different, all triangles."

---

## Phase 3 — You-Do (one round of Shape Garden)

Hand off to the activity's `find-shape` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `find-shape`
- **Target shape**: a fresh one (not triangles — to prove the insight transfers). Suggest **circles** for the first You-Do round.
- **Shape count**: 10 total, 4–5 of the target kind, rest distractors (mixed kinds, mixed orientations, mixed sizes)
- **CPA layer**: Concrete (shapes shown with name labels per `shape-garden.md`)
- **Max attempts**: **3** per `micro-lessons.md` first-encounter forgiveness
- **Hints**: enabled at K standard thresholds

### Pass outcome
- Kid taps all target shapes, taps Done (or auto-completes after 3 s of stillness).
- Activity announces "{N}! You found all {N} circles" on round-pass.
- `mastery.standard_practicing` fires for K.G.2.
- Library entry created.
- `firstEncounter` for K.G.2 flips to `false`.

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
| Thumbnail | Four triangles arranged in a 2×2 grid, each in a different orientation/size, with a soft "▲" badge overlay |
| Short label | "Same kind, different look" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~60 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `iShowShape: "triangle"`, `triangleVariants: 4`, `distractors: 3` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `youDoShape: "circle"`, `targetCount: 4` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.G.2
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid taps a distractor shape** during I-Show — no input is honored during I-Show.
- **Kid taps a distractor shape** during We-Try — soft no-op (no SFX penalty in this lesson context; we want the kid focused on triangles, not on what "wrong" feels like). Per the Tap-Pick selection-semantic.
- **All triangles different colors** — the visual variety includes color variation alongside orientation/size. Confirm color-blind-safe palette (the *shape* is what matters; color is incidental decoration).
- **The 4 triangle variants must all be unambiguously triangles** — no degenerate cases (e.g., extremely flat "needle" triangles). The point is that *recognizable* triangles in different orientations all count.

---

## Open Questions

- **Triangle variants in I-Show** — 4 proposed (upright small, point-down, upright large, 45°-rotated). Confirm in playtest these are clearly different but unambiguously triangles.
- **You-Do shape choice** — circles proposed (different from triangles to prove transfer). Alternative: another triangle round to reinforce. Suggest circles to prove the *concept* transfers; subsequent free-play rounds rotate through triangles, squares, hexagons.
- **Distractor count balance** — 3 distractors among 7 shapes in I-Show is ~30% noise. Confirm in playtest this is enough to make the target stand out without making the search trivial.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft | |
