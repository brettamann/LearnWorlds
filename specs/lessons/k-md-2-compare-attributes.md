# MicroLesson — Directly Compare Two by Attribute (K.MD.2)

> "Put them side by side. The one that goes farther is longer; the side that tips down is heavier." Introduces direct comparison of two objects by length (measuring stick) and by weight (balance scale). Second Caretaker's Bench lesson, queued for the kid's first entry to `compare-two`.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/shared/stylus-mechanics.md`, `specs/activities/kindergarten/caretakers-bench.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-md-2-compare-attributes` |
| Concept ID | `K.MD.2` |
| Standard | K.MD.2 — Directly compare two objects with a measurable attribute in common, to see which object has "more of"/"less of" the attribute |
| Region | Sanctuary |
| Introducing activity | Caretaker's Bench |
| Sub-mode | `compare-two` |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 75 s |
| Status | Draft |
| Prerequisite | K.MD.1 introduced (attribute words are the vocabulary K.MD.2 builds on). Not blocking — lesson stands on its own if reached first. |

---

## Setting

Caretaker's Bench's standard scene. This lesson covers **both tools** in two short demonstrations — length (measuring stick) and weight (balance scale) — so the kid sees both comparison modes before going solo. The bench is staged with two object pairs in sequence.

- **Length pair (I-Show)**: a **feather** (long) and a **twig** (shorter). Measuring stick visible above the bench, fixed in position.
- **Weight pair (We-Try)**: a **rock** and an **acorn**. Balance scale at the right side of the bench, fixed in position with two empty pans.
- Object pairs are visibly distinguishable so the answer is unambiguous.

Per `k-activity-patterns.md`: standard K HUD, Sanctuary narrator, Buddy at lower-left on an overturned crate.

---

## Phase 1 — I-Show (≈30 s)

The kid watches the pointer compare a pair by length using the measuring stick.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Feather and twig on the bench surface. Measuring stick fixed above them. Music bed in. |
| 0:02 | Narrator opens. |
| 0:05 | Narrator: "Which is longer — this feather, or this twig?" Brief camera nudge over each object. |
| 0:08 | Glowing pointer picks up the **feather** → drags onto the measuring stick. The stick "magnetically" aligns the feather's left end to the stick's zero mark. Snap. |
| 0:11 | Pointer picks up the **twig** → drags onto the stick beneath the feather. The twig's left end also aligns at zero. Snap. Both objects now visible along the stick, left ends matched. |
| 0:14 | A **soft glow** marks the right end of each object. The feather's glow is clearly farther along the stick than the twig's. |
| 0:16 | Narrator delivers the rule. |
| 0:19 | Pointer drifts to the **feather** and taps it (confirming the longer object). Sparkle on the feather; warm "tick" cue. |
| 0:21 | Narrator confirms. |
| 0:23 | Brief beat. Pointer drifts away. |
| 0:24 | Narrator previews the weight half. |
| 0:28 | "I've got this" button has been visible since 0:18. I-Show ends. |

### Narration script

> *(0:02)* "Which is longer — this feather, or this twig?"
>
> *(0:08, as feather aligns)* "Put them side by side on the measuring stick. Line up the ends."
>
> *(0:14, as the glow marks show)* "See — the feather reaches farther."
>
> *(0:19, after pointer taps feather)* "The feather is longer."
>
> *(0:23)* "Put them side by side. The one that goes farther is longer."
>
> *(0:24)* "We can compare weight, too — with a scale."

### Notes for the narrator
- "Put them side by side. The one that goes farther is longer" is the kid-language version of the procedural rule for length comparison. Land it slowly.
- "Line up the ends" is essential — without it, kids will compare objects placed at different starting points (a common misconception). Make this beat clear.
- The weight preview at 0:24 prepares the kid for the We-Try switch to the balance scale.

---

## Phase 2 — We-Try (≈30 s)

The kid uses the **balance scale** to compare a rock and an acorn by weight.

### Setup

| Element | State |
|---|---|
| Scene | Workbench. Feather and twig are gone; **rock** and **acorn** on the bench surface. Measuring stick fades out; **balance scale** fades in to the right, both pans empty. |
| Glow target | The **rock** halos softly; the **left pan** of the scale halos to match. |
| Pointer | Gone — the kid's stylus is the pointer now. |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Which is heavier — the rock, or the acorn? Put them on the scale." Rock + left pan halos pulse. |
| → kid drags | Kid drags the rock toward the scale. |
| | If dropped on the left pan → snap, "thunk" SFX. Left pan dips slightly (only one object so far). Narrator: "Rock on one side." |
| | If dropped elsewhere → rock returns to bench. |
| +0.5 s | Acorn halos; **right pan** halos. Narrator: "Now the acorn." |
| → kid drags | Kid drags the acorn → right pan. Snap, "thunk." |
| +0.5 s | Both objects now on the scale. The scale **tips dramatically toward the rock side** with a mechanical "tilt-creak" SFX. The rock side dips low; the acorn side rises. The animation takes ~1.5 s for clarity. |
| +1.0 s after tip | A **soft glow** appears on the rock side of the scale (the heavier side). Narrator: "Look — the scale tips toward the heavier one." |
| +0.5 s | Indicator: a small "tap to confirm" prompt appears, with the **rock** halo brightening. Narrator: "Tap the heavier one." |
| → kid taps | Kid taps the rock (or the acorn). |
| | If rock → sparkle on rock, chime. Narrator: "The rock is heavier." |
| | If acorn → soft "nope." Narrator: "Look at the scale — it tips down toward the rock." Rock halos brighter. Retry. |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no input at any step, the halo on the next-expected target brightens and the narrator gently repeats the cue. After another 5 s, the system auto-completes the step. Lesson advances either way.

### Pass condition
Any kid drag onto either pan + any tap on either object counts as participation. The lesson advances regardless of perfect accuracy.

### Narration script

> *(start)* "Your turn. Which is heavier — the rock, or the acorn? Put them on the scale."
>
> *(after rock placed)* "Rock on one side."
>
> *(prompting acorn)* "Now the acorn."
>
> *(after scale tips)* "Look — the scale tips toward the heavier one."
>
> *(tap prompt)* "Tap the heavier one."
>
> *(after correct tap)* "The rock is heavier."
>
> *(after wrong tap)* "Look at the scale — it tips down toward the rock."

---

## Phase 3 — You-Do (one round of Caretaker's Bench)

Hand off to the activity's `compare-two` sub-mode for a real round. The round uses **length** (measuring stick) — different from We-Try's weight — so the kid demonstrates transfer across both tools the lesson covered.

### Round parameters

- **Sub-mode**: `compare-two`
- **Attribute**: length
- **Object pair**: a **ribbon** (long) and a **wooden spoon** (shorter)
- **Tool**: measuring stick (fixed in position)
- **CPA layer**: Concrete (stick shows tick marks and labels)
- **Max attempts**: **3** per `micro-lessons.md` first-encounter forgiveness
- **Hints**: enabled at K standard thresholds

### Pass outcome
- Kid drags both objects onto the stick (aligned at zero), then taps the longer one (ribbon).
- `mastery.standard_practicing` fires for K.MD.2.
- Library entry created.
- `firstEncounter` for K.MD.2 flips to `false`.

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
| Thumbnail | A two-panel image: left shows a feather and twig aligned on a measuring stick; right shows a balance scale tipping toward a rock |
| Short label | "Side by side, which is more?" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~75 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `iShowAttribute: "length"`, `iShowPair: ["feather", "twig"]`, `weTryAttribute: "weight"`, `weTryPair: ["rock", "acorn"]` |
| `lesson.wetry_object_placed` | `object`, `targetPan` (left/right), `correctPosition: Bool` |
| `lesson.wetry_comparison_tapped` | `tappedObject`, `correct: Bool` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `youDoAttribute: "length"`, `youDoPair: ["ribbon", "spoon"]`, `firstTapCorrect: Bool` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.MD.2
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid drops both objects on the same pan** (We-Try) — second object replaces the first, or rejects with soft "nope," per `caretakers-bench.md` decision pending. Lesson defers to whatever the activity ships; if rejection, narrator says: "One on each side." Confirm UX choice during implementation.
- **Kid taps the scale itself instead of an object** — no-op; narrator gently re-prompts: "Tap the heavier object — the rock or the acorn."
- **Equal weights / equal lengths** — not used in the lesson (We-Try and You-Do pairs are visibly distinct). Equal pairs are out of scope at launch per `caretakers-bench.md`'s decision note.
- **Object stays on the bench after lesson end** — the You-Do round refreshes the bench with the ribbon/spoon pair; the rock and acorn don't persist.
- **Scale animation timing** — the dramatic 1.5 s tip is essential for the comparison to read. If playtest finds the kid taps before the tip completes, lock taps until the tip finishes.
- **Length pair with non-zero alignment** — the measuring stick "magnetically" aligns objects at zero in the lesson. The activity enforces this at Concrete layer. At higher layers, the stick may not snap; the kid has to align manually. Not relevant for the lesson (Concrete layer only).

---

## Open Questions

- **Both tools in one lesson vs two lessons** — current spec: one lesson covers length (I-Show) and weight (We-Try). Alternative: split into `lesson-k-md-2a-length` and `lesson-k-md-2b-weight`. Trade-off: one lesson is denser but stays close to the 75 s budget; two lessons fragments the K.MD.2 introduction across two first-round encounters. Suggest one lesson at launch; split only if playtest shows the kid leaves the lesson confused about which tool to use when.
- **Lesson length 75 s** — at the edge of budget. Both-tools coverage justifies it. If playtest shows attention drops, consider:
  - **(a)** Cut the "tap to confirm" beat in We-Try and let the scale-tip + glow be the answer (saves ~5 s but reduces kid agency).
  - **(b)** Cut the weight-preview narration at 0:24 (saves ~3 s but the tool switch feels more abrupt).
- **You-Do tool choice (length vs weight)** — current spec: length (different from We-Try's weight, confirms transfer). Alternative: weight (same as We-Try, easier hand-off but doesn't validate generalization). Suggest length.
- **Tool fading transitions** — measuring stick fades out / balance scale fades in between Phase 1 and Phase 2. Confirm this reads as a clean tool swap rather than a stage change.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — covers both length (I-Show) and weight (We-Try) tools in one lesson | |
