# MicroLesson — One-to-One Correspondence (K.CC.4a)

> The first lesson a K kid encounters. Bedrock counting procedure: one touch per object, no doubles, no skips. Plays at first entry to Counting Parade for a fresh K kid.

References: `specs/shared/micro-lessons.md`, `specs/activities/kindergarten/counting-parade.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-cc-4a-one-to-one` |
| Concept ID | `K.CC.4a` |
| Standard | K.CC.4a — Pair each quantity of objects with one and only one number |
| Region | Sanctuary |
| Introducing activity | Counting Parade |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 60 s |
| Status | Draft |

---

## Setting

The Counting Parade scene with the parade pre-staged. Three (I-Show) or four (We-Try) **single-species fawns** stand calmly on the grassy path — no movement yet. Soft afternoon light, music bed quiet under the narration. The Buddy watches from the lower-left, attentive.

- **Single-species** intentional: this matches the Concrete-layer rule (low cognitive load on what to count).
- The standard count badge is **hidden** at lesson start; appears with the first count.
- The "Done" button and other normal HUD elements are **hidden** during I-Show and We-Try; they appear in You-Do.

---

## Phase 1 — I-Show (≈22 s)

The kid watches. A glowing pointer (rendered as a soft amber glow with a faint wisp trail — *not* a literal cursor or finger) demonstrates the procedure.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up; three fawns standing in line, evenly spaced. Music bed comes in low. |
| 0:01 | Narrator begins. |
| 0:04 | Glowing pointer appears just outside the leftmost fawn. |
| 0:05 | Pointer drifts onto fawn 1. Touch → sparkle on fawn 1. Count badge appears showing **1**. |
| 0:08 | Pointer drifts to fawn 2. Touch → sparkle. Badge updates to **2**. |
| 0:11 | Pointer drifts to fawn 3. Touch → sparkle. Badge updates to **3**. |
| 0:14 | Pointer fades out. All three fawns retain their sparkle. Badge holds at **3**. |
| 0:15 | **"I've got this" button** appears at the bottom of the screen. |
| 0:22 | I-Show ends; advance to We-Try. |

### Narration script

> *(0:01)* "Let's count these fawns together. Watch how each one gets one touch."
>
> *(0:05)* "One." *(pointer touches fawn 1)*
>
> *(0:08)* "Two." *(touches fawn 2)*
>
> *(0:11)* "Three." *(touches fawn 3)*
>
> *(0:14)* "Three fawns. Each one got exactly one touch."

### Notes for the narrator
- Warm, unhurried, slightly amused. Like an older sibling pointing things out.
- The word "exactly" lands a hair early — this is the conceptual punchline.

---

## Phase 2 — We-Try (≈22 s)

The kid takes one or two actions. The system completes the rest.

### Setup

| Element | State |
|---|---|
| Scene | Four fawns in a line, same single species as Phase 1 |
| Count badge | Hidden until first kid tap |
| Pointer | Gone — the kid's stylus is the pointer now |
| Glow target | Fawn 1 is highlighted with a soft cyan halo (system says "tap me") |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Now you try. Touch this first fawn." Fawn 1 halo pulses. |
| 0:00 → kid taps | Kid taps fawn 1 → sparkle, badge **1** appears, narrator says "One." |
| +0.5 s | Fawn 2 halo pulses. Narrator: "Now this one." |
| 0:00 → kid taps | Kid taps fawn 2 → sparkle, badge **2**, "Two." |
| +0.5 s | Fawns 3 and 4 highlight together (system takes over). Brief glowing-pointer animation touches each in turn. Narrator: "Three. Four." Badge ticks up to **4**. |
| +1.5 s | Narrator: "Four fawns. Each one got one touch." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
If the kid waits **> 5 s** without tapping after a halo prompt, the system **gently performs the tap for them** (pointer animation, sparkle, narration) and continues to the next prompt. The lesson does not stall on input.

### Pass condition
Any attempt at either highlighted fawn — success, near-miss, even a tap on a different fawn — counts as participation. The lesson advances regardless of perfection.

### Narration script

> *(start)* "Now you try. Touch this first fawn."
>
> *(after kid tap 1)* "One."
>
> *(prompting next)* "Now this one."
>
> *(after kid tap 2)* "Two."
>
> *(auto-completing remaining)* "Three. Four."
>
> *(closing)* "Four fawns. Each one got one touch."

---

## Phase 3 — You-Do (one round of Counting Parade)

The lesson hands off to the Counting Parade activity for a real round.

### Round parameters

- **Sub-mode**: `count-the-parade` (default)
- **Arrangement**: line
- **Count**: 4 creatures (single species; fawns to match the lesson's visual continuity)
- **CPA layer**: Concrete (per K starting layer in `adaptive-scaffolding.md`)
- **Max attempts**: **3** (vs the default 2; first-encounter extra forgiveness per `micro-lessons.md`)
- **Hints**: enabled at standard thresholds (5 s hesitation → highlight next; 10 s → narrator reminder)

### Pass outcome
- Kid taps each creature exactly once, taps Done (or auto-completes after 3 s of stillness).
- `mastery.standard_practicing` fires for K.CC.4a → kid earns the standard mastery reward.
- Lesson `lesson.youdo_passed` fires → library entry created.
- The activity proceeds to the next round normally; `firstEncounter` for K.CC.4a is now `false`.

### Fail outcome (all 3 attempts miss)
- `lesson.youdo_failed_out` fires.
- Library entry is **still created** (the kid saw the demos).
- `firstEncounter` for K.CC.4a flips to `false`.
- Mastery status stays `Introduced` (not promoted to Practicing).
- Dashboard flag: "K.CC.4a first attempt unsuccessful — may need teacher attention."
- The activity continues at the Concrete layer with normal scaffolding.

---

## Library Entry

When filed, the lesson appears in the kid's library with:

| Field | Value |
|---|---|
| Surface (when in Sanctuary) | Stamp Wall stamp |
| Surface (when in Wundletown) | Spell Book page |
| Surface (when in Mathopolis) | Casebook clip |
| Thumbnail | A small illustration: three fawns in a line, each with a soft sparkle above |
| Short label | "Counting one at a time" |
| Original region badge | Sanctuary leaf icon |
| Replay duration | ~60 s (full lesson) |

The lesson always **plays in Sanctuary style** regardless of which surface the kid opens it from. Identity is stable.

---

## Telemetry

This lesson uses the standard MicroLesson events from `micro-lessons.md`. Lesson-specific payload fields:

| Event | Custom payload |
|---|---|
| `lesson.started` | `species: "fawn"`, `phaseOneCount: 3`, `phaseTwoCount: 4`, `phaseThreeCount: 4` |
| `lesson.skipped_to_youdo` | `atPhase: "i-show"` is the most common; track to identify over-confident skipping |
| `lesson.youdo_passed` | `attempts: 1|2|3` — distribution helps tune `maxAttempts` |

---

## Reward Emissions

Per `reward-economy.md`:

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + filed library entry + `mastery.standard_practicing` mastery reward (collectible card)
- `lesson.youdo_failed_out` → no coins; library entry filed; no mastery reward (status stays Introduced)
- Replays → no rewards

---

## Edge Cases

- **Kid hits "I've got this" at 15 s into I-Show** — skips to You-Do directly. The lesson is still filed if You-Do passes. Many such skips followed by You-Do fails are a signal: dashboard surfaces "kid is skipping lessons but failing the You-Do."
- **Kid taps wildly during We-Try** — first tap on any fawn satisfies the pass condition for that step. Wild tapping doesn't fail the lesson; it just doesn't get the precise modeling.
- **App backgrounded mid-We-Try** — pause and persist. Resume from the exact step within 5 minutes; restart We-Try after 5 minutes.
- **Single species not visually distinct enough** — unlikely with fawns (they're recognizable), but if playtest finds a problem, swap to a different species. Lesson visual continuity should be preserved across phases.
- **Kid's home theme is Sci-fi Base** — Stamp Wall still appears as a Stamp Wall when in Sanctuary; in the Hub interior the Stamp Wall surface adapts (stamps display on a sci-fi panel for sci-fi homes). The lesson content does not change.

---

## Open Questions

- **Species choice** — fawns are the proposed default for this first lesson (warm, gentle, easy to count). Confirm during playtest; alternatives: goats, ducklings, baby unicorns (slightly more magical but visually busier).
- **We-Try kid-action count** — 2 taps proposed (fawns 1 and 2), then system auto-completes 3 and 4. Could be 1 (just fawn 1), with system doing the rest; would shorten the phase but reduce kid agency. Suggest 2 at launch.
- **Pointer style** — "soft amber glow with wisp trail" is the proposal. Make sure it doesn't read as a literal disembodied hand (kids fixate on hands). Maybe a small leaf or a stylized petal as the carrier visual — Sanctuary-themed.
- **Music bed during narration** — keep it under the voice (-12 dB while narration plays). Confirm with audio team.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-29 | Initial draft (the K-foundational lesson) | |
