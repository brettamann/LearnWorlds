# Activity Spec — Fluency Within 5

> The K opt-in activity that builds **fluency with addition and subtraction within 5** (K.OA.5). Quick-fire +/− problems with the Buddy in a friendly practice clearing. Per-instance mastery tracks each of the 42 sums and differences within 5 independently. Includes the first speed-run mode in K — opt-in only, with a combo multiplier.

References: `specs/shared/stylus-mechanics.md`, `specs/shared/number-writing-modes.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/reward-economy.md`, `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activity-spec-template.md`.

---

## Header

| Field | Value |
|---|---|
| Activity name | Fluency Within 5 |
| Activity slug | `fluency-within-5` |
| Region | Sanctuary |
| Grade | K |
| Standards | K.OA.5 |
| Status | Draft |
| Last updated | 2026-05-30 |
| Surfacing | **Opt-in** — does not appear in the K Daily Quest rotation by default; kid chooses to enter from the Sanctuary tile menu |

---

## Setting & Tone

- **Scene** — A small grassy practice clearing in the Sanctuary, just off the main path. A simple wooden post with a chalkboard hangs in the center — the **problem board**. The Buddy sits on a small mat across from the kid (visible at lower-left, larger than usual — the Buddy is a *practice partner* here, not a side observer). Treats float in jars on a nearby shelf — earnable rewards.
- **Atmosphere** — Bright midmorning Sanctuary light. Music bed is a slightly more upbeat version of the Sanctuary palette (light flute + soft brush percussion). Subtle "ready to play" feel. Palette anchors: grass-green, chalkboard-slate, treat-jar gold.
- **Buddy presence** — **Buddy is the activity's host.** Sits across from the kid on a small training mat. Reacts to each correct answer with a small celebratory wiggle; reacts to combo streaks with bigger hops. On round-pass, Buddy gets a treat.
- **Narrator** — Sanctuary warm naturalist (standard K voice).

---

## Standards Coverage

| Standard | What the kid does | Telemetry event | Mastery threshold |
|---|---|---|---|
| **K.OA.5** (fluently add and subtract within 5) | Solves quick-fire +/− problems within 5. Answers via tile-select (Concrete) or free-write (Pictorial+). Per-instance mastery: 42 facts (21 addition + 21 subtraction). | `fluency.fact_attempted` (payload: `fact`, `correct`, `latencyMs`, `mode`) | 5/3/3 per fact (concept-wide rolls up when all 42 mastered) |

---

## Concepts: Introduced vs Exercised

| Concept | Role | Lesson | Granularity | Notes |
|---|---|---|---|---|
| **K.OA.5** (fluency within 5) — granularity: **per-instance**, 42 fact keys | Introduces | `specs/lessons/k-oa-5-fluency-within-5.md` | per-instance | Lesson covers the fluency-practice rhythm using a representative-sample pattern (one or two facts as worked examples; the kid generalizes the procedure to all 42). |

### Registry impact

- `K.OA.5.introducedBy = fluency-within-5`
- Instance keys: 21 sums (`"0+0"`, ..., `"5+0"`) + 21 differences (`"1-0"`, ..., `"5-5"`).

---

## Sub-Modes

### Sub-mode: `casual` (default)

- **Standards targeted** — K.OA.5
- **What the kid does** — Untimed practice. Problem appears on the chalkboard. Kid taps a tile (Concrete) or free-writes (Pictorial+) the answer. Correct → Buddy wiggles, next problem appears after a brief pause. Incorrect → warm narrator + correct answer revealed, same problem retried.
- **Pass condition** — A "set" is **8 problems**. Pass = ≥6 correct on first try.
- **Fail behavior** — Round continues regardless; the kid completes all 8 problems. The Pass/Fail status is for telemetry and reward purposes only.

### Sub-mode: `speed-run` *(opt-in within the activity)*

- **Standards targeted** — K.OA.5 (fluency emphasis)
- **What the kid does** — Timed practice. 10 problems with a **combo multiplier**: each consecutive correct answer increases the coin payout (1× → 2× → 3× max). Wrong answer resets the combo. Each problem has a generous ~10-second timer (not a stress timer — closer to "if you're stuck for 10s, the system reveals and moves on"). Timer is visible as a soft progress ring around the problem board.
- **Pass condition** — All 10 problems attempted. Pass = ≥7 correct OR max-combo achieved.
- **Fail behavior** — Same as casual; round completes regardless. Failed Speed Run doesn't penalize; the kid just earns fewer coins.
- **Entry guard** — Speed Run is opt-in *within the Fluency Within 5 activity*. Per the plan's confidence-first principle, the kid never lands in a timed mode by surprise. The casual sub-mode is always offered first; Speed Run is presented as an alternative ("ready for a faster round?").

### Sub-mode: `number-range-stretch` *(challenge variant)*

- **Standards targeted** — K.OA.5 extended to within 10 (the 1st-grade fluency range)
- **What the kid does** — Same as casual but with facts up to within 10 (not just within 5). Tests whether the kid can apply within-5 fluency to slightly larger numbers.
- **Pass condition** — ≥6 of 8 correct.
- **Reward bump** — Challenge chest per `reward-economy.md`.

---

## Visual Layout

```
+--------------------------------------------------------+
| [exit]                              [coins: 12]        |
|                                                        |
|   <practice clearing — grass, distant trees>          |
|                                                        |
|                ┌──────────────────┐                    |
|                │   <chalkboard>   │                    |
|                │                  │                    |
|                │     3 + 2 = ?    │   <problem board>  |
|                └──────────────────┘                    |
|                                                        |
|                                                        |
|              [3]   [4]   [5]   [6]                    |
|              <tile selector — Concrete layer>         |
|                                                        |
|             [problem 2 of 8]    [combo: 2×]            |
|                                                        |
|  [Buddy on mat]                       [notebook >]     |
|                                                        |
+--------------------------------------------------------+
```

- **Persistent scene anchors** — practice clearing, Buddy on mat (lower-left, larger than usual), HUD per K convention.
- **Interactive elements** — tile selector buttons at Concrete (4 numeral options including the correct answer + 3 close distractors), OR free-write zone at Pictorial+. Speed Run mode adds a soft progress ring around the chalkboard.
- **Progress indicator** — "problem N of M" at the bottom; combo multiplier visible in speed-run mode.
- **Math notebook tab** — collapsed by default. **Encouraged** in free-write rounds (Pictorial+).

---

## State Machine

```
[idle/intro] → narrator opens with sub-mode-specific prompt
   ↓
[sub-mode chooser] → kid picks casual / speed-run (if eligible) / number-range-stretch (if challenge banner)
   ↓
[round_setup] → first problem appears on chalkboard
   ↓
[problem_active] → kid taps tile or free-writes
   ↓ (input submitted OR speed-run timer fires)
[evaluating] → check answer
   ↓
[problem_pass | problem_fail] → Buddy reacts; brief pause
   ↓ (next problem queued)
[problem_active] → loop until all problems in set complete
   ↓
[round_complete] → tally pass/fail per sub-mode rule; reward emission
   ↓
[next round queued | exit]
```

**Exit conditions** — standard per K patterns. Manual exit mid-round preserves progress within the round; on re-entry, the round restarts (fluency rounds are short and shouldn't preserve mid-round state).

---

## Stylus Interactions

| Mechanic | Where used | Local overrides |
|---|---|---|
| **Tap-Pick** (selection semantic) | Tile-select answer entry (Concrete layer). 4 tiles: correct + 3 distractors. | Standard. Distractors are chosen from "near-misses" (off-by-one or off-by-the-other-operand). |
| **Free-Write** | Free-write answer entry (Pictorial+ layers). Single-digit recognition. | Mode 2 Prompted free-write per `number-writing-modes.md`. End-of-input timeout 1.2 s. Tile fallback after 2 recognition failures. |

---

## Number-Writing Modes

| Layer | Mode used |
|---|---|
| Concrete | Tile-select (no number-writing) |
| Pictorial | **Mode 2 — Prompted free-write** (with tile fallback after 2 fails) |
| Abstract | **Mode 2 — Prompted free-write** (no tile fallback offered) |

Mode 3 (Blind) is not used here — the visible problem on the chalkboard IS the prompt that the visible quantity in Mode 2 represents.

---

## Audio Cues

> **Runtime source**: narration cues live in [`content/strings/en-US/activities/fluency-within-5.json`](../../../content/strings/en-US/activities/fluency-within-5.json). The prose below is the design-time reference; the JSON is the authoritative source the TTS pipeline and runtime consume.

### Narrator lines (Sanctuary warm naturalist)

#### `casual`
- **Round start**: "Quick practice with the Buddy. Easy ones today."
- **Per-problem (no narration mid-problem)** — silence; the kid focuses
- **Correct answer**: (no narration unless combo milestone; just Buddy's celebratory wiggle + soft chime)
- **Correct combo milestone (e.g., 3 in a row)**: "Three in a row!"
- **Incorrect answer**: "{Fact} is {result}. Try the next one." Brief warm tone.
- **Round complete (pass)**: "{N} of 8! Buddy gets a treat."
- **Round complete (fail / fewer than 6)**: "Good practice. Want to keep going?"

#### `speed-run`
- **Round start**: "Faster this time. See how many you can get in a row!"
- **Combo increase**: "Two!" "Three!" with rising pitch on multiplier increases
- **Correct (high combo)**: Buddy hops bigger
- **Incorrect (combo reset)**: "Almost! Combo reset — keep going."
- **Round complete**: "Top combo: {maxCombo}!"

#### `number-range-stretch` (challenge)
- **Round start**: "Bigger numbers today. Same idea — go!"

### SFX

| Event | SFX |
|---|---|
| Problem appears on chalkboard | Soft "chalk" sound |
| Tile tap | Crisp "tap" + visual selection ring |
| Free-write submit | Subtle "ink-flick" |
| Correct answer | Bright chime (escalates pitch with combo) |
| Incorrect answer | Soft "nope" (no shame — warm in tone) |
| Buddy wiggle/hop | Cute animal-specific cue |
| Round pass | Sanctuary chime stinger + Buddy treat-jar opens |
| Speed Run timer warning (last 3 s of problem) | Subtle "tick" |

### Music

- Sanctuary upbeat practice bed: light flute + soft brush percussion + occasional finger-snap, ~100 BPM.
- In Speed Run mode, the tempo subtly bumps up (to ~110 BPM) — adds energy without rushing.
- Round-pass stinger over the bed.

---

## Scaffolding Triggers

Uses `ScaffoldQuery` per round, including `firstEncounterLesson` for K.OA.5 routing.

**Per-fact targeting:** when the activity selects a fact for a round, it picks from the kid's per-instance state — preferring facts that are still `Introduced` or `Practicing`, deprioritizing `Mastered` facts (kid sees them less often but not zero). This is the **intelligent practice scheduling** noted in the plan.

| Trigger | Response |
|---|---|
| **5 s of no input on a problem (casual)** | Highlight one tile as a hint? **No** — fluency activities don't hint at the answer. Instead, narrator gently re-states: "{Fact} — what's the answer?" |
| **10 s of no input (casual)** | Reveal the correct answer with warm narration; treat as a fail attempt; move to next problem. |
| **Speed-run timer reaches 3 s remaining** | Soft tick cue. |
| **Speed-run timer expires** | Treat as wrong answer; combo resets; move to next problem. |
| **Per-fact pattern of failures** | If a fact has been attempted 3+ times in a session with persistent failure, the activity flags it as "needs work" — surfaces it more often in subsequent rounds AND in the dashboard. |
| **2 consecutive round failures** | Apply the **staggered demotion** rule. Sub-mode demotion order: `number-range-stretch` → `speed-run` → `casual`. CPA demotion: Abstract → Pictorial → Concrete (tile-select). |

---

## CPA Progression

| Layer | What it looks like in Fluency Within 5 |
|---|---|
| **Concrete** | Problem displayed as `3 + 2 = ?`. Below: **tile selector** (4 tiles with numeric options: the correct answer + 3 close distractors). No free-write expected. |
| **Pictorial** | Problem displayed. **Free-write zone** for the answer. Tile fallback **available** after 2 failed free-writes. |
| **Abstract** | Problem displayed. Free-write only. No tile fallback offered. |

- **Default starting layer (K, fresh kid)** — Concrete.
- **Promotion conditions** — 3 consecutive passes at the current layer (per-fact AND per-mode combined).
- **Demotion conditions** — 2 consecutive failures at the current layer.

---

## Reward Emissions

| Event | Trigger | Reward (per `reward-economy.md`) |
|---|---|---|
| `round.passed` | Round passes (≥6 of 8 correct in casual; ≥7 of 10 in speed-run) | +2 coins (base) per problem correct (so 6 correct = +12 coins); speed-run combo multiplier applies (1×, 2×, 3×) |
| `round.notebook_bonus` | Notebook had ≥3 strokes (occasional in free-write modes) | +1 coin |
| `streak.session_3` / `_5` / `_10` | Standard | Per shared spec |
| `milestone.problems_25` / `_100` | Lifetime in this activity | Per shared spec |
| `mastery.standard_practicing` / `_mastered` | Per-fact mastery rolls up to K.OA.5 concept-wide when all 42 mastered | Per shared spec |
| `challenge.completed` | `number-range-stretch` round passes | Challenge chest |

### Activity-specific events
- **`fluency.fact_mastered`** — single fact reaches per-instance mastery (5 successes / 3 sessions / 3 days). Awards a **Buddy treat** (cosmetic; goes to a treat-collection display in the Hub).
- **`fluency.max_combo_achieved`** — kid achieves max 3× combo in a speed-run round. Awards a Buddy emote unlock.

### Collectibles
- **Buddy Treats** — **10 unique treats** at launch (reduced from 42 in the K-review pass — too many treats for too long a road; 10 distinct treats land more often and feel achievable). Each treat is awarded for hitting a per-instance fact-mastery milestone (1st fact, 5th fact, 10th, 15th, 20th, 25th, 30th, 35th, 40th, all 42 = "Complete Treat Cabinet"). Treats display in a Hub case shaped like the treat-jar shelf from the activity.
- **Buddy Emotes** — 8 unlockable emote animations the Buddy can perform in the Hub (a backflip, a happy spin, a clap, etc.). Earned via max-combo speed-run achievements.

Complete the treat set (all 10) for a Hub trophy: the **Buddy Treat Cabinet**.

**Note on the reduction:** the K-review pass identified that 42 unique treats (one per fact mastered) created a collection that was both expensive in art (42 unique illustrations) and discouraging in pacing (a kid mastering ~5 facts a week wouldn't complete the set in their K year). The 10-treat milestone-driven model preserves the "Buddy reacts to your fluency" feel with achievable cadence.

---

## Telemetry Events

(Beyond shared `scaffold.*`, `economy.*`, `lesson.*` events.)

| Event | Payload |
|---|---|
| `fluency.round_started` | `subMode`, `presentationLayer`, `problemCount` |
| `fluency.problem_started` | `fact` (e.g., "3+2"), `expectedAnswer`, `mode`, `factTargetingReason` (e.g., "needs-work", "rotation") |
| `fluency.fact_attempted` | `fact`, `kidAnswer`, `correct`, `latencyMs`, `mode` |
| `fluency.combo_change` | `combo`, `multiplier` |
| `fluency.fact_mastered` | `fact`, `attemptsToMastery`, `daysToMastery` |
| `fluency.round_completed` | `success`, `subMode`, `factsAttempted`, `factsCorrect`, `maxCombo` |
| `fluency.collectible_dropped` | `itemId`, `setProgress`, `collectibleType` (treat / emote) |

---

## Challenge Variant

**Number Range Stretch** — `number-range-stretch` sub-mode (facts within 10 instead of 5).

- **Entry point** — A "Stretch Round!" banner appears on Fluency Within 5's tile in the Sanctuary 1× per day at launch (tunes post-launch).
- **Reward bump** — Challenge chest per `reward-economy.md`.

---

## Edge Cases & Error Handling

- **Kid taps two tiles in rapid succession** — first tap counts; second is ignored within the standard Tap-Pick debounce (200 ms).
- **Free-write produces a multi-digit answer for a single-digit problem** — answer is rejected as wrong (the expected answer is single-digit within 5). Narrator: "The answer is one digit. Try again."
- **Speed-run timer expires while kid is mid-stroke (free-write)** — current stroke completes; if recognized as the correct answer, count as correct (don't punish the kid for being close to the answer when the timer fires). If incorrect or unrecognized, count as wrong.
- **Distractor tiles include the correct answer twice (bug)** — must not happen; the tile-pool generator picks distinct values. Add a validation check.
- **Per-fact mastery and the 42-fact instance set** — if the concept registry's instanceKeys for K.OA.5 doesn't match the activity's expected fact set, log an error. The activity ships with a hardcoded fact set that mirrors the registry; mismatch = bug.
- **Stylus disconnect mid-write (Pictorial+)** — current stroke cancels; kid retries.
- **App backgrounded mid-round** — round restarts on resume (within 5 min) since fluency rounds are short.
- **Audio muted** — visual cues (chalkboard problem, Buddy reactions) carry the full experience.

---

## Decisions Needed

- **Speed-run timer length** — proposed 10 s per problem. At K, this is more "if you stall, move on" than a stress timer. Confirm in playtest.
- **Combo multiplier cap** — proposed 3×. Higher caps reward sustained accuracy but may feel grindy. 3× feels balanced for K.

---

## Notes for Later

- **Per-fact distractor authoring** — the activity needs a distractor table per fact (e.g., for `3+2=5`, distractors might be `4, 5, 6, 7`). Author this table before launch.
- **Treat collection display** — UX for the 42-treat case in the Hub. A jar-shelf visualization. Confirm with art.
- **Speed-run music tempo bump** — 100 → 110 BPM. Confirm doesn't feel disruptive.
- **First-encounter forgiveness for fluency lessons** — the lesson uses a sample fact (e.g., "2+1"). After lesson, the activity has 41 other facts the kid hasn't seen explicitly. First-encounter forgiveness applies at the concept level (K.OA.5), not per-fact. Confirm the kid isn't expected to perfect-score a brand-new fact in their first round.

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical across phases. **Stylus input** (for free-write at higher CPA layers) flows through `StylusInputProvider`.


```
FluencyWithin5View
├── ClearingBackgroundLayer (parallax grass)
├── BuddyView (on mat; larger than other K activities; reaction animations are central)
├── ChalkboardView (the problem display)
├── TileSelectorView (Concrete layer: 4 tiles below the chalkboard)
├── FreeWriteZoneView (Pictorial+ layer: replaces tile selector)
├── ComboMultiplierView (visible in speed-run mode)
├── SpeedRunTimerRing (visible in speed-run mode)
├── ProgressIndicator (problem N of M)
├── TreatJarShelf (visible in background; jars fill as treats are earned in-session)
├── HUDView
└── NotebookTab (encouraged in free-write rounds)
```

### Reusable opportunities surfaced

- **Per-fact intelligent practice scheduling** — first activity to do this. Generalizes for 1st-grade Quick-Cast (within 10) and 2nd-grade Power Drills (within 20). Both will need the same "needs work" weighting. Should be a shared module: `FactSchedulingEngine`.
- **Speed Run mode** — first opt-in timed mode in K. Pattern generalizes for 1st-grade Quick-Cast and 2nd-grade Power Drills. Should be a shared `SpeedRunMode` component with combo multiplier and timer ring.
- **Buddy as primary host** — first activity where Buddy is sized larger and is the kid's practice partner. Pattern may reuse for future Buddy-centric activities (Buddy training, Buddy mini-games).
- **Distractor tile generator** — picks N-1 close-miss distractors. Generalizes for any single-answer tile-select activity (Storyteller's Pond's tile-select fallback, future).

### Performance

- ~5 sprites on screen at any time (chalkboard, tiles, Buddy, treat jar). Trivial.
- Per-fact selection logic runs once per problem; cheap.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first opt-in K activity; first to use per-fact intelligent practice scheduling; first to include a Speed Run timed mode in K (opt-in only) | |
