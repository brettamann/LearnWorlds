# Activity Spec — Ten-Frame Pond

> The K activity that introduces the **ten-frame representation** and the foundational composition/decomposition concepts: K.OA.3 (decompose ≤10 multiple ways), K.OA.4 (make sums of 10), K.NBT.1 (compose 11–19 as 10 + n).

References: `specs/shared/stylus-mechanics.md`, `specs/shared/math-notebook.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/reward-economy.md`, `specs/shared/micro-lessons.md`, `specs/activity-spec-template.md`.

---

## Header

| Field | Value |
|---|---|
| Activity name | Ten-Frame Pond |
| Activity slug | `ten-frame-pond` |
| Region | Sanctuary |
| Grade | K |
| Standards | K.OA.3, K.OA.4, K.NBT.1 |
| Status | Draft |
| Last updated | 2026-05-30 |

---

## Setting & Tone

- **Scene** — A magical lily pond at the edge of the Sanctuary. Sunlight dapples the water surface. Ten large lily pads float in a tidy 2×5 grid — two rows of five — at the center of the pond. A school of fish drifts in a soft current along the bottom of the screen, waiting to be moved.
- **Atmosphere** — Soft water sounds: distant lap, occasional plip. The Sanctuary music bed shifts slightly cooler than Counting Parade (mid-morning vs afternoon). Palette anchors: water blue, pond green, soft pearl-white for the lily pads, sun-yellow highlights.
- **Buddy presence** — The Buddy sits on a small mossy stone at the lower-left, watching the pond. Idle animations: occasional shake-off, dipping a paw in the water. Reacts to round completion with a small celebratory hop.
- **Narrator** — Sanctuary warm naturalist (consistent with all K activities).

---

## Standards Coverage

| Standard | What the kid does | Telemetry event | Mastery threshold |
|---|---|---|---|
| **K.OA.3** (decompose ≤10 into pairs, multiple ways) | Fills the ten-frame in two visually distinct groups; over multiple rounds, shows the same target with different splits | `tenframe.decomposition_demonstrated` (payload: `target`, `partA`, `partB`) | 5 successes at Abstract, ≥3 sessions, ≥3 days |
| **K.OA.4** (make sums of 10) | In sums-of-10 sub-mode: drags the missing fish onto a partially-full frame until 10 is reached | `tenframe.make_ten_completed` (payload: `startingAmount`) | Same |
| **K.NBT.1** (compose 11–19 as 10 + n) | In two-frame sub-mode: fills one frame to 10 (collapses to a "ten pearl") then adds 1–9 more in a second frame | `tenframe.teen_composition_completed` (payload: `tens`, `ones`, `total`) | Same |

---

## Concepts: Introduced vs Exercised

Ten-Frame Pond is the K-canonical entry point for the **ten-frame representation** itself plus three composition concepts. The ten-frame intro is bundled into the K.OA.3 lesson (the first concept the kid encounters here) rather than treated as its own concept — the kid learns the tool by using it.

| Concept | Role | Lesson | Notes |
|---|---|---|---|
| **K.OA.3** (decompose ≤10 multiple ways) | Introduces | `specs/lessons/k-oa-3-decomposition.md` | First lesson played here. **Also introduces the ten-frame as a representational tool** (kids learn it through use). |
| **K.OA.4** (make sums of 10) | Introduces | `specs/lessons/k-oa-4-make-ten.md` | Fires on first entry to the `make-ten` sub-mode. |
| **K.NBT.1** (compose 11–19 as 10 + n) | Introduces | `specs/lessons/k-nbt-1-teens-as-ten-plus.md` | Fires on first entry to the `ten-plus-n` sub-mode. The "collapse to ten pearl" visual is the conceptual anchor. |

### Registry impact

- `K.OA.3.introducedBy = ten-frame-pond`
- `K.OA.4.introducedBy = ten-frame-pond`
- `K.NBT.1.introducedBy = ten-frame-pond`

---

## Sub-Modes

### Sub-mode: `fill-to-target`

- **Standards targeted** — K.OA.3 (decomposition emerges naturally as the kid drags fish in groups)
- **What the kid does** — A target N (≤10) is announced. The kid drags fish from the source pool onto lily pads until the frame holds exactly N.
- **Pass condition** — Frame contains exactly N fish. Auto-fires the "done" state after **3 s of no new drags** when target is reached; the visible Done button is also available.
- **Fail behavior** — Wrong count (over or under) → warm narrator + demonstration: the system shows the correct fill, then a new round of the same target.

### Sub-mode: `two-ways`

- **Standards targeted** — K.OA.3 explicitly
- **What the kid does** — A target N is announced. The kid fills the frame to N **twice in a row** with a **visibly different split** each time. "Show me five another way."
- **Pass condition** — Two rounds of the same N completed with the second decomposition distinct from the first (different split position, ideally different colors per side).
- **Fail behavior** — If the second attempt matches the first (e.g., both 5 = 2 + 3 in the same arrangement), narrator: "Show me a *different* way to make five." Frame clears; retry.

### Sub-mode: `make-ten`

- **Standards targeted** — K.OA.4
- **What the kid does** — The frame opens **partially full** (e.g., 7 fish already placed, scattered across pads). Narrator: "We have 7. Make 10." The kid drags the missing fish (3) to fill the frame.
- **Pass condition** — Frame contains exactly 10 fish. Auto-fires after 3 s of stillness once 10 is reached.
- **Visual reward** — On reaching 10, the entire frame **collapses with a shimmer animation** into a single glowing "ten pearl" floating above where the frame was. The pearl persists for ~2 s as celebration before the next round.
- **Fail behavior** — Wrong count → warm demonstration showing exactly how many were missing.

### Sub-mode: `ten-plus-n`

- **Standards targeted** — K.NBT.1
- **What the kid does** — Two frames sit side-by-side. The first frame is **already full and collapsed** into a glowing ten pearl. The second frame is empty. A target like 13, 17, or 19 is announced; the kid drags N fish (1–9) into the second frame.
- **Pass condition** — Second frame contains exactly the right number of extras (target − 10).
- **Visual reinforcement** — As the kid drags, the count badge shows both forms: **"10 + 3"** and **"13"**, side by side, ticking up with each fish.
- **Fail behavior** — Wrong count → narrator demonstrates: "We had ten. Three more makes thirteen." Frame clears; retry.

### Sub-mode: `three-frames` *(challenge variant)*

- **Standards targeted** — K.NBT.1 stretched into K.CC.1 territory (counting to 30)
- **What the kid does** — Three frames side-by-side. First two are pre-collapsed ten pearls (= 20). The kid fills the third frame to reach a target 21–30.
- **Pass condition** — Third frame matches the target.
- **Reward bump** — Challenge chest on completion per `reward-economy.md`.

---

## Visual Layout

```
+--------------------------------------------------------+
| [exit]                                  [coins: 12]    |
|                                                        |
|   <rippling pond background, dappled sunlight>        |
|                                                        |
|   +-----+-----+-----+-----+-----+                     |
|   |  ●  |  ●  |  ●  |     |     |   <ten-frame:       |
|   +-----+-----+-----+-----+-----+    2 rows × 5 pads> |
|   |  ●  |  ●  |     |     |     |                     |
|   +-----+-----+-----+-----+-----+                     |
|                                                        |
|                  [count: 5]                            |
|                                                        |
|   ~~~  ◐  ◐  ◐  ◐  ◐  ◐  ~~~                          |
|   <fish source pool — drifting school at bottom>      |
|                                                        |
|  [Buddy idle]                          [notebook >]   |
|                                                        |
|                  [ done? ]                             |
+--------------------------------------------------------+
```

- **Persistent scene anchors** — rippling pond water (parallax), bordering reeds, occasional dragonfly. Buddy on mossy stone in lower-left.
- **Interactive elements**:
  - **Lily pad cells** — drop targets (Drag-and-Drop snap-to-grid). Single-occupancy. Each pad holds one fish.
  - **Fish in pool** — draggable source. Tapping or dragging from the school picks up one fish.
  - **Fish on a pad** — tap to **remove** (fish swims back to the source pool, count ticks down). No penalty for corrections.
  - **Ten pearl** (when a frame collapses) — non-interactive; visual reward only.
- **Math notebook tab** — collapsed on right edge. Optional relationship; +1 coin bonus if used.
- **HUD elements**:
  - Top-left: exit (small house icon)
  - Top-right: live coin count
  - Center-below-frame: count badge (shows current count; in `ten-plus-n` mode shows both "10 + N" and total)
  - Bottom-center: Done button (visible after first fish placed)

### Two-frame layout (`ten-plus-n` sub-mode)

```
   +-+-+-+-+-+   +-+-+-+-+-+
   | | | | | |   | | | | | |
   +-+-+-+-+-+   +-+-+-+-+-+
   | | | | | |   | | | | | |
   +-+-+-+-+-+   +-+-+-+-+-+
    <ten pearl>   <extras>

         count: 10 + 3 = 13
```

---

## State Machine

```
[idle/intro] → narrator opens with sub-mode prompt
   ↓
[setup] → frame configured per sub-mode (empty / partially-filled / two-frame / three-frame)
         count badge hidden until first interaction
   ↓
[active] → kid drags fish; fish snap to cells; badge appears + ticks
   ↓ (kid taps Done OR auto after 3 s of stillness at target)
[evaluating] → check fish count vs target
   ↓
[round_passed]                       [round_failed]
   ↓                                    ↓
[reward + visual flourish:           [warm narrator + demonstrate]
 ten pearl collapse if 10 reached]      ↓
   ↓                                  [retry at current layer]
[next round queued]                     ↓
                                     [if 2 consecutive fails: demote per scaffolding]
```

**Exit conditions**:
- Kid taps exit → save progress, return to Hub.
- Daily Quest mode: 5 rounds, auto-exit.
- Free Play: continuous until kid exits or 30-min soft cap.

---

## Stylus Interactions

| Mechanic | Where used | Local overrides |
|---|---|---|
| **Drag-and-Drop (snap-to-grid)** | Primary mechanic: fish from source pool → lily pad cells | Snap radius standard (24 pt). Cells are single-occupancy; dropping on an occupied cell returns the fish to the source. |
| **Tap (correction)** | Tap a fish on a lily pad to remove it | Tap tolerance: standard tap. Removal animates the fish swimming back to the source pool. |

No other mechanics. Tap-Count is **not** used here (this is a placement activity, not a counting activity).

---

## Number-Writing Modes

Ten-Frame Pond does **not** require the kid to write numerals at launch. The count badge displays numerals; equation forms appear automatically in `ten-plus-n` mode.

**Notebook usage**: optional, encouraged in `ten-plus-n` rounds — the kid can write the equation `10 + 3 = 13` if they want (Mode 2 prompted free-write, since the equation is visible). The +1 notebook bonus applies.

A future v1.1 enhancement might add an explicit "write the answer" prompt in advanced rounds.

---

## Audio Cues

> **Runtime source**: narration cues live in [`content/strings/en-US/activities/ten-frame-pond.json`](../../../content/strings/en-US/activities/ten-frame-pond.json). The prose below is the design-time reference; the JSON is the authoritative source the TTS pipeline and runtime consume.

### Narrator lines (Sanctuary voice)

#### `fill-to-target`
- **Round start**: "Put {N} fish on the pond."
- **Mid-progress hesitation**: "Keep going — drag fish from the school below."
- **Round pass**: "{N}! You put {N} fish on the pond."
- **Round fail (over)**: "We have {actual}. We needed {target}. Tap some fish to send them back."
- **Round fail (under)**: "We have {actual}. We need {N − actual} more."

#### `two-ways`
- **First round prompt**: "Make {N} fish on the pond."
- **Second round prompt**: "Now make {N} a different way."
- **Pass**: "Two ways to make {N}. Nice."
- **Fail (same split)**: "Show me a *different* way to make {N}."

#### `make-ten`
- **Round start**: "We have {start} fish. Make 10."
- **Mid-progress**: (no narration unless hesitation)
- **Round pass**: "Ten! That's a full pond." *(ten pearl shimmers)*
- **Round fail**: "We have {actual}. We need {10 − actual} more to make ten."

#### `ten-plus-n`
- **Round start**: "We have ten fish here. Add {n} more to make {target}."
- **Mid-progress**: badge ticks "10 + 1 = 11... 10 + 2 = 12..." as kid drags
- **Round pass**: "{target}! Ten and {n} more."
- **Round fail**: "We have {actual}. We needed {target}."

#### `three-frames` (challenge)
- **Round start**: "Two full ponds — that's twenty. Add {n} more to make {target}."
- **Pass**: "{target}! Twenty and {n} more."

### SFX

| Event | SFX |
|---|---|
| Fish picked up from source | Soft "swish" |
| Fish snaps onto lily pad | Light "plop" + soft chime |
| Fish removed from pad (tap) | "Whoosh" back to source |
| Drop on occupied / invalid cell | Soft "no" puff |
| Frame fills to 10 (collapse) | **Shimmer-collapse**: rising chime + brief sparkle wash; fish merge visually into a glowing pearl |
| Round pass | Sanctuary chime stinger |
| Round fail | Soft sad-but-warm chord |

### Music

- Sanctuary mid-morning bed: gentle strings + harp, ~85 BPM, 75-second loop.
- Slight intensity bump as a frame approaches 10 in `make-ten` and `fill-to-target` (subtle — kids shouldn't feel rushed).
- Round-pass stinger plays *over* the bed.

---

## Scaffolding Triggers

Uses `ScaffoldQuery` per round (see `adaptive-scaffolding.md`) — including `firstEncounterLesson` for routing to lessons on first encounter with K.OA.3, K.OA.4, or K.NBT.1.

| Trigger | Response |
|---|---|
| **5 s of no drag activity** | Highlight an empty target lily pad (any empty one) for 1.5 s with a glow |
| **10 s of no drag activity** | Narrator: "Drag a fish from the school below onto a lily pad." |
| **Kid drops fish outside the frame entirely** | Fish returns to source pool with a soft "whoosh"; no penalty |
| **Kid drops fish on an occupied pad** | Fish returns to source; brief "this pad has one" tooltip animation |
| **Kid taps Done with wrong count** | Round fails; warm demonstration (system completes the fill, narrating "we needed {N}; here's how it looks") |
| **2 consecutive round failures** | Apply the **staggered demotion** rule from `adaptive-scaffolding.md`: demote CPA layer first (Abstract → Pictorial → Concrete). If already at Concrete, demote sub-mode (`ten-plus-n` → `make-ten` → `two-ways` → `fill-to-target`) and CPA layer resets to Concrete for the simpler sub-mode. |
| **2 consecutive failures within `fill-to-target` at Concrete** (already at floor sub-mode + layer) | Reduce target N (e.g., from 8 to 5) |

---

## CPA Progression

| Layer | What it looks like in Ten-Frame Pond |
|---|---|
| **Concrete** | Fish as draggable objects; count badge shows numeral **and** dot pattern matching the frame fill. At round-pass, cardinality is announced verbally. |
| **Pictorial** | Fish + frame; count badge shows **numeral only** (dot pattern dropped). The ten-frame's empty cells become the pictorial cue — "I see 5 dots and 5 empty spaces; that's 5 of 10." |
| **Abstract** | Fish + frame; count badge shows the **equation form** alongside (`3 + 2 = 5` for two-ways; `10 + 3 = 13` for ten-plus-n). Numerals stay primary; fish are still draggable but the math is foregrounded. |

- **Default starting layer (K, fresh kid)** — Concrete.
- **Promotion conditions** — 3 consecutive passes at the current layer.
- **Demotion conditions** — 2 consecutive failures at the current layer.

### Decomposition coloring rule

In `two-ways` sub-mode, the visual coloring of the fish depends on the layer:
- **Concrete**: each side of the split is a **different species** (e.g., 4 blue koi + 1 yellow tetra). The kid can *see* the decomposition.
- **Pictorial**: same color, but a **visible boundary/divider** appears between the two groups (subtle).
- **Abstract**: same color, no divider. The kid has to **see the split themselves** (or write the equation).

This matches the Counting Parade single-species-by-layer rule's spirit: visual scaffolds drop as the kid graduates.

---

## Reward Emissions

| Event | Trigger | Reward (per `reward-economy.md`) |
|---|---|---|
| `round.passed` | Round passes | +2 coins |
| `round.notebook_bonus` | Notebook had ≥3 strokes during round | +1 coin |
| `streak.session_3` / `_5` / `_10` | Standard streak thresholds | Per shared spec |
| `milestone.problems_25` / `_100` | Lifetime in this activity | Per shared spec |
| `mastery.standard_practicing` / `_mastered` | Adaptive scaffolding emits | Per shared spec |
| `challenge.completed` | Three Frames round passes | Challenge chest (rare fish guaranteed) |
| **`tenframe.strategy_variety_bonus`** | **Three distinct decompositions of the same target N within one session** | **Rare Sanctuary Reef collectible** (one of ~6 special fish only available this way) |

### Activity-specific collectibles
- **Sanctuary Reef Cards** — ~20 fish species at launch. Drops at ~1 in 5 round-pass events, weighted toward unseen cards.
- **Rare Sanctuary Reef** — ~6 special fish only earned via the strategy variety bonus (three distinct decompositions of the same target). These are *prized*: collecting all six earns a Hub trophy: the **Reef Atlas**.
- This collectible system rewards **MP.7** ("look for and make use of structure") — kids who explore multiple decompositions are demonstrating flexible number sense.

---

## Telemetry Events

(Beyond the shared `scaffold.*`, `economy.*`, and `lesson.*` events.)

| Event | Payload |
|---|---|
| `tenframe.round_started` | `subMode`, `target`, `prePopulated`, `presentationLayer` |
| `tenframe.fish_dragged` | `fromZone` (source/cell-N), `toZone` (cell-N/source/elsewhere), `latencyMs` |
| `tenframe.fish_removed` | `cell`, `roundElapsedMs` |
| `tenframe.frame_collapsed_to_ten` | `subMode`, `fillSequence` (the cells filled in order) |
| `tenframe.decomposition_demonstrated` | `target`, `partA`, `partB`, `partALocation` (top/bottom row, left/right) |
| `tenframe.make_ten_completed` | `startingAmount`, `missingDragged`, `attempts` |
| `tenframe.teen_composition_completed` | `tens`, `ones`, `total`, `attempts` |
| `tenframe.round_completed` | `success`, `subMode`, `attemptsThisRound`, `hintsFired` |
| `tenframe.strategy_variety_bonus_earned` | `target`, `decompositionsThisSession` (the list) |
| `tenframe.collectible_dropped` | `cardId`, `setProgress`, `isRare` |

---

## Challenge Variant

**Three Frames** (Number Range Stretch + K.NBT.1 extension).

- **What changes** — Three ten-frames side-by-side. First two are pre-collapsed ten pearls (= 20). Kid fills the third frame to reach a target 21–30.
- **Entry point** — "Triple Pond!" banner appears on Ten-Frame Pond's tile in the Sanctuary 1× per day at launch (tunes post-launch per the Counting Parade precedent).
- **Reward bump** — Challenge chest on completion (rare Sanctuary Reef fish guaranteed).

---

## Edge Cases & Error Handling

- **Kid drops fish on already-occupied pad** — fish snaps back to the source pool with a soft "no" puff. No penalty. Brief "this pad has one" visual.
- **Kid drags fish off a pad after placing it** — equivalent to tap-to-remove: fish swims back to source, count ticks down. This is intentional (correction is free).
- **Fish source pool runs out of visible fish** — pool auto-refills from offscreen. The pool is conceptually infinite; the visible school just looks like ~8 fish at a time.
- **Ten pearl is dragged or tapped** — non-interactive in `ten-plus-n` mode (the kid can't accidentally undo a collapsed frame). In `make-ten`, the pearl appears as the round-pass reward and is non-interactive for its ~2-second display.
- **Pre-populated fish in `make-ten`** — non-draggable, non-removable. Visually distinguished by a soft pearl-white halo so the kid sees "these are already here."
- **Two-Ways mode and the kid produces the same split twice** — the second attempt is rejected with "Show me a different way to make {N}." The frame clears; kid tries again. After 2 failed second-attempts, the system demotes to `fill-to-target` for a few rounds.
- **Stylus disconnect mid-drag** — fish freezes mid-air; on reconnect, fish returns to source. Round state preserved.
- **App backgrounded mid-round** — pause and persist (including current frame state). Resume within 5 minutes; restart round after.
- **Audio muted** — count badge and equation form carry the full information; ten-pearl collapse is visually loud enough to register without sound.
- **Kid spams fish placement and removal** — Drag-and-Drop debouncing handles this; no fail state. Logged for telemetry; persistent spamming may indicate kid is exploring or stuck.

---

## Open Questions

- **Strategy variety bonus pacing** — How many distinct decompositions of the same target N earn the rare card? Suggest **3** (e.g., 7 = 4+3, 5+2, 6+1) at launch; tune in playtest.
- **Ten pearl collapse animation duration** — currently ~2 s. Long enough to feel rewarding; short enough not to interrupt flow. Confirm in playtest.
- **Two-Ways color rule** — different species at Concrete layer (visible decomposition) drops to same color at Abstract. Confirm species pairings and color contrast meet accessibility requirements (color-blind palette).
- **Fish source pool layout** — drifting school at bottom (current proposal). Alternative: a "fish well" anchor point (kid drags from one spot). Drifting school is more charming but harder to grab consistently with a stylus; tune in playtest.
- **Notebook prompt for advanced rounds** — should the kid be prompted to write `10 + 3 = 13` in the notebook for `ten-plus-n` mode? Defer to v1.1.
- **`two-ways` sub-mode requires 2 rounds per target** — should those count as 1 problem (one logical attempt) or 2 (two atomic rounds)? Affects coin payouts and milestone tracking. Suggest **2 atomic rounds** (kid did real work twice) at launch.

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical across phases.


```
TenFramePondView
├── PondBackgroundLayer (parallax water + ripples + dragonfly)
├── BuddyView (idle behaviors)
├── TenFrameView (generic 2×5 grid; reused for single, two-frame, three-frame layouts)
│    └── LilyPadCell (drop target; single-occupancy)
├── FishSourcePool (draggable source; drifting animation)
├── CountBadgeView (single-mode + equation-mode rendering)
├── TenPearlView (collapse animation overlay)
├── DoneButtonView (visible after first placement)
├── HUDView (coin count, exit)
└── NotebookTab (shared math-notebook component)
```

### Reusable opportunities surfaced by this spec

- **`TenFrameView`** is highly reusable: it appears in lessons, in the Hub trophy displays, and conceptually feeds Crystal Bundler (1st) and Place Value Vault (2nd). Should be a shared component.
- **"Collapse to single unit" animation** generalizes to all place-value bundling (10 ones → 1 ten, 10 tens → 1 hundred, etc.). Build it once in a shared place-value visualization library.
- **`FishSourcePool` drifting-school animation** could be reused in Storyteller's Pond (creatures drifting on the water).

### Performance considerations

- Up to 30 fish on screen in `three-frames` mode. Use sprite atlases.
- Particle effects (sparkles, ten-pearl shimmer) should pool.
- Pond background ripple shader runs continuously; budget appropriately for older iPads.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft | |
| 2026-05-30 | All three MicroLessons authored and linked (K.OA.3, K.OA.4, K.NBT.1). Activity is now lesson-complete and ready-to-build | |
| 2026-05-30 | Scaffolding-triggers table now defers to the staggered demotion rule in `adaptive-scaffolding.md` (CPA layer demotes first, then sub-mode) | |
