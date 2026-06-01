# MicroLesson — Classify and Sort by Count (K.MD.3)

> "Sort the things, then sort the bins." The procedure for K.MD.3 broken into its two phases: items go into categories, then categories rank by count. First lesson played in Care Pantry. Establishes the activity's universal two-phase round rhythm.

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/care-pantry.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-md-3-classify-and-sort` |
| Concept ID | `K.MD.3` |
| Standard | K.MD.3 — Classify objects into given categories; count the numbers of objects in each category and sort the categories by count |
| Region | Sanctuary |
| Introducing activity | Care Pantry |
| Sub-mode | `simple-pantry` (3 categories — small enough to demo both phases in the time budget) |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 75 s |
| Status | Draft |
| Prerequisite | None |

---

## Setting

Care Pantry's standard scene: the Sanctuary supply hut, lantern-lit. For the lesson, the mess at the center of the workbench is **pre-staged** to **3 categories × small counts** so the kid can see the full two-phase loop in one lesson.

- **I-Show mess**: 6 items total — 3 treats (🦴 🦴 🦴), 2 beds (🛏️ 🛏️), 1 toy (🧸). Selected for visually-obvious count differences (3 > 2 > 1) so Phase 2's sort lands cleanly.
- **We-Try mess**: 7 items — 4 treats, 2 beds, 1 toy. Slightly different counts so it doesn't feel like a mirror of I-Show.
- **Bins**: 3 labeled category bins along the bottom (treats / beds / toys). Each shows a count badge starting at 0.
- **Podium slots**: hidden during Phase 1, appear in Phase 2.

Per `k-activity-patterns.md`: standard K HUD, Sanctuary narrator, Buddy at lower-left on a basket.

---

## Phase 1 — I-Show (≈30 s)

The kid watches both phases run on autopilot — the pointer sorts items, then sorts bins.

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Mess of 6 items at workbench center; 3 empty bins below. Music bed in. |
| 0:02 | Narrator opens. |
| 0:05 | Narrator: "Two jobs today. First, sort the supplies." Glowing pointer appears at the mess. |
| 0:07 | Pointer picks up a treat → drags to the treats bin. Snap, "plop" + chime. Bin count badge ticks to **1**. |
| 0:09 | Pointer picks up a bed → beds bin. Bin count to **1**. |
| 0:11 | Pointer picks up the toy → toys bin. Bin count to **1**. |
| 0:13 | Pointer auto-sweeps the remaining treats (2) and beds (1) into their bins in quick succession. Counts settle: treats **3**, beds **2**, toys **1**. |
| 0:17 | All items are in. Brief "ahhh, tidy" stinger plays. Narrator: "All sorted. Now the second job." |
| 0:20 | Phase 2 begins. Podium slots fade in below the bins, labeled **least / 2 / most**. Bins lift slightly to indicate they're now draggable. |
| 0:22 | Pointer picks up the toys bin (count **1**) → drops on **least**. Snap, "settle" chime. |
| 0:25 | Pointer picks up the beds bin (count **2**) → drops on **2** (middle). Snap. |
| 0:27 | Pointer picks up the treats bin (count **3**) → drops on **most**. Snap. |
| 0:29 | Podium settles. Frame brightens. Narrator delivers the insight. |
| 0:30 | "I've got this" button has been visible since 0:17. I-Show ends. |

### Narration script

> *(0:02)* "The Caretaker stepped out. Two jobs today."
>
> *(0:05)* "First, sort the supplies." *(pointer begins sorting)*
>
> *(0:13)* *(quietly under the sweep)* "Treats with treats, beds with beds, toys with toys."
>
> *(0:17)* "All sorted. Now the second job."
>
> *(0:20)* "Put the baskets in order — fewest to most."
>
> *(0:22–0:27, syncopated with each podium drop)* "One — the fewest. Two. Three — the most."
>
> *(0:29)* "Sort the things, then sort the baskets. That's how we tidy."

### Notes for the narrator
- "Sort the things, then sort the baskets" is the kid-language version of "classify, count, sort by count." Land it as the closing punchline.
- Phase transition at 0:17–0:20 should feel like turning a page — pause briefly between phases.
- Counts during the pointer's bin drops at 0:22–0:27 are the load-bearing comparison: "1 < 2 < 3" is what the kid is meant to internalize without us labeling it as math.

---

## Phase 2 — We-Try (≈25 s)

The kid does one or two drops in each phase; system completes the rest.

### Setup

| Element | State |
|---|---|
| Scene | Same hut. Mess of 7 items (4 treats, 2 beds, 1 toy) at center. 3 empty bins below. |
| Glow target | A single **treat** in the mess highlights with a soft cyan halo; the **treats bin** halos to match. |
| Pointer | Gone — the kid's stylus is the pointer now. |
| Podium slots | Still hidden — Phase 2 will materialize them. |

### Choreography

**Phase 1 (categorize)**

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Drop this treat in the treats basket." Treat + treats bin halo pulses. |
| → kid drags | Kid drags treat → snap on treats bin, count **1**, narrator: "One treat." |
| +0.5 s | A **bed** in the mess halos; **beds bin** halos. Narrator: "Now this one." |
| → kid drags | Kid drags bed → snap on beds bin, count **1**, narrator: "One bed." |
| +0.5 s | System auto-completes remaining 5 items via pointer sweep (3 more treats, 1 more bed, 1 toy). Counts settle: treats **4**, beds **2**, toys **1**. Narrator: "And the rest." |
| End of Phase 1 | Brief stinger; narrator: "All sorted." |

**Phase 2 (sort by count)**

| Time | Action |
|---|---|
| +1.0 s | Podium slots fade in (**least / 2 / most**). Bins lift to indicate they're draggable. |
| +0.5 s | The **toys bin** (count **1**) halos; the **least** podium slot halos. Narrator: "This basket has the fewest. Drag it to 'least'." |
| → kid drags | Kid drags toys bin → snap on least. Narrator: "Fewest." |
| +0.5 s | System auto-completes the other two bins (beds → 2, treats → most) via pointer animation. Narrator: "Two. Most." |
| End | Frame brightens. Narrator: "All in order. Nicely done." We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no drag activity (standard hesitation threshold per `stylus-mechanics.md`), the target's halo brightens and the narrator gently repeats the cue. After another 5 s, the system auto-drags. Lesson advances either way.

### Pass condition
Any kid drag onto any valid target passes. Even one drag in each phase is enough; system completes the rest.

### Narration script

> *(start)* "Your turn. Drop this treat in the treats basket."
>
> *(after kid drop)* "One treat."
>
> *(prompting bed)* "Now this one."
>
> *(after kid drop)* "One bed."
>
> *(auto-completing rest)* "And the rest."
>
> *(Phase 1 close)* "All sorted."
>
> *(Phase 2 open)* "This basket has the fewest. Drag it to 'least'."
>
> *(after kid drop)* "Fewest."
>
> *(auto-completing remaining bins)* "Two. Most."
>
> *(closing)* "All in order. Nicely done."

---

## Phase 3 — You-Do (one round of Care Pantry)

Hand off to the activity's `simple-pantry` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `simple-pantry`
- **Category count**: 3 (matches lesson)
- **Items per category**: 3 / 2 / 1 (fresh counts; not the lesson's 4 / 2 / 1)
- **Phases**: both run (Phase 1 categorize, then Phase 2 sort)
- **CPA layer**: Concrete (per K starting layer; bins show icon + text labels, podium shows "least / 2 / most")
- **Max attempts**: **3** per round (vs default 2; first-encounter forgiveness per `micro-lessons.md`)
- **Hints**: enabled at standard thresholds (5 s hesitation → halo; 10 s → narrator prompt)

### Pass outcome
- Kid completes Phase 1 (all items in correct bins) and Phase 2 (all bins in correct podium positions).
- `mastery.standard_practicing` fires for K.MD.3.
- Library entry created.
- `firstEncounter` for K.MD.3 flips to `false`.
- Caretaker thanks; round-pass celebration.

### Fail outcome (Phase 1 or Phase 2 fails after 3 attempts)
- System auto-completes the failing phase via demonstration.
- Round still ends with the supplies sorted (kid gets the visual reward).
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
| Thumbnail | A workbench split in two: left side shows items going into 3 bins; right side shows 3 bins on a least → most podium |
| Short label | "Sort, then sort again" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~75 s |

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `categoryCount: 3`, `iShowItemCount: 6`, `weTryItemCount: 7` |
| `lesson.wetry_item_dropped` | `itemKind`, `targetBin`, `correct: Bool` (phase 1) |
| `lesson.wetry_bin_dropped` | `binCategory`, `podiumPosition`, `correct: Bool` (phase 2) |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `phase1Outcome: "passed|auto"`, `phase2Outcome: "passed|auto"` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.MD.3
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid drops a treat in the beds bin during We-Try Phase 1** — soft "nope" puff, treat returns to mess. No round-level penalty. Narrator does NOT correct verbally (this is We-Try; the halo guidance is enough — over-narration would feel scolding).
- **Kid grabs and drops a bin during Phase 1** — bins are not draggable during Phase 1 (locked in position). Soft "nope" if attempted; bin stays.
- **Kid drags the largest bin to "least" in Phase 2** — soft "nope" puff, bin returns. No correction narration in We-Try; halo on the correct target re-pulses.
- **Phase 2 with 2 categories instead of 3** — would simplify podium to least/most only. Not used in the lesson (we want the kid to see all 3 podium positions). Confirm `simple-pantry` defaults to 3 categories for the lesson queue.
- **Lesson timed out (e.g., kid wanders away mid-We-Try)** — pause and persist for 5 min; restart We-Try if longer.

---

## Open Questions

- **Lesson length 75 s** — over the 60 s target. Both phases need demonstrating; the 6-item Phase 1 + 3-bin Phase 2 is already minimal. Consider:
  - **(a)** Cut I-Show pointer-sweep at 0:13 (skip showing the remaining items go in) and trust the kid to infer — saves ~4 s.
  - **(b)** Cut Phase 2 We-Try kid-action (system auto-completes all 3 bins after Phase 1) — saves ~10 s but reduces kid agency in Phase 2.
  - Suggest (a) first; only adopt (b) if playtest shows attention loss in the final third.
- **Categories chosen for I-Show** — treats / beds / toys are concrete and clearly distinguishable. The 4th category from Care Pantry (grooming) is omitted in this lesson to stay within `simple-pantry`'s 3-category scope. Confirm playtest the kid generalizes to 4 categories in `full-pantry` without a second lesson.
- **"Sort the things, then sort the baskets" closer** — playtest the phrase. Does the parallel structure land for K, or does "sort... sort" confuse? Backup: "First sort the supplies. Then put the baskets in order."

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first lesson covering a two-phase activity end-to-end within one lesson | |
