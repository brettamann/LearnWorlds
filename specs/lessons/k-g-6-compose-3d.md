# MicroLesson — Compose 3D Shapes (K.G.6)

> "Simple shapes go together to make bigger structures." Build-a-Habitat's Phase 2 procedure: place 3D pieces onto a completed frame to compose the full habitat. **Fires in Phase 2 of the kid's *first* Build-a-Habitat round**, immediately after the K.G.5 lesson + Phase 1 (per Build-a-Habitat's `intra_round_lesson_chain: true` declaration).

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/build-a-habitat.md`, `specs/lessons/k-g-5-sticks-and-clay.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-g-6-compose-3d` |
| Concept ID | `K.G.6` |
| Standard | K.G.6 — Compose simple shapes to form larger shapes |
| Region | Sanctuary |
| Introducing activity | Build-a-Habitat |
| Phase | Phase 2 (Raise the Habitat) |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 55 s |
| Status | Draft |
| Prerequisite | K.G.5 lesson just completed in the same round's Phase 1 (per the intra-round lesson chain) |

---

## Setting

Build-a-Habitat's standard scene, **mid-round** — Phase 1 has just completed in the **same first round** as the K.G.5 lesson. A completed triangle frame is visible at the build site (the frame the kid just built in K.G.5's You-Do). Phase 2's source pool of 3D pieces has just drifted in (cubes, cones, cylinders, spheres).

- **Completed frame**: solid triangle, foreground. **This is the kid's own frame** from the just-completed Phase 1 — visual continuity is strong.
- **Phase 2 ghost outline**: a single **cube** target sits on top of the triangle frame (the fawn shelter target).
- **Source pool**: 3D pieces drift at the lower-right. ~3 cubes + a few cones/cylinders/spheres as distractors.
- **Resident creature**: the baby fawn still waits at the edge of the clearing.
- **Phase indicator** at the bottom of the screen: "phase 2: raise the habitat"

The lesson begins **immediately after Phase 1 completes** — the kid's just successfully built a frame; now they learn how to compose the 3D structure. The intra-round lesson chain makes this a continuous experience: build, learn, build more.

---

## Phase 1 — I-Show (≈22 s)

The kid watches. The phase establishes that 3D pieces snap onto the frame in specific positions to compose the larger structure.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up mid-round. Triangle frame solid, ghost cube outline visible on top. Source pool drifting in. Music bed continues from Phase 1. |
| 0:02 | Narrator opens. |
| 0:05 | Glowing pointer drifts to the source pool, picks up a **cube** → drags up to the ghost target on the triangle frame. |
| 0:08 | Snap, "thud" + chime. Cube settles onto the frame, ghost outline fades. |
| 0:10 | The structure is complete (triangle frame + cube). It sits there for a moment, looking like a small shelter. |
| 0:12 | The fawn at the edge of the clearing **gets up and walks slowly toward the habitat**. Narrator narrates the moment. |
| 0:16 | Fawn enters the habitat. Sanctuary chime stinger plays. |
| 0:18 | Narrator delivers the insight while the fawn nestles in. |
| 0:21 | "I've got this" button has been visible since 0:13. I-Show ends. |

### Narration script

> *(0:02)* "Now we raise the habitat. The frame is the base — we add shapes on top."
>
> *(0:05)* "A cube. It goes on the triangle frame."
>
> *(0:10)* "Look — a triangle frame and a cube together. The shelter is ready."
>
> *(0:12)* "Here comes the fawn."
>
> *(0:18)* "Simple shapes go together to make bigger structures. A frame and a cube — that's a habitat."

### Notes for the narrator
- "Simple shapes go together to make bigger structures" is the conceptual punchline. Slightly slower delivery.
- "Here comes the fawn" lands a soft emotional beat — the kid sees who they're building for.
- Tone stays warm; the resident creature moment is the activity's payoff.

---

## Phase 2 — We-Try (≈18 s)

The kid drags a 3D piece onto a fresh target.

### Setup

| Element | State |
|---|---|
| Scene | The previous fawn shelter resets (fawn waves and leaves; structure dissolves). A fresh triangle frame appears (or the kid's existing frame from their just-completed Phase 1, whichever matches the round state). |
| Ghost outline | A fresh ghost cube target sits on top of the triangle frame. |
| Source pool | 3D pieces drifting (refilled) |
| Glow target | The ghost cube target halos |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Now you. Put a cube on top." |
| 0:03 | Ghost cube target halo pulses. |
| → kid drags | Kid drags any 3D piece. If a **cube** → snap, narrator: "Cube. The shelter." If a non-cube (cone/cylinder/sphere) → piece returns, narrator: "Try a cube — the square one." |
| +0.5 s | Structure complete (frame + cube). Narrator: "A habitat — frame and cube together." |
| +1.0 s | The (new) fawn walks into the habitat. Sanctuary chime stinger. |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no drag activity (standard hesitation threshold per `stylus-mechanics.md`), the system pulses the cube target more brightly and a glow appears around any cubes in the source pool. After another 5 s, the system auto-drags a cube onto the target.

### Pass condition
Any kid drag onto the cube target passes — even with a non-cube piece (which corrects gently). Even one drag attempt is enough; system completes if needed.

### Narration script

> *(start)* "Now you. Put a cube on top."
>
> *(after correct drag)* "Cube. The shelter."
>
> *(after non-cube drag)* "Try a cube — the square one."
>
> *(closing, after structure complete)* "A habitat — frame and cube together."

---

## Phase 3 — You-Do (continues the same round's Phase 2)

The You-Do is **not a fresh round** — it's the **continuation of the same round** the kid is in. The K.G.5 lesson's You-Do already played as that round's Phase 1; this K.G.6 lesson's You-Do plays as that same round's Phase 2.

### Round parameters

- **Phase context**: continuation of the current Build-a-Habitat round (sub-mode: `simple-shelter`)
- **Phase 1 outcome**: already complete (the kid's triangle frame from a few seconds ago)
- **Phase 2 target**: 1 cube → fawn shelter
- **Resident creature**: baby fawn (still waiting at the edge)
- **CPA layer**: Concrete
- **Max attempts**: **3** per `micro-lessons.md` first-encounter forgiveness
- **Hints**: enabled

### Pass outcome
- Both phases complete; fawn moves in.
- `mastery.standard_practicing` fires for K.G.6 (and K.G.5 if not already practicing).
- Library entry created for K.G.6.
- `firstEncounter` for K.G.6 flips to `false`.
- `habitat.permanent_fixture_built` fires — second fawn shelter (or duplicate; per the activity spec, duplicates don't create new map fixtures, so the kid sees the same Sanctuary view).

### Fail outcome (all 3 Phase 2 attempts miss)
- System auto-completes Phase 2.
- Library entry for K.G.6 filed.
- `firstEncounter` for K.G.6 flips to `false`.
- Mastery status stays `Introduced`.
- Dashboard flag.

---

## Library Entry

| Field | Value |
|---|---|
| Surface (Sanctuary) | Stamp Wall stamp |
| Surface (Wundletown) | Spell Book page |
| Surface (Mathopolis) | Casebook clip |
| Thumbnail | A triangle frame with a cube on top, fawn nestling inside |
| Short label | "Shapes stack into structures" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~55 s |

The K.G.5 and K.G.6 stamps sit **side-by-side** on the Stamp Wall — they're the two-phase pair.

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `frameShape: "triangle"`, `targetPiece: "cube"`, `residentCreature: "fawn"` |
| `lesson.wetry_piece_dragged` | `pieceType`, `correct: Bool`, `wasCorrection: Bool` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `phase2Outcome: "passed|auto"` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.G.6
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

The thank-you collectible from the fawn (a tail-tuft or similar small Sanctuary memento) fires on round-pass as well, per Build-a-Habitat's reward design.

---

## Edge Cases

- **Kid drags a cube onto the frame in the wrong spot** — frame is solid; only the ghost target position accepts the cube. Off-target drops return the cube to source. Confirm in playtest whether kids try to "place anywhere"; if so, consider letting any frame-adjacent spot snap.
- **Kid drags a cone instead of a cube** — cone returns to source with the corrective narration. Helps the kid notice piece-type differences for K.G.6's broader "compose" intent.
- **The fawn was already used in the K.G.5 lesson's You-Do** — by the time the K.G.6 lesson fires (round 2 of Build-a-Habitat), the fawn is the same creature character returning for another visit (or a fresh fawn — designer choice). Confirm narrative consistency: per the K.G.5 spec, each habitat completion is treated as a new visual reward, not a long-term character. Same here.
- **3D piece visual differentiation** — cubes, cones, cylinders, spheres must be visually distinct at the source-pool size. Confirm with art; the K kid needs to recognize "cube" by sight without ambiguity.

---

## Open Questions

- ~~**Lesson firing timing**~~ **Resolved 2026-05-30**: Build-a-Habitat declares `intra_round_lesson_chain: true`. K.G.5 fires in Phase 1, K.G.6 fires in Phase 2 of the **same first round**. The kid never encounters Phase 2 cold.
- **Cube as the only Phase 2 target in the first K.G.6 lesson** — keeps things simple. Subsequent rounds (creature-home, grand-habitat) introduce cones, cylinders, spheres through play (not lesson). Confirm this isn't too narrow an introduction.
- **First-round duration with chained lessons** — total ~3–4 min for the first Build-a-Habitat round (K.G.5 lesson + Phase 1 + K.G.6 lesson + Phase 2). Confirm in playtest this isn't fatiguing for K kids; alternative is to split the chain (K.G.5 in round 1, K.G.6 in round 2) at the cost of cold Phase 2.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft | |
| 2026-05-30 | Updated to reflect Build-a-Habitat's `intra_round_lesson_chain: true` — this lesson fires in the same first round's Phase 2, immediately after K.G.5 + Phase 1 (not in a separate second round). Setting, Phase 3 (You-Do as continuation), and Open Questions updated accordingly | |
