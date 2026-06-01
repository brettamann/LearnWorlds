# MicroLesson — Write Numerals (K.CC.3)

> "Numerals are signs we draw to show how many." Teaches the **trace procedure** (follow the dotted line, in stroke order) using **two contrasting numerals**: "5" (multi-stroke, with curve + horizontal) in I-Show and "8" (single continuous loop) in We-Try. After this lesson, the kid applies the same procedure to all 21 numerals (0–20) through Scribe's Tower practice.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/shared/number-writing-modes.md`, `specs/activities/kindergarten/scribes-tower.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-cc-3-write-numerals` |
| Concept ID | `K.CC.3` |
| Standard | K.CC.3 — Read and write numbers using base ten numerals from 0 to 20 |
| Region | Sanctuary |
| Introducing activity | Scribe's Tower |
| Sub-mode | `trace-numeral` |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 75 s |
| Status | Draft |
| Prerequisite | K.CC.4a / K.CC.4b lessons completed (the kid knows what counting and "how many" mean — now they learn the *symbols* for the counts) |

---

## Setting

Scribe's Tower's standard scene: round writing-tower interior, shelves of magical scrolls and floating numeral characters, stained-glass light, central writing desk. For this lesson, the desk surface shows a **bright dotted ghost of the numeral "5"** with **stroke-order indicators** ("1" and "2" small badges at the start of each sub-stroke).

The desk also shows a small visual cue above the ghost: **five sparkling fireflies** in a loose cluster — anchoring "this is the numeral that means *five*." The fireflies don't move during the trace; they're a quantity reference.

Per `k-activity-patterns.md`: standard K HUD, Sanctuary narrator. Buddy on the reading cushion at lower-left.

---

## Phase 1 — I-Show (≈22 s)

The kid watches. The phase pairs the numeral shape with the quantity it represents, then demonstrates the trace procedure.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Tower interior visible. Writing desk shows the bright dotted "5" with stroke-order indicators and five fireflies above. Music bed in. |
| 0:02 | Narrator opens by pairing numeral and quantity. |
| 0:05 | The **5 fireflies** above the ghost briefly pulse one at a time (5 quick sparkles). Narrator counts under: "One. Two. Three. Four. Five." |
| 0:09 | The ghost "5" itself glows briefly. Narrator: "This is *five*." |
| 0:11 | Narrator: "Watch how we write it." |
| 0:13 | Glowing pointer drifts to the **stroke-1 indicator** (top-left corner of the 5). |
| 0:14 | Pointer traces sub-stroke 1: the **top horizontal bar** of the 5, then **down the left side** to the middle. Smooth motion, ~2 s. Trail glows along the dotted line as it goes. |
| 0:16 | Pointer lifts. Stroke-2 indicator pulses. |
| 0:17 | Pointer traces sub-stroke 2: the **bottom curve** of the 5, sweeping right and down and curving up to close the bottom. Smooth motion, ~2 s. |
| 0:19 | **Numeral comes to life** — the dotted "5" solidifies into a bouncy numeral character that hops in place. The fireflies above scatter and reform into a soft "5" arrangement, mirroring the numeral. |
| 0:22 | Narrator delivers the insight. "I've got this" button has been visible since 0:15. I-Show ends. |

### Narration script

> *(0:02)* "Look at the desk. Five fireflies — and the dotted shape is the number *five*."
>
> *(0:05)* *(under-count syncopated with sparkles)* "One. Two. Three. Four. Five."
>
> *(0:09)* "This is *five*. The shape and the count go together."
>
> *(0:11)* "Watch how we write it."
>
> *(0:14, syncopated with stroke 1)* "Down the side…"
>
> *(0:17, syncopated with stroke 2)* "…and around the curve."
>
> *(0:22)* "That's *five*. Numerals are signs we draw to show how many."

### Notes for the narrator
- The under-count at 0:05 is brisk (5 sparkles in ~1.5 s) — establishes the quantity quickly without belaboring it. The kid already knows how to count to 5 from K.CC.4a/4b.
- "The shape and the count go together" is the K.CC.3 conceptual punchline — numerals *mean* quantities. Land it warmly.
- "Down the side… and around the curve" pairs words with motion. Helps kids who learn through verbal stroke instructions.
- The numeral coming to life is the activity's signature reward — let the animation breathe.

---

## Phase 2 — We-Try (≈25 s)

The kid traces the **"8"** — a structurally different numeral from the I-Show's "5". The 8's single continuous loop contrasts with the 5's two-stroke structure, demonstrating that the trace procedure generalizes across very different numeral shapes.

### Why a different numeral than I-Show

The K.CC.3 lesson follows the **representative-sample authoring pattern** but with a small enhancement: I-Show and We-Try cover **structurally contrasting numerals** so the kid sees that the procedure works for both:
- "5" (I-Show): multi-stroke, mix of straight + curved segments, stroke order matters.
- "8" (We-Try): single continuous loop, no lift, kid handles a curve all the way around.

Together these two cover most of the motor patterns the kid will encounter in 0–20. A kid who traces both successfully has high confidence that "3", "6", "9", and the rest follow the same logic.

### Setup

| Element | State |
|---|---|
| Scene | Desk shows dotted "8" with a **single stroke-order indicator** (the "1" badge at the top of the loop). |
| Fireflies above | 8, static (visual reminder of quantity) |
| Trace target | The "1" indicator halos faintly |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator opens: "Now a different number. The *eight*. Same idea — follow the dotted line." |
| 0:04 | Narrator: "Start at the top — it's all one loop, no lifting." Stroke-1 indicator halo pulses at the top of the 8. |
| → kid traces | Kid drags stylus along the dotted path. **Geometric scoring** (per `number-writing-modes.md` Mode 1) accumulates. Trail glows where on-path; dim where off-path. |
| | If kid lifts mid-trace: the partial trail stays; kid can resume from where they lifted (no penalty for lifts, unlike strict cursive practice). |
| | If kid pauses for >5 s: halo brightens; after another 5 s, system auto-traces. |
| | If completed trace score ≥ 80%: pass. The "8" numeral character comes to life — does a small loop-the-loop in the air, then climbs to the shelf to join the "5" from earlier. |
| | If score < 80%: warm narrator + ghost re-glows; one retry allowed before lesson advances. |
| 0:22 | Narrator: "That's *eight* — well done. Same procedure, different number." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no stylus motion (standard hesitation threshold per `stylus-mechanics.md`), the next-stroke indicator brightens. After another 5 s, the system auto-traces. Lesson advances either way.

### Pass condition
Any kid attempt to trace passes the lesson — even a low-score trace counts as participation. The Mode 1 score still gets logged for telemetry; lesson-pass doesn't depend on a perfect first trace.

### Narration script

> *(start)* "Now a different number. The *eight*. Same idea — follow the dotted line."
>
> *(prompting)* "Start at the top — it's all one loop, no lifting."
>
> *(mid-trace)* (no narration; the kid is doing the work)
>
> *(on pass)* "That's *eight* — well done. Same procedure, different number."
>
> *(on retry)* "Almost — let's go slowly. Follow the dotted line."

---

## Phase 3 — You-Do (one round of Scribe's Tower)

Hand off to the activity's `trace-numeral` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `trace-numeral`
- **Target numeral**: **"3"** — yet another structurally distinct numeral (two stacked open curves on the right side, top-down stroke direction). Different from both lesson numerals (5 and 8) to demonstrate the procedure generalizes broadly.
- **Quantity reference**: 3 fireflies (matches)
- **CPA layer**: Concrete (full stroke order indicators, quantity, name spelled out)
- **Max attempts**: **3** per `micro-lessons.md` first-encounter forgiveness
- **Hints**: enabled at K standard thresholds (5 s pulse; 10 s narrator prompt)

### Pass outcome
- Kid traces "3" with score ≥ 80%.
- The "3" numeral character animates onto the shelf and joins the "5" and "8" already there from the lesson.
- **Stamp earned** for "3" → poster updates to "1 of 21" (the lesson's I-Show and We-Try demos count as exposure, not mastery — only the You-Do's traced numeral earns a stamp).
- `mastery.standard_practicing` fires for K.CC.3 (concept-wide) when the kid first achieves any per-numeral mastery; this is the first one.
- Library entry created.
- `firstEncounter` for K.CC.3 flips to `false`.

### Fail outcome (all 3 attempts miss)
- Library entry filed.
- `firstEncounter` flips to `false`.
- Mastery status for K.CC.3 stays `Introduced`.
- Per-numeral mastery for "3" stays `Introduced`.
- Dashboard flag.

---

## Library Entry

| Field | Value |
|---|---|
| Surface (Sanctuary) | Stamp Wall stamp |
| Surface (Wundletown) | Spell Book page |
| Surface (Mathopolis) | Casebook clip |
| Thumbnail | The dotted "5" with stroke-order indicators, fireflies above |
| Short label | "How to write a numeral" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~60 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus events delegated to `number-writing-modes.md`:

| Event | Custom payload |
|---|---|
| `lesson.started` | `iShowNumeral: 5`, `weTryNumeral: 8`, `youDoNumeral: 3`, `mode: "trace"` |
| `lesson.wetry_trace_completed` | `numeral: 8`, `score: Float`, `attempts: Int`, `assistedTraceUsed: Bool` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `youDoNumeral: 3`, `youDoScore: Float` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.CC.3 (concept-wide, on first per-numeral mastery)
- `scribe.numeral_mastered` for "1" fires after the kid has demonstrated 5 traces of "1" across 3 sessions / 3 days (per Scribe's Tower per-numeral mastery rules) — not from this single round
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid traces in wrong stroke order** during We-Try (starts stroke 2 first) — at Concrete layer, the system gently steers: the wrong-stroke trail is dimmer; narrator after a moment: "Let's start at the **1**." Lesson continues to advance.
- **Kid traces both strokes as one connected motion** (no lift between strokes) — geometric scoring still works if the connecting line falls within tolerance; otherwise the score drops. Per Mode 1 spec, this counts; stroke order is "soft" at Concrete and not enforced at Abstract.
- **Kid lifts stylus mid-stroke and starts over** — current trace cancels; ghost reverts to "ready" state; kid can restart the stroke.
- **The fireflies above the desk distract the kid** — they should be subtle (slow sparkle every ~2 s, low brightness). Confirm in playtest.
- **Numeral "5" character design** — the bouncy personality should be charming but not distracting once it hops up to the shelf. Idle on shelf should be quieter than the in-the-spotlight animation.
- **Audio muted** — visual stroke-order indicators carry the procedure. The under-count of the 5 fireflies at I-Show start happens visually (sparkles) without audio dependency.

---

## Open Questions

- ~~**Demo numeral choice**~~ **Resolved 2026-05-30**: I-Show uses "5" (multi-stroke), We-Try uses "8" (single continuous loop), You-Do uses "3" (stacked curves). Three structurally different numerals demonstrate that the trace procedure generalizes broadly.
- **Stroke narration verbalization** ("Down the side… and around the curve") — kid-friendly directional language. Some kids may benefit from more explicit "from top to middle, then curve right" descriptions. Defer to playtest.
- **The "5", "8", and "3" personalities** — bouncy / loopy / curly. Confirm with art that each character looks like its own personality, not just generic happy-numerals. Each of the 21 numerals needs a distinct vibe per Scribe's Tower's design.
- **Lesson length 75 s** — over the 60 s target. The dual-numeral introduction (5 + 8) plus the structural-contrast insight justifies the extra time. If playtest shows attention drops, consider trimming I-Show's firefly under-count from 5 to a faster 3-2-1 visual sweep.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first lesson using a worked-example numeral ("5") with procedure generalization to a different numeral ("1") in You-Do | |
| 2026-05-30 | Expanded We-Try to cover a second structurally-contrasting numeral ("8" — single continuous loop). Lesson now covers 5, 8, and 3 (You-Do) to demonstrate the trace procedure generalizes across very different motor patterns. Total duration target bumped from 60 s to 75 s. | |
