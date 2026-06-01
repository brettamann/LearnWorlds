# Adaptive Scaffolding State Machine

> The invisible system that silently moves a kid up and down the Concrete → Pictorial → Abstract progression based on their performance. Every activity consumes this state to decide which representation to show; every round emits success/failure events that update it.

The kid never sees a "level up" or "you've been moved down a level" message. The adaptive behavior is **invisible by design** — the kid just notices that the problems look slightly different.

---

## Principles

1. **Per concept, not per activity.** A kid's layer for *one-to-one correspondence* persists across Counting Parade, Story Pond, and any other activity that touches that concept.
2. **Generous on the way down, conservative on the way up.** It's easier to drop a layer (kid is struggling, reduce friction) than to climb (kid genuinely needs to demonstrate the higher representation).
3. **Mastery requires breadth.** Not just "got it right once at the abstract layer" but "consistently demonstrates at the abstract layer across multiple sessions and contexts."
4. **Wrong answers are warmth, then demonstration.** Never punitive. Always show the *next layer down* and re-attempt the original prompt later.
5. **No surprise jumps.** Promotion/demotion changes one layer at a time per round outcome. Big swings only over many rounds.

---

## Data Model

### Per kid, per concept

```
ConceptState {
  conceptId: String              // e.g., "K.CC.4a" (one-to-one correspondence)
  granularity: ConceptWide | PerInstance  // see "Mastery Granularity" below
  instanceKey: String?           // present iff granularity = PerInstance (e.g., "5" for the numeral 5)
  currentLayer: Concrete | Pictorial | Abstract
  firstEncounter: Bool           // true until the MicroLesson (if any) has played; see "First Encounter"
  layerStats: {
    Concrete:  { attempts: Int, successes: Int, currentStreak: Int }
    Pictorial: { attempts: Int, successes: Int, currentStreak: Int }
    Abstract:  { attempts: Int, successes: Int, currentStreak: Int }
  }
  sessionsTouched: [SessionId]   // distinct sessions where this concept was attempted
  lastUpdated: Timestamp
  masteryStatus: Introduced | Practicing | Mastered
}
```

### Concept Registry

The registry maps **Utah standard codes → concept IDs**, sometimes 1:1, sometimes splitting a standard across sub-concepts (e.g., K.CC.4 splits into 4a, 4b, 4c).

The registry is canonical content data and lives in `data/concept-registry.json` (TBD). Activities declare which concept IDs they touch per round.

### Mastery Granularity

A concept's mastery state is tracked at one of two granularities, declared in the concept registry:

- **`concept-wide`** (default) — one `ConceptState` per kid per concept. The kid has a single mastery state for the whole concept across all activities. Most concepts use this (e.g., K.OA.3 decomposition is one state regardless of which target number is being decomposed).
- **`per-instance`** — N `ConceptState` records per kid per concept, one per declared instance key. Used when a concept has many discrete sub-elements that benefit from independent mastery tracking.

**Examples of per-instance concepts:**
- **K.CC.3** (write numerals 0–20) — 21 instances, one per numeral. The kid may have mastered "1" but still be Practicing "13."
- **K.OA.5 / 1.OA.6.b / 2.OA.2.b** (fluency activities) — 1 instance per fact (e.g., "3+4", "7+5"). The kid may know `3+4=7` but still be working on `8+5=13`.

**Concept registry declaration:**

```jsonc
{
  "id": "K.CC.3",
  "granularity": "per-instance",
  "instanceKeys": ["0", "1", "2", ..., "20"]   // enumerated set
}

{
  "id": "K.OA.3",
  "granularity": "concept-wide"   // no instance keys
}
```

**Concept-wide mastery** uses the standard "5 successes at Abstract, ≥3 sessions, ≥3 days" rule (see *Mastery Definition* below). **Per-instance mastery** applies the same rule **per instance** — each numeral or fact reaches mastery independently.

**Concept-wide rollup from per-instance**: for per-instance concepts, the overall concept-wide mastery rolls up only when **all instances are mastered**. K.CC.3 reaches concept-wide `Mastered` when all 21 numerals are individually `Mastered`. Until then, the concept-wide status is `Practicing` (with N of M instances mastered shown in the dashboard).

### Exercises-Only Mastery (coverage-based)

Some concepts are **exercised** by multiple activities but never explicitly **introduced** via a MicroLesson — they have no canonical introducer and no `lesson-*.md` file. Their mastery cannot use the standard "first lesson + success counting" model. Instead, they use **coverage-based mastery**.

**Registry declaration:**

```jsonc
{
  "id": "K.OA.1",
  "granularity": "concept-wide",
  "requiresLesson": false,
  "exercisesOnlyMastery": {
    "demonstrationModes": ["scene-manipulation", "notebook-drawing", "equation-form"],
    "minModesDemonstrated": 2,
    "minSessions": 3,
    "fallbackPracticeCount": 20
  }
}
```

**Rule:**

A concept reaches `Mastered` when **either** condition holds:

1. **Coverage path**: kid has demonstrated **≥ `minModesDemonstrated`** of the declared demonstration modes across **≥ `minSessions`** distinct sessions.
2. **Fallback path**: kid has logged **≥ `fallbackPracticeCount`** successes in any activity that exercises this concept.

**Telemetry contract:**

Activities that exercise an exercises-only concept emit `pond.representation_used` (or analogous) events with a `representationType` payload field matching one of the declared `demonstrationModes`. The mastery engine aggregates these events.

**Example for K.OA.1:**
- Activity Storyteller's Pond emits `pond.representation_used { type: "scene-manipulation" }` when the kid drags creatures during a story.
- The same activity emits `{ type: "notebook-drawing" }` when the kid sketches in the notebook during a round.
- The same activity emits `{ type: "equation-form" }` when the kid solves a problem at the Abstract CPA layer (where equations appear).
- When the kid has demonstrated ≥ 2 of the 3 modes across ≥ 3 sessions, K.OA.1 reaches `Mastered`.
- Or, if the kid has 20 successes in K.OA.1-exercising activities, the fallback path triggers mastery.

This model lets us track mastery for "soft" concepts that don't fit the lesson-and-practice mold without requiring an artificial introduction event.

#### Sibling credit rules (added 2026-05-30)

Some exercises-only concepts can be **structurally hard to reach** because their demonstration modes overlap a sibling concept's natural success path. K.OA.1's `scene-manipulation` mode, for example, is essentially what a kid does when they succeed at K.OA.2 word problems — but a kid who consistently picks tile-select as their answer input might never trigger the `scene-manipulation` event explicitly.

A registry entry can declare **sibling credit rules** that automatically grant a demonstration mode based on a sibling concept's mastery state:

```jsonc
{
  "id": "K.OA.1",
  "exercisesOnlyMastery": {
    "demonstrationModes": ["scene-manipulation", "notebook-drawing", "equation-form"],
    "minModesDemonstrated": 2,
    "minSessions": 3,
    "fallbackPracticeCount": 20,
    "siblingCreditRules": [
      {
        "siblingConceptId": "K.OA.2",
        "siblingMasteryState": "Practicing",
        "grantedMode": "scene-manipulation",
        "rationale": "K.OA.2 inherently exercises scene manipulation."
      }
    ]
  }
}
```

**Runtime behavior:** when K.OA.2's state advances to `Practicing` (or higher), the mastery engine credits K.OA.1 with the `scene-manipulation` demonstration mode. The kid then needs to demonstrate just **1 additional mode** (notebook OR equation) to reach the `minModesDemonstrated: 2` threshold — keeping K.OA.1 mastery reachable for tile-select-preferring kids.

Sibling credits do **not** lower `minSessions` or `fallbackPracticeCount`; the kid still needs distributed practice. The sibling credit only fills one mode-slot.

---

## The State Machine

Three layers, two directions, four trigger events.

```
         promote_success                   promote_success
Concrete ────────────────────► Pictorial ────────────────────► Abstract
         ◄──────────────────            ◄──────────────────
         demote_struggle                   demote_struggle
```

### Triggers

| Trigger | When | Effect |
|---|---|---|
| `success` | Round passed at current layer | streak++; check promote_success |
| `failure` | Round failed at current layer | streak = 0; check demote_struggle |
| `hint_used` | Kid used a scaffold mid-round | counts as soft-success; does NOT advance promotion streak |
| `tile_fallback_used` | Kid resorted to tile selection (numwrite) | counts as fail for layer movement |

### Promotion (move up a layer)

- **promote_success** fires when `currentStreak ≥ 3` at the current layer.
- Promotion bumps `currentLayer` one step up (Concrete → Pictorial → Abstract).
- The current-layer streak resets to 0 (kid now has to demonstrate at the new layer).
- Cannot promote past Abstract.

### Demotion (move down) — staggered

Demotion is **staggered** so the system makes smaller adjustments first. CPA layer demotes before sub-mode whenever both are available.

**`demote_struggle`** fires when **2 consecutive failures** at the current configuration occur:

1. **If `currentLayer > Concrete`**: demote one layer (Abstract → Pictorial → Concrete). Smaller change first.
2. **Else if the activity has multiple sub-modes and `currentSubMode > simplest`**: demote one sub-mode step; `currentLayer` resets to the activity's default starting layer for the new sub-mode (typically Concrete for K).
3. **Else**: no further demotion possible. The kid is at the floor. Continued failures still fire the `failure` event but no layer/sub-mode change occurs; the dashboard flags persistent floor-failures for teacher/parent attention.

**Streak after demotion**: the streak that triggered the demote resets to 0. The demoted-layer streak does **not** reset — the kid keeps any prior success accumulated there.

**Why staggered?** A smaller change (layer) first lets the system collect more signal before making a bigger change (sub-mode). A struggling kid gets gentler representations before the conceptual content simplifies.

### Why asymmetric (3 vs 2)?
Demotion is faster than promotion. A struggling kid gets relief quickly; a thriving kid has to demonstrate the higher representation a little more before we trust it.

### Failure Cap and Forced Demotion — no skipping

**Principle: prefer demoting to skipping. The kid learns nothing by skipping a problem they can't solve.**

There is no "skip this problem" option presented to the kid during a round. Failures always lead to learning — at an easier level if needed.

**The rule** (applies to all activities except MicroLesson You-Do phases):
- **2 consecutive failures** trigger `demote_struggle` (per the staggered rule above), whether the failures are on the same problem (retries) or across different problems (round-to-round).
- After demotion, the **next problem is presented at the lower CPA layer or simpler sub-mode**.
- The kid never moves past a failed problem at the same level — they get another problem, just easier.

**MicroLesson You-Do phases** override with first-encounter forgiveness:
- Up to **3 attempts** at the same You-Do problem before the lesson ends as "failed out."
- Failed-out outcome does **NOT** trigger `demote_struggle` (we don't double-punish a kid who just saw the demos).
- See `micro-lessons.md`.

**Manual exit**: the kid can always tap Exit to return to the Hub; that's not a "skip" of any individual problem — it's leaving the activity entirely.

---

## First Encounter (MicroLesson Branch)

Before normal scaffolding begins for a freshly-encountered concept, the system checks whether a **MicroLesson** should play. Full spec: `micro-lessons.md`.

### Branch decision

When a round begins, the scaffolding system inspects each concept the round touches:

```
for conceptId in round.conceptIds:
  state = ConceptState(kid, conceptId)
  registry = ConceptRegistry[conceptId]
  if state.firstEncounter AND registry.requiresLesson AND activity.introduces(conceptId):
    return PlayLesson(registry.lessonId)
  else:
    proceed with normal scaffolding flow
```

If multiple introduced concepts qualify in the same round, **only the first by registry order** plays its lesson; others defer to their own first encounters in later rounds.

### What "first encounter" means

- `firstEncounter` is initialized to `true` when `ConceptState` is created (lazily, on the kid's first touch of the concept).
- It flips to `false` when the lesson's You-Do phase completes (passed or failed out — both count).
- For concepts where `requiresLesson` is `false`, `firstEncounter` flips to `false` on the first ordinary round outcome (success or failure).
- `firstEncounter` **resets to `true`** if the kid hasn't touched the concept in **60 days** (2 months). Next encounter plays the lesson again — kids returning after long absences get a refresher rather than being expected to remember. The library entry is preserved; the kid keeps any cosmetic rewards earned previously. The refresher just re-plays the lesson and records a fresh `firstEncounter` event.

### After the lesson

When the MicroLesson finishes, the round proceeds as if it were the kid's first non-lesson round of this concept:
- `currentLayer` is set per `Starting Layer (Fresh Concept)` below.
- The You-Do round inside the lesson **already counts** as the first round outcome — the activity does not run an additional round immediately after.
- Mastery status transitions per the lesson outcome:
  - Lesson You-Do passed → `Introduced` → `Practicing`.
  - Lesson You-Do failed out → `Introduced` (and dashboard flag).

### Activities that exercise but don't introduce

A concept can be **introduced** by activity A and **exercised** by activity B. If a kid hits the concept in B before A, the system still plays the lesson (lessons are concept-keyed, not activity-keyed). The lesson uses its **canonical** introducing region's style (per `micro-lessons.md`), even though the kid is currently in a different activity.

### Concepts that don't get lessons

If `requiresLesson` is `false`, no branch fires. The round proceeds at the starting layer immediately.

---

## Starting Layer (Fresh Concept)

When a concept is touched for the first time (after the MicroLesson, if one fired), the kid's `currentLayer` is set by the **grade default**:

| Grade | Default starting layer |
|---|---|
| K | Concrete |
| 1 | Pictorial |
| 2 | Abstract |

Override per concept allowed (e.g., 1st-grade "making tens" might start at Pictorial even though some 1st-grade concepts start higher).

---

## Mastery Definition

A concept is **Mastered** when **all** of:
- ≥ 5 successes at the Abstract layer
- Across ≥ 3 distinct sessions
- Over a span of ≥ 3 calendar days
- Most recent attempt at Abstract was a success
- No failures in the last 3 Abstract attempts

Mastery is the dashboard's headline metric. Until then, the concept is one of:
- **Introduced** — has been seen at least once (any layer)
- **Practicing** — has had successes but mastery conditions not met

---

## Wrong-Answer Behavior

The "warmth-then-demonstrate" pattern is universal:

1. **Acknowledge warmly** — region narrator delivers a kind line. (Not "Wrong!" Not "Try again!" Something like "Almost. Watch this.")
2. **Demonstrate at the next layer down** — animate the same problem with one more layer of scaffold. (Abstract → Pictorial: bar model appears alongside the equation. Pictorial → Concrete: counters appear.)
3. **Re-attempt the original** — after the demonstration finishes, the kid gets a fresh problem at *their current layer*. Not the same problem (avoids "I memorized the answer"); a new problem of the same type.
4. **Layer movement** — 2 consecutive wrong answers triggers `demote_struggle`. The third problem (if it ever comes) will be at the lower layer.

Activities can override the "next layer down demonstration" with a custom animation appropriate to the activity, as long as the principle holds (show the answer at one more concrete representation).

---

## Cross-Activity Propagation

When a kid succeeds or fails at a concept in **Activity A**, the result updates the concept state used by **Activity B**.

Example:
- Kid plays Counting Parade and demotes from Pictorial to Concrete on K.CC.4a.
- Kid later opens Story Pond. Story Pond also touches K.CC.4a.
- Story Pond starts the kid at Concrete for K.CC.4a problems.

This means the system has **one truth per concept per kid**, not per (concept × activity).

### Caveats
- Activities can show a layer **richer** than the kid's current layer if it makes sense for the activity context (e.g., always show ten-frames in Ten-Frame Pond even for kids whose K.NBT.1 layer is Concrete, because the ten-frame *is* the activity). The kid's *judgment* still happens at their concept layer.
- Some concepts are activity-bound (e.g., a "shape composition fluency" might only live inside Build-a-Habitat). Those are flagged in the registry.

---

## Session Behavior

- **Within a session** — promotion/demotion fires immediately. The kid feels the adjustment within the activity.
- **Across sessions** — the kid's concept state persists between sessions. Yesterday's progress is today's starting point.
- **Decay** — none at launch. If a kid hasn't touched a concept in a while, they keep their layer. (Possible v1.1: light decay after long absence — e.g., demote one layer after 30 days idle.)

---

## Hint Layer (within-layer scaffolding)

Independent of layer movement, the system fires **hints** within a layer when a kid hesitates or near-fails:

- **Hesitation hint** — after **5–8 s** of no input, a soft visual nudge (e.g., highlight the next item to tap, glow the next snap point).
- **Mid-stroke hint** — for trace/cut mechanics, a ghost-path nudge after **3 s** of stalled motion.
- **Confirmation hint** — for low-confidence digit recognition, the "I think I see a 7 — is that right?" prompt.

Hints are tracked per round and reported via telemetry. They do **not** demote the layer but do prevent promotion (`hint_used` counts as soft-success, not full-success).

---

## Telemetry Events

| Event | When | Payload |
|---|---|---|
| `scaffold.round.success` | round passed | conceptIds[], layer, hintsUsed |
| `scaffold.round.failure` | round failed | conceptIds[], layer, attemptDetails |
| `scaffold.promote` | layer increased | conceptId, fromLayer, toLayer, streakAtPromote |
| `scaffold.demote` | layer decreased | conceptId, fromLayer, toLayer, consecutiveFailures |
| `scaffold.mastery_reached` | mastery conditions met | conceptId, totalAttempts, daysToMastery |
| `scaffold.hint_fired` | a hint was shown | conceptId, hintType, layer |

---

## Activity Contract

Activities pass a `ScaffoldContext` to the runner at round start and receive layer instructions back:

```
ScaffoldQuery {
  conceptIds: [ConceptId]            // which concept(s) this round targets
  problemType: ProblemTypeId         // activity's own type identifier
  introducedConceptIds: [ConceptId]  // subset of conceptIds the activity flags as introducing (vs exercising)
}

ScaffoldResponse {
  presentationLayer: Concrete | Pictorial | Abstract
  hintsAllowed: Bool                 // some activities suppress hints in challenge mode
  firstEncounterLesson: MicroLessonId?  // if non-null, route to the lesson runner before the round
}

// maxAttempts is a universal rule (2 default, 3 for MicroLesson You-Do)
// rather than a per-round field. See "Failure Cap and Forced Demotion" above.
```

After the round:
```
ScaffoldOutcome {
  conceptIds: [ConceptId]
  result: Success | Failure | Skipped
  hintsUsed: Int
  attemptCount: Int
  fallbackUsed: Bool         // e.g., numwrite tile fallback
}
```

The state machine consumes outcomes and emits events.

---

## Edge Cases

- **Round touches multiple concepts** — outcome applies to all listed `conceptIds`. Layer movement is computed per concept independently.
- **Activity abandons mid-round** (kid exits) — no outcome recorded; the round doesn't count for either direction.
- **Kid skips a problem** (where skipping is offered) — `Skipped`. No layer movement.
- **Challenge mode** — challenge rounds always run at the kid's current Abstract layer (or higher if the activity supports it). Challenge results do **not** affect baseline concept state — challenges are reward-grinding, not assessment.

---

## Adversarial / Cheat Concerns

- **Kid taps randomly to fail quickly and lower difficulty** — possible. Mitigation: streak-based demotion is forgiving but slow. A kid who fails enough rounds will land at Concrete and probably get bored. The activity's reward emissions cap on Concrete (smaller coin payouts for the easier layer) reduces the incentive. Not bulletproof; not a problem worth over-engineering for K–2.
- **Parent helps the kid finish problems** — outside our control. The dashboard surfaces "completed quickly with no scaffolding" patterns as a soft signal.

---

## Runtime Implementation Notes

The on-disk `ConceptState` array (per `mastery-state.schema.json`) is the **persistence shape**. At runtime, the engine maintains an in-memory **index** for fast lookup; this section captures the contract.

### Index requirements

Lookups happen every time an activity round starts (to resolve `ScaffoldQuery`), and on every round-outcome telemetry event (to update mastery state). For a kid with full content coverage, the array size grows quickly:

| Grade | Concept-wide states | Per-instance states | Total per kid |
|---|---|---|---|
| K | ~18 | ~63 (K.CC.3 = 21 numerals; K.OA.5 = 42 facts) | ~80 |
| 1 (estimated) | ~25 | ~145 (1.OA.6.b ≈ 100 within-10 facts; place value instances) | ~170 |
| 2 (estimated) | ~30 | ~400+ (2.OA.2.b ≈ 380 within-20 facts; multi-digit instances) | ~430+ |

Linear scans through hundreds of records on every round entry would not meet the latency budget. The runtime must index.

### Required index

```
ConceptStateIndex {
  byCompositeKey: Map<String, ConceptState>   // key = "{conceptId}::{instanceKey ?? '*'}"
  byConceptId:    Map<ConceptId, [ConceptState]>  // for "all states under K.CC.3" queries
}
```

- **Build on load**: index is constructed from the persisted array when the kid's profile is loaded.
- **Maintain on mutation**: every state update writes through the index AND the array (the array is the source of truth on disk; the index is the lookup accelerator).
- **Rebuild on schema migration**: if the persisted file is from an older schema version, migrate the array first, then rebuild the index.

### Composite key convention

- Concept-wide concept: key = `"{conceptId}::*"` (e.g., `"K.CC.4a::*"`).
- Per-instance concept: key = `"{conceptId}::{instanceKey}"` (e.g., `"K.CC.3::5"`, `"K.OA.5::3+2"`).
- The `*` sentinel for concept-wide keeps the key format uniform — every lookup uses the same key shape.

### Exercises-only tracking index

`exercisesOnlyTracking` is keyed by `conceptId` in the persistence schema; runtime keeps it as a simple `Map<ConceptId, ExercisesOnlyTracking>`. No composite key needed since exercises-only concepts are always concept-wide.

### Telemetry consumption

When a `scaffold.round.success` or `scaffold.round.failure` event fires, the runtime:
1. For each conceptId touched: derive the composite key (with instanceKey if the concept is per-instance and the activity provided one in the round context).
2. Look up the `ConceptState` via the index — O(1).
3. Mutate the state (layer, streak, mastery status checks).
4. Write through to disk (batched if needed, but never lost).

### Persistence batching

State mutations during a session can be batched and flushed at:
- Session end (definitely)
- Activity exit (preferred)
- Round completion (acceptable; modest write volume)
- Each state mutation (overkill for K but acceptable)

The implementation choice is a perf-vs-durability trade-off. Suggest **flush on activity exit** at launch with batched fsync; tune based on telemetry of session durations and crash rates.

### Per-instance state explosion at higher grades

By 2nd grade, a heavily-engaged kid can accumulate 400+ `ConceptState` records. Worth flagging:

- **Persisted size** — at ~200 bytes per record, that's ~80 KB per kid. Trivial for local storage; modest for cloud sync.
- **Lazy initialization** — `ConceptState` records aren't created until first touch. A new kid starts with 0 records and accumulates only what they've encountered.
- **Aging / archival** — at launch, all records persist forever. If long-term database size becomes a concern (likely v2+ scale issue), archive `Mastered` records with old `lastUpdated` dates to a cold-storage table.

---

## Open Questions

- **Promote streak (3) and demote threshold (2)** — playtest with kids; tune per grade if needed.
- **Mastery thresholds (5 / 3 / 3-day)** — these are sensible defaults. The teacher dashboard may want adjustable thresholds for classroom IEP cases (v1.1).
- **Concept granularity** — splitting K.CC.4 into 4a/4b/4c is one call; we may discover other standards benefit from sub-concept splits. Iterate during activity-spec authoring.
- **Layer-skip on extreme success** — if a kid posts 6 consecutive successes at Concrete *without using any hints*, is that signal enough to skip Pictorial and jump to Abstract? Tempting; risks pushing too fast. Defer.
- **Long-term decay** — v1.1 likely. Threshold and decay model TBD.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-29 | Initial draft | |
| 2026-05-29 | Added First Encounter (MicroLesson) branch; `ConceptState.firstEncounter` field; `ScaffoldQuery.introducedConceptIds` and `ScaffoldResponse.firstEncounterLesson` | |
| 2026-05-30 | Staggered demotion rule (CPA layer first, then sub-mode); explicit "no skipping" failure cap; firstEncounter resets after 60 days idle; removed `maxAttempts` field (universal rule) | |
| 2026-05-30 | Added **mastery granularity** (concept-wide default, per-instance opt-in with `instanceKeys`); added **exercises-only mastery** (coverage-based for concepts never explicitly introduced — e.g., K.OA.1) | |
| 2026-05-30 | Added **Runtime Implementation Notes** section covering the in-memory ConceptState index (`byCompositeKey` + `byConceptId`), composite key convention (`{conceptId}::{instanceKey ?? '*'}`), persistence batching guidance, and per-instance state size estimates per grade | |
| 2026-05-30 | Added **sibling credit rules** to exercises-only mastery. K.OA.1 now credits `scene-manipulation` automatically when K.OA.2 reaches `Practicing`, making K.OA.1 mastery reachable for tile-select-preferring kids | |
