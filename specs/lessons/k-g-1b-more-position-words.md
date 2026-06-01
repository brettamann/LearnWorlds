# MicroLesson — More Position Words (K.G.1, follow-up)

> Companion to `k-g-1-positional-language.md`. Covers the three position words not introduced in the first lesson — `below`, `in front of`, `beside` — using the same vocabulary-first pattern. Fires on the kid's **second** Where's Buddy? session (or first time any of these three words is selected by the activity).

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/wheres-buddy.md`, `specs/lessons/k-g-1-positional-language.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-g-1b-more-position-words` |
| Concept ID | `K.G.1` (same concept; second-encounter lesson) |
| Standard | K.G.1 — Describe relative positions of objects |
| Region | Sanctuary |
| Introducing activity | Where's Buddy? |
| Sub-mode | `place-mode` |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 60 s |
| Status | Draft |
| Prerequisite | `lesson-k-g-1-positional-language` completed (kid knows `above`, `behind`, `next to`) |

---

## Setting

Same Where's Buddy? scene the kid saw before. Visual continuity is intentional — the kid recognizes "I'm back here, learning more words." Same 5 landmarks: tree, well, mushroom, rock cluster, cottage. Buddy at center-stage.

For this lesson, the visual choices target the **opposite half** of the position-word pairs the kid already knows:
- `below` (pair of `above`)
- `in front of` (pair of `behind`)
- `beside` (pair of `next to`, with a slight semantic distinction noted below)

Per `k-activity-patterns.md`: standard K HUD, Sanctuary narrator, Buddy center-stage.

---

## Phase 1 — I-Show (≈22 s)

The kid watches. Each new word is introduced **as a pair with its already-known opposite**, then the new word is demonstrated alone.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Buddy at center. Landmarks visible. Music bed in. |
| 0:02 | Narrator opens, referring back to the prior lesson. |
| 0:05 | Glowing pointer drifts Buddy **above the well** (familiar position from prior lesson). Narrator: "You know this — above the well." Brief pause. |
| 0:07 | Pointer drifts Buddy **below the well** — landing in the air just under the well's rim. **A soft directional arrow** points from the well downward. Narrator: "Now this — *below* the well." |
| 0:10 | Buddy returns to center. |
| 0:12 | Narrator: "And this." Buddy turns toward the cottage. |
| 0:13 | Pointer drifts Buddy **behind the cottage** (briefly, ~1 s, recall cue). Narrator: "Behind the cottage — you know that." |
| 0:14 | Pointer drifts Buddy **in front of the cottage** — clearly on the cottage's front side. Narrator: "And *in front of* the cottage." |
| 0:17 | Buddy returns to center. |
| 0:19 | Narrator: "One more." Buddy turns toward the rock cluster. |
| 0:20 | Pointer drifts Buddy **beside the rocks** (close adjacent, not overlapping). Narrator: "Beside the rocks. That's like 'next to' — right alongside." |
| 0:22 | Buddy returns to center. Pointer fades. |
| 0:23 | Narrator delivers the closing insight. |
| 0:25 | "I've got this" button has been visible since 0:18. I-Show ends. |

### Narration script

> *(0:02)* "You already know some position words. Let's add three more."
>
> *(0:05)* "You know this — *above* the well."
>
> *(0:07)* "Now this — *below* the well." *(Buddy floats below well's rim)*
>
> *(0:13)* "Behind the cottage — you know that."
>
> *(0:14)* "And *in front of* the cottage." *(Buddy at cottage front)*
>
> *(0:20)* "Beside the rocks. That's like 'next to' — right alongside." *(Buddy adjacent to rocks)*
>
> *(0:23)* "Above, below. Behind, in front of. Next to, beside. Six words. They tell us *where*."

### Notes for the narrator
- The pairing structure (above/below, behind/in front of, next to/beside) is the pedagogical heart of this lesson. Each new word lands *against* its already-known opposite. Pause briefly between the known and the new for the contrast to register.
- "That's like 'next to' — right alongside" is the only place where two words are presented as near-synonyms. We're not training a precise distinction; we're acknowledging that everyday English uses both for similar geographies.
- The closing list of all six words is a "you now know the full set" beat. Warm, slightly proud — not formal.

---

## Phase 2 — We-Try (≈22 s)

The kid drags Buddy to one of the new positions; system completes a second.

### Setup

| Element | State |
|---|---|
| Scene | Same clearing. Buddy at center. |
| Glow target | The **mushroom** halos softly (target landmark for the first We-Try drop). |
| Position cue | None visible yet — narrator will speak it. |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Put the Buddy *below* the mushroom." (Mushroom halo intensifies as "mushroom" is spoken.) |
| 0:03 | A **directional arrow** appears at the mushroom pointing downward (Concrete-layer scaffolding cue). |
| → kid drags | Kid drags Buddy. If dropped in the "below" zone of the mushroom → snap, narrator: "Below the mushroom — yes." |
| | If dropped elsewhere → Buddy returns to center, narrator: "Below the mushroom — try the spot lower than the mushroom." Arrow brightens. |
| +0.5 s | Second cue: tree glows. Narrator: "Now put the Buddy *in front of* the tree." Directional arrow points outward from the tree's front. |
| → kid drags | Kid drags Buddy to the in-front zone of the tree. Same correction flow. |
| +1.0 s | System **auto-completes** any remaining positions if the kid pauses, narrating each placement. |
| 0:22 | Narrator: "Two more places for the Buddy. You know all six words now." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no drag activity (standard hesitation threshold per `stylus-mechanics.md`), the directional arrow brightens and the narrator gently repeats the cue. After another 5 s, the system auto-drags. Lesson advances either way.

### Pass condition
Any kid drag onto any zone passes. The lesson advances regardless of perfect accuracy.

### Narration script

> *(start)* "Your turn. Put the Buddy *below* the mushroom."
>
> *(after correct drop)* "Below the mushroom — yes."
>
> *(after wrong drop)* "Below the mushroom — try the spot lower than the mushroom."
>
> *(second cue)* "Now put the Buddy *in front of* the tree."
>
> *(after correct drop)* "In front of the tree."
>
> *(closing)* "Two more places for the Buddy. You know all six words now."

---

## Phase 3 — You-Do (one round of Where's Buddy?)

Hand off to the activity's `place-mode` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `place-mode`
- **Position word**: **`beside`** (the third new word, not yet exercised in the We-Try)
- **Reference landmark**: the **well** (fresh landmark, not used in this lesson's We-Try)
- **CPA layer**: Concrete (directional cue arrow visible with the audio prompt)
- **Max attempts**: **3** per `micro-lessons.md` first-encounter forgiveness
- **Hints**: enabled at K standard thresholds

### Pass outcome
- Kid drags Buddy to the `beside` zone of the well.
- Activity announces "Perfect — the Buddy is beside the well."
- `mastery.standard_practicing` fires for K.G.1 (second-encounter lesson counts as additional K.G.1 practice — does not re-fire mastery if already firing).
- Library entry created (separate stamp from the first K.G.1 lesson — the two stamps sit side-by-side on the Stamp Wall).
- All six K.G.1 position words are now formally introduced.

### Fail outcome (all 3 attempts miss)
- Library entry filed.
- Mastery status for K.G.1 unchanged (whatever it was before this lesson).
- Dashboard flag.

---

## Library Entry

| Field | Value |
|---|---|
| Surface (Sanctuary) | Stamp Wall stamp (paired visually with the first K.G.1 stamp) |
| Surface (Wundletown) | Spell Book page |
| Surface (Mathopolis) | Casebook clip |
| Thumbnail | A three-panel image: Buddy below a mushroom, Buddy in front of a tree, Buddy beside a rock cluster |
| Short label | "Three more position words" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~60 s |

The K.G.1 and K.G.1b stamps sit **side-by-side** on the Stamp Wall — they're the position-words pair.

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `wordsIntroduced: ["below", "in front of", "beside"]`, `landmarks: ["well", "cottage", "rocks"]`, `isSecondaryLesson: true` |
| `lesson.wetry_drop` | `positionWord`, `landmark`, `dropZone`, `correct: Bool`, `wasCorrection: Bool` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `youDoWord: "beside"`, `youDoLandmark: "well"` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry. **Does not** re-fire `mastery.standard_practicing` for K.G.1 if already practicing (no double-credit for the secondary lesson).
- `lesson.youdo_failed_out` → library entry only.
- Replays → no rewards.

---

## Edge Cases

- **Kid hasn't completed the first K.G.1 lesson** — prerequisite check should prevent this; if state is corrupted, fall back to the first K.G.1 lesson.
- **The "beside" vs "next to" near-synonymy** — the narrator briefly acknowledges this in I-Show ("That's like 'next to'"). Activity scaffolding treats them as interchangeable for round selection. Don't penalize the kid for not distinguishing them.
- **Directional arrow for "in front of"** — must clearly indicate "out from the front face of the landmark." For round landmarks (well, mushroom), front is the side facing the kid's viewpoint by convention. Confirm with art.
- **Lesson firing timing** — the lesson queue should select this lesson the first time any of the three new words is queued for a round. If the kid never gets a `below`/`in front of`/`beside` round (unlikely given activity rotation), the lesson never fires and the kid only knows the first three words. Activity rotation must guarantee all six words rotate within ~5 rounds.

---

## Open Questions

- **Pacing between Lesson 1 and Lesson 1b** — second session is the proposed cadence. Alternative: same session, 2 rounds after Lesson 1. Suggest second session at launch (gives Lesson 1's three words time to consolidate before adding three more).
- **`beside` vs `next to` distinction** — current spec treats them as near-synonyms. In strict math/English, `beside` implies horizontal adjacency while `next to` is broader. We're not training the distinction at K; both work. Revisit at 1st or 2nd grade if needed.
- **Stamp pairing on Stamp Wall** — two K.G.1 stamps adjacent vs combined into one "position words mastered" stamp. Suggest two adjacent stamps so the kid sees their progress; combined stamp loses the moment.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — companion to the first K.G.1 lesson. Covers `below`, `in front of`, `beside` using a pairing-with-known-opposite pattern. Fires on the kid's second Where's Buddy session. | |
