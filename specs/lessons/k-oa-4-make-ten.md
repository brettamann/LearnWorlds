# MicroLesson — Make Ten (K.OA.4)

> "When you have some, figure out how many more it takes to make ten." The first move toward the **make-a-ten strategy** that powers most of 1st-grade addition. Builds on K.OA.3 (decomposition).

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/ten-frame-pond.md`, `specs/lessons/k-oa-3-decomposition.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-oa-4-make-ten` |
| Concept ID | `K.OA.4` |
| Standard | K.OA.4 — Make sums of 10 using any number from 1 to 9 |
| Region | Sanctuary |
| Introducing activity | Ten-Frame Pond |
| Sub-mode | `make-ten` |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 60 s |
| Status | Draft |
| Prerequisite | K.OA.3 lesson completed (ten-frame is now familiar) |

---

## Setting

Ten-Frame Pond's standard scene. The ten-frame opens **partially full** — this is the K.OA.4 setup. Specifically: **7 fish are pre-placed**, scattered across the 10 pads (3 in the top row, 4 in the bottom row, leaving 3 empty cells).

Pre-placed fish have a **soft pearl-white halo** indicating "these are already here — you can't move them" (per `ten-frame-pond.md`).

Source pool drifts below as usual. Count badge starts visible showing **7** (already populated).

---

## Phase 1 — I-Show (≈22 s)

The kid watches. The phase establishes "we have some; we need to figure out how many more to make ten" — the conceptual move from arbitrary counts to a target of 10.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Frame partially full (7 fish, pre-placed). Count badge **7**. The 3 empty pads have a **soft cyan outline** indicating "these are still open." |
| 0:02 | Narrator opens. |
| 0:05 | Narrator: "We have seven." Badge **7** pulses gently. |
| 0:07 | Narrator: "Watch the empty spots." The 3 empty cells pulse softly. |
| 0:09 | Glowing pointer drifts to the source pool, picks up a fish → places it on the first empty pad. Snap, badge **8**, narrator: "Eight." |
| 0:12 | Pointer picks up another fish → second empty pad. Snap, badge **9**, narrator: "Nine." |
| 0:15 | Pointer picks up a third fish → third empty pad. Snap, badge **10**, narrator: "Ten." |
| 0:16 | **Frame collapses to a glowing ten pearl** — fish merge with the shimmer-collapse animation (per `ten-frame-pond.md`). Pearl hovers above where the frame was. |
| 0:18 | Narrator: "Ten! We had seven. We needed three more." |
| 0:21 | Narrator delivers the strategic insight. |
| 0:24 | "I've got this" button has been visible since 0:17. I-Show ends. |

### Narration script

> *(0:02)* "Look — the pond already has fish on it."
>
> *(0:05)* "We have seven."
>
> *(0:07)* "Watch the empty spots."
>
> *(0:09–0:15, synced with each placement)* "Eight. Nine. Ten."
>
> *(0:18)* *(after pearl collapse)* "Ten! We had seven. We needed three more."
>
> *(0:21)* "When the pond is full, that's ten. Count what's empty — that's how many more to add."

### Notes for the narrator
- "Count what's empty — that's how many more to add" is the strategy. It's the K version of "find the complement to 10," which becomes the 1st-grade Make-a-Ten spell.
- "When the pond is full, that's ten" — anchors the ten-frame's full-state as the meaning of "ten."
- Tone stays warm; no hurry.

---

## Phase 2 — We-Try (≈20 s)

The kid drags the missing fish onto a frame that's been pre-populated.

### Setup

| Element | State |
|---|---|
| Scene | Frame pre-populated with **6 fish** (a different starting amount from I-Show to discourage memorization) |
| Pre-placed fish | Pearl-white halo, non-interactive |
| Empty cells | 4 cells with soft cyan outline |
| Source pool | Standard drifting school |
| Count badge | Starts visible at **6** |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Now you. We have six. Make ten." |
| 0:03 | First empty cell halo pulses (the cell closest to a kid-handed area). |
| → kid drags | Kid drags a fish → snap, badge **7**, narrator: "Seven." |
| +0.5 s | Second empty cell halo pulses. Narrator: "Keep going." |
| → kid drags | Kid drags a fish → snap, badge **8**, narrator: "Eight." |
| +0.5 s | Remaining 2 empty cells highlight together. System auto-completes via pointer animation: drags 2 more fish in. Narrator: "Nine. Ten." |
| 0:18 | Frame collapses to ten pearl. Narrator: "Ten! We had six. We needed four more." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no drag activity (standard hesitation threshold per `stylus-mechanics.md`), the system pulses the next empty cell more brightly and the narrator says "Drag one from the school." After another 5 s, the system auto-taps with the pointer. Lesson advances either way.

### Pass condition
Any kid drag of any fish onto an empty cell passes. Even one drag is enough; the system completes the rest.

### Narration script

> *(start)* "Now you. We have six. Make ten."
>
> *(after drop 1)* "Seven."
>
> *(prompt)* "Keep going."
>
> *(after drop 2)* "Eight."
>
> *(auto-completing)* "Nine. Ten."
>
> *(closing, after pearl)* "Ten! We had six. We needed four more."

---

## Phase 3 — You-Do (one round of Ten-Frame Pond)

Hand off to the activity's `make-ten` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `make-ten`
- **Starting amount**: **8** (yet another starting number, again to discourage memorization)
- **Empty cells**: 2
- **Target**: 10 (always, in this sub-mode)
- **CPA layer**: Concrete (K starting layer)
- **Max attempts**: **3** (first-encounter extra forgiveness)
- **Hints**: enabled at K standard thresholds

### Pass outcome
- Kid drags 2 fish onto empty cells, frame collapses to ten pearl.
- Activity announces "Ten! You had eight. You needed two more" on round-pass.
- `mastery.standard_practicing` fires for K.OA.4.
- Library entry created.
- `firstEncounter` for K.OA.4 flips to `false`.

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
| Thumbnail | Ten-frame with 7 fish on it, 3 empty cells glowing cyan, a small arrow pointing at the gaps, badge **7 → 10** |
| Short label | "Filling up to ten" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~60 s |

This stamp sits next to the K.OA.3 stamp on the Stamp Wall — the kid sees the conceptual progression at a glance.

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `iShowStartingAmount: 7`, `weTryStartingAmount: 6`, `youDoStartingAmount: 8` |
| `lesson.wetry_completed` | `kidDrags: Int`, `autoDrags: Int`, `latencyMs: Int` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `startingAmount: 8`, `missingDragged: 2` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.OA.4
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid tries to drag a pre-placed (pearl-haloed) fish** — fish doesn't lift. Soft "this one's already here" tooltip appears briefly. No penalty.
- **Kid drags more fish than the gap allows** (e.g., target is 10, kid drags an 11th fish thinking they need to keep going) — the 11th drop on an occupied cell returns to the source. The frame still collapses at 10 as designed.
- **Kid drags a fish onto an *already-pearl* frame** — the pearl is non-interactive in the lesson. Fish returns to source.
- **Pre-placement arrangement** — fish are scattered, not packed (top row has 3, bottom row has 4 for the I-Show 7-start). Confirm in art that scattered placement is visually clear without looking accidental.
- **Empty cells use cyan outline** — must be color-blind safe (cyan vs occupied pad green is one combo to verify; alternative is to use a dashed border or pulse animation rather than relying on color).

---

## Open Questions

- **Starting amounts (7, 6, 8) across I-Show, We-Try, You-Do** — different on purpose so the kid doesn't memorize "the answer is 3." Confirm this isn't confusing; alternative is to use the same starting amount in all three phases (downside: the kid learns the answer not the strategy).
- **Empty-cell visual** — cyan outline proposed. Could also be a soft pulsing glow, a dashed circle, a question mark on the pad. Defer to art direction.
- **Pre-placement spatial pattern** — scattered vs row-filled vs anchored to one side? Scattered is most natural for "we have 7 from a previous round" but may visually compete with the empty cells. Worth playtesting.
- **Tap-to-remove behavior on the kid's placed fish** — if a kid places a fish then immediately removes it (tap), the count ticks back down. Lesson should continue to advance via auto-completion if the kid pauses too long. Confirm this works cleanly.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft | |
| 2026-05-30 | Normalized We-Try hesitation threshold from 4 s to 5 s (matches `stylus-mechanics.md` standard) | |
