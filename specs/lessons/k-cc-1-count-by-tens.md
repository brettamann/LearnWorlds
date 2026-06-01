# MicroLesson — Count by Tens (K.CC.1, challenge variant)

> "Groups of ten count faster." The strategic shift from one-at-a-time to ten-at-a-time. Each cluster is treated as a single unit valued 10. Fires the first time the kid enters the **Tens Parade** challenge variant.

References: `specs/shared/micro-lessons.md`, `specs/activities/kindergarten/counting-parade.md`, `specs/lessons/k-cc-4a-one-to-one.md`, `specs/lessons/k-cc-4b-cardinality.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-cc-1-count-by-tens` |
| Concept ID | `K.CC.1` (the count-by-tens portion of the standard) |
| Standard | K.CC.1 — Count to 100 by ones and by tens |
| Region | Sanctuary |
| Introducing activity | Counting Parade (Tens Parade challenge variant) |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 70 s |
| Status | Draft |
| Prerequisite | K.CC.4a and K.CC.4b lessons completed; kid has opted into the Tens Parade challenge |

---

## Setting

A wider view of the Sanctuary path than the standard Counting Parade — sweeping out to suggest the larger herd that's about to arrive. Music bed has a slight rising-energy variant (the challenge "stretch" feel) without becoming stressful.

Three or four **clusters of 10 single-species creatures** stand on the path. Each cluster is **visually grouped** — the creatures stand close together, with a soft cohesive halo around the cluster so it reads as one unit.

- **Single species per round** — challenges still respect the cardinality-not-anchored-to-species principle for the cluster, but each cluster is the same species for visual clarity.
- The count badge starts hidden, appears with the first count.
- A small "× 10" or "= 10" marker briefly appears above each cluster as it's counted (visual reinforcement that the cluster *means* 10).

---

## Phase 1 — I-Show (≈25 s)

The kid watches. The key teaching beat: **the first cluster's individual creatures are briefly revealed** so the kid sees that the cluster genuinely contains 10. Clusters 2 and 3 are trusted as 10 thereafter without the reveal.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Three clusters of 10 baby gryphons visible on the path. Wider camera. Music bed comes in. |
| 0:02 | Narrator begins. |
| 0:05 | Glowing pointer drifts to cluster 1. **Quick reveal**: each creature in the cluster sparkles in sequence (10 sparkles, ~1.2 s total), with rapid narrator under-count "one-two-three-four-five-six-seven-eight-nine-ten." |
| 0:07 | The 10 creatures **collapse visually** — they slide tighter together, and a **"10"** label rises above the cluster with a soft chime. Count badge appears showing **10**. Narrator: "Ten in this group." |
| 0:12 | Pointer drifts to cluster 2. No reveal this time — cluster pulses briefly, "10" label rises above it, badge ticks to **20**. Narrator: "Ten more — twenty." |
| 0:16 | Pointer drifts to cluster 3. Same: pulse, "10" label, badge ticks to **30**. Narrator: "Ten more — thirty." |
| 0:20 | Pointer fades. Count badge **30** glows briefly (cardinality reinforcement). |
| 0:21 | Narrator delivers the strategic insight. |
| 0:25 | "I've got this" button has been visible since 0:18. I-Show ends. |

### Narration script

> *(0:02)* "Look at all these baby gryphons. So many to count!"
>
> *(0:05)* *(quick under-count)* "One-two-three-four-five-six-seven-eight-nine-ten." *(cluster collapses; "10" rises)*
>
> *(0:08)* "Ten in this group."
>
> *(0:12)* "Ten more — twenty." *(cluster 2)*
>
> *(0:16)* "Ten more — thirty." *(cluster 3)*
>
> *(0:21)* "Thirty gryphons. Counting by tens is much faster than one at a time."

### Notes for the narrator
- The rapid under-count is the *only* moment of speed in the lesson. Everything else is unhurried.
- "Counting by tens is much faster than one at a time" — this is the strategic punchline. It justifies the new procedure by contrasting with what the kid already knows (one-by-one counting).
- Slight celebratory lift on "thirty" — bigger number, more victory.

---

## Phase 2 — We-Try (≈22 s)

The kid taps clusters as the system shows the "10" labels.

### Setup

| Element | State |
|---|---|
| Scene | Two clusters of 10 visible; a third cluster of 10 walks in from the top during the lesson |
| Count badge | Hidden until first kid tap |
| Cluster reveals | NOT shown — the kid is trusting that each cluster is 10 (the I-Show established this) |
| Glow target | First cluster highlights when ready |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Scene opens with 2 clusters; the third walks in. Narrator: "Your turn. Each group is ten." |
| 0:04 | First cluster halo pulses. Narrator: "Touch this group." |
| → kid taps | Kid taps cluster 1 → cluster pulses, "10" label rises, badge **10**, narrator "Ten." |
| +0.5 s | Second cluster halo pulses. Narrator: "Now this one." |
| → kid taps | Kid taps cluster 2 → "10" label, badge **20**, narrator "Twenty." |
| +0.5 s | Third cluster auto-completes; pointer touches; "10" label, badge **30**, narrator "Thirty." |
| +1.0 s | Narrator: "Thirty gryphons in three groups." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
If the kid waits **> 5 s** after a halo prompt, the system auto-taps with the pointer. Lesson advances either way.

### Pass condition
Any kid tap inside or near a highlighted cluster passes. Even a tap on the wrong cluster passes — the system steers and continues.

### Narration script

> *(start)* "Your turn. Each group is ten."
>
> *(prompt 1)* "Touch this group."
>
> *(after kid tap 1)* "Ten."
>
> *(prompt 2)* "Now this one."
>
> *(after kid tap 2)* "Twenty."
>
> *(auto-completing)* "Thirty."
>
> *(closing)* "Thirty gryphons in three groups."

---

## Phase 3 — You-Do (one Tens Parade round)

Hand off to the activity's Tens Parade challenge variant for a real round.

### Round parameters

- **Sub-mode**: `tens-parade` (challenge variant)
- **Clusters**: 3 (matches the lesson) — challenge-mode escalation comes in later rounds
- **Cluster size**: 10 each
- **Target final count**: **30**
- **Single species**: yes (per the lesson's species or a new one)
- **CPA layer**: Concrete (first encounter for K.CC.1 by-tens)
- **Max attempts**: **3** (first-encounter extra forgiveness)
- **Hints**: enabled
- **Reward bump**: this is a challenge round, so successful completion earns a **challenge chest** per `reward-economy.md`

### Pass outcome
- Kid taps each cluster, taps Done (or auto-completes).
- Activity announces "Thirty! Three groups of ten" on round-pass.
- `mastery.standard_practicing` fires for K.CC.1.
- Library entry created.
- `firstEncounter` for K.CC.1 flips to `false`.
- Challenge chest awarded.

### Fail outcome (all 3 attempts miss)
- Library entry filed.
- `firstEncounter` flips to `false`.
- Mastery status stays `Introduced`.
- Challenge chest **not** awarded (challenge rewards require success).
- Dashboard flag.

---

## Library Entry

| Field | Value |
|---|---|
| Surface (Sanctuary) | Stamp Wall stamp — bigger / more decorated stamp than ordinary lessons (challenge lessons stand out) |
| Surface (Wundletown) | Spell Book page with a "stretch" border |
| Surface (Mathopolis) | Casebook clip flagged "advanced" |
| Thumbnail | A cluster of small creatures with a glowing **10** label above, plus a stylized "× 3 = 30" badge |
| Short label | "Counting by tens" |
| Original region badge | Sanctuary leaf + small star (challenge marker) |
| Replay duration | ~70 s |

The challenge-tier visual treatment makes these lessons feel earned — the kid sought out the challenge and now has a slightly prouder library entry.

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `species: "baby_gryphon"`, `clusterCount: 3`, `clusterSize: 10`, `isChallenge: true` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `clustersTapped: 3`, `finalCount: 30` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.CC.1 + **challenge chest** (small or medium per `reward-economy.md`)
- `lesson.youdo_failed_out` → library entry only; no coins; no challenge chest
- Replays → no rewards

The challenge chest on first-pass is the "you earned this stretch" payoff.

---

## Edge Cases

- **Kid taps individual creatures inside a cluster instead of the cluster as a unit** — first tap inside the cluster counts as a cluster tap (the whole cluster activates, "10" label rises, badge ticks by 10). Subsequent taps inside the same cluster are no-ops (the cluster is already counted). This forgivingly handles the kid who hasn't fully internalized "tap the group."
- **Kid taps cluster 2 before cluster 1** — order doesn't matter for cardinality, but the count goes up by 10 regardless. Badge ticks to **10** on first cluster tap, **20** on second, etc. Narrator says "ten" / "twenty" / "thirty" in tap order — order-independence is part of K.CC.4b which is already mastered by the time the kid hits this challenge.
- **Cluster visual cohesion breaks at small screen sizes** — clusters must remain visually distinct from "individual creatures next to each other." Use a halo / shading effect that scales with the screen. Define in art direction.
- **Tens Parade is the kid's *first* Counting Parade entry** — shouldn't happen per the prerequisite (the challenge isn't surfaced until standard Counting Parade has been played), but if state import or a bug allows it, the system should detect missing K.CC.4a/4b state and play those lessons first.
- **Kid taps the "10" label** — labels are not interactive. Soft no-op.

---

## Open Questions

- **Species choice for the by-tens lesson** — baby gryphons proposed (fits "challenge = a bit more magical"). Alternatives: tiny dragons, glowing koi schools. Choose during art direction.
- **Cluster visual treatment** — needs an art spec. A subtle shared halo? A loose drawn line around each cluster? Avoid making clusters look like cages.
- **The rapid under-count in I-Show** (~1.2 s for 10 sparkles) — confirm this reads as "look, there really are 10" without overwhelming. Playtest with kids; tune speed if needed.
- **Should the lesson briefly show what *not* using the strategy looks like?** A quick "if we counted one at a time, we'd be here forever" beat could underline the value. Suggest playtest both.
- **Challenge reward magnitude** — what tier of chest fires here? Suggest "small" for the first successful tens-by-tens, "medium" for streaks of successful Tens Parade rounds. Tune with the broader reward balancing pass.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-29 | Initial draft (the K-challenge lesson) | |
