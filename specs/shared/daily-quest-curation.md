# Daily Quest Curation

> The algorithm that picks **which rounds to play** in a kid's Daily Quest each day. Daily Quest is the ≤ 5-minute short, varied warm-up across already-introduced concepts.

References: `specs/shared/adaptive-scaffolding.md`, `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `we-are-going-to-eventual-lantern.md` (top-level plan).

---

## Goals

1. **Quick + varied.** ≤ 5 minutes total, 5 rounds typical, spread across activities.
2. **Spaced repetition.** Concepts the kid hasn't touched recently get priority.
3. **Mastery-aware.** Concepts in `Introduced` or early `Practicing` weight higher than `Mastered`.
4. **No surprises.** Daily Quest never introduces a new concept (those get lessons in Free Play); only reinforces.
5. **Streak-respecting.** A kid on a streak shouldn't have the streak broken by an impossible quest day.

---

## Inputs

The algorithm reads:
- The kid's full `ConceptState` set (per `adaptive-scaffolding.md`).
- The kid's session log for the past 14 days.
- The kid's current region (Sanctuary / Wundletown / Mathopolis).
- The kid's grade level (sets the eligible concept pool).
- Today's date (for spaced-repetition windowing).
- The activity registry (to know which activities exercise which concepts).
- Recent telemetry: hesitation rates, fail rates, abandon rate by activity.

---

## Output

A `DailyQuest` = ordered list of **5 round specs**, each:
```
{
  activityId: ActivityId,
  subMode: SubModeId,
  conceptIds: [ConceptId],  // for telemetry
  presentationLayer: Concrete | Pictorial | Abstract,  // matches kid's current state
  reasonForInclusion: enum (see below)
}
```

`reasonForInclusion` is one of:
- `spaced-repetition-due` — concept hasn't been touched in N days
- `practicing-reinforcement` — concept at Practicing, needs more reps
- `near-mastery-finisher` — concept is close to Mastered threshold
- `rotation-variety` — included for activity-variety
- `streak-friendly-warmup` — easy/familiar round to keep streak alive

---

## Algorithm

### Step 1 — Pool eligible concepts

A concept is eligible for Daily Quest if:
- Kid's `ConceptState` exists for it (kid has been introduced).
- Concept's `firstEncounter` is `false` (lesson already played).
- Concept belongs to the kid's grade-region OR earlier grades (cross-grade review allowed; ahead-of-grade not).

For per-instance concepts: each `instance` is eligible separately. Pick at most 1 instance per concept per quest.

### Step 2 — Score each eligible concept

Each concept gets a priority score:

```
score(concept) =
    spacingWeight(daysSinceLastTouch)         // 0–40
  + masteryWeight(masteryState)               // 0–30
  + struggleWeight(recentFailRate)            // 0–20
  + freshnessWeight(neverDoneInDailyQuest)    // 0–10
```

| Sub-score | Logic |
|---|---|
| `spacingWeight` | 0 days ago = 0; 3 days = 20; 7+ days = 40 (capped) |
| `masteryWeight` | Introduced=30; Practicing=20; near-mastery=15; Mastered=5 |
| `struggleWeight` | Fail rate in last 5 rounds: 0%=0; 20%=10; 40%+=20 |
| `freshnessWeight` | Never in a Daily Quest before = 10; otherwise 0 |

### Step 3 — Pick 5 concepts

Greedy selection with constraints:
1. Pick the highest-scoring concept.
2. Pick the next highest, with **diversity constraint**: prefer concepts from a different activity than already-picked.
3. Repeat until 5 concepts picked.
4. **Tie-breaker**: alphabetical conceptId (deterministic; helps with bug repro).

### Step 4 — Sequence the 5 rounds

Within the 5 picks, sequence for kid flow:
1. **First round** = a high-confidence (high mastery, low recent fail rate) concept. Easy warmup.
2. **Middle rounds** = spaced repetition + practicing reinforcement.
3. **Last round** = streak-friendly (high confidence again) to end on a positive note.

### Step 5 — Configure each round

For each picked concept:
- Resolve which activity exercises it (use canonical-introducer first, then any exerciser).
- Use kid's current sub-mode + CPA layer for that concept's activity.
- If concept is per-instance, pick the highest-priority instance per Step 2 logic.
- Generate round parameters (count, target, etc.) per activity spec.

---

## Edge cases

### Brand-new kid (no ConceptState records yet)
- **First Daily Quest** of a kid's lifetime: launches `Counting Parade` with `count-the-parade` sub-mode and the K.CC.4a lesson. Single round, not 5. This is the kid's onboarding-into-K experience.
- Subsequent days: as more concepts get introduced, Daily Quest grows toward 5 rounds.

### Kid has fewer than 5 eligible concepts
- Daily Quest is **shorter** that day (e.g., 3 rounds for a kid who has only touched 3 concepts).
- Encourages Free Play to broaden exposure.

### Kid is on a struggle pattern (many recent fails)
- Daily Quest temporarily prioritizes `Mastered` and `near-mastery-finisher` rounds.
- Avoids stacking struggle.
- After 2 consecutive Daily Quests of low confidence, dashboard surfaces "consider review" to parents.

### Kid switched regions
- Eligible concepts still include the prior region (kid can stay in Sanctuary while in Wundletown for review).
- Visual flavor of Daily Quest matches the kid's current Hub region.

### Real-world events
- **Birthday day**: prepend a brief Buddy birthday party (~30 s) before the quest.
- **Holiday active**: themed visual overlay on the quest (no math change).

### Same activity multiple times
- The diversity constraint usually prevents this, but it's allowed if 2 concepts within one activity both rank very high. Cap: at most 2 rounds per activity per quest.

---

## Time-of-day handling

The Daily Quest is "the kid's first session of the day." Per-day means **per calendar day in the kid's local time**. Multiple sessions in one day:
- First session = Daily Quest (with the day's curated selection).
- Subsequent sessions = Free Play OR the kid can replay Daily Quest from the library (no re-credit for the day's streak; replay is just for fun).

---

## Streak-friendliness

Daily Quest is the **streak gate** for the daily-streak reward system. A streak day is satisfied when:
- The kid completes ≥ 3 of the 5 quest rounds, OR
- The kid plays ≥ 5 minutes in Free Play.

The latter clause means a kid who skips Daily Quest but plays Free Play extensively still keeps their streak.

---

## Telemetry

| Event | Payload |
|---|---|
| `daily_quest.assembled` | `kidId`, `roundCount`, `conceptIds[]`, `reasonForInclusion[]` |
| `daily_quest.started` | `kidId`, `assembledQuestId` |
| `daily_quest.round_completed` | `questId`, `roundIndex`, `success`, `latencyMs` |
| `daily_quest.completed` | `questId`, `roundsCompleted`, `roundsPassed`, `totalDurationSec` |
| `daily_quest.abandoned` | `questId`, `roundsCompleted`, `abandonedAt` |

These feed playtest analysis of quest fit + the streak-friendliness check.

---

## Implementation notes

### Suggested module structure

```
DailyQuestCurator
├── EligibleConceptResolver (Step 1)
├── ConceptScorer (Step 2)
├── DailyQuestAssembler (Steps 3–5)
└── DailyQuestRunner (executes the assembled quest, emits telemetry)
```

### Performance

- Concept pool at K is ~25 entries; at 2nd grade up to ~70.
- Scoring is O(n) per concept; trivial overhead.
- Assembly runs once per day per kid; cached for the day.

### Cache invalidation

The assembled quest invalidates if:
- Kid achieves mastery mid-day (one of the picked concepts is no longer the right pick).
- Kid skips an activity (re-assemble from the remaining).
- Calendar day rolls over.

---

## Open Questions

- **Daily Quest length** — 5 rounds proposed; the playtest watchlist will track whether 5 is right.
- **Cross-region Daily Quest** — a 2nd-grader's quest may include K review rounds. Confirm the kid's current region's visual flavor wraps these review rounds gracefully.
- **Spaced repetition decay curve** — the linear-to-7-days curve is a heuristic. Tune from telemetry.
- **Streak grace days** — should kids get N "skip days" per month to preserve streaks during travel/illness? Suggest yes at launch (3/month, surfaced as "you have 3 streak savers"). Confirm in playtest.
- **Curation override for assignments** — when teachers/parents assign specific activities (per the dashboard's assignable activities feature), do those replace Daily Quest, or stack alongside? Suggest **replace for that day** to keep total session length sane.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — spaced-repetition + mastery-weighted curation algorithm, 5-round target, streak-friendly bookends | |
