# MicroLesson — Compare Groups by Matching (K.CC.6)

> "Draw a line from one to one. Whatever's left over has more." Introduces the matching strategy for comparing two groups of objects. First lesson played in Picnic Baskets. Also the first production demonstration of the **Draw-Line** stylus mechanic for the kid.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/shared/stylus-mechanics.md`, `specs/activities/kindergarten/picnic-baskets.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-cc-6-compare-by-matching` |
| Concept ID | `K.CC.6` |
| Standard | K.CC.6 — Use matching or counting strategies to identify whether the number of objects in one group is greater than, less than, or equal to the number in another (up to 10 objects) |
| Region | Sanctuary |
| Introducing activity | Picnic Baskets |
| Sub-mode | `match-by-line` (lesson demonstrates the matching strategy specifically; counting strategy is exercised in the sibling sub-mode without its own lesson) |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 65 s |
| Status | Draft |
| Prerequisite | None |

---

## Setting

Picnic Baskets' standard scene: picnic blanket on a midday glade with two woven baskets. For this lesson, the baskets are pre-staged with **small, visually distinct counts** so the matching procedure is uncluttered.

- **I-Show baskets**: Basket A (🦄 unicorn icon) — 4 apple slices. Basket B (🐉 hatchling icon) — 3 sparkleberries.
- **We-Try baskets**: Basket A — 3 apples. Basket B — 5 sparkleberries. Different counts so it doesn't echo I-Show, and B-has-more flips the side that has the leftover.
- **Indicator buttons**: hidden during the matching action; appear after the kid has drawn lines (or after the system auto-draws).
- Items inside each basket are anchor points for the Draw-Line mechanic.

Per `k-activity-patterns.md`: standard K HUD, Sanctuary narrator, Buddy at lower-left on a small pillow.

---

## Phase 1 — I-Show (≈25 s)

The kid watches. The pointer draws matching lines one at a time, then taps the indicator.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Picnic blanket, two baskets visible with their contents. Music bed in. |
| 0:02 | Narrator opens. |
| 0:05 | Narrator: "Two baskets today. Which has more?" Brief camera nudge between baskets. |
| 0:07 | Narrator: "Watch — we'll match them, one to one." Glowing pointer appears between the baskets. |
| 0:08 | Pointer draws a **line** from apple 1 (basket A) to sparkleberry 1 (basket B). Soft "pencil-on-paper" SFX along the stroke; line settles with a light chime. |
| 0:11 | Pointer draws a second line from apple 2 to sparkleberry 2. |
| 0:14 | Pointer draws a third line from apple 3 to sparkleberry 3. |
| 0:17 | Pointer hovers over apple 4 → swings toward basket B → no more sparkleberries available. Apple 4 **pulses with a soft glow** — un-matched. |
| 0:19 | Narrator delivers the insight. |
| 0:21 | Indicator buttons fade in: **[A has more] [equal] [B has more]**. |
| 0:22 | Pointer drifts to **[A has more]** and taps it. Soft "yes" chime. |
| 0:23 | Narrator confirms. |
| 0:25 | "I've got this" button has been visible since 0:17. I-Show ends. |

### Narration script

> *(0:02)* "Two baskets today. Which has more?"
>
> *(0:07)* "Watch — we'll match them, one to one."
>
> *(0:08–0:14, syncopated with each line drop)* "One to one. Two to two. Three to three."
>
> *(0:19)* "And one apple has no pair. That basket has more."
>
> *(0:22, after pointer taps A-has-more)* "Basket A has more."
>
> *(0:23)* "When something's left over, that side has more."

### Notes for the narrator
- "One to one" is the bedrock matching language — land it softly, not chant-like.
- The "and one apple has no pair" beat is the conceptual punchline — pause before delivering.
- "When something's left over, that side has more" is the generalizable rule the kid takes away. Land it slowly.

---

## Phase 2 — We-Try (≈25 s)

The kid draws one or two lines; system completes the matching; kid taps the indicator (or system auto-completes).

### Setup

| Element | State |
|---|---|
| Scene | Picnic blanket. Basket A: 3 apples. Basket B: 5 sparkleberries. |
| Glow target | Apple 1 in basket A halos softly; sparkleberry 1 in basket B halos to match. |
| Pointer | Gone — the kid's stylus is the pointer now. |
| Indicator buttons | Hidden until matching action completes. |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Draw a line from this apple to that sparkleberry." Halos on apple 1 and sparkleberry 1 pulse. |
| → kid draws | Kid drags from apple 1 toward basket B. If stroke ends near sparkleberry 1 (within Draw-Line anchor tolerance) → line connects, chime. Narrator: "One to one." |
| | If stroke ends in empty space → line dissolves with soft "nope"; halos re-pulse. |
| | If stroke connects apple 1 to a *different* sparkleberry → line connects anyway (any A-to-B match is fine; the lesson rewards the matching procedure, not pair selection). Narrator: "One to one." |
| +0.5 s | Apple 2 halos; sparkleberry 2 halos. Narrator: "Now this one." |
| → kid draws | Kid draws a second line. Same flow. |
| +0.5 s | System auto-completes the third match (apple 3 to sparkleberry 3) via pointer animation. Narrator: "Three to three." |
| +1.0 s | Two sparkleberries in basket B remain un-matched. They pulse with soft glow. Narrator: "And two sparkleberries have no pair." |
| +1.0 s | Indicator buttons fade in. The **[B has more]** button halos softly. Narrator: "Which basket has more? Tap the answer." |
| → kid taps | Kid taps any indicator. If [B has more] → chime + "Yes — basket B has more." |
| | If [A has more] or [equal] → soft "nope"; correct indicator brightens; narrator: "Look — two sparkleberries with no pair. Basket B has more." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no input (drawing or tapping), the current halo brightens and the narrator gently repeats the cue. After another 5 s, the system auto-draws/auto-taps. Lesson advances either way.

### Pass condition
Any kid drag (line) or any kid tap (indicator) counts as participation. The lesson advances regardless of perfect accuracy.

### Narration script

> *(start)* "Your turn. Draw a line from this apple to that sparkleberry."
>
> *(after kid draws line 1)* "One to one."
>
> *(prompting line 2)* "Now this one."
>
> *(after kid draws line 2)* "Two to two."
>
> *(auto-completing line 3)* "Three to three."
>
> *(after un-matched leftover pulses)* "And two sparkleberries have no pair."
>
> *(indicator prompt)* "Which basket has more? Tap the answer."
>
> *(after correct tap)* "Yes — basket B has more."
>
> *(after wrong tap)* "Look — two sparkleberries with no pair. Basket B has more."

---

## Phase 3 — You-Do (one round of Picnic Baskets)

Hand off to the activity's `match-by-line` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `match-by-line`
- **Basket A count**: 5 apples
- **Basket B count**: 4 sparkleberries
- **Result**: A-has-more (different from We-Try's B-has-more, to confirm transfer)
- **CPA layer**: Concrete (indicator buttons show numerals AND labels like "A has more")
- **Max attempts**: **3** per `micro-lessons.md` first-encounter forgiveness
- **Hints**: enabled at K standard thresholds

### Pass outcome
- Kid draws lines between baskets, taps the correct indicator.
- `mastery.standard_practicing` fires for K.CC.6.
- Library entry created.
- `firstEncounter` for K.CC.6 flips to `false`.

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
| Thumbnail | Two baskets side by side with three matching lines drawn between their contents, and one item left un-matched glowing softly |
| Short label | "Match one to one" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~65 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `iShowCountA: 4`, `iShowCountB: 3`, `weTryCountA: 3`, `weTryCountB: 5` |
| `lesson.wetry_line_drawn` | `fromAnchor`, `toAnchor`, `validPair: Bool`, `wasCorrection: Bool` |
| `lesson.wetry_indicator_tapped` | `indicator` (more/less/equal), `correct: Bool` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `linesDrawnByKid: integer`, `firstIndicatorCorrect: Bool` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.CC.6
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid draws a line from apple to apple** (same basket) — line dissolves; narrator does not correct (we don't want over-narration during We-Try). Halos re-pulse to show the correct intent (A-to-B).
- **Kid draws sloppy curves** — Draw-Line accepts up to standard tolerance; the line connects start and end anchors regardless of path shape.
- **Kid double-draws to the same sparkleberry** (e.g., apple 1→B1, then apple 2→B1) — second line replaces the first or attaches as a fork? Per `stylus-mechanics.md` Draw-Line semantics, each B anchor can only receive one line; the second attempt dissolves with soft "nope." Confirm during implementation.
- **Kid taps an indicator before drawing any lines** — indicator buttons aren't visible until matching is in progress or complete; this isn't reachable in the lesson flow. Confirm UI ordering.
- **Counts where un-matched items are split across both baskets** — not possible (one side always has the leftover when counts differ). For equal counts, no leftover anywhere → `[equal]` is correct. Equal-counts case isn't in the lesson; it's exercised in the activity.

---

## Open Questions

- **Equal-counts demonstration** — current lesson only shows the "leftover means more" case. Equal counts (all items pair up, no leftovers) is a distinct conceptual moment. Trade-off: adding it extends the lesson past 75 s. Suggest leaving it for activity scaffolding — first equal-counts round will use Concrete-layer cues (a brief narrator note: "Every item has a pair — they're equal").
- **Pointer drawing speed in I-Show** — too fast and the kid misses the procedure; too slow and the lesson drags. Suggested: ~1 line per second across 3 lines, syncopated with the narrator's "one to one, two to two, three to three." Confirm in playtest.
- **Sparkleberry vs other treat-B options** — sparkleberry is whimsical and Sanctuary-flavored. Alternative: a more conventional treat (a small biscuit). Confirm with art; sparkleberry preferred for distinctive look against the apples.
- **The visual representation of "no pair"** — current spec: leftover item pulses with a soft glow. Alternative: leftover item gets a small "?" or a dashed empty-loop drawn out from it. Suggest soft glow for launch; revisit if playtest finds the unpaired item doesn't read as obviously "leftover."

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first kid-facing use of the **Draw-Line** stylus mechanic; only the matching strategy is taught (counting strategy is exercised without its own lesson) | |
