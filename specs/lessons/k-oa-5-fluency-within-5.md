# MicroLesson — Fluency Within 5 (K.OA.5)

> "Read the problem, pick the answer, next one." Introduces the fluency-practice rhythm. The kid sees one worked example, does one with hints, then enters a real round. Uses the **representative-sample authoring pattern** — one fact (`2 + 1`) is the worked example; the kid generalizes the procedure to the other 41 facts in the K.OA.5 instance set.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/fluency-within-5.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-oa-5-fluency-within-5` |
| Concept ID | `K.OA.5` |
| Standard | K.OA.5 — Fluently add and subtract using numbers within 5 |
| Region | Sanctuary |
| Introducing activity | Fluency Within 5 |
| Sub-mode | `casual` |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 70 s |
| Status | Draft |
| Prerequisite | K.OA.1 + K.OA.2 (representation + word problems within 10) introduced. The kid has done addition/subtraction in story context (Storyteller's Pond) before meeting it as fluency practice. Not blocking — lesson stands on its own. |

---

## Setting

Fluency Within 5's standard scene: practice clearing with the wooden chalkboard. Buddy sits on the practice mat at lower-left, **larger than usual** (Buddy is the activity's co-host). Treat jar shelf visible in the background.

- **I-Show fact**: `2 + 1` — the smallest non-trivial sum, chosen because the visual representation is unambiguous (kid can see 2 + 1 in their head without scaffolding overhead).
- **We-Try fact**: `3 - 1` — a subtraction, chosen so the kid sees both operations in the lesson. Different operands than I-Show.
- **You-Do fact**: `2 + 2` — fresh sum, still trivial enough that the kid is unlikely to fail it on a first attempt.
- **Per-instance mastery note**: This lesson only triggers `firstEncounter: false` for K.OA.5 as a *concept*. Each of the 42 facts has its own per-instance state; the kid hasn't seen most of them yet. The activity's per-fact scheduling handles introducing them one at a time without re-firing this lesson.

Per `k-activity-patterns.md`: standard K HUD, Sanctuary narrator, Buddy in lower-left (larger here, on a mat).

---

## Phase 1 — I-Show (≈25 s)

The kid watches one problem play out — read, scan tiles, select correct, Buddy reacts, move on.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Practice clearing, empty chalkboard, Buddy on mat, tile row visible but empty. Music bed in. |
| 0:02 | Narrator opens. |
| 0:05 | Narrator: "Quick practice. Watch one." Soft "chalk" SFX as the problem **`2 + 1 = ?`** appears on the chalkboard. |
| 0:07 | Tiles fade in below the chalkboard: **[2] [3] [4] [5]** (correct + 3 near-miss distractors). |
| 0:09 | Glowing pointer drifts from chalkboard to tile **[3]**. |
| 0:11 | Pointer taps **[3]**. Crisp "tap" + selection ring. Bright chime. The `?` on the chalkboard transforms into `3`. |
| 0:13 | Buddy wiggles celebratory. Soft chime + cute animal cue. |
| 0:15 | The chalkboard fades to blank. Brief pause. |
| 0:17 | Narrator delivers the rhythm rule. |
| 0:20 | "I've got this" button has been visible since 0:17. |
| 0:25 | I-Show ends. |

### Narration script

> *(0:02)* "Quick practice. Watch one."
>
> *(0:05, problem appears)* "Two plus one."
>
> *(0:09, pointer scans tiles)* "Find the answer."
>
> *(0:11, pointer taps 3)* "Three."
>
> *(0:13, Buddy reacts)* "Yes — and the Buddy is happy."
>
> *(0:17)* "Read the problem, pick the answer, next one. That's the rhythm."

### Notes for the narrator
- "Quick practice" — set the tone as light and brisk, not high-stakes. This activity should never feel like a test.
- "Read the problem, pick the answer, next one. That's the rhythm." is the kid-language version of "this is how fluency practice works." Land "next one" as the punchline that signals brisk pacing.
- Avoid emphasizing speed. K kids should associate this activity with "fun with Buddy," not "go fast."

---

## Phase 2 — We-Try (≈25 s)

The kid does one problem with halo hints; system narrates each step.

### Setup

| Element | State |
|---|---|
| Scene | Practice clearing. Chalkboard ready for the next problem. Buddy attentive. |
| Glow target | None yet — appears when the problem does. |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Now you try." Soft "chalk" SFX; problem **`3 - 1 = ?`** appears on the chalkboard. |
| 0:02 | Tiles fade in: **[1] [2] [3] [4]**. The correct tile **[2]** halos softly. |
| 0:03 | Narrator: "Three take away one." |
| → kid taps | Kid taps a tile. |
| | If **[2]** → selection ring, chime, the `?` becomes `2`. Buddy wiggles. Narrator: "Two." |
| | If wrong tile → soft "nope" puff, brief warm tone. Narrator: "Three take away one is two." Correct tile [2] brightens. Auto-progresses to the right answer in ~1 s. |
| +1.0 s | Chalkboard fades. Brief pause. |
| +1.0 s | Narrator closes. |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no tap, the correct tile's halo brightens and the narrator gently re-prompts: "Three take away one — what's left?" After another 5 s, the system auto-taps the correct tile (with pointer animation and "two" narration). Lesson advances either way.

### Pass condition
Any tap (correct or wrong) counts as participation. The lesson advances regardless of correctness.

### Narration script

> *(start)* "Now you try."
>
> *(problem appears)* "Three take away one."
>
> *(after correct tap)* "Two."
>
> *(after wrong tap)* "Three take away one is two."
>
> *(closing)* "That's the rhythm. The Buddy is ready for more."

---

## Phase 3 — You-Do (one round of Fluency Within 5)

Hand off to the activity's `casual` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `casual`
- **Problem count**: a **shortened first set of 4 problems** (vs the standard 8) — gentler first-encounter pacing, per `micro-lessons.md` first-encounter forgiveness. After this round, future rounds use the standard 8-problem set.
- **Fact selection for the 4 problems**: include `2+2` first (the You-Do anchor), then 3 more facts from the "easy starter" subset (small operands, e.g., `1+1`, `2+0`, `3-1`). The activity's per-fact scheduler picks the remaining 3 facts.
- **CPA layer**: Concrete (tile-select, no free-write)
- **Distractors**: 3 near-miss distractors per problem (standard)
- **Max attempts**: **2 per problem** instead of the activity default (1 per problem) — first-encounter extra leniency
- **Hints**: per `fluency-within-5.md` — no answer-hints; only narrator re-prompts on 5 s hesitation
- **Pass condition for this first round**: ≥2 of 4 correct on first try (relaxed from the activity's ≥6 of 8 standard)
- **Treat jar bonus**: the first treat jar pour happens regardless of pass/fail on this round (Buddy gets a treat for the kid's first session — a warm welcome to the activity)

### Pass outcome
- Kid completes the 4-problem set with ≥2 correct.
- `mastery.standard_practicing` fires for K.OA.5 (concept-level).
- Per-fact `standard_practicing` fires for the facts the kid got right (per-instance mastery tracking begins).
- Library entry created.
- `firstEncounter` for K.OA.5 (concept) flips to `false`.
- Treat jar pours; Buddy celebrates.

### Fail outcome (fewer than 2 correct on first try)
- Round still completes (the kid sees all 4 problems regardless).
- Library entry filed.
- `firstEncounter` flips to `false`.
- Mastery status for K.OA.5 stays `Introduced` (per-fact states remain `Introduced` for missed facts).
- Treat jar still pours (the first-session treat is a warm-welcome guarantee, not a reward gate).
- Dashboard flag if 0 of 4 correct.

---

## Library Entry

| Field | Value |
|---|---|
| Surface (Sanctuary) | Stamp Wall stamp |
| Surface (Wundletown) | Spell Book page |
| Surface (Mathopolis) | Casebook clip |
| Thumbnail | A chalkboard reading "2 + 1 = 3" with the Buddy mid-wiggle beside it |
| Short label | "Quick practice with Buddy" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~70 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `iShowFact: "2+1"`, `weTryFact: "3-1"`, `youDoAnchorFact: "2+2"`, `youDoProblemCount: 4` |
| `lesson.wetry_tap` | `tappedAnswer`, `correct: Bool`, `wasAutoCompleted: Bool` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `factsCorrect: integer`, `factsAttempted: 4`, `firstFactCorrect: Bool` |
| `lesson.youdo_failed_out` | `factsCorrect: integer`, `factsAttempted: 4` |

Per-fact `fluency.fact_attempted` events fire normally during the You-Do round.

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.OA.5 + first-session treat jar pour + Buddy celebration
- `lesson.youdo_failed_out` → library entry only + first-session treat jar pour (warm-welcome guarantee)
- Per-fact `fluency.fact_mastered` doesn't fire from this lesson (no fact reaches 5/3/3 in one round); per-instance tracking begins for facts the kid attempts.
- Replays → no rewards.

---

## Edge Cases

- **Kid taps tile during I-Show** — tiles are non-interactive during I-Show; the pointer is doing the demonstration. Tap is a no-op.
- **Kid taps "I've got this" before We-Try completes** — standard skip-to-You-Do behavior per `micro-lessons.md`. The lesson is still filed if You-Do passes.
- **Free-write mode in the You-Do** — not used. The You-Do round is Concrete (tile-select). Kid hasn't been introduced to free-write fluency yet; per-fact promotion to Pictorial layer happens later as facts master individually.
- **Buddy is too distracting** — Buddy reactions are small (a wiggle, a soft chime) during problems and slightly bigger between problems. The chalkboard is the kid's focal point; Buddy is reinforcement, not competition. Confirm in playtest.
- **Speed Run not introduced** — Speed Run is opt-in within the activity and explicitly not surfaced in the lesson. The kid sees only Casual mode here. Per `fluency-within-5.md`, Speed Run is offered as an alternative after the kid has played Casual at least once.
- **First-session treat jar pour even on fail** — intentional. The kid's first encounter with the activity gets a guaranteed positive Buddy moment, even if every fact was wrong. Subsequent rounds use the standard reward gating.
- **Lesson re-replay vs activity entry** — if the kid hits the library and re-watches this lesson, the You-Do hand-off goes to a fresh casual round (8 problems, standard pacing), not the shortened 4-problem first-encounter round. The 4-problem version is reserved for the very first attempt only.

---

## Open Questions

- **You-Do problem count (4 vs 8)** — current spec: 4 problems for first-encounter forgiveness. Alternative: full 8. Trade-off: 4 keeps the lesson within the 70 s target and respects K attention span; 8 normalizes the kid to the activity's standard round shape immediately. Suggest 4 for launch; revisit if playtest shows the kid is confused by the second-session jump to 8.
- **Pass threshold (≥2 of 4)** — relaxed from the activity's ≥6 of 8 (which scales to ≥3 of 4). Going lower (≥2) acknowledges this is the kid's very first fluency exposure. Confirm in playtest the threshold feels right; tighten to ≥3 of 4 if too easy.
- **I-Show fact choice** (`2 + 1`) — chosen for triviality (kid likely already knows it). Alternative: `1 + 1` (even more trivial) or `3 + 1` (slightly more challenging). Suggest `2 + 1` — clearly above counting-on-fingers triviality without being effortful.
- **We-Try fact choice** (`3 - 1`) — chosen to introduce subtraction in the lesson. Alternative: another addition fact (e.g., `2 + 2`) to keep the lesson operation-uniform; subtraction would surface in You-Do or later rounds. Suggest current — early introduction of both operations matches the standard's "fluently add **and subtract**."
- **Pacing between problems** — 1 s pause after Buddy reaction is the proposed cadence. Could be tighter (0.5 s) for brisker feel; could be longer (1.5 s) for more reflection time. Confirm in playtest.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first opt-in K activity's lesson; uses representative-sample pattern (3 facts cover the procedure for 42); first-encounter forgiveness includes shortened 4-problem round and relaxed pass threshold | |
