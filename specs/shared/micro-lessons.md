# MicroLessons (Teach Before Testing)

> The system that introduces new procedures, strategies, and representations *before* the kid is asked to perform them solo. Lessons fire on first encounter with a flagged concept, follow **I-Show / We-Try / You-Do**, and live in a re-watchable per-region library after.

References: `adaptive-scaffolding.md` (First Encounter branch), `stylus-mechanics.md`, `reward-economy.md`.

---

## Principles

1. **Teach before testing.** Novices learn faster from worked examples than from problem-solving practice (the worked-example effect). New concepts get explicit instruction, not just gentle correction.
2. **Brisk, never patronizing.** Lessons are tight (~60–90 s total). Real math language. Show the *strategy* explicitly with visible thinking.
3. **Recoverable.** Every lesson stays in a library the kid can return to anytime. Forgetting is allowed.
4. **Skippable for experts.** Kids who already know the concept can fast-forward to the You-Do round via an "I've got this" affordance.
5. **First encounter only is mandatory.** Subsequent encounters use normal adaptive scaffolding.
6. **One regional voice per lesson.** A K-grade lesson always uses the Sanctuary narrator and art, even if replayed from Wundletown's Spell Book. Lesson identity is stable.

---

## Trigger Conditions

A MicroLesson fires when **all** are true:

- The concept's `requiresLesson` flag is `true` in the concept registry.
- The kid's `ConceptState.firstEncounter` for this concept is `true` (no prior lesson played).
- The activity declares this concept as one it **introduces** (vs *exercises*) per the activity spec template.

A kid can **manually replay** any lesson they've completed from the Hub's regional library (Stamp Wall / Spell Book / Casebook).

A kid **cannot** trigger a lesson for a concept that hasn't been introduced yet (the library only contains completed lessons; locked-future lessons are optional — see Open Questions).

---

## Which concepts get lessons?

> **Criterion:** concepts that introduce a procedure, strategy, or new representation.

Examples that **do** get lessons:
- One-to-one correspondence (K.CC.4a)
- Cardinality — "the last number you say is how many" (K.CC.4b)
- Ten-frame structure (K.NBT.1)
- Decomposition into pairs (K.OA.3)
- The "make a ten" strategy (1.OA.6)
- The unknown-addend interpretation of subtraction (1.OA.4)
- Bundling 10 ones into a ten (1.NBT.2 / 2.NBT.1)
- The standard algorithm with carrying (2.NBT.5 / 2.NBT.7)
- Partitioning a shape into thirds (2.G.3)

Examples that **do not** get lessons:
- "Tap each creature" — affordance-clear
- "Drag the coin onto the price" — affordance-clear
- "Recognize a triangle" — visual recognition, no procedure
- Counting to N for known N — extension of already-introduced counting

Marking happens in the concept registry per concept. Activity specs declare which of their concepts they *introduce*.

---

## Lesson Template

Three phases, all in the introducing region's visual style and narrator voice.

### Phase 1 — I-Show (15–25 s, target 20 s)

- Narrator + animation walks the strategy end-to-end.
- Kid input is *ignored* for round logic; Pencil may be used for free doodling only (no advancement).
- Narrator **thinks aloud** the strategy using real math language. Example for K.CC.4a:
  > *"Watch how I count these fawns. I'll touch each one — one. Two. Three. Each touch is one fawn. Each fawn gets one touch. That's how we know we have exactly three."*
- "I've got this" button **appears at the 15-second mark** (just after the strategy is laid out). Tapping it fast-forwards directly to You-Do.

### Phase 2 — We-Try (15–25 s, target 20 s)

- A second, similar example.
- The system sets up the problem; the kid is asked to take **one or two actions** explicitly.
- Highlighted targets, ghost cues, and narrator guidance are all visible.
- Narrator: *"You try the next part. Touch the next fawn."*
- The kid taps; the system completes the rest automatically while narrator continues to think aloud.
- If the kid hesitates **>5 s**, the system gently shows the next action.
- Pass condition: any attempt at the highlighted step counts (success or near-miss both pass).

### Phase 3 — You-Do (one full round, no time cap)

- A normal activity round at the kid's current CPA layer (typically Concrete for a freshly-introduced concept).
- Standard adaptive-scaffolding rules apply with **extra forgiveness**:
  - **Max attempts**: 3 (vs default 2 before demotion fires).
  - **Demotion threshold**: 3 consecutive fails on this round counts as "needs more help" — the concept stays at Introduced status and is flagged for the dashboard, but the system does not demote a layer based on first-encounter struggle alone.
- On pass: the concept moves from `firstEncounter: true` to `firstEncounter: false`, and from Mastery status `Introduced` (no state) → `Practicing`.
- On full-fail (3 attempts missed): the concept is still marked `firstEncounter: false`, and Mastery status becomes `Introduced`. The dashboard flags this for teacher/parent attention if it persists.

### Total budget
**≤ 90 seconds** including all narration. Lessons that need more should be split into multiple concepts.

---

## "I've Got This" Skip Affordance

Available after **15 s** of I-Show have elapsed (i.e., after the strategy has been demonstrated at least once).

- Visible: a small, friendly button at the bottom of the screen.
- Tapping it skips to **You-Do** directly.
- The lesson is still **filed in the library** on completion (the kid can replay it later).
- Telemetry logs the skip; many skips in a row may signal the kid is over-claiming mastery — dashboard surfaces this gently.

The button is **not** shown during library re-watches (kids can scrub freely there).

---

## Data Model

```
ConceptRegistryEntry {
  id: ConceptId                       // e.g., "K.CC.4a"
  standardCode: String                // Utah Core code
  requiresLesson: Bool                // marked per the criterion above
  lessonId: MicroLessonId?            // null if requiresLesson = false
  introducedBy: ActivityId?           // the canonical activity that introduces this
  ...
}

MicroLesson {
  id: MicroLessonId                   // e.g., "lesson-k-cc-4a-one-to-one"
  conceptId: ConceptId
  regionalStyle: Sanctuary | Wundletown | Mathopolis
  thumbnail: ImageRef                 // shown in the library
  shortLabel: String                  // e.g., "Counting one at a time"
  phases: {
    iShow: {
      durationSec: Double
      script: NarrationScriptRef       // see authoring section
      animationRef: AnimationRef
    }
    weTry: {
      durationSec: Double
      script: NarrationScriptRef
      kidActions: [KidActionSpec]      // declares the highlighted step(s)
    }
    youDo: {
      problemTemplate: ProblemTemplateRef  // a normal round of the activity
      maxAttempts: Int                  // default 3 (vs normal 2)
    }
  }
}
```

The `firstEncounter: Bool` flag is added to `ConceptState` in `adaptive-scaffolding.md`.

---

## Activity Integration

Activities query the scaffolding context as today, with an additional field:

```
ScaffoldQuery {
  conceptIds: [ConceptId]
  problemType: ProblemTypeId
}

ScaffoldResponse {
  presentationLayer: Concrete | Pictorial | Abstract
  hintsAllowed: Bool
  maxAttempts: Int
  firstEncounterLesson: MicroLessonId?  // new — if non-null, play this lesson before the round
}
```

If `firstEncounterLesson` is non-null, the activity routes to the lesson runner before its own round logic. The lesson runner returns a `LessonOutcome` (passed/failed/skipped) and the activity proceeds.

Activities that introduce **multiple** concepts in the same round handle lesson firing one of two ways, declared at the activity level:

**Default — Queue across rounds**:
Lessons play one at a time, in concept-registry order. The first-encountered concept's lesson plays first; subsequent ones defer to their own first encounters in later rounds. Prevents lesson overload in a single sitting. Used by most activities.

**Override — Intra-round lesson chain** (opt-in per activity):
Activities can declare `intra_round_lesson_chain: true` in their concept declarations. When set, multiple introduced concepts in the same round fire their lessons **sequentially within that round** — each lesson plays at its natural point in the round flow (e.g., Phase 1 lesson then Phase 2 lesson within a single Build-a-Habitat round). Use case: **paired concepts that are structurally sequenced within a round** and where encountering the second concept cold (without a lesson) would be pedagogically wrong. The kid never encounters a brand-new concept without instruction.

Use intra-round chaining when:
- Two concepts are structurally inseparable (e.g., K.G.5 builds the frame that K.G.6 then composes onto)
- Encountering the second concept without a lesson would force scaffolding to do too much work
- The total lesson burden within a round stays under ~3 minutes combined (otherwise it's too much for one sitting)

Avoid intra-round chaining when:
- Concepts are independent (the kid could meet them in any order)
- Activities have many introduced concepts (3+) where chaining would create lesson-overload
- The activity's natural pacing already accommodates round-to-round queuing

### Session-level lesson cap (added 2026-05-30)

A fresh kid hitting Counting Parade for the first time may queue lessons for K.CC.4a, K.CC.4b, K.CC.2 within ~10 minutes — that's up to 3 minutes of MicroLesson content in one session, on top of normal gameplay. To avoid first-session fatigue:

**Rule:** the lesson runner enforces a soft cap of **2 MicroLessons per session** for any kid whose `aggregateCounters.lifetimeRounds < 20` (the "fresh kid" window).

**Behavior when the cap is hit:**
- The third lesson the system would otherwise fire is **deferred to the next session**.
- The kid still gets to play the round; their `firstEncounter` for that concept stays `true`.
- The activity uses Concrete-layer scaffolding aggressively for the un-introduced concept (the round still plays, just without a lesson preamble).
- Telemetry event `lesson.session_cap_deferred` fires with the deferred conceptId.

**Exemptions to the cap:**
- **Intra-round lesson chain** lessons (e.g., K.G.5 → K.G.6 in Build-a-Habitat) count as **one slot** combined, not two. The chain's pedagogical integrity outweighs the cap.
- **Lesson replays initiated by the kid from the library** are never counted (the kid chose to watch).
- Once `lifetimeRounds ≥ 20`, the cap lifts entirely. Experienced kids can handle more lessons per session.

**Rationale:** at ~60–75 s per lesson, two lessons + one round + first-encounter rounds for the un-lessoned concept is ≈ 4–5 min — well-paced for a K kid's first session. Three lessons + rounds risks pushing past 6+ min of mostly-passive content before the kid plays freely.

**Resolution order** when multiple lessons compete for the third slot:
1. The lesson tied to the activity's **canonical introducer** (per the concept registry) wins for that slot if possible.
2. Otherwise, registry-order tiebreak (alphabetical by conceptId).
3. The next-in-line lesson defers.

**Open question:** should the cap also apply at higher grades? Suggest 1st & 2nd grade keep the same cap rule at launch and tune from telemetry.

---

## Library Affordances (per region)

The library is **one logical collection** of completed lessons per kid. The **display surface** changes with the kid's current region:

| Region | Surface | Visual |
|---|---|---|
| Sanctuary (K) | **Stamp Wall** | A wall in the Hub interior with stamped marks; each lesson is a stamp. Tap to replay. |
| Wundletown (1) | **Spell Book** | An open tome on a podium; each lesson is a spell page. Tap a page to replay. |
| Mathopolis (2) | **Casebook training reel** | A binder of training clips; tap a clip to replay. |

The kid sees the same lessons regardless of which surface they open. The surface just looks like the current region.

### Library entry data
Per lesson in the library:
- Thumbnail (region-specific art)
- Short label (e.g., "Counting one at a time")
- Original region (a small badge)
- Last viewed date (subtle)
- "Replay" button — opens the lesson in full

### Locked future lessons
**Decision: not at launch.** The library shows only completed lessons. A clean wall is preferred over a wall of silhouettes that might overwhelm a kid. (Reconsider in v1.1 if engagement data suggests motivation benefit.)

### Replay UX
- Full scrub control (timeline at bottom).
- All three phases playable in order; can skip among them.
- **"I've got this"** button is **not** shown during replays.
- Replays do not award any new rewards (the lesson was filed on first completion).
- Replays do not affect concept state (no scaffolding events fired).

---

## Authoring Guidelines

### Voice and tone
- **Brisk.** Total ≤ 90 s.
- **Real math language.** Don't dumb down — "make a ten," not "the magic ten trick."
- **Show the thinking.** Narrator says what they're doing as they do it, not after.
- **No talking down.** No "you'll love this!" or "are you ready, little champion?"
- **Regional flavor in delivery, not in math.** The math stays standard; the narrator's voice and metaphors fit their region.

### Representative-sample pattern

When a concept has a **broad set of sub-elements** (e.g., K.G.1's six position words, K.CC.3's 21 numerals, K.OA.5's many addition facts), lessons may demonstrate only a **representative sample** rather than every element. The activity's scaffolding (especially Concrete-layer cues) handles the rest.

**When this is appropriate:**
- The concept's sub-elements all share the same procedure or mental move (so the kid generalizes from a few examples).
- The activity's Concrete-layer scaffolding can support the un-demonstrated elements without confusion.
- Demonstrating every element would push the lesson over the 90 s budget.

**When this is NOT appropriate:**
- Sub-elements have meaningfully different procedures (the kid won't generalize).
- The activity lacks scaffolding for the un-demonstrated elements.

**Examples in use:**
- K.G.1 lesson covers 3 of 6 position words; the activity's directional-cue scaffolding handles the rest.
- K.CC.3 lesson covers writing one numeral ("5"); the activity's trace-mode scaffolding handles the other 20.

**Authoring requirement:** lessons using this pattern must explicitly note (in their Setting or Open Questions section) which sub-elements they cover and which they leave to activity scaffolding. The reasoning must be visible to future lesson authors and playtesters.

### Authoring artifact
Each lesson lives in `specs/lessons/<concept-id>.md` and follows this structure (validated against the K vertical-slice lessons):

- **Header** — concept ID, standard code, region, introducing activity, narrator voice, total duration target, status, prerequisite lessons (if any)
- **Setting** — scene description, what's on screen, Buddy presence per `k-activity-patterns.md`, narrator voice
- **Phase 1 — I-Show** — timestamped animation choreography table, full narration script with timing cues in parens, notes for the narrator
- **Phase 2 — We-Try** — setup table (scene state), choreography table with kid-tap moments, hesitation rule (default 5 s — see `stylus-mechanics.md`), pass condition, full narration script
- **Phase 3 — You-Do** — round parameters (references the parent activity's sub-mode), pass outcome, fail outcome
- **Library Entry** — per-region surface spec (Stamp Wall / Spell Book / Casebook), thumbnail description, short label, original-region badge, replay duration
- **Telemetry** — custom payload fields beyond the shared MicroLesson events from this spec
- **Reward Emissions** — references `reward-economy.md`; lists what fires for pass / failed-out / replay
- **Edge Cases** — anything not obvious (interruptions, accessibility, kid edge behaviors)
- **Open Questions** — undecided items with context
- **Changelog** — dated entries

Content / design can co-edit lesson files without engineer involvement. The lesson runner consumes them via the same data model as other activity content.

---

## Audio Cues

| Event | Cue |
|---|---|
| Lesson starts | Region-specific opening flourish (Sanctuary chime, Wundletown wand-flick, Mathopolis horn) |
| I-Show narration | Narrator + soft music bed, ducked under voice |
| We-Try kid prompt | A subtle "your turn" cue |
| We-Try kid action | Standard activity SFX for the mechanic used |
| You-Do round | Standard activity audio |
| Lesson completion (filed to library) | Small "added to library" chime (subtle) |
| Library replay opens | Page-flip / shutter / stamp-press depending on surface |

---

## Telemetry Events

| Event | When | Payload |
|---|---|---|
| `lesson.started` | First-encounter lesson begins | conceptId, lessonId, activityId |
| `lesson.phase_completed` | A phase finishes naturally | conceptId, phase (iShow/weTry/youDo), durationMs |
| `lesson.skipped_to_youdo` | Kid taps "I've got this" | conceptId, atPhase, secondsElapsed |
| `lesson.youdo_passed` | You-Do round passed | conceptId, attempts |
| `lesson.youdo_failed_out` | You-Do failed all 3 attempts | conceptId, attempts |
| `lesson.filed_to_library` | Library entry created | conceptId, lessonId |
| `lesson.replayed_from_library` | Kid opens from library | conceptId, surface (StampWall/SpellBook/Casebook) |
| `lesson.replay_phase_scrubbed` | Kid scrubs during replay | conceptId, fromPhase, toPhase |

These feed the dashboard (lesson completion rates, dwell time, replay frequency).

---

## Reward Emissions

MicroLessons emit reward events through the standard `reward-economy.md` model:

| Event | When | Reward |
|---|---|---|
| `lesson.youdo_passed` | First completion | Standard `round.passed` payout (+2 coins) **plus** filing the lesson in the library (a non-currency reward) |
| `lesson.replayed_from_library` | Replay | No coins. No collectibles. (Replays are for learning, not grinding.) |
| `mastery.standard_practicing` | First You-Do pass moves concept to Practicing | Standard mastery reward per `reward-economy.md` |

Lesson filing is intentionally not a chest — the library entry itself *is* the reward.

---

## Composition with Adaptive Scaffolding

The First Encounter branch lives in `adaptive-scaffolding.md`. Summary:

- Fresh `ConceptState` has `firstEncounter: true`.
- On activity round start, `ScaffoldQuery` returns `firstEncounterLesson: MicroLessonId?`.
- If non-null, lesson runs before the round; on completion, `firstEncounter` flips to `false`.
- Subsequent rounds use the normal scaffolding flow described in that doc.

The lesson runner does not bypass the scaffolding state machine; it routes through it as a "first encounter" mode.

---

## Edge Cases

- **App backgrounded mid-lesson** — pause and persist phase + elapsed time. Resume at the same point on next entry within 5 minutes. After 5 minutes, restart the current phase (kid likely forgot context).
- **Kid stops paying attention during I-Show** — system can't detect this. Auto-advance after duration. If kid then fails You-Do all 3 attempts, the next time the activity is opened, the system *offers* a replay ("Want to watch that lesson again?") — opt-in.
- **Multiple introduced concepts in one round** — only the first-by-registry-order concept's lesson plays. Other introductions defer to their own first encounters in later rounds.
- **Concept registry says `requiresLesson: true` but lesson file is missing** — log a warning, skip the lesson, mark `firstEncounter: false`, behave as if lesson completed. Dashboard surfaces unauthored lessons for content team.
- **Imported state (kid migrating from another device)** — if `firstEncounter` is already false on import, the lesson does not re-fire. Library entry is also expected to be present in imported state.
- **Audio muted** — lesson still plays; narration auto-captions in the kid's reading mode (per the reading-load decisions). For pre-readers in K, audio-muted lessons display the animation only; consider this a graceful degrade, not equivalent.
- **Stylus disconnect mid-We-Try** — pause until input source available; offer touch fallback if Pencil unreachable.

---

## Open Questions

- **Locked-future lessons in the library** — show silhouettes (motivational) or hide entirely (cleaner)? Decision: hide at launch; reconsider in v1.1.
- **Mid-activity replay access** — should a kid be able to re-watch a lesson mid-round (e.g., "I forget how to make a ten" — pause and replay)? Suggest yes via the notebook tab UI; specifics TBD.
- ~~**Decay / refresher** — if a kid hasn't touched a concept in 30+ days, should the system offer a shorter refresher (I-Show only)? Defer to v1.1.~~ **Resolved 2026-05-30**: `firstEncounter` resets to `true` after **60 days** without touching the concept. The full lesson re-plays as a refresher on next encounter. Library entries and prior rewards are preserved. See `adaptive-scaffolding.md` for the canonical rule.
- **Cross-region replay** — if a 2nd grader replays a K lesson from the Casebook, does the lesson play in Mathopolis art? **Decision: no — lesson plays in its original region style. Identity is stable.**
- **Lesson length cap** — 90 s is the target. Some concepts (standard algorithm) might genuinely need longer. Split into multiple concepts or allow exceptions?
- **Authoring tooling** — content team writes lesson scripts in markdown; do we need a preview tool? Defer until content authoring begins.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-29 | Initial draft (introduces the teach-before-testing system) | |
| 2026-05-30 | Expanded authoring template to match the structure all 7 K vertical-slice lessons actually use; locked the 60-day firstEncounter decay rule | |
| 2026-05-30 | Added **session-level lesson cap** (2 lessons per session for fresh kids with <20 lifetime rounds; intra-round chain counts as 1 slot; replays exempt) to prevent first-session lesson fatigue | |
| 2026-05-30 | Added **intra-round lesson chain override** (activities can opt in to firing multiple introduced-concept lessons within a single round). Added **representative-sample pattern** for lessons that cover a sample of a broad concept (e.g., 3 of 6 position words). Resolves Build-a-Habitat's K.G.6 cold-encounter problem and formalizes the K.G.1 lesson's authoring approach | |
