# MicroLesson — Flat or Solid (K.G.3)

> "Flat shapes live on paper. Solid shapes you can see from many sides." The 2D-vs-3D distinction made tactile by the reflecting pond: 3D shapes rotate to show their depth; 2D shapes stay paper-flat.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/shape-garden.md`, `specs/lessons/k-g-2-shape-recognition.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-g-3-flat-or-solid` |
| Concept ID | `K.G.3` |
| Standard | K.G.3 — Identify shapes as two-dimensional ("flat") or three-dimensional ("solid") |
| Region | Sanctuary |
| Introducing activity | Shape Garden |
| Sub-mode | `flat-or-solid` |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 60 s |
| Status | Draft |
| Prerequisite | K.G.2 lesson completed (kid can recognize shape kinds) |

---

## Setting

Shape Garden's standard scene with the **reflecting pond visible on the right**. The pond is the key visual cue: **3D shapes live in the water** (where they can be seen from all sides), **2D shapes live on the path** (paper-flat).

For this lesson:
- **Path (left)**: a row of 4 shapes — a 2D circle, a 2D square, a 2D triangle, plus one 3D shape that's *temporarily on the path* (a cube — this one will move to the pond during the lesson).
- **Pond (right)**: 2 existing 3D shapes already in the water — a sphere (jelly-bubble) and a cone (mushroom gnome). Both rotate gently to show 3D-ness.
- **Bins** (lower portion): two bins — "**flat**" (paper icon) and "**solid**" (cube icon) — sit between the path and the pond.

The visual story is built into the geography: shapes from the path and the pond have different relationships to the bins.

---

## Phase 1 — I-Show (≈25 s)

The kid watches. The phase establishes the distinction by showing both kinds in their natural habitats, then demonstrating the sort.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Path on left with 4 shapes; pond on right with 2 rotating 3D shapes. Bins visible at the bottom. Music bed in. |
| 0:02 | Narrator opens by drawing attention to the path. |
| 0:04 | A subtle highlight wash sweeps across the 3 path shapes (circle, square, triangle). They stay paper-flat. |
| 0:06 | Narrator: "Flat. You see them from one side — like a drawing on paper." |
| 0:09 | Camera attention shifts to the pond. The 2 pond shapes (sphere, cone) glow softly. They continue their gentle rotation. |
| 0:11 | Narrator: "Solid. You can see them from many sides." |
| 0:14 | Glowing pointer drifts to the **circle** on the path. Touch → circle lifts slightly. Pointer drags it to the **"flat" bin**. Soft "plop." Narrator: "Circle — flat." |
| 0:18 | Pointer drifts to the **cube** on the path (the misfit). Touch → cube lifts and **starts rotating** (its 3D-ness reveals itself). Pointer drags it to the **"solid" bin**. Narrator: "Cube — solid." |
| 0:22 | Narrator delivers the insight. |
| 0:25 | "I've got this" button has been visible since 0:18. I-Show ends. |

### Narration script

> *(0:02)* "Look at the path. These shapes are flat."
>
> *(0:06)* "Flat. You see them from one side — like a drawing on paper."
>
> *(0:09)* "Now look at the pond. These shapes are solid."
>
> *(0:11)* "Solid. You can see them from many sides."
>
> *(0:14)* "Circle — flat." *(drops in flat bin)*
>
> *(0:18)* "Cube — solid." *(drops in solid bin)*
>
> *(0:22)* "Flat shapes live on paper. Solid shapes have many sides."

### Notes for the narrator
- The "live on paper" / "have many sides" phrasing is the kid-language version of "2D vs 3D." The standard terms (`two-dimensional`, `three-dimensional`) appear in the Standard column but the lesson uses the kid-friendly versions.
- "From one side" / "from many sides" is the operational distinction — what the kid actually *sees* differently.
- The cube rotating when picked up is the key visual moment. Land it.

---

## Phase 2 — We-Try (≈20 s)

The kid drags shapes into the two bins.

### Setup

| Element | State |
|---|---|
| Scene | Fresh shape row at the top — 4 mixed shapes (a 2D triangle, a 2D hexagon, a 3D cylinder, a 3D sphere). The pond on the right has no shapes left (they've been "moved to bins" off-screen). |
| Bins | "flat" and "solid" bins visible at the bottom |
| 3D shapes | Gently rotating to signal their 3D-ness |
| 2D shapes | Static, paper-flat |
| Progress badge | Hidden until first drop |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Some are flat. Some are solid. Put them in the right baskets." |
| 0:03 | First shape (the 2D triangle) gets a soft halo. |
| → kid drags | Kid drags the triangle. If dropped on **flat** bin → snap, badge `sorted: 1 of 4`, narrator: "Triangle — flat." If dropped on **solid** bin → shape returns to source, narrator: "Triangles are flat. Try the flat basket." |
| +0.5 s | Next shape (the 3D cylinder) gets a halo. |
| → kid drags | Kid drags the cylinder. Same correction pattern if wrong. |
| +0.5 s | Remaining 2 shapes auto-complete with pointer animation. Narrator names each as it sorts. |
| +1.0 s | Narrator: "Four shapes. Two flat. Two solid." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no drag activity, the system pulses both bins. Narrator: "Pick a shape and drag it to a basket — flat or solid." After another 5 s, the system auto-drags the next shape into its correct bin.

### Pass condition
Any kid drag of any shape onto either bin passes. Wrong-bin drops return the shape (with corrective narration) and don't count as a pass, but the lesson advances after the kid's *next* successful drop. If the kid never makes a successful drop, the auto-complete handles it.

### Narration script

> *(start)* "Your turn. Some are flat. Some are solid. Put them in the right baskets."
>
> *(after correct drop)* "{Shape} — {flat/solid}."
>
> *(after incorrect drop)* "{Shapes plural} are {flat/solid}. Try the {flat/solid} basket."
>
> *(auto-completing)* "{Shape} — {flat/solid}."
>
> *(closing)* "Four shapes. Two flat. Two solid."

---

## Phase 3 — You-Do (one round of Shape Garden)

Hand off to the activity's `flat-or-solid` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `flat-or-solid`
- **Shape count**: 6 mixed (3 of each kind) — a fresh combination from the lesson
- **Source layout**: row of 6 shapes at top
- **Bins**: "flat" and "solid"
- **CPA layer**: Concrete (shapes show their name labels)
- **Max attempts**: **3** per `micro-lessons.md` first-encounter forgiveness
- **Hints**: enabled

### Pass outcome
- Kid sorts all 6 shapes correctly, taps Done (or auto-completes after 3 s of stillness).
- Activity announces "All sorted! Three flat and three solid."
- `mastery.standard_practicing` fires for K.G.3.
- Library entry created.
- `firstEncounter` for K.G.3 flips to `false`.

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
| Thumbnail | Split image: left half shows a paper-flat circle and square; right half shows a rotating sphere and cube (with motion lines indicating rotation) |
| Short label | "Flat or solid" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~60 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `pathShapes: [...]`, `pondShapes: [...]`, `iShowSortedShapes: ["circle", "cube"]` |
| `lesson.wetry_drop` | `shape`, `bin`, `correct: Bool`, `wasCorrection: Bool` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `correctSorts`, `incorrectSorts` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.G.3
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid drags a 2D shape into the pond** — pond is not a drop target; shape returns to source. Per `shape-garden.md`.
- **Kid drags a 3D shape into the pond instead of the solid bin** — same; pond is decorative, not a drop target. Subtle hint after second pond-drop attempt: "Drop it in the **solid basket** — that's the one for 3D shapes."
- **3D shape rotation must be visually distinct from 2D** — if the kid can't tell the difference visually, the lesson fails its purpose. Confirm rotation rate (~0.2 rev/s per `shape-garden.md`) is perceptible without being dizzying.
- **The temporary cube on the path** (I-Show setup) — exists to demonstrate "a 3D shape can appear among 2D ones; what makes it 3D is how it behaves when you interact." Pre-launch art note: confirm the cube doesn't look 2D in its still state, or the demo loses force.

---

## Open Questions

- **Audio cue for "lift and rotate"** when picking up a 3D shape — should there be a small "ahh, it's 3D" reveal sound? Suggest yes (a subtle 3D-air-whoosh) but tune in playtest.
- **Bin icon design** — "flat" = paper icon; "solid" = cube icon. Confirm these read clearly to non-readers; consider adding a tiny text label below the icon for the CPA Concrete layer.
- **Should the lesson explicitly show that 3D shapes *also* look flat when frozen?** E.g., briefly stop rotation to show "from this angle alone, it could look 2D." Probably over-complicating; defer.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft | |
