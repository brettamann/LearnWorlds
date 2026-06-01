# MicroLesson — Cardinality (K.CC.4b)

> "The last number you say tells you how many." Builds on K.CC.4a one-to-one correspondence by surfacing the insight that the final count *is* the cardinality — not just the name of the last object touched.

References: `specs/shared/micro-lessons.md`, `specs/activities/kindergarten/counting-parade.md`, `specs/lessons/k-cc-4a-one-to-one.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-cc-4b-cardinality` |
| Concept ID | `K.CC.4b` |
| Standard | K.CC.4b — The last number said represents the number of objects counted; count is order-independent |
| Region | Sanctuary |
| Introducing activity | Counting Parade |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 62 s |
| Status | Draft |
| Prerequisite | K.CC.4a lesson completed (typically the kid's 2nd Counting Parade round) |

---

## Setting

Same Counting Parade scene as the K.CC.4a lesson. Visual continuity matters — the kid recognizes "oh, I'm here again." Single-species **fawns** (matches the 4a lesson and Concrete-layer single-species rule). Soft afternoon light, music bed quiet. The Buddy watches from lower-left.

- **Single-species** still required at this layer.
- The count badge **starts hidden**; appears with the first count, same as 4a.
- The standard HUD elements (Done button, etc.) are hidden during I-Show and We-Try; appear in You-Do.

---

## Phase 1 — I-Show (≈22 s)

The kid watches. Glowing pointer demonstrates counting — but this time the focus is on **what the last number means**, not the procedure of touching.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up; three fawns standing in line. Music bed comes in low. |
| 0:01 | Narrator begins. |
| 0:04 | Glowing pointer appears, touches fawn 1 → sparkle, badge **1**. |
| 0:06 | Pointer touches fawn 2 → sparkle, badge **2**. |
| 0:08 | Pointer touches fawn 3 → sparkle, badge **3**. |
| 0:11 | Brief pause. Badge **3** **pulses gently** with a soft glow — this is the cardinality moment. |
| 0:12 | Pointer fades out. Narrator delivers the cardinality insight while the badge stays highlighted. |
| 0:15 | **Successor (K.CC.4c) callout** — narrator names the +1 insight; sparkles on fawn 1, fawn 2, fawn 3 pulse in sequence as "one more" is spoken to reinforce the per-step growth. |
| 0:20 | Brief reinforcement beat — narrator restates the cardinality rule succinctly. |
| 0:24 | "I've got this" button has been visible since 0:15. I-Show ends. |

### Narration script

> *(0:01)* "Let's count these fawns again."
>
> *(0:04)* "One. Two. Three." *(pointer touches each in time)*
>
> *(0:11)* *(badge pulses)* "Listen — the last number I said was three. That means there are three fawns. Three is **how many**."
>
> *(0:15)* "And see — each fawn made the count grow by just one. One, two, three. Each one is *one more* than the last."
>
> *(0:20)* "The last number you say tells you how many. Every time."

### Notes for the narrator
- Slightly slower than the 4a lesson. The cardinality insight is the punchline; let it land.
- Emphasize "how many" — that phrase is what the kid will hear in prompts forever after.
- The "*one more*" beat at 0:15 carries K.CC.4c (successor) — pronounce "one more" with slight emphasis. This is the only explicit surfacing of the +1 insight in K lessons; everything else relies on it being implicit in counting.
- The phrase "Every time" closes warmly, not sternly.

---

## Phase 2 — We-Try (≈22 s)

The kid counts (or watches the system count), then explicitly identifies the cardinality by tapping the matching numeral.

### Setup

| Element | State |
|---|---|
| Scene | Four fawns in a line |
| Count badge | Hidden until the first tap |
| Pointer | Gone — kid taps |
| Glow target | Fawn 1 highlights first |
| Numeral tile row | Hidden until counting finishes |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Touch each fawn." Fawn 1 halo pulses. |
| → kid taps | Kid taps fawn 1 → sparkle, badge **1**, narrator "One." |
| +0.5 s | Fawn 2 halo pulses. Narrator: "Next." |
| → kid taps | Kid taps fawn 2 → sparkle, badge **2**, "Two." |
| +0.5 s | Fawns 3 and 4 highlight together — system auto-completes with pointer animation. Narrator: "Three. Four." Badge ticks to **4**. |
| +1.0 s | **Numeral tile row appears below the parade**: three tiles, numerals **3**, **4**, **5**. Narrator: "How many fawns altogether?" |
| → kid taps | Kid taps a numeral tile. |
| +0.5 s | Tile pulses; if correct (**4**), confetti sparkle, narrator: "Four. The last number you said. That's how many." |
| | If incorrect, narrator gently re-prompts: "Listen — what was the last number you counted? *(pause)* Four." Highlights the **4** tile. Kid taps. Narrator confirms. |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
If the kid waits **> 5 s** after the "How many?" prompt, the system gently highlights the correct tile (**4**) and the narrator says "It's four — the last number you said." Lesson advances either way.

### Pass condition
The kid taps any tile (correct preferred; near-misses still pass the lesson). The point is exposure to the cardinality question, not perfection on the first attempt.

### Narration script

> *(start)* "Your turn. Touch each fawn."
>
> *(after tap 1)* "One."
>
> *(prompting next)* "Next."
>
> *(after tap 2)* "Two."
>
> *(auto-completing)* "Three. Four."
>
> *(tiles appear)* "How many fawns altogether?"
>
> *(correct tap)* "Four. The last number you said. That's how many."
>
> *(incorrect tap)* "Listen — what was the last number you counted? Four. *(highlight tile)* Tap four."

---

## Phase 3 — You-Do (one round of Counting Parade)

Hand off to the activity for a real round. The cardinality question is **embedded into the activity's normal flow** — the count badge already shows the total and the narrator already says "Six! There are six fawns" on round-pass. The lesson just made that callout *meaningful*.

### Round parameters

- **Sub-mode**: `count-the-parade` (default)
- **Arrangement**: line
- **Count**: 5 creatures (single species)
- **CPA layer**: Concrete
- **Max attempts**: **3** (first-encounter extra forgiveness)
- **Hints**: enabled at standard thresholds

### Pass outcome
- Kid taps each creature, taps Done (or auto-completes).
- The activity's standard cardinality announcement ("Five! There are five fawns") **counts as K.CC.4b practice**.
- `mastery.standard_practicing` fires for K.CC.4b → kid earns the mastery reward.
- Lesson library entry created.
- `firstEncounter` for K.CC.4b flips to `false`.

### Fail outcome (all 3 attempts miss)
- Lesson library entry still filed.
- `firstEncounter` flips to `false`.
- Mastery status stays `Introduced`.
- Dashboard flag.

---

## Library Entry

| Field | Value |
|---|---|
| Surface (Sanctuary) | Stamp Wall stamp (paired visually with the K.CC.4a stamp) |
| Surface (Wundletown) | Spell Book page |
| Surface (Mathopolis) | Casebook clip |
| Thumbnail | Three fawns + a glowing **3** badge above them, with the **3** circled in soft gold |
| Short label | "The last number is how many" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~60 s |

The K.CC.4a and K.CC.4b stamps sit **side-by-side on the Stamp Wall** — they're paired in the kid's mind too.

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `species: "fawn"`, `weTryTileChoices: [3, 4, 5]` |
| `lesson.wetry_tile_tapped` | `taggedNumeral: Int`, `correct: Bool`, `latencyMs: Int` — distribution helps us spot whether kids guess vs reason |
| `lesson.youdo_passed` | `attempts: 1|2|3` |

The `wetry_tile_tapped` event is unique to this lesson because the cardinality tile-selection step is a custom interaction.

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.CC.4b
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid taps the count badge during I-Show or We-Try** — no-op (badge isn't interactive during the lesson).
- **Kid taps two tiles in rapid succession** — first tap wins; second is ignored.
- **Numeral tile design** — must be visually distinguishable from creatures (different size/shape/color) so the kid doesn't think they're more things to count. Suggest soft pastel tiles with large clear numerals.
- **Order-independence in K.CC.4b** — this is a sub-claim of the standard (count is the same regardless of order). The lesson doesn't explicitly demonstrate this; it's implicit in the kid's success when they tap creatures in a non-left-to-right order during normal play. Activity scaffolding handles this naturally.
- **Kid tile-taps a number that's *plausible* but wrong** (e.g., tapped **3** instead of **4**) — gentle re-prompt with the correct tile highlighted. No failure of the lesson; this is *exactly* the misconception we're addressing.

---

## Open Questions

- **Tile choice range** — should the tile row always be [count-1, count, count+1]? That gives the kid context (a small range to choose from) without making it trivial. Suggest yes; vary range per count.
- **Tile row should disappear during You-Do** — confirm with activity: Counting Parade's normal round doesn't have a tile row, so this is a lesson-only UI element.
- **When 4b lesson plays relative to 4a** — currently designed to fire on the kid's 2nd Counting Parade round (after 4a's lesson + first practice round). Confirm playtest finds this pacing right; alternative is to fire after 3+ practice rounds when K.CC.4a feels stable.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-29 | Initial draft | |
| 2026-05-30 | Added explicit +1 successor callout at 0:15 to surface K.CC.4c (the exercises-only sibling). Successor is no longer purely implicit. | |
