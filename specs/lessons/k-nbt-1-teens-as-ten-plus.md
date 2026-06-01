# MicroLesson — Teens as 10 + N (K.NBT.1)

> "Eleven, twelve, thirteen — these are ten *and some more*." Teaches the kid to see numbers 11–19 as a structured composition of one ten and ones, using the **two-frame layout** with the first frame already collapsed to a ten pearl. The conceptual bridge from "counting things" to "place value."

References: `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activities/kindergarten/ten-frame-pond.md`, `specs/lessons/k-oa-4-make-ten.md`.

---

## Header

| Field | Value |
|---|---|
| Lesson ID | `lesson-k-nbt-1-teens-as-ten-plus` |
| Concept ID | `K.NBT.1` |
| Standard | K.NBT.1 — Compose and decompose numbers from 11–19 into ten ones and some further ones (e.g., 18 = 10 + 8) |
| Region | Sanctuary |
| Introducing activity | Ten-Frame Pond |
| Sub-mode | `ten-plus-n` |
| Narrator voice | Sanctuary warm naturalist |
| Total duration target | ≤ 70 s |
| Status | Draft |
| Prerequisite | K.OA.3 and K.OA.4 lessons completed (kid is fluent with ten-frames and the ten-pearl collapse) |

---

## Setting

A wider pond view than the single-frame sub-modes — the camera pulls back slightly to show **two ten-frames side-by-side** with a small visual gap between them. The kid recognizes the layout from prior practice of make-ten; the ten-pearl is now a familiar visual landmark.

- **Left frame**: **already full and collapsed into a glowing ten pearl**, floating above the left frame's footprint. The frame's lily pads are visible underneath the pearl as a faint outline.
- **Right frame**: **empty**, with the standard 2×5 lily-pad arrangement.
- **Source pool**: standard drifting school at the bottom.
- **Count badge**: displayed in a special **two-line format**:
  - Top line: `10 + 0`
  - Bottom line: `10` (or the kid's running total)
- The badge updates dynamically as the kid adds fish to the right frame.

Buddy at lower-left on a mossy stone as always.

---

## Phase 1 — I-Show (≈25 s)

The kid watches. The phase establishes the **two-frame structure** ("we already have ten — now add some more") and the **dual count representation** ("10 + 3" alongside "13").

### Animation choreography

| Time | Action |
|---|---|
| 0:00 | Scene fades up. Two-frame layout visible: left = ten pearl, right = empty. Badge shows `10 + 0` / `10`. Music bed in. |
| 0:02 | Narrator opens. |
| 0:05 | Narrator: "We already have ten." Ten pearl on the left pulses gently. Badge top line **`10 + 0`** pulses with it. |
| 0:08 | Narrator: "Now let's add some more." Glowing pointer drifts to the source pool. |
| 0:10 | Pointer picks up a fish → places on right-frame top-row pad 1. Snap, badge updates: `10 + 1` / `11`. Narrator: "Eleven — ten and one." |
| 0:13 | Pointer picks up another fish → right-frame top-row pad 2. Badge `10 + 2` / `12`. Narrator: "Twelve — ten and two." |
| 0:16 | Pointer picks up a third fish → right-frame top-row pad 3. Badge `10 + 3` / `13`. Narrator: "Thirteen — ten and three." |
| 0:19 | Pointer fades. Badge `10 + 3` / `13` glows. |
| 0:21 | Narrator delivers the structural insight. |
| 0:25 | "I've got this" button has been visible since 0:16. I-Show ends. |

### Narration script

> *(0:02)* "Look at this pond — it's bigger now. Two frames."
>
> *(0:05)* "The left side is already full. We have ten."
>
> *(0:08)* "Now let's add some more."
>
> *(0:10)* "Eleven — ten and one."
>
> *(0:13)* "Twelve — ten and two."
>
> *(0:16)* "Thirteen — ten and three."
>
> *(0:21)* "Teen numbers are *ten and some more*. Eleven is ten and one. Twelve is ten and two. Thirteen is ten and three."

### Notes for the narrator
- Every new fish triggers the **dual phrasing**: the number, then "ten and N." This pairing is the conceptual move.
- "Teen numbers are ten and some more" — the closing insight gives the kid a phrase they can apply.
- Emphasize "and" — it's the connective tissue between the ten and the extras.

---

## Phase 2 — We-Try (≈20 s)

The kid drags fish to make a target teen number.

### Setup

| Element | State |
|---|---|
| Scene | Two-frame layout. Left = ten pearl. Right = empty. |
| Target | **15** (different from I-Show's 13 to discourage memorization) |
| Source pool | Standard |
| Count badge | Starts at `10 + 0` / `10`, displayed |

### Choreography

| Time | Action |
|---|---|
| 0:00 | Narrator: "Your turn. Make fifteen. We already have ten." |
| 0:03 | First empty cell on the right frame halo pulses. |
| → kid drags | Kid drags a fish → snap, badge `10 + 1` / `11`, narrator: "Eleven — ten and one." |
| +0.5 s | Second empty cell halo pulses. Narrator: "Keep going to fifteen." |
| → kid drags | Kid drags a fish → snap, badge `10 + 2` / `12`, narrator: "Twelve." |
| +0.5 s | Remaining 3 empty cells highlight together; system auto-completes with pointer: drags 3 more fish in. Narrator: "Thirteen. Fourteen. Fifteen." |
| 0:18 | Badge `10 + 5` / `15` glows. Narrator: "Fifteen — ten and five." |
| End | We-Try ends; advance to You-Do. |

### Hesitation rule
After **5 s** of no drag (standard hesitation threshold per `stylus-mechanics.md`), system pulses the next target cell brighter and narrator nudges: "Drag one from the school." After another 5 s, system auto-taps. Lesson advances either way.

### Pass condition
Any kid drag onto the right frame passes. Even one is enough.

### Narration script

> *(start)* "Your turn. Make fifteen. We already have ten."
>
> *(after drop 1)* "Eleven — ten and one."
>
> *(prompt)* "Keep going to fifteen."
>
> *(after drop 2)* "Twelve."
>
> *(auto-completing)* "Thirteen. Fourteen. Fifteen."
>
> *(closing)* "Fifteen — ten and five."

---

## Phase 3 — You-Do (one round of Ten-Frame Pond)

Hand off to the activity's `ten-plus-n` sub-mode for a real round.

### Round parameters

- **Sub-mode**: `ten-plus-n`
- **Target**: **17** (a different teen to discourage memorization)
- **Left frame**: pre-collapsed ten pearl (always, in this sub-mode)
- **Right frame**: empty
- **CPA layer**: Concrete (K starting layer)
- **Max attempts**: **3** (first-encounter extra forgiveness)
- **Hints**: enabled at K standard thresholds

### Pass outcome
- Kid places 7 fish on the right frame, taps Done (or auto-completes after 3 s).
- Activity announces "Seventeen! Ten and seven" on round-pass.
- `mastery.standard_practicing` fires for K.NBT.1.
- Library entry created.
- `firstEncounter` for K.NBT.1 flips to `false`.

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
| Thumbnail | Two-frame layout: left = ten pearl glowing, right = 3 fish, badge `10 + 3 = 13` |
| Short label | "Ten and some more" |
| Original region badge | Sanctuary leaf |
| Replay duration | ~70 s |

This stamp anchors the K-counting arc. K.CC.4a/4b/4c lay the counting foundation; K.OA.3 introduces decomposition; K.OA.4 anchors ten as a target; K.NBT.1 turns ten into a *structural* unit. The Stamp Wall's row of K stamps tells this story visually.

---

## Telemetry

Standard MicroLesson events from `micro-lessons.md`, plus:

| Event | Custom payload |
|---|---|
| `lesson.started` | `iShowTarget: 13`, `weTryTarget: 15`, `youDoTarget: 17` |
| `lesson.wetry_completed` | `kidDrags: Int`, `autoDrags: Int` |
| `lesson.youdo_passed` | `attempts: 1|2|3`, `target: 17`, `extrasPlaced: 7` |

---

## Reward Emissions

- `lesson.youdo_passed` → standard `round.passed` (+2 coins) + library entry + `mastery.standard_practicing` for K.NBT.1
- `lesson.youdo_failed_out` → library entry only
- Replays → no rewards

---

## Edge Cases

- **Kid tries to drag a fish onto the left (collapsed) frame** — the ten pearl is non-interactive; fish drop on the pearl returns to source with a soft "no" puff. Brief "this side is already ten" tooltip.
- **Kid tries to drag a fish off the right frame** (tap-to-remove a placed fish) — works as in normal Ten-Frame Pond: fish swims back, count ticks down. Useful for corrections.
- **Kid drags 8+ fish into the right frame** (more than target) — extras snap to the source as the right frame fills past the target. The frame *can* hold up to 10 fish on the right side; if kid fills it to 10, it'll collapse to a second ten pearl (and the activity then enters a state the lesson didn't anticipate). For the lesson, **cap the kid's drags at target + 1** (one over to let them correct via tap-to-remove); subsequent drags return to source.
- **Badge two-line format on small screens** — confirm legibility on iPad mini sizes; consider single-line fallback `10 + 3 = 13` if vertical space is tight.
- **Color of the ten pearl** — should be **distinct from the fish color** so the kid sees it's no longer "fish." Suggest soft gold-white.

---

## Open Questions

- **Targets across phases (13 / 15 / 17)** — escalating teen numbers. Confirm this feels like a natural progression, not arbitrary. Alternative: keep consistent (all 13) so the kid focuses on the structure not the number.
- **Dual badge format `10 + N` / `N+10`** — proposed two-line format. Confirm with art; consider single-line `10 + 3 = 13` if cleaner. The equation form aligns with the Abstract CPA layer's rendering (per `k-activity-patterns.md`); for the lesson we want both forms visible regardless of layer.
- **Should the lesson explicitly decompose a teen (the *reverse* direction)?** K.NBT.1 says "compose and decompose." Composing 10 + 7 → 17 is the lesson's forward direction. Decomposing 17 → 10 + 7 is the reverse. Suggest the reverse direction lives in a separate dedicated round type within `ten-plus-n` rather than in the first-encounter lesson — too much for one ≤70 s lesson.
- **Visual continuity from K.OA.4** — both lessons feature the ten-pearl collapse. K.OA.4's lesson ends with a fresh ten pearl; K.NBT.1's lesson opens with an existing ten pearl. Consider a brief transitional moment in the K.NBT.1 lesson opening that says "remember the ten pearl from before? we already have one" — strengthens the conceptual link. Defer to playtest.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft | |
| 2026-05-30 | Normalized We-Try hesitation threshold from 4 s to 5 s (matches `stylus-mechanics.md` standard) | |
