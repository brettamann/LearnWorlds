# MicroLesson — Compare Two Written Numerals (K.CC.7)

> "The wide side points to the bigger number." Introduces comparing two written numerals (1–10) with `>`, `<`, and `=`. Second Picnic Baskets lesson, queued for the kid's first entry to `numeral-compare`. Builds on K.CC.6's matching strategy — same comparison concept, now with numerals rather than groups.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/picnic-baskets.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-cc-7-compare-numerals` |
| Concept ID | `K.CC.7` |
| Standard | K.CC.7 — Compare two numbers between 1 and 10 presented as written numerals |
| Region | Sanctuary |
| Introducing activity | Picnic Baskets |
| Sub-mode | `numeral-compare` |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 65 s |
| Status | Draft |
| Prerequisite | K.CC.6 introduced (the matching/leftover idea is borrowed for the dot-pattern scaffold). Note: not blocking — if a kid somehow reaches `numeral-compare` first, this lesson stands on its own. |

---

## Setting

Picnic Baskets' standard scene reduced to the **numeral-compare** layout: the picnic blanket is mostly cleared, with two large numeral cards centered on the blanket and a gap between them awaiting a symbol. At Concrete layer, **small dot patterns appear beneath each numeral** as the visual quantity reference (a scaffold that goes away at Pictorial+).

- **I-Show numerals**: **7** on the left, **4** on the right. Both unambiguous, both inside K.CC.7's 1–10 range. Dots beneath: 7 dots and 4 dots in a quick-read pattern.
- **We-Try numerals**: **3** on the left, **5** on the right. Different ratio so the lesson doesn't echo I-Show (and the answer flips to `<`).
- **Symbol tile row** at the bottom: `>`, `<`, `=` draggable tiles.

Per `k-activity-patterns.md`: standard K HUD, Sanctuary narrator, Buddy at lower-left on a pillow.

---

## Phase 1 — I-Show (≈25 s)

The kid watches the pointer pick a symbol and place it in the gap.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Numeral cards (**7**  ?  **4**) on the blanket; dot patterns beneath each numeral (Concrete-layer scaffolding). Symbol tile row (>, <, =) at the bottom. Music bed in. |
| 0:02 | Narrator opens. |
| 0:05 | Narrator: "Seven and four. Which is bigger?" Brief camera nudge between the two numerals. |
| 0:07 | The dot pattern under the **7** pulses briefly; then the dot pattern under the **4** pulses. The visual comparison is implicit (7 dots > 4 dots). |
| 0:10 | Glowing pointer appears at the symbol tile row. |
| 0:11 | Pointer picks up the `>` tile and drifts toward the gap between the numerals. |
| 0:13 | Pointer places `>` in the gap. Snap with warm "settle" chime. The wide side of the `>` faces the **7**; the point faces the **4**. |
| 0:14 | Narrator delivers the rule. |
| 0:17 | The wide side of the placed `>` glows softly; an animated arrow briefly draws from the `>`'s wide side outward to the **7**. |
| 0:21 | Narrator delivers the closing insight. |
| 0:23 | "I've got this" button has been visible since 0:17. I-Show ends. |

### Narration script

> *(0:02)* "Seven and four. Which is bigger?"
>
> *(0:07, dots pulse)* "Look at the dots — seven is more than four."
>
> *(0:11)* "We use a special mark to say so."
>
> *(0:13, as `>` snaps in)* "Seven is greater than four."
>
> *(0:17, with the wide-side arrow)* "The wide side of the mark points to the bigger number."
>
> *(0:21)* "Greater than. Less than. Equal to. Three marks, one job."

### Notes for the narrator
- "Wide side points to the bigger number" is the kid-language version of the directional rule for `>` and `<`. Land it slowly — this is the conceptual handle the kid takes away.
- "Greater than. Less than. Equal to." — name all three explicitly at the close, even though the lesson only demonstrates `>`. This previews the symbols the kid will meet in the round.
- Soft confidence — not lecturing.

---

## Phase 2 — We-Try (≈25 s)

The kid drags a symbol into the gap.

### Setup

| Element | State |
|---|---|
| Scene | Numeral cards (**3**  ?  **5**) with dot patterns beneath. Symbol tile row at the bottom. |
| Glow target | Dot patterns under both numerals pulse briefly when narrator references them. |
| Pointer | Gone — the kid's stylus is the pointer now. |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Three and five — which mark goes between them?" Dot patterns under each numeral pulse softly. |
| 0:03 | The `<` tile in the row halos briefly (a subtle cue — the lesson is steering toward `<` but doesn't lock the kid out of choosing). |
| → kid drags | Kid drags any symbol toward the gap. |
| | If `<` is dropped → snap with chime; narrator: "Three is less than five." |
| | If `>` is dropped → returns to tile row with soft "nope" puff. Narrator: "Look at the dots — three has fewer than five." `<` tile halos brighter. |
| | If `=` is dropped → returns with soft "nope." Narrator: "They're not the same. Three has fewer." `<` tile halos brighter. |
| +1.0 s after correct snap | Wide-side glow + arrow on the placed `<` points to the **5**. Narrator: "The wide side points to the bigger number — five." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no input, the `<` tile's halo brightens and the narrator gently repeats the cue. After another 5 s, the system auto-drags the correct symbol into the gap (with pointer animation and narration). Lesson advances either way.

### Pass condition
Any kid drag onto the gap (correct symbol or wrong) counts as participation. Wrong choices loop back up to 2 times; on a third miss, system auto-completes. The lesson advances either way.

### Narration script

> *(start)* "Your turn. Three and five — which mark goes between them?"
>
> *(after correct drop)* "Three is less than five. The wide side points to the bigger number — five."
>
> *(after `>` wrong drop)* "Look at the dots — three has fewer than five."
>
> *(after `=` wrong drop)* "They're not the same. Three has fewer."

---

## Phase 3 — You-Do (one round of Picnic Baskets)

Hand off to the activity's `numeral-compare` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `numeral-compare`
- **Left numeral**: **6**
- **Right numeral**: **6** (equal — kid hasn't seen `=` in the lesson; this round forces the third symbol to surface)
- **Correct symbol**: `=`
- **CPA layer**: Concrete (dot patterns beneath numerals as scaffold)
- **Max attempts**: **3** per `micro-lessons.md` first-encounter forgiveness
- **Hints**: enabled at K standard thresholds (5 s hesitation → halo; 10 s → narrator prompt)

### Pass outcome
- Kid drags `=` into the gap.
- Activity announces "Six is equal to six — same on both sides."
- `mastery.standard_practicing` fires for K.CC.7.
- Library entry created.
- `firstEncounter` for K.CC.7 flips to `false`.

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
| Thumbnail | Two large numerals (7 and 4) on a picnic blanket with a `>` symbol between them, wide side facing the 7 |
| Short label | "Greater, less, equal" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~65 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `iShowLeft: 7`, `iShowRight: 4`, `weTryLeft: 3`, `weTryRight: 5` |
| `lesson.wetry_symbol_dropped` | `symbolChosen` (>, <, =), `correct: Bool`, `attemptNumber` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `youDoLeft: 6`, `youDoRight: 6`, `youDoSymbol: "="` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.CC.7
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid drops symbol outside the gap** — symbol returns to tile row with no narration penalty (the gap is generously snap-radius'd at 30 pt). After 2 such misses, the gap halos to draw attention to the target zone.
- **Kid grabs the same wrong symbol twice in We-Try** — second miss triggers the correction narration regardless of whether it's the same or a different wrong symbol.
- **Kid covers the dot patterns with the symbol** mid-drag — the dot patterns sit *beneath* the numerals, not in the gap, so they're not covered by the dragged symbol. Confirm in layout.
- **Numerals with two-digit values** (e.g., comparing 7 and 12) — out of scope for K.CC.7 (range is 1–10). The activity enforces this; lesson doesn't need to handle it.
- **Equal numerals scaffolding** — equal isn't shown in I-Show or We-Try; it surfaces only in the You-Do round (6 vs 6). The Concrete-layer narration when the kid lands on `=` makes the equality explicit: "Same on both sides." If the kid struggles with equality specifically, the activity's scaffolding handles it (no separate lesson needed).
- **Dot patterns under one-digit numerals** — patterns up to 10 dots: arrange in ten-frame-style (2×5) for instant recognition. Reuses the visual vocabulary of Ten-Frame Pond, which kids may have seen by now (Ten-Frame Pond is introduced earlier in the K activity ladder). Confirm dot pattern style with art.

---

## Open Questions

- **Equality not demonstrated in I-Show or We-Try** — current spec saves `=` for the You-Do round. Trade-off: the kid hits an unfamiliar symbol cold in You-Do (mitigated by the visual obviousness of two equal numerals + the dot patterns + the Concrete-layer narration). Alternative: a second I-Show/We-Try beat for `=` adds ~15 s; would push the lesson over 80 s. Suggest the current design for launch; if `=` proves confusing, add a small "and one more mark" beat to the lesson close.
- **Symbol orientation reinforcement** — "wide side points to the bigger number" is the rule. Some kids learn this as the alligator-mouth analogy ("the mouth eats the bigger number"). We're avoiding the alligator framing because (a) it's babyish per the Tone & Aesthetic principles and (b) "wide side points" is the real math language we want to land. Confirm in playtest that the wide-side framing transfers; alligator-mouth is a fallback only if it doesn't.
- **You-Do round numerals (6 vs 6)** — chosen to surface `=`. Alternative: a third inequality case (e.g., 8 vs 2) to reinforce `>`/`<`. Trade-off: the kid has seen `>` (I-Show) and `<` (We-Try) but not `=`; You-Do should expose the unseen symbol so all three are covered before the kid is on their own. Suggest 6 vs 6.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — second Picnic Baskets lesson; introduces `>`, `<`, `=` with the wide-side-points rule | |
