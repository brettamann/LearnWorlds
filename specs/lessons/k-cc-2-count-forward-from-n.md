# MicroLesson — Count Forward from N (K.CC.2)

> "You don't have to start at one. You can pick up at any number and keep going." The strategic shift from always-start-at-1 to count-on. Builds on K.CC.4a (one-to-one) and K.CC.4b (cardinality).

References: `specs/shared/micro-lessons.md`, `specs/activities/kindergarten/counting-parade.md`, `specs/lessons/k-cc-4a-one-to-one.md`, `specs/lessons/k-cc-4b-cardinality.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-cc-2-count-forward-from-n` |
| Concept ID | `K.CC.2` |
| Standard | K.CC.2 — Count forward beginning from a given number within the known sequence (instead of having to begin at 1) |
| Region | Sanctuary |
| Introducing activity | Counting Parade |
| Sub-mode | `count-forward-from-n` |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 65 s |
| Status | Draft |
| Prerequisite | K.CC.4a and K.CC.4b lessons completed |

---

## Setting

The Counting Parade scene, mid-day. Some fawns are **already standing in the parade area** when the scene opens — they have small faint **pre-counted numerals** (1, 2, 3, 4) floating above them. The path remains open at the entry; more fawns will arrive during the lesson.

- Pre-counted fawns are visually distinguished by their numeral labels above (faint, not distracting).
- New arrivals enter from the top of the path, walking down into formation.
- The count badge starts already showing the pre-counted total (**4**) — this primes the kid for "we already have four."

---

## Phase 1 — I-Show (≈25 s)

The kid watches. The lesson establishes that the four fawns *are already counted* and we'll continue from there as new ones arrive.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Four fawns standing in line with faint numerals **1**, **2**, **3**, **4** above them. Count badge shows **4**. |
| 0:02 | Narrator begins. |
| 0:05 | Narrator says "We already have four." Each numeral above the fawns pulses briefly in sequence (1 → 2 → 3 → 4). |
| 0:09 | Three new fawns walk into view from the top of the path. They line up to the right of the existing four. The pre-counted numerals **fade out** as the new fawns arrive (~2 s fade). |
| 0:13 | Glowing pointer appears at the first new fawn. Touch → sparkle, badge **5**, narrator "Five." |
| 0:16 | Pointer touches new fawn 2 → sparkle, badge **6**, narrator "Six." |
| 0:19 | Pointer touches new fawn 3 → sparkle, badge **7**, narrator "Seven." |
| 0:22 | Pointer fades. Narrator delivers the insight. |
| 0:25 | "I've got this" button has been visible since 0:18. I-Show ends. |

### Narration script

> *(0:02)* "Look — these fawns are already counted."
>
> *(0:05)* "One, two, three, four." *(numerals pulse in sequence)*
>
> *(0:09)* "We have four. Now more fawns are coming. We don't need to start over."
>
> *(0:13)* "We start from four. Five." *(touches new fawn 1)*
>
> *(0:16)* "Six." *(touches new fawn 2)*
>
> *(0:19)* "Seven." *(touches new fawn 3)*
>
> *(0:22)* "Seven fawns. We started where we left off."

### Notes for the narrator
- "We don't need to start over" — this is the conceptual punchline. Let it have a small breath.
- "We started where we left off" — closes the lesson with the strategy named in kid-language.

---

## Phase 2 — We-Try (≈25 s)

The kid does the count-on with one or two guided taps.

### Setup

| Element | State |
|---|---|
| Scene | Three fawns pre-counted (faint numerals **1**, **2**, **3** above); count badge shows **3** |
| New arrivals | Three more fawns walk in from the top |
| Glow target | First new fawn highlights when ready |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Scene opens. Pre-counted fawns visible. Badge shows **3**. |
| 0:02 | Narrator: "We have three fawns. More are coming." |
| 0:05 | Three new fawns walk in; pre-counted numerals fade as they arrive. |
| 0:08 | First new fawn halo pulses. Narrator: "Touch the next fawn. We start from three." |
| → kid taps | Kid taps → sparkle, badge **4**, narrator "Four." |
| +0.5 s | Second new fawn halo pulses. Narrator: "Now this one." |
| → kid taps | Kid taps → sparkle, badge **5**, "Five." |
| +0.5 s | Third new fawn auto-completes; pointer touches it; badge **6**, narrator "Six." |
| +1.0 s | Narrator: "Six fawns. We started at three and counted on." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
If the kid waits **> 5 s** after a halo prompt, the system auto-taps with the pointer animation. Lesson advances either way.

### Pass condition
Any kid tap on a highlighted target counts. Even a tap on the wrong fawn passes the lesson — the system gently steers and continues.

### Narration script

> *(0:02)* "We have three fawns. More are coming."
>
> *(prompt 1)* "Touch the next fawn. We start from three."
>
> *(after kid tap 1)* "Four."
>
> *(prompt 2)* "Now this one."
>
> *(after kid tap 2)* "Five."
>
> *(auto-completing)* "Six."
>
> *(closing)* "Six fawns. We started at three and counted on."

---

## Phase 3 — You-Do (one round of Counting Parade)

Hand off to the activity's `count-forward-from-n` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `count-forward-from-n`
- **Starting N**: **5** (pre-counted fawns shown with faint numerals 1–5)
- **New arrivals**: 3 fawns
- **Target final count**: **8**
- **Arrangement**: line
- **CPA layer**: Concrete
- **Max attempts**: **3** (first-encounter extra forgiveness)
- **Hints**: enabled

### Pass outcome
- Kid taps each new fawn, taps Done (or auto-completes).
- Activity announces "Eight! There are eight fawns" on round-pass (reinforces K.CC.4b cardinality alongside K.CC.2).
- `mastery.standard_practicing` fires for K.CC.2.
- Library entry created.
- `firstEncounter` for K.CC.2 flips to `false`.

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
| Thumbnail | Three fawns pre-numbered (1, 2, 3, faded) on the left + an arrow + a fawn arriving with badge **4** |
| Short label | "Counting on from any number" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~65 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `species: "fawn"`, `preCountedN: 4`, `newArrivals: 3` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `startN: 5`, `targetCount: 8` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.CC.2
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid taps a pre-counted fawn during the lesson** — pre-counted fawns are not interactive during the lesson. Tap is a soft no-op (no penalty, no sparkle). After the lesson, pre-counted fawns are still non-interactive in the activity.
- **Numerals above pre-counted fawns are confusing** — they're meant as a brief visual scaffold; they fade as new arrivals come (per Counting Parade's locked decision: pre-counted numerals fade ~2 s after kid taps past N).
- **Kid forgets the starting number and counts from 1** — if they start re-counting the pre-counted fawns (tapping them), the soft no-op happens. They never actually get a count from 1 because the badge starts at **N**. The narrator can re-orient if hesitation lingers: "We start from three. Touch the next new fawn."
- **The lesson's starting N is fixed (3 or 4)** — playtest may show that varying the starting number in lessons (e.g., starting at 5 or 6) is more meaningful, but for the first encounter we use a small, predictable N.

---

## Open Questions

- **Should the lesson explicitly show what "counting on" looks like vs starting over?** The current design just shows counting on. A more explicit contrast — "we could count from one (sigh), or we could start at four (yay)" — might cement the strategic insight more strongly. Suggest playtest both and pick.
- **Pre-counted numeral styling** — currently "faint." Define precisely: 40% opacity? Specific gold/cream color? Specific font? Punt to art team but lock in playtest.
- **Should the You-Do round use the same starting N as the lesson?** Currently the lesson is N=3 → 6, You-Do is N=5 → 8. Different N reinforces "this works at any starting number." Alternative: same N for first round, then escalate.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-29 | Initial draft | |
