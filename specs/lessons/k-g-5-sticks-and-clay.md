# MicroLesson — Sticks and Clay (K.G.5)

> "Corners with clay, lines with sticks." The procedure for building 2D shapes from components — clay balls at vertices, sticks at edges. First lesson played in Build-a-Habitat. Also establishes the **two-phase rhythm** of the activity (this is Phase 1; Phase 2 will come).

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/build-a-habitat.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-g-5-sticks-and-clay` |
| Concept ID | `K.G.5` |
| Standard | K.G.5 — Model and create shapes from components such as sticks and clay balls |
| Region | Sanctuary |
| Introducing activity | Build-a-Habitat |
| Phase | Phase 1 (Sticks & Clay) |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 65 s |
| Status | Draft |
| Prerequisite | None — Build-a-Habitat's first lesson (often the kid's first encounter with K.G shapes in a building context) |

---

## Setting

Build-a-Habitat's standard scene: grassy Sanctuary clearing, faint foundation circle at the build site. For this lesson, the target is a **triangle frame** (the smallest, most teachable shape).

- **Ghost outline**: a bright triangle outline visible at the build site, with **3 vertex indicators** (small empty circles at the corners) and **3 edge positions** (faint dotted lines along the sides).
- **Source pool**: clay balls and sticks drift in a corner at the lower-right. ~5 of each visible.
- **Resident creature**: a baby fawn waits at the edge of the clearing (the future occupant). Visible but patient.

Per `k-activity-patterns.md`: standard K HUD, Sanctuary narrator, Buddy at lower-left on a log.

---

## Phase 1 — I-Show (≈25 s)

The kid watches. The phase establishes the **corners-then-edges** procedure and the conceptual move that "shapes are built from parts."

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Empty clearing with triangle ghost outline at the build site. Source pool drifting at lower-right. Fawn waiting at the edge. Music bed in. |
| 0:02 | Narrator opens. |
| 0:05 | Narrator: "First, the corners." Glowing pointer drifts to the source pool. |
| 0:07 | Pointer picks up a **clay ball** → drags to vertex 1 (top of triangle). Snap, warm "thunk." |
| 0:10 | Pointer picks up a second clay ball → vertex 2 (lower-left). Snap. |
| 0:13 | Pointer picks up a third clay ball → vertex 3 (lower-right). Snap. |
| 0:16 | Narrator: "Now the sticks." |
| 0:18 | Pointer picks up a **stick** → drags to edge 1 (between vertex 1 and vertex 2). Snap, "click" + chime. |
| 0:21 | Pointer picks up a second stick → edge 2 (between vertex 2 and vertex 3). Snap. |
| 0:24 | Pointer picks up a third stick → edge 3 (between vertex 3 and vertex 1). Snap. |
| 0:25 | **Frame solidifies** — outline brightens, lift stinger plays, ghost becomes a solid triangle frame. |
| 0:26 | Narrator delivers the insight. |
| 0:29 | "I've got this" button has been visible since 0:18. I-Show ends. (Note: this lesson does NOT advance to Phase 2 — that's covered by the K.G.6 lesson later.) |

### Narration script

> *(0:02)* "Let's build the frame for a fawn shelter. A triangle."
>
> *(0:05)* "First, the corners. The clay balls go where the lines meet."
>
> *(0:07–0:14, syncopated with each placement)* "One. Two. Three."
>
> *(0:16)* "Now the sticks. They go along the sides, between the corners."
>
> *(0:18–0:23, syncopated)* "One. Two. Three."
>
> *(0:26)* "A triangle frame. Corners with clay, lines with sticks. That's how we make shapes."

### Notes for the narrator
- "Corners with clay, lines with sticks" is the kid-language version of "vertices with vertex-objects, edges with edge-objects." Land it slowly — this is the procedural rule the kid takes away.
- "That's how we make shapes" generalizes beyond triangle: this same procedure will work for squares, rectangles, pentagons.
- Slight celebratory lift on the frame solidify — the kid built something.

---

## Phase 2 — We-Try (≈22 s)

The kid drags a few components; system completes.

### Setup

| Element | State |
|---|---|
| Scene | Empty clearing. **Triangle ghost outline** again (same shape — visual continuity from I-Show). |
| Source pool | Clay balls and sticks drifting (refilled) |
| Glow target | First vertex (top of triangle) highlights with a soft halo |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Start with the corners." |
| 0:03 | First vertex halo pulses. |
| → kid drags | Kid drags any clay ball. If dropped on the highlighted vertex → snap, narrator: "One corner." |
| | If dropped on the wrong vertex → snap anyway (any vertex is fine; corners are interchangeable). Narrator: "Corner." |
| | If dropped on an edge → clay returns to source. Narrator: "Corners first." |
| +0.5 s | Second vertex halo pulses. |
| → kid drags | Kid drags another clay ball; same flow. |
| +0.5 s | Third vertex auto-completes via pointer animation. Narrator: "Three." |
| +1.0 s | Narrator: "Now the sticks." First edge halo pulses. |
| → kid drags | Kid drags a stick; same correction patterns. |
| +0.5 s | Remaining sticks auto-complete. Narrator: "Two. Three." |
| 0:22 | Frame solidifies. Narrator: "A triangle frame — corners and lines together." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no drag activity (standard hesitation threshold per `stylus-mechanics.md`), the system pulses the next target position more brightly. After another 5 s, the system auto-drags. Lesson advances either way.

### Pass condition
Any kid drag onto a valid target passes. Even one drag is enough; system completes the rest.

### Narration script

> *(start)* "Your turn. Start with the corners."
>
> *(after vertex drop)* "{One/Two/Three} corner{s}."
>
> *(after edge attempt with clay)* "Corners first."
>
> *(stick transition)* "Now the sticks."
>
> *(after stick drop)* "{One/Two/Three}."
>
> *(closing, after frame solidifies)* "A triangle frame — corners and lines together."

---

## Phase 3 — You-Do (one round of Build-a-Habitat)

Hand off to the activity's `simple-shelter` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `simple-shelter`
- **Target frame**: triangle (matches the lesson, building visual continuity)
- **Phase 1 target**: 3 clay balls + 3 sticks → triangle frame
- **Phase 2 target**: 1 cube → fawn shelter
- **Resident creature**: baby fawn
- **CPA layer**: Concrete (per K starting layer)
- **Max attempts**: **3** per `micro-lessons.md` first-encounter forgiveness
- **Hints**: enabled

### Pass outcome (Phase 1 + Phase 2 both complete)
- Kid builds the triangle frame in Phase 1, places the cube in Phase 2.
- Fawn moves into the habitat; round-pass celebration fires.
- `mastery.standard_practicing` fires for K.G.5.
- **K.G.6 is also touched** during Phase 2, but per the multi-introduced-concepts queue rule in `micro-lessons.md`, K.G.6's first-encounter is *deferred*; the round counts as K.G.6 exposure but no mastery event fires for K.G.6 yet. (See Open Questions for the alternative.)
- Library entry created for K.G.5.
- `firstEncounter` for K.G.5 flips to `false`.

### Fail outcome (Phase 1 fails 3 attempts)
- System auto-completes Phase 1 via demonstration.
- Phase 2 still runs (kid still gets K.G.6 exposure).
- Library entry for K.G.5 filed.
- `firstEncounter` for K.G.5 flips to `false`.
- Mastery status for K.G.5 stays `Introduced`.
- Dashboard flag.

---

## Library Entry

| Field | Value |
|---|---|
| Surface (Sanctuary) | Stamp Wall stamp |
| Surface (Wundletown) | Spell Book page |
| Surface (Mathopolis) | Casebook clip |
| Thumbnail | A triangle frame with 3 clay balls visible at vertices and 3 sticks along edges, against a soft Sanctuary background |
| Short label | "Corners and lines make shapes" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~65 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `targetFrame: "triangle"`, `iShowComponents: {clay: 3, stick: 3}` |
| `lesson.wetry_component_placed` | `componentType` (clay/stick), `targetPosition`, `correct: Bool`, `wasCorrection: Bool` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `phase1Outcome: "passed|auto"`, `phase2Outcome: "passed|auto"` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.G.5
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

Build-a-Habitat's `habitat.permanent_fixture_built` event also fires from the You-Do round if both phases complete — the kid's first habitat begins populating the Sanctuary Hub view.

---

## Edge Cases

- **Kid tries to place a clay ball on an edge position** — clay returns to source; narrator: "Corners first." This is a procedural correction, not a failure.
- **Kid tries to place a stick before all clay balls are placed** — stick can still snap to its edge target (edges don't require both clay balls present yet). After-the-fact, when both clay balls are in place, the stick visually "settles." Confirm this works in implementation (might be cleaner to require clay balls first and reject the stick until then; tune per playtest).
- **Vertex indicators in CPA Pictorial vs Concrete** — Concrete: bright empty circles; Pictorial: faint dots. The lesson uses Concrete (vertex indicators bright).
- **Source pool empties during the lesson** — pool auto-refills; the visible school just looks like ~5 of each at a time.
- **The fawn at the edge of the clearing** — visible from lesson start; does not move until round-pass when it enters the habitat (Phase 3 You-Do, after Phase 2 completes). Confirm the fawn's idle behavior is subtle (looking around, occasional tail flick) so it doesn't compete with the build action for attention.

---

## Open Questions

- **Lesson length 65 s** — slightly over the 60 s target. The 6 component placements (3 clay + 3 sticks) justify this. If playtest shows attention drops, consider showing only 2 clay balls + 2 sticks in I-Show (the kid generalizes the procedure from 4 placements rather than 6).
- **Should the lesson include the Phase 1 → Phase 2 transition?** Current draft ends at Phase 1 completion; the kid sees Phase 2 for the first time in the You-Do round (without a lesson, since K.G.6's lesson is queued for next round). Alternative: include a brief "now Phase 2 begins" beat at lesson end to set expectations. Trade-off: extends lesson length further but smooths the transition.
- **Snap correction strictness in We-Try** — currently very forgiving (any clay on any vertex, any stick on any edge, all narrated). Confirm this doesn't undermine the "corners first, sticks second" procedure. Suggest keeping the stick-on-vertex correction strict (sticks really do belong on edges) while letting clay-on-any-vertex be loose.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first K lesson for a two-phase activity (Build-a-Habitat) | |
