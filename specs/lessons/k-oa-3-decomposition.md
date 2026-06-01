# MicroLesson — Decomposition (K.OA.3)

> "Numbers can be split into smaller groups — in more than one way." Bundles the introduction of the **ten-frame representation** alongside the decomposition concept. The first lesson played inside Ten-Frame Pond.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/ten-frame-pond.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-oa-3-decomposition` |
| Concept ID | `K.OA.3` |
| Standard | K.OA.3 — Decompose numbers ≤ 10 into pairs in more than one way |
| Region | Sanctuary |
| Introducing activity | Ten-Frame Pond |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 75 s (slightly longer — dual introduction) |
| Status | Draft |
| Bundled introductions | The **ten-frame representation** itself. Kids learn the tool through this lesson. |

---

## Setting

Ten-Frame Pond's standard scene: rippling pond, 2×5 lily-pad grid, fish source pool drifting along the bottom. Music bed quiet under narration. Buddy at lower-left on a mossy stone, watching the pond. Per `k-activity-patterns.md`: standard K HUD, Sanctuary narrator, Buddy idle behaviors.

- The ten-frame is **empty** at lesson start.
- Source pool contains **both blue koi and yellow tetras** (decomposition coloring rule for Concrete layer).
- Count badge starts hidden.

---

## Phase 1 — I-Show (≈28 s)

The kid watches. The phase covers two ideas in sequence: (1) **what the ten-frame is**, then (2) **how to split a number**.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up; empty ten-frame visible; fish source pool drifting below. Music bed in. |
| 0:02 | Narrator begins introducing the ten-frame. |
| 0:04 | Glowing pointer drifts across the frame, briefly touching each of the 10 pads in a left-to-right, top-then-bottom sweep (≈2 s for all 10 — each pad lights up faintly as touched). |
| 0:07 | Pointer fades. Frame pads have a faint glow indicating "these are your 10 spots." Glow fades by 0:09. |
| 0:09 | Narrator transitions to the decomposition demonstration. |
| 0:11 | Pointer drifts to the source pool, picks up a **blue koi**, places it on top-row pad 1 → soft "plop." Badge appears showing **1**. |
| 0:13 | Pointer picks up a second blue koi → pad 2. Badge **2**. |
| 0:15 | Pointer picks up a third blue koi → pad 3. Badge **3**. |
| 0:17 | Narrator emphasizes "three." Brief pause. |
| 0:18 | Pointer picks up a **yellow tetra** → bottom-row pad 1. Badge **4**. |
| 0:20 | Pointer picks up a second yellow tetra → bottom-row pad 2. Badge **5**. |
| 0:22 | Narrator: "Three and two." Brief pause. Badge **5** glows. |
| 0:24 | **Frame clears with a soft wave animation** (fish swim back to source); badge resets to hidden. |
| 0:25 | Narrator: "Here's another way." |
| 0:26 | Pointer drags 4 blue koi to top-row pads 1–4 in rapid succession (one per ~0.4 s). Badge **4**. |
| 0:28 | Pointer drags 1 yellow tetra to bottom-row pad 1. Badge **5**. |
| 0:30 | Narrator: "Four and one — still five." Badge **5** glows. |
| 0:31 | Pointer fades. Narrator delivers the closing insight. |
| 0:34 | "I've got this" button has been visible since 0:18. I-Show ends. |

### Narration script

> *(0:02)* "This is the pond. It has ten lily pads."
>
> *(0:04)* *(pointer sweeps the frame)* "Ten spots in all."
>
> *(0:09)* "Watch — I'll put five fish on the pond. Three blue koi…"
>
> *(0:11–0:16, syncopated with each placement)* "One. Two. Three."
>
> *(0:18–0:21)* "…and two yellow tetras. Four. Five."
>
> *(0:22)* "Three and two. That's five."
>
> *(0:25)* "Here's another way to make five."
>
> *(0:26–0:29, faster placements)* "Four blue koi… and one yellow tetra. Four and one."
>
> *(0:30)* "Still five."
>
> *(0:31)* "Numbers can be split lots of different ways. Three and two. Four and one. They're all five."

### Notes for the narrator
- Pacing slows on the first decomposition (3 + 2) — the kid is meeting the concept. Speeds up on the second (4 + 1) — pattern is established.
- "Still five" is the conceptual punchline: the *whole* doesn't change even when the *parts* do. Land it with a small breath before.
- Avoid saying "equation," "addends," or "addition" — those are upcoming vocabulary. "Split," "and," "parts" are kid-language.

---

## Phase 2 — We-Try (≈22 s)

The kid drags fish to make 5 with two colors. The system completes whatever the kid doesn't finish.

### Setup

| Element | State |
|---|---|
| Scene | Empty ten-frame |
| Source pool | Both blue koi and yellow tetras visible (separated by a subtle gap so the kid sees two options) |
| Glow target | None at start — kid chooses where to drop first |
| Count badge | Hidden until first drop |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Put five fish on the pond. Use both colors." |
| → kid drags | Kid drags any fish (blue or yellow) onto a pad → snap, badge **1**. |
| +0.5 s | Narrator: "Good. Keep going." |
| → kid drags | Kid drags a second fish → snap, badge **2**. |
| +0.5 s | If the kid has placed at least one of each color: continue. If they've placed two of the same color, narrator: "Now try the other color." |
| → kid drags | Kid drags more fish (with continued narration encouraging the other color if needed) until either 5 are placed, or the kid pauses for >5 s. |
| +5 s (or 5 placed) | If <5 placed at pause, **system auto-completes** with pointer animation: drags the remaining fish, alternating colors as needed to ensure a visible split. Each placement narrated: "Three." "Four." "Five." |
| +1.5 s | Badge **5** glows. Narrator: "Five fish — {X blue} and {Y yellow}. That's five." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no drag activity (matches the standard hesitation threshold in `stylus-mechanics.md`). After auto-help completes, lesson advances.

### Pass condition
Any kid drag of any fish onto a pad passes the We-Try. Even one drag is enough; the system completes the rest.

### Narration script

> *(start)* "Your turn. Put five fish on the pond. Use both colors."
>
> *(after first drop)* "Good. Keep going."
>
> *(if monochrome by drop 2)* "Now try the other color."
>
> *(per remaining placement, auto or kid)* "Three." / "Four." / "Five."
>
> *(closing)* "Five fish — {X blue} and {Y yellow}. That's five."

---

## Phase 3 — You-Do (one round of Ten-Frame Pond)

Hand off to the activity's `fill-to-target` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `fill-to-target`
- **Target**: **6** (one more than the lesson, to nudge a fresh problem)
- **Frame**: empty
- **Source**: both blue koi and yellow tetras (decomposition coloring at Concrete)
- **CPA layer**: Concrete (K starting layer)
- **Max attempts**: **3** (first-encounter extra forgiveness)
- **Hints**: enabled at K standard thresholds

### Pass outcome
- Kid places 6 fish on the pond (any color combination), taps Done (or auto-completes after 3 s).
- `mastery.standard_practicing` fires for K.OA.3.
- Library entry created.
- `firstEncounter` for K.OA.3 flips to `false`.

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
| Thumbnail | A ten-frame with 3 blue koi on top row, 2 yellow tetras on bottom row, badge **5** |
| Short label | "Splitting numbers two ways" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~75 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `target: 5`, `firstSplit: "3+2"`, `secondSplit: "4+1"` |
| `lesson.wetry_color_distribution` | `bluePlaced: Int`, `yellowPlaced: Int`, `kidVsAutoSplit` — distribution helps tune the "use both colors" nudge |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `decompositionShown: "X+Y"` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.OA.3
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid uses only one color in We-Try** — the system steers via narration ("Now try the other color"). If the kid never switches, the auto-complete fills with the other color to ensure the visible decomposition is demonstrated. The lesson still passes.
- **Kid drops fish off-frame** — fish returns to source; no penalty. Narrator does not comment.
- **Kid taps a placed fish (tap-to-remove) during the lesson** — fish swims back to source; count ticks down; lesson continues naturally. Useful for kids who change their mind.
- **Source pool runs low on one color** — pool auto-refills; the visible school just looks like ~4 of each color at a time.
- **Frame clears mid-lesson** — only happens at scripted moments (between the two I-Show demonstrations). The clear is fully animated and narrated; not a surprise.
- **Color-blind accessibility** — blue koi and yellow tetras differ in color *and* in shape/pattern (koi have spots, tetras have stripes). The decomposition is perceivable without relying on color alone.

---

## Open Questions

- **Color/species pair** — blue koi + yellow tetras proposed. Confirm species pairing in art direction; ensure they're visually distinguishable beyond color (per accessibility above).
- ~~**Hesitation threshold** — currently 4 s in We-Try (vs 5 s elsewhere). Confirm this faster timing feels right for a first-encounter lesson; alternative is to keep 5 s for consistency.~~ **Resolved 2026-05-30**: normalized to 5 s across all lessons to match the standard hesitation threshold in `stylus-mechanics.md`.
- **Lesson length** — 75 s target is over the 60 s norm. The dual introduction (ten-frame + decomposition) justifies this. If playtest shows attention drops, consider splitting the ten-frame intro into a separate ~15 s "scene tour" that plays only once on first Ten-Frame Pond entry, with K.OA.3 as a more focused 60 s lesson after.
- **Second decomposition pace** — 4+1 is shown faster than 3+2 by design (pattern established). Confirm in playtest that this doesn't feel rushed for the conceptual "still five" moment.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft (K.OA.3 + bundled ten-frame intro) | |
| 2026-05-30 | Normalized We-Try hesitation threshold from 4 s to 5 s (matches `stylus-mechanics.md` standard) | |
