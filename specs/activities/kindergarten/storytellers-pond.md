# Activity Spec — Storyteller's Pond

> The K activity that introduces **solving word problems within 10** (K.OA.2). Stories play out at the pond's edge — ducks arrive, dragonflies leave, dragonlings splash in — and the kid acts out the math by manipulating the scene. Structurally novel: the **first activity with story-templated rounds**, validating data model needs for word-problem content.

References: `specs/shared/stylus-mechanics.md`, `specs/shared/math-notebook.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/reward-economy.md`, `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activity-spec-template.md`.

---

## Header

| Field | Value |
|---|---|
| Activity name | Storyteller's Pond |
| Activity slug | `storytellers-pond` |
| Region | Sanctuary |
| Grade | K |
| Standards | K.OA.1, K.OA.2 |
| Status | Draft |
| Last updated | 2026-05-30 |

---

## Setting & Tone

- **Scene** — A reedy pond at the edge of the Sanctuary, just before dusk. The water is still; soft light reflects from the surface. A wooden **storyteller's lectern** sits at the bank, with the **Storyteller** — a small wise turtle character — perched on it (the Storyteller is the *narrator* in this activity; this is one of the few cases where the narrator has a visible body in the scene). Reeds line the water. The pond is a stage; creatures arrive and leave during stories.
- **Atmosphere** — Warm golden-hour light; gentle frog-and-cricket bed alongside the Sanctuary music; occasional ripple on the water surface. Palette anchors: pond-blue, reed-green, sunset gold.
- **Buddy presence** — Per `k-activity-patterns.md`: Buddy at lower-left on a flat stone, watching the pond. Reacts to creature arrivals/departures with attentive head-tilts. Hops on round-pass.
- **Narrator** — Sanctuary warm naturalist voice, **delivered through the Storyteller turtle's character** (visible in the scene). The turtle "speaks" with subtle mouth animation synced to the narration. This is a deliberate choice for Storyteller's Pond: the narrator-as-character makes the storytelling act feel intentional.

---

## Standards Coverage

| Standard | What the kid does | Telemetry event | Mastery threshold |
|---|---|---|---|
| **K.OA.1** (represent addition/subtraction with objects, drawings, equations) | Throughout: the kid represents the story's math by **manipulating creatures in the scene** (objects), optionally **drawing in the math notebook** (drawings), and seeing **the answer prompt in equation form** at higher CPA layers. Multiple representations are inherent to the activity. | `pond.representation_used` (payload: `representationType`: "scene-manipulation" / "notebook-drawing" / "equation-form") | 5/3/3 standard |
| **K.OA.2** (solve addition/subtraction word problems within 10) | Listens to a story, manipulates the scene to match, answers the question (count of creatures at end). | `pond.word_problem_solved` (payload: `problemType`, `targetAnswer`, `kidAnswer`, `correct`) | Same |

---

## Concepts: Introduced vs Exercised

| Concept | Role | Lesson | Notes |
|---|---|---|---|
| **K.OA.2** (solve word problems within 10) | Introduces | `specs/lessons/k-oa-2-word-problems.md` | First lesson covers an **add-to** story with full scene manipulation. The lesson teaches the procedure: listen → watch the scene play out → count. Bar model appears implicitly. |
| **K.OA.1** (represent with objects, drawings, equations) | **Exercises (no introducer)** | — | Coverage-based mastery per `adaptive-scaffolding.md`. Demonstration modes: `["scene-manipulation", "notebook-drawing", "equation-form"]`. Mastery fires when kid demonstrates ≥2 of 3 modes across ≥3 sessions, OR via fallback 20 successes. |

### Registry impact

- `K.OA.2.introducedBy = storytellers-pond`
- (K.OA.1 has no canonical introducer; it's woven across multiple K.OA / K.NBT activities as inherent design)

---

## Story Templates

Stories follow **type templates** with slot-filled variables. The data model needs to express:

```
StoryTemplate {
  id: String                    // e.g., "add-to-ducks-1"
  type: AddTo | TakeFrom | PutTogether | TakeApart
  creature: CreatureKind        // ducks, dragonflies, dragonlings, frogs, fish
  startN: Int                   // 0–10
  changeN: Int                  // 1–N
  resultN: Int                  // computed; equals startN + changeN (add-to) or - (take-from)
  narrationTemplate: String     // e.g., "{startN} {creature_plural} are in the pond. {changeN} more swim in. How many now?"
  visualSteps: [SceneStep]      // ordered animation steps that match the narration
  answerFormat: "numeral" | "tile-select"  // how kid responds
}
```

Each round picks a story template and plays it.

---

## Sub-Modes

### Sub-mode: `add-to` (default)

- **Standards targeted** — K.OA.1, K.OA.2
- **Template family** — `add-to-*`
- **Story shape** — "N creatures are in the pond. M more arrive. How many now?"
- **Visual flow** — N creatures already in the pond; M arrive (walking/swimming in from off-screen) one at a time during narration.
- **Kid's task** — After story completes, the question prompt appears: "How many {creatures} altogether?" Kid writes the answer (Mode 2 prompted free-write) or taps a numeral tile from 2–3 options at lower layers.
- **Pass condition** — Correct count.
- **Fail behavior** — Warm narrator + the Storyteller re-tells the story slowly with the kid counting along ("look — 1, 2, 3 here, then 4, 5 arrive — 5 in all").

### Sub-mode: `take-from`

- **Template family** — `take-from-*`
- **Story shape** — "N creatures are in the pond. M leave. How many are left?"
- **Visual flow** — N creatures in the pond; M leave (walking/flying away off-screen).
- **Kid's task** — Same response format as `add-to`.

### Sub-mode: `put-together`

- **Template family** — `put-together-*`
- **Story shape** — "A creatures are on the lily pad. B creatures are by the reeds. How many altogether?"
- **Visual flow** — Two groups visible at start; question asks for the total.
- **Kid's task** — Same response format.

### Sub-mode: `take-apart`

- **Template family** — `take-apart-*`
- **Story shape** — "There are N creatures. A are on the lily pad. How many are by the reeds?"
- **Visual flow** — Total N visible; A are clearly grouped; the kid figures out the rest.
- **Kid's task** — Answer the count of the second group.

### Sub-mode: `two-step` *(challenge variant)*

- **Standards targeted** — K.OA.2 stretched
- **Template family** — `two-step-*`
- **Story shape** — Combines two operations: "N here. M arrive. Then P leave. How many?"
- **Visual flow** — Sequential — N visible, then M arrive (badge updates), then P leave (badge updates).
- **Kid's task** — Answer after both operations.
- **Reward bump** — Challenge chest per `reward-economy.md`.

---

## Visual Layout

```
+--------------------------------------------------------+
| [exit]                              [coins: 12]        |
|                                                        |
|   <pond scene — water, reeds, sunset light>           |
|                                                        |
|     <Storyteller turtle on lectern>                   |
|         🐢                                             |
|                                                        |
|              🦆🦆🦆                                    |
|         <creatures in/around the pond>                |
|                                                        |
|             [story playback indicator]                |
|                                                        |
|   <bar model area — appears for answer phase>        |
|   [ █ █ █ █ █ ] [ █ █ ]                              |
|                                                        |
|             [answer prompt: "how many?"]              |
|                                                        |
|  [Buddy on stone]                       [notebook >]   |
|                                                        |
|             [ replay story ]   [ done? ]              |
+--------------------------------------------------------+
```

- **Persistent scene anchors** — pond, reeds, Storyteller turtle on lectern, Buddy on stone.
- **Interactive elements during story** — minimal. The kid watches the story play out. Tap-Pick is enabled on creatures (kid can count by tapping if helpful), but this is optional.
- **Interactive elements during answer** — math notebook (write the answer) OR tile-select (2–3 numeral tiles below the bar model). At Concrete layer, both options visible; at Pictorial/Abstract, just one (configured per round).
- **Bar model area** — appears below the pond during the answer phase. Shows the math structure: `[ N ] [ M ]` for put-together, `[ Total ] - [ A ] = [ ? ]` for take-from, etc. The bar model is a **K-friendly representation** — colored bars whose lengths match the counts. (See CPA section for when it appears.)
- **Replay story button** — always available; lets the kid hear/see the story again without restarting the round.

---

## State Machine

```
[idle/intro] → narrator (Storyteller turtle) opens
   ↓
[story_telling] → narration + scene animation; creatures arrive/leave/group per template
   ↓
[story_complete] → scene freezes in its final state; question prompt appears
   ↓
[answer_phase] → kid writes (notebook) or taps tile; bar model visible at Concrete layer
   ↓
[evaluating] → check kid's answer against expected
   ↓
[round_passed]                       [round_failed]
   ↓                                    ↓
[reward + Storyteller approval]      [Storyteller re-tells slowly; kid counts along]
   ↓                                    ↓
[next round queued]                  [retry the same problem, or a similar one]
                                        ↓
                                     [if 2 consecutive fails: demote per staggered rule]
```

**Exit conditions** — standard per K patterns.

---

## Stylus Interactions

| Mechanic | Where used | Local overrides |
|---|---|---|
| **Tap-Pick** (counting semantic) | During the story phase, the kid can optionally tap creatures to count along | No-op for non-target taps (the kid is just counting; no "wrong" tap). Disabled during animation playback to prevent confusion. |
| **Free-Write** | Answer phase — kid writes the numeral answer in the math notebook's recognition zone | Mode 2 prompted free-write. End-of-input timeout 1.2 s. Confidence threshold 0.70. Fallback chain to tile selection per `number-writing-modes.md`. |
| **Tap-Pick** (selection semantic) | Answer phase at Concrete layer — kid taps a numeral tile (3 options shown) instead of free-writing | Standard selection behavior. |

The notebook is **encouraged** in this activity (not optional) — the kid is expected to either write the answer or use the tile selector. The notebook is **open by default** during the answer phase.

---

## Number-Writing Modes

| Layer | Mode used |
|---|---|
| Concrete | **Mode 2** (Prompted free-write) with tile-select fallback always available; the visible scene IS the prompt's quantity reference |
| Pictorial | **Mode 2** (Prompted free-write); tile fallback only after 2 free-write fails |
| Abstract | **Mode 2** (Prompted free-write) only; no tile fallback offered |

Mode 1 (Trace) is not used here — the kid is computing the answer, not transcribing a known numeral. The activity *prompts* via the visible scene; Mode 2 is the right fit.

Mode 3 (Blind free-write) is also not used at K; the visible scene always serves as the prompt's quantity context.

---

## Audio Cues

> **Runtime source**: narration cues live in [`content/strings/en-US/activities/storytellers-pond.json`](../../../content/strings/en-US/activities/storytellers-pond.json). The prose below is the design-time reference; the JSON is the authoritative source the TTS pipeline and runtime consume.

### Narrator lines (Sanctuary warm naturalist, voiced through the Storyteller turtle)

#### `add-to` story flow
- **Story opening**: "Listen. *{startN} {creature_plural} are in the pond.*" *(creatures visible)*
- **Mid-story**: "*{changeN} more {creature_plural} swim in.*" *(creatures arrive)*
- **Question**: "How many {creature_plural} altogether?"
- **Round pass**: "{resultN}! Yes — {startN} and {changeN} more makes {resultN}."
- **Round fail**: "Let me tell it again — slowly this time." *(replay with kid counting along)*

#### `take-from` story flow
- **Story opening**: "Listen. *{startN} {creature_plural} are in the pond.*"
- **Mid-story**: "*{changeN} of them {leave_verb}.*"
- **Question**: "How many are left?"
- **Round pass**: "{resultN}! {startN} take away {changeN} is {resultN}."

#### `put-together`
- **Story opening**: "Look. *{A} {creature_plural} on the lily pad.* *{B} more by the reeds.*"
- **Question**: "How many altogether?"
- **Round pass**: "{total}! {A} and {B} together is {total}."

#### `take-apart`
- **Story opening**: "There are {total} {creature_plural}. *{A} on the lily pad.* The rest are by the reeds."
- **Question**: "How many are by the reeds?"
- **Round pass**: "{remainder}! {total} take away {A} leaves {remainder}."

#### `two-step` (challenge)
- **Story opening**: combines two of the above sequentially
- **Question**: asks for the final count
- **Round pass**: "{final}! Look at all that math you did."

### SFX

| Event | SFX |
|---|---|
| Storyteller turtle speaks | Subtle mouth-clack sync layered with the narration (very gentle) |
| Creature arrives at the pond | Species-specific entry (duck quack, dragonfly buzz, dragonling splash) |
| Creature leaves | Species-specific exit (quack-fade, buzz-fade, splash-out) |
| Story finishes / question appears | Soft "bell" cue |
| Kid writes/taps answer | Standard ink-on-paper or tap-chime |
| Round pass | Sanctuary chime stinger |
| Round fail | Soft sad-but-warm chord; Storyteller turtle nods understandingly |
| Replay story button tapped | Subtle "rewind" cue |

### Music

- Sanctuary dusk bed: gentle strings + harp + soft frog-and-cricket texture, ~80 BPM.
- Music dims slightly during narration (no competition with the Storyteller's voice).
- Round-pass stinger plays over the bed.

---

## Scaffolding Triggers

Uses `ScaffoldQuery` per round, including `firstEncounterLesson` for K.OA.2 routing.

| Trigger | Response |
|---|---|
| **5 s of no input in answer phase** | At Concrete layer, the bar model glows briefly to draw attention. At Pictorial / Abstract, the question prompt re-pulses. |
| **10 s of no input in answer phase** | Narrator: "Look at the pond — how many {creature_plural} do you see?" |
| **Kid taps Replay Story** | Re-plays the story from the beginning. No penalty. Logged for telemetry (replays may indicate the kid needs more processing time). |
| **Kid writes a wrong digit (high confidence)** | Warm "almost — let me show you" + Storyteller turtle re-tells with under-counting (e.g., "1, 2, 3, 4, 5 — five ducks"). |
| **2 consecutive round failures** | Apply the **staggered demotion** rule from `adaptive-scaffolding.md`: demote CPA layer first. If already at Concrete, demote sub-mode (`two-step` → `take-apart` → `put-together` → `take-from` → `add-to`). |

---

## CPA Progression

| Layer | What it looks like in Storyteller's Pond |
|---|---|
| **Concrete** | Full scene manipulation visible during story (creatures arrive/leave on screen). **Bar model** appears during answer phase to visually represent the math. **Tile selector** is offered alongside free-write as an answer option. |
| **Pictorial** | Scene manipulation still visible. **Bar model** appears (still). Tile selector hidden — kid free-writes. |
| **Abstract** | Scene manipulation visible during story. **Bar model** does NOT appear; only the question prompt. **Equation form** appears briefly during the question (e.g., "5 + 2 = ?"). Kid free-writes the answer. |

- **Default starting layer (K, fresh kid)** — Concrete.
- **Promotion conditions** — 3 consecutive passes at the current layer.
- **Demotion conditions** — 2 consecutive failures at the current layer.

### Bar model design

The bar model at Concrete and Pictorial layers is a **K-friendly representation**: colored horizontal bars whose lengths correspond to the counts. Examples:

- `add-to` (5 + 2 = ?): `[ █ █ █ █ █ ]` (blue) + `[ █ █ ]` (yellow) = `[ ? ? ? ? ? ? ? ]`
- `take-from` (7 − 3 = ?): `[ █ █ █ █ █ █ █ ]` (blue) − `[ █ █ █ ]` (yellow taken away) = `[ ? ? ? ? ]`
- `put-together` and `take-apart` use similar bar comparisons.

The bar model anchors the math structure visually before the kid has to think symbolically. Becomes more abstract / disappears at higher CPA layers.

---

## Reward Emissions

| Event | Trigger | Reward (per `reward-economy.md`) |
|---|---|---|
| `round.passed` | Round passes | +2 coins |
| `round.notebook_bonus` | Notebook had ≥3 strokes (any: scratch counting marks, drawing the bar, or writing the answer) | +1 coin |
| `streak.session_3` / `_5` / `_10` | Standard | Per shared spec |
| `milestone.problems_25` / `_100` | Lifetime in this activity | Per shared spec |
| `mastery.standard_practicing` / `_mastered` | Adaptive scaffolding emits for K.OA.1 and K.OA.2 | Per shared spec |
| `challenge.completed` | `two-step` round passes | Challenge chest (rare pond-creature collectible guaranteed) |

### Activity-specific collectibles
- **Pond Creature Cards** — ~15 species at launch (ducks, dragonflies, dragonlings, frogs, fish, turtles, swans, etc.). Drops at ~1 in 4 round-pass events.
- **Story Mementos** — small objects representing the story arcs played (e.g., "the day the dragonlings learned to dive" memento). Earned by completing a round of each unique story template. ~30 unique mementos at launch (varies by template count).
- Complete the creature set for a Hub trophy: the **Pond Census Atlas**.

---

## Telemetry Events

(Beyond shared `scaffold.*`, `economy.*`, `lesson.*` events.)

| Event | Payload |
|---|---|
| `pond.round_started` | `subMode`, `storyTemplateId`, `startN`, `changeN`, `resultN`, `presentationLayer` |
| `pond.story_played` | `narrationDurationMs`, `kidTappedReplay: Bool`, `replayCount: Int` |
| `pond.creature_tap_during_story` | `creatureKind`, `count_at_tap` (kid counting along) |
| `pond.answer_phase_started` | `answerFormat: "freewrite"|"tile-select"`, `barModelShown: Bool` |
| `pond.answer_submitted` | `kidAnswer: Int`, `correct: Bool`, `inputMethod: "freewrite"|"tile"`, `attempts: Int`, `replaysUsed: Int` |
| `pond.word_problem_solved` | `problemType`, `targetAnswer`, `kidAnswer`, `correct` |
| `pond.round_completed` | `success`, `subMode`, `attemptsThisRound`, `hintsFired`, `storyMementoEarned: Bool` |
| `pond.collectible_dropped` | `cardId`, `setProgress`, `collectibleType` (creature or memento) |

---

## Challenge Variant

**Two-Step Tales** — `two-step` sub-mode.

- **What changes** — Story combines two operations sequentially.
- **Entry point** — A "Two-Step Tale!" banner appears on Storyteller's Pond's tile in the Sanctuary 1× per day at launch.
- **Reward bump** — Challenge chest (rare pond creature collectible guaranteed).

---

## Edge Cases & Error Handling

- **Kid taps creatures during story playback** — taps register but don't affect the story (creatures are on a scripted path). At Concrete layer, taps can do a "count along" SFX (gentle "ding"); at higher layers, taps are visually marked but silent.
- **Kid uses Replay Story 3+ times in a single round** — no penalty, but logged. Dashboard surfaces high-replay patterns as a teacher signal ("this kid might need spoken-word comprehension help").
- **Kid types a multi-digit answer when the answer is single-digit** (e.g., writes "11" when answer is "5") — per Mode 2 fallback, low-confidence prompt fires for the multi-digit interpretation; kid confirms; round either passes (if intended) or fails.
- **Story template's narration doesn't match the visual flow** — confirm in content authoring that `visualSteps` matches `narrationTemplate` slot-for-slot. The data model should validate this at template-load time.
- **The Storyteller turtle is the narrator — what if narrator voice changes for accessibility?** Voice swap should still come through the turtle's mouth animation; the turtle is the visual presence, the voice is the narrator's per-region setting.
- **Audio muted** — narration auto-captions appear in the kid's reading mode (per the reading-load decisions). K kids who can't read yet might struggle in audio-muted Storyteller's Pond; the activity should detect mute and visually emphasize the scene flow (creature arrivals/departures highlight more brightly without audio).
- **Bar model rendering on small screens** — must scale down without losing meaning. Confirm minimum cell size in art.

---

## Open Questions

- **Story template count at launch** — how many distinct templates per sub-mode? Suggest ~5 per type (5 add-to, 5 take-from, 5 put-together, 5 take-apart, 2 two-step challenge) = ~22 templates at launch. Tune based on content authoring capacity.
- **Storyteller turtle as visible narrator** — design choice deliberate for this activity. Confirm with art direction; the turtle character needs personality (wise but warm, not stern). Mouth-sync animation may add complexity.
- **Bar model design at K** — colored bars work pedagogically. Confirm color choices are color-blind safe (blue + yellow proposed; alternatives if accessibility requires).
- **Replay Story button — visible always or only after question phase begins?** Suggest always visible once the story has played at least once. The kid shouldn't be stuck mid-story without a replay option.
- **Notebook open by default vs. encouraged** — per `math-notebook.md`, the math notebook can have three relationships (optional / encouraged / required). Storyteller's Pond proposes **encouraged** (notebook peeks open during answer phase) but the activity provides tile-select alternatives at Concrete. Confirm this is the right pacing.
- **K.OA.1 mastery without lesson** — K.OA.1 is exercised here without an explicit lesson. Mastery still fires when the kid has used multiple representations across sessions. Confirm the adaptive scaffolding system can detect "kid has used scene + notebook + equation form" as the K.OA.1 mastery signal. May need a specific telemetry rule.

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical across phases.


```
StorytellersPondView
├── PondBackgroundLayer (parallax water + reeds + sunset light)
├── StorytellerTurtleView (mouth-sync narrator animation)
├── BuddyView (idle, attentive head-tilts)
├── PondCreatureStageView (the scripted creature animations per story template)
│    └── CreatureSprite (varies by species; entry/exit animations per template)
├── BarModelView (visible at Concrete/Pictorial; specific render per problem type)
├── AnswerPhaseView (notebook recognition zone + tile-select alternatives)
├── ReplayStoryButton
├── DoneButtonView
├── HUDView
└── NotebookTab (peeks open during answer phase)
```

### Story-template data model (preview for D phase)

This activity is the first with **content-templated rounds**. The data model needs:

```jsonc
{
  "id": "add-to-ducks-1",
  "subMode": "add-to",
  "creature": "duck",
  "startN": 5,
  "changeN": 2,
  "resultN": 7,
  "narrationTemplate": "{startN} ducks are in the pond. {changeN} more swim in. How many altogether?",
  "visualSteps": [
    { "at": "0s", "action": "spawn", "count": 5, "position": "pond-center" },
    { "at": "3s", "action": "spawn-sequence", "count": 2, "position": "off-screen-left → pond-edge", "interval": "1s" }
  ],
  "answerFormat": "numeral",
  "barModel": "add-to-5-2"
}
```

The D phase should formalize this schema and validate template content against it.

### Reusable opportunities surfaced by this spec

- **Story template system** — first activity with content-templated rounds. Generalizes to 1st-grade Wundle Tales and 2nd-grade Hero Missions (both are word-problem activities at different number ranges). The same template engine should serve all three.
- **Bar model rendering** — the bar model component for visualizing add/take/total structures generalizes for any word-problem activity. Should be a shared component.
- **Visible narrator (Storyteller turtle)** — first activity with the narrator embodied as a scene character. Could become a pattern for region-specific narrator embodiments (a wizard for Wundletown? a TV anchor for Mathopolis?).
- **Replay-content button** — the "replay story" affordance generalizes for any activity where the kid might need to re-experience the prompt (multi-step word problems in 1st/2nd would benefit).

### Performance considerations

- Story playback involves scripted sprite movements + narration sync. Use a timeline coordinator; don't poll.
- Up to ~10 creature sprites visible at once (5 start + 5 arrive). Sprite atlases recommended.
- Bar model is procedural geometry (colored bars of variable length); cheap to render.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first K activity with **content-templated story rounds**; first activity with a **visible narrator character** (the Storyteller turtle); introduces the **bar model** as a K-friendly word-problem representation | |
| 2026-05-30 | K.OA.2 MicroLesson authored and linked; K.OA.1 role updated to **Exercises (no introducer)** with coverage-based mastery rule per `adaptive-scaffolding.md`. Activity is now lesson-complete and ready-to-build | |
