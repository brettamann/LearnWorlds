# MicroLesson — Word Problems Within 10 (K.OA.2)

> "Stories have math inside them — listen, watch what happens, then count." Teaches the **word problem procedure**: listen → see the scene play out → count the result. Uses an **add-to story** (4 + 2 = 6) as the canonical worked example. The bar model anchors the math structure visually.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/shared/bar-model.md`, `specs/activities/kindergarten/storytellers-pond.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-oa-2-word-problems` |
| Concept ID | `K.OA.2` |
| Standard | K.OA.2 — Solve addition and subtraction word problems within 10 |
| Region | Sanctuary |
| Introducing activity | Storyteller's Pond |
| Sub-mode | `add-to` (lesson uses add-to as canonical example; subsequent rounds rotate through other sub-modes) |
| Narrator voice | Sanctuary warm naturalist, voiced through the **Storyteller turtle** (visible scene character) |
| Total duration target | ≤ 75 s |
| Status | Draft |
| Prerequisite | K.CC.4a (one-to-one) and K.CC.4b (cardinality) lessons completed — the kid can count and knows the last-number-is-how-many rule |

---

## Setting

Storyteller's Pond's standard scene: reedy pond at the edge of the Sanctuary, sunset light, Storyteller turtle perched on the wooden lectern at the bank. Buddy on a flat stone at lower-left.

For this lesson, the pond is empty at the start — creatures (ducks) will arrive during the story.

Per `k-activity-patterns.md`: Storyteller's Pond uses the **visible narrator** pattern. The Storyteller turtle's mouth animates in sync with the narration.

---

## Phase 1 — I-Show (≈28 s)

The kid watches. The Storyteller tells a simple add-to story. The scene plays out. At the end, the pointer counts all the creatures, demonstrating the procedure of "to find the answer, count the final scene."

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Empty pond. Storyteller turtle on lectern, ready. Music bed in. |
| 0:02 | Storyteller turtle opens (mouth-sync). |
| 0:04 | **4 ducks swim in** from off-screen-right and settle onto the pond surface, evenly spaced. |
| 0:07 | Storyteller continues. |
| 0:10 | **2 more ducks swim in** from off-screen-left, joining the existing 4. Now 6 ducks total on the pond. |
| 0:13 | Storyteller pauses, asks the question. |
| 0:15 | Brief silent beat while the kid would mentally count. |
| 0:17 | Pointer appears, drifts to the leftmost duck. **Counts each duck** with a small sparkle on each. Narrator (still the Storyteller voice) counts under: "One. Two. Three. Four. Five. Six." (~5 s) |
| 0:22 | All 6 ducks now sparkle-marked. Count badge appears showing **6**. |
| 0:23 | **Bar model appears** below the pond: `[ █ █ █ █ ]` (blue, the 4 starting) + `[ █ █ ]` (yellow, the 2 added) → result bracket already pre-filled as `[ █ █ █ █ █ █ ]` (purple, 6). |
| 0:26 | Storyteller delivers the insight. |
| 0:28 | "I've got this" button has been visible since 0:18. I-Show ends. |

### Narration script

> *(0:02)* "Listen to this story."
>
> *(0:04, ducks arrive)* "Four ducks are in the pond."
>
> *(0:10, more ducks arrive)* "Two more ducks swim in."
>
> *(0:13)* "How many ducks altogether?"
>
> *(0:15, silent beat)* [pause]
>
> *(0:17, counting)* "Let's count them. One. Two. Three. Four. Five. Six."
>
> *(0:22)* "Six!"
>
> *(0:23, bar model appears)* "Look — four ducks and two more makes six. That's the story's answer."
>
> *(0:26)* "When you hear a story, watch what happens, then count what's left at the end."

### Notes for the narrator
- The Storyteller turtle's voice is the same Sanctuary warm naturalist; the *delivery* gets a slight "telling a tale" inflection — measured, paced, kid-aware.
- "How many ducks altogether?" hangs in the air for ~2 s of silence — this is the moment the kid would mentally try to count.
- "When you hear a story… count what's left at the end" is the lesson's procedural takeaway. Land it as a friendly tip, not a lecture.

---

## Phase 2 — We-Try (≈22 s)

The kid solves a story with system support.

### Setup

| Element | State |
|---|---|
| Scene | Empty pond (same setup as I-Show; refreshes for the new story) |
| Story | New shape: "Three frogs on the lily pad. Two hop in." (3 + 2 = 5) |
| Bar model | Hidden at story start; appears with the question |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Storyteller starts: "Listen. **Three frogs are on the lily pad.**" 3 frogs appear on a lily pad in the pond. |
| 0:04 | "**Two more hop in.**" 2 frogs leap from off-screen, joining the 3. |
| 0:07 | "**How many frogs altogether?**" Bar model appears: `[ █ █ █ ]` + `[ █ █ ]` = `[ ? ? ? ? ? ]` (gray placeholder bracket). |
| 0:10 | Storyteller: "**Count the frogs.**" First frog gets a soft halo. |
| → kid taps | Kid taps frog 1 → sparkle, narrator: "One." |
| +0.5 s | Next frog halos. Kid taps → "Two." |
| +0.5 s | Remaining 3 frogs highlight together; system auto-completes with pointer animation. Narrator: "Three. Four. Five." |
| +1.5 s | Bar model placeholder fills in (gray → purple): `[ █ █ █ █ █ ]`. Storyteller: "**Five frogs.**" |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no tap activity, the next-frog halo brightens. After another 5 s, the system auto-taps with the pointer.

### Pass condition
Any kid tap on any frog passes. The lesson is teaching the procedure, not testing perfect count execution.

### Narration script

> *(start)* "Listen. Three frogs are on the lily pad."
>
> *(after 2 frogs hop in)* "Two more hop in."
>
> *(question)* "How many frogs altogether?"
>
> *(prompting count)* "Count the frogs."
>
> *(after kid tap 1)* "One."
>
> *(after kid tap 2)* "Two."
>
> *(auto-completing)* "Three. Four. Five."
>
> *(closing)* "Five frogs."

---

## Phase 3 — You-Do (one round of Storyteller's Pond)

Hand off to the activity's `add-to` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `add-to`
- **Story template**: a fresh one (not 4+2 or 3+2 from the lesson). Suggest **`add-to-ducks-2`**: "5 ducks in the pond. 1 more swims in. How many?" (5 + 1 = 6)
- **Bar model**: visible (Concrete layer)
- **Answer format**: `tile-select` (Concrete layer fallback — 3 tiles: 5, 6, 7) OR free-write in notebook (kid's choice)
- **CPA layer**: Concrete (full scene + bar model + tile fallback + audio prompt)
- **Max attempts**: **3** per `micro-lessons.md` first-encounter forgiveness
- **Hints**: enabled at K standard thresholds

### Pass outcome
- Kid answers correctly (writes 6 or taps the 6 tile).
- Storyteller delivers the round-pass line: "Six! Five and one more makes six."
- `mastery.standard_practicing` fires for K.OA.2.
- Library entry created.
- `firstEncounter` for K.OA.2 flips to `false`.

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
| Thumbnail | The Storyteller turtle on its lectern with a pond scene behind, 4 ducks + 2 more, and a bar model below |
| Short label | "Stories with math inside" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~75 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `iShowStory: "4-ducks-plus-2"`, `weTryStory: "3-frogs-plus-2"`, `youDoStory: "add-to-ducks-2"` |
| `lesson.wetry_kid_counted_along` | `kidTapsBeforeAuto: Int` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `youDoStoryId: "add-to-ducks-2"`, `inputMethod: "freewrite"|"tile"` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.OA.2
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

The kid may also earn a Pond Creature Card (duck variant) and a Story Memento ("the day you heard your first pond tale") from the You-Do round per Storyteller's Pond's reward design.

---

## Edge Cases

- **Kid taps creatures during the I-Show story** — taps are ignored during I-Show (the kid is watching). The pointer does the counting after the story.
- **Kid taps creatures during the story playback in We-Try** — soft no-op (no SFX); the kid counts at the "Count the frogs" prompt, not during the story.
- **Kid uses the Replay Story button during We-Try** — story re-plays from the start. Lesson advances after the kid attempts the count phase.
- **Storyteller turtle mouth-sync** — must be synced to the narration with ≤100 ms variance. Confirm in implementation.
- **Add-to vs the other 3 sub-modes** — the lesson covers add-to as the canonical example. Subsequent rounds rotate through take-from, put-together, take-apart without further lessons. The kid generalizes the "listen → watch → count" procedure to all four. Worth playtesting whether take-from (creatures leaving) needs its own lesson; suggest no at launch, add if playtest shows confusion.
- **Bar model first appearance** — this is the kid's first time seeing the bar model. The lesson doesn't explicitly explain the bar model itself; the visual is its own explanation (bar lengths match counts). Confirm in playtest that the bar reads intuitively without verbal explanation.

---

## Open Questions

- **Add-to as the canonical example** — chosen because adding-things-arriving is visually clear and intuitive. Alternative: put-together (two groups visible from the start; question asks the total) is more conceptually about "addition as combination." Suggest add-to at launch; rotating through other sub-modes in early rounds will give exposure.
- **Bar model introduction** — the bar appears in I-Show without verbal explanation. Adequate? Or should the Storyteller briefly say "Look at the bars — four blue plus two yellow equals six"? Trade-off: more talking vs visual self-explanation. Suggest visual-only at launch; add verbal if needed.
- **Storyteller turtle character design** — wise, warm, slightly slow-spoken. Confirm with character design that the turtle reads as the right tone for K.
- **Story narration silence beat (0:13–0:17)** — 2 seconds of silence between question and counting demonstration. Confirm playtest finds this comfortable (not too long for K attention spans).
- **You-Do tile-select fallback** — at Concrete, both free-write and tile-select are offered. Should the kid see both immediately, or only see tiles after failing free-write once? Suggest both visible at launch; reduces friction.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first K word-problem lesson; introduces the bar model implicitly through I-Show visual | |
