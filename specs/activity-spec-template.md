# Activity Spec Template

> Copy this file to `specs/activities/<grade>/<activity-slug>.md` and fill in each section. Sections marked **REQUIRED** must be present. **OPTIONAL** can be omitted if not applicable. Implementation-readiness is the bar: an engineer should be able to build the activity from this spec without further design decisions.

---

## Header — REQUIRED

| Field | Value |
|---|---|
| Activity name | (e.g., Counting Parade) |
| Activity slug | `counting-parade` |
| Region | Sanctuary / Wundletown / Mathopolis |
| Grade | K / 1 / 2 |
| Standards | Comma-separated Utah Core codes (e.g., K.CC.1, K.CC.2, K.CC.4a–c) |
| Status | Draft / Reviewed / Ready-to-build / Built |
| Last updated | YYYY-MM-DD |

---

## Setting & Tone — REQUIRED

- **Scene** — what the kid sees on open. Two or three sentences.
- **Atmosphere** — sound bed, lighting, palette anchors.
- **Buddy presence** — is the Buddy in this scene? Where? Idle behaviors?
- **Narrator** — which region narrator runs this scene (per the decisions doc).

---

## Standards Coverage — REQUIRED

For each standard the activity targets, state:
- **Standard code** (e.g., K.CC.4a)
- **What the kid does** to demonstrate the standard
- **What the system observes** to mark progress (the telemetry event)
- **Mastery threshold** — how many successes across how many sessions count as mastery

This is the contract between the activity and the standards-mastery data model.

---

## Concepts: Introduced vs Exercised — REQUIRED

For each concept the activity touches, mark its role. **Three valid roles:**

- **Introduces** — this activity is the canonical introducer. Plays the MicroLesson on first encounter.
- **Exercises** — the concept is touched here, but introduced elsewhere via lesson. Uses normal adaptive scaffolding only.
- **Exercises (no introducer)** — the concept is exercised here, but has **no canonical introducer anywhere** (the registry sets `requiresLesson: false` and has no `introducedBy`). Mastery is detected via coverage-based or fallback-practice signals per `adaptive-scaffolding.md`'s Exercises-Only Mastery rule.

| Concept | Role | Lesson | Granularity | Notes |
|---|---|---|---|---|
| `K.CC.4a` | Introduces | `specs/lessons/k-cc-4a-one-to-one.md` | concept-wide | Canonical activity for one-to-one correspondence |
| `K.CC.4b` | Exercises | — (introduced in Counting Parade) | concept-wide | |
| `K.CC.5` | Exercises | — | concept-wide | Extension at higher number ranges; uses K.CC.4a scaffolding |
| `K.OA.1` | Exercises (no introducer) | — | concept-wide | Coverage-based mastery: demonstrationModes = [scene, notebook, equation] |
| `K.CC.3` | Introduces | `specs/lessons/k-cc-3-write-numerals.md` | per-instance (21 numerals) | Mastery tracked per numeral; concept-wide mastery rolls up |

### Rules
- Each concept that has an introducer has **exactly one canonical introducer** across all activities.
- Concepts where the registry sets `requiresLesson: false` are **Exercises** or **Exercises (no introducer)**.
- An activity that **extends** a concept to a wider number range (e.g., counting up to 100 instead of 10) does **not** introduce — it exercises the same concept at higher difficulty.
- **Granularity** (`concept-wide` default, `per-instance` opt-in) is declared per concept in the concept registry. Activity specs should reflect what the registry says.
- "Introduces" is a declarative claim against the global registry. Conflicts are resolved in the registry, not in activity specs.

See `specs/shared/micro-lessons.md` for the full lesson model and `specs/shared/adaptive-scaffolding.md` for mastery granularity and exercises-only mastery rules.

---

## Sub-Modes — REQUIRED

If the activity has more than one mode (e.g., Shape Garden's Find / Flat-or-Solid / Sort), enumerate each:

### Sub-mode: `<name>`
- **Standard(s) targeted** —
- **What the kid does** —
- **Pass condition** —
- **Fail behavior** — (see Scaffolding section for details)

---

## Visual Layout — REQUIRED

Describe the scene with enough detail to mock. ASCII diagram or annotated description. Identify:
- **Persistent scene anchors** (background elements; unchanging)
- **Interactive elements** (taps, drags, target zones)
- **Math notebook tab** placement (always available; default open or default collapsed?)
- **HUD elements** (coin count, progress bar, exit button)

Example:

```
+---------------------------------------------------+
| [exit]                            [coins: 12]     |
|                                                   |
|   <scene area>                                    |
|                                                   |
|                                                   |
|                                       [notebook>] |
+---------------------------------------------------+
```

---

## State Machine — REQUIRED

The activity's high-level flow as named states with transitions. Cover:
- **Entry state** — what runs when the activity opens
- **Round states** — the loop the kid is in
- **Success / failure transitions** — what fires what
- **Exit conditions** — when the activity ends a session

A simple bulleted state list is fine; a Mermaid diagram is welcome but not required.

---

## Stylus Interactions — REQUIRED

For each stylus mechanic used (from `specs/shared/stylus-mechanics.md`), specify:
- **Mechanic name** (e.g., Tap-count, Drag-and-drop, Cut-along-guides)
- **Where used** in this activity
- **Any local overrides** to tolerances or behaviors (default to library values; only specify deltas)

---

## Number-Writing Modes — OPTIONAL

If the activity asks the kid to write digits, specify per writing moment:
- **Mode used** — Trace / Prompted free-write / Blind free-write (from `specs/shared/number-writing-modes.md`)
- **Range expected** — single digit / 0–20 / 0–100 / etc.
- **Fallback behavior** — what happens if recognition fails the threshold

---

## Audio Cues — REQUIRED

- **Narrator lines** — scripted prompts and confirmations. Use placeholders (`{count}`, `{name}`) where dynamic.
- **Sound effects** — what fires on what (tap, success, failure, level-up)
- **Music bed** — loop length, intensity changes, region-appropriate flavor

Long line lists can live in a sibling `<slug>.lines.md` file referenced from here.

---

## Scaffolding Triggers — REQUIRED

What counts as "the kid is struggling" — concrete and observable. Each trigger references the shared **Adaptive Scaffolding State Machine** (`specs/shared/adaptive-scaffolding.md`) for the response.

Examples:
- *2 wrong answers in a row* → drop one CPA layer for the next problem
- *Hesitation >8s on a tap-count round* → highlight the next item to tap
- *3 wrong answers in same session* → offer the "show me with objects" affordance

---

## CPA Progression — REQUIRED

State the activity's representation layers and how the kid moves between them:
- **Concrete** — what objects / manipulables
- **Pictorial** — what visual representations (ten-frames, bar models, number lines)
- **Abstract** — what symbols / equations
- **Default starting layer** — for a fresh user
- **Promotion conditions** — what success looks like to move up a layer
- **Demotion conditions** — what struggle looks like to move down a layer

---

## Reward Emissions — REQUIRED

What rewards the activity emits and when. References the **Reward Economy Event Model** (`specs/shared/reward-economy.md`).

| Event | Trigger | Reward |
|---|---|---|
| `round.correct` | kid passes a round | +N coins |
| `round.notebook_used` | kid wrote in notebook this round | +N bonus coins |
| `streak.reached` | N rounds in a row correct | +chest of type `<type>` |
| `mastery.reached` | a standard moves from "practiced" to "mastered" | +1 collectible card |

---

## Telemetry Events — REQUIRED

Events the activity logs for the dashboard and progress tracking. Each event has:
- **Event name** (e.g., `activity.round.completed`)
- **Payload fields** (activity ID, kid ID, standard codes touched, success/fail, latency)
- **Aggregations consumed by dashboard** (e.g., session count, mastery progress, time on task)

---

## Challenge Variant — REQUIRED

Every activity has at least one opt-in challenge mode (see plan: Challenge Modes section). Specify:
- **Variant name** (e.g., "Tens Parade")
- **What changes** vs the base activity (number range, mixed concepts, speed run)
- **Entry point** — how the kid triggers it
- **Reward bump** — what's special about the rewards

---

## Edge Cases & Error Handling — REQUIRED

Anything not obvious. Examples:
- Stylus disconnect mid-round → behavior?
- Backgrounded mid-activity → resume from where, or restart round?
- Audio muted → does the activity still work?
- Kid taps the wrong thing repeatedly → at what point do we intervene?

---

## Decisions Needed — OPTIONAL

**Block authoring**: questions that must be answered before the activity can be considered ready-to-build. Each item should have an owner and a target decision date.

Examples:
- "Should the activity allow free placement at the Abstract layer, or stay snap-to-target everywhere?"
- "Confirm species pairing for decomposition coloring meets color-blind accessibility."

If this section is empty when the activity is otherwise complete, mark Status as `Ready-to-build`.

---

## Notes for Later — OPTIONAL

**Non-blocking**: items to revisit during playtest or post-launch tuning. The activity can ship without these resolved.

Examples:
- "Hesitation thresholds (5 s, 10 s) are starting values — tune in playtest."
- "Challenge variant entry frequency: 1× per day at launch; tune from engagement data."
- "Confirm narrator's celebratory line rotation feels varied across long sessions."

---

## Implementation Notes — OPTIONAL

Hints for the engineer that aren't part of the design contract. Performance considerations, suggested SwiftUI view hierarchy, reusable component opportunities, etc.

---

## Changelog — OPTIONAL

| Date | Change | Author |
|---|---|---|
| YYYY-MM-DD | Initial draft | |
