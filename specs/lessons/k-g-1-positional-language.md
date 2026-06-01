# MicroLesson — Positional Language (K.G.1)

> "Position words tell us where something is, relative to something else." Introduces the *concept* of positional language through three clear demonstrations (`above`, `behind`, `next to`). The other three words (`below`, `in front of`, `beside`) are exercised through subsequent rounds without their own lessons — same scaffolding system handles them.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/wheres-buddy.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-g-1-positional-language` |
| Concept ID | `K.G.1` |
| Standard | K.G.1 — Describe relative positions of objects using terms such as *above, below, beside, in front of, behind, next to* |
| Region | Sanctuary |
| Introducing activity | Where's Buddy? |
| Sub-mode | `place-mode` (lesson demonstrates via Buddy placement) |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 65 s |
| Status | Draft |
| Prerequisite | None — kid has heard positional language ambiently in Hub navigation, but this is the first explicit lesson |

---

## Setting

Where's Buddy?'s standard scene: late-afternoon Sanctuary clearing with landmarks (tree, well, mushroom, rock cluster, cottage). Buddy starts at the center of the clearing, visible.

Per `k-activity-patterns.md`: standard K HUD, Sanctuary narrator. The Buddy is **center-stage** for this lesson rather than at lower-left — Where's Buddy? makes Buddy the focal interactive element.

The lesson uses **3 of the 5 landmarks** for clear demonstrations (well, tree, mushroom — these have unambiguous "above," "behind," "next to" geography).

---

## Phase 1 — I-Show (≈25 s)

The kid watches. The phase demonstrates *what a position word means* by moving Buddy three times — each time pairing the spoken word with the visible position.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Buddy at center of clearing. Landmarks visible. Music bed in. |
| 0:02 | Narrator opens. |
| 0:05 | Narrator: "Watch where the Buddy goes." Buddy turns toward the well (orientation cue). |
| 0:07 | Glowing pointer drifts Buddy **up and over** the well, landing in the air above it. **A soft directional arrow** points from the well upward to where Buddy now floats. Narrator: "Above the well." |
| 0:10 | Buddy returns to center (smooth glide back). |
| 0:12 | Narrator: "Now this." Buddy turns toward the tree. |
| 0:13 | Pointer drifts Buddy **behind** the tree. Buddy partially disappears behind the tree's canopy. A soft directional arrow indicates the front of the tree, and Buddy is on the back side. Narrator: "Behind the tree." |
| 0:16 | Buddy returns to center. |
| 0:18 | Narrator: "And this." Buddy turns toward the mushroom. |
| 0:19 | Pointer drifts Buddy to the side of the mushroom, **adjacent but not overlapping**. A soft directional arrow connects Buddy and mushroom side-by-side. Narrator: "Next to the mushroom." |
| 0:22 | Buddy returns to center. Pointer fades. |
| 0:23 | Narrator delivers the insight. |
| 0:25 | "I've got this" button has been visible since 0:18. I-Show ends. |

### Narration script

> *(0:02)* "Watch where the Buddy goes."
>
> *(0:07)* "Above the well." *(Buddy floats above)*
>
> *(0:13)* "Behind the tree." *(Buddy partially obscured behind tree)*
>
> *(0:19)* "Next to the mushroom." *(Buddy adjacent to mushroom)*
>
> *(0:23)* "Position words tell us *where* something is. Above. Behind. Next to. There are more — you'll see them as we play."

### Notes for the narrator
- Each position word is delivered with **clear pause** before and after — the word is the load-bearing element of the phrase.
- "Above," "behind," "next to" land with slight emphasis. The visual demonstration is the meaning.
- "There are more — you'll see them as we play" sets up the kid for `below`, `in front of`, `beside` without trying to cram them in here.
- Tone: like an older sibling showing you something cool, not a teacher delivering a list.

---

## Phase 2 — We-Try (≈22 s)

The kid drags Buddy to one stated position; system completes a second.

### Setup

| Element | State |
|---|---|
| Scene | Same clearing. Buddy back at center starting position. |
| Glow target | The **well** glows softly (the target landmark for the first We-Try drop) |
| Position cue | None visible yet — the narrator will speak it |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Put the Buddy *above* the well." (The well halo intensifies briefly as "well" is spoken.) |
| 0:03 | A **directional arrow** appears at the well pointing upward (Concrete-layer scaffolding cue). |
| → kid drags | Kid drags Buddy. If dropped in the "above" zone of the well → zone-snap, narrator: "Above the well — yes." |
| | If dropped elsewhere → Buddy returns to center, narrator: "Above the well — try the spot higher than the well." Arrow brightens. |
| +0.5 s | Second cue: tree glows. Narrator: "Now put the Buddy *behind* the tree." |
| → kid drags | Kid drags Buddy to the behind zone of the tree. Same correction flow. |
| +1.0 s | System **auto-completes** any remaining positions if the kid pauses, with pointer animation. Narrator names each placement. |
| 0:22 | Narrator: "You moved the Buddy two places. Position words help us tell where things go." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no drag activity (standard hesitation threshold per `stylus-mechanics.md`), the directional arrow brightens and the narrator gently repeats the cue. After another 5 s, the system auto-drags. Lesson advances either way.

### Pass condition
Any kid drag onto any zone passes (correct steers; incorrect corrects). The lesson advances regardless of perfect accuracy.

### Narration script

> *(start)* "Your turn. Put the Buddy *above* the well."
>
> *(after correct drop)* "Above the well — yes."
>
> *(after wrong drop)* "Above the well — try the spot higher than the well."
>
> *(second cue)* "Now put the Buddy *behind* the tree."
>
> *(after correct drop)* "Behind the tree."
>
> *(closing)* "You moved the Buddy two places. Position words help us tell where things go."

---

## Phase 3 — You-Do (one round of Where's Buddy?)

Hand off to the activity's `place-mode` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `place-mode`
- **Position word**: a fresh one from the introduced three — suggest **`next to`** (different from the We-Try's `above` and `behind`, to confirm transfer)
- **Reference landmark**: a fresh landmark — suggest the **cottage** (fresh visual from the demo)
- **CPA layer**: Concrete (directional cue arrow appears with the audio prompt per `wheres-buddy.md`)
- **Max attempts**: **3** per `micro-lessons.md` first-encounter forgiveness
- **Hints**: enabled at K standard thresholds

### Pass outcome
- Kid drags Buddy to the `next to` zone of the cottage.
- Activity announces "Perfect — the Buddy is next to the cottage."
- `mastery.standard_practicing` fires for K.G.1.
- Library entry created.
- `firstEncounter` for K.G.1 flips to `false`.

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
| Thumbnail | A three-panel image: Buddy above a well, Buddy behind a tree, Buddy next to a mushroom |
| Short label | "Position words" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~65 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `wordsIntroduced: ["above", "behind", "next to"]`, `landmarks: ["well", "tree", "mushroom"]` |
| `lesson.wetry_drop` | `positionWord`, `landmark`, `dropZone`, `correct: Bool`, `wasCorrection: Bool` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `youDoWord: "next to"`, `youDoLandmark: "cottage"` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.G.1
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid tries to drag Buddy mid-narration** during I-Show — Buddy isn't draggable during I-Show; pointer is doing the demonstration.
- **Directional arrow visual** at the Concrete layer — must be clearly directional (not just a dot or glow). Test with kids: does an arrow → "above" register correctly without verbal explanation? If not, consider augmenting with a tiny up-arrow icon next to the landmark.
- **"Behind" the tree visual** — the tree must have enough visual depth that Buddy *partially obscured* reads as "behind" (not "inside" the tree). Confirm with art.
- **The other 3 position words** (`below`, `in front of`, `beside`) — not introduced in this lesson. They're exercised in subsequent rounds at Concrete layer where the directional arrow handles the scaffolding. Confirm in playtest that the kid can generalize from "above + behind + next to" to the others, or that the Concrete scaffolding is sufficient. If not, consider a second lesson covering the remaining 3 words after the kid has had a few rounds.
- **Buddy's facial expression / body language** during the lesson — Buddy should look attentive and a little playful (this is a game), not stiff. Confirm with character design.

---

## Open Questions

- **Three words vs all six in one lesson** — current spec: 3 words. Alternative: cram all 6 into a faster I-Show. Trade-off: cramming risks attention loss; restraining to 3 leaves the kid to encounter 3 unfamiliar words during gameplay. Suggest 3 at launch with the Concrete-layer scaffolding picking up the slack; playtest will tell if the other 3 cause confusion.
- **Word ordering** — `above`, `behind`, `next to` chosen for visual clarity. Alternative orderings might emphasize different geographic concepts (vertical/horizontal/adjacent). Confirm in playtest.
- **Directional arrow style** at Concrete layer — a literal arrow icon, a glowing dotted path, or a soft motion-blur trail showing "this direction"? Defer to art direction.
- **Should the second introduced lesson (for `below` / `in front of` / `beside`)** be a thing? Decision pending playtest. If kids struggle with the un-introduced words, add `lesson-k-g-1b-more-position-words.md` covering the remaining three.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — introduces 3 of 6 position words, relies on activity scaffolding for the remaining 3 | |
