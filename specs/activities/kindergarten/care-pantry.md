# Activity Spec — Care Pantry

> The K activity that introduces **classifying objects into categories, counting each category, and sorting the categories by count** (K.MD.3). Two-phase round structure: Phase 1 categorize → Phase 2 sort-by-count. Sets up the kid for early data work that becomes more formal in 1st-grade Wundle Census and 2nd-grade Crime Lab.

References: `specs/shared/stylus-mechanics.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/reward-economy.md`, `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activity-spec-template.md`.

---

## Header

| Field | Value |
|---|---|
| Activity name | Care Pantry |
| Activity slug | `care-pantry` |
| Region | Sanctuary |
| Grade | K |
| Standards | K.MD.3 |
| Status | Draft |
| Last updated | 2026-05-30 |

---

## Setting & Tone

- **Scene** — The Sanctuary's **supply hut**, a small wooden barn-style room with a long workbench. Cubbies and shelves line the walls; the workbench in the middle holds the **mess** that needs sorting — creature treats, beds, toys, and grooming tools jumbled into a heap. The Caretaker (an off-screen helper character; voice-only) has stepped out and asks the kid to tidy up while they're gone.
- **Atmosphere** — Bright midday light through wooden slats. Music bed is the Sanctuary palette with a soft "industrious" texture (light brushwork, gentle organizing). Palette anchors: warm wood, hay-gold, cubby-shadow brown.
- **Buddy presence** — Per `k-activity-patterns.md`: Buddy at lower-left on a small basket, watching the work. Reacts to bin completions with attentive head-tilts. Hops on round-pass.
- **Narrator** — Sanctuary warm naturalist.

---

## Standards Coverage

| Standard | What the kid does | Telemetry event | Mastery threshold |
|---|---|---|---|
| **K.MD.3** (classify, count, sort by count) | Phase 1: drags items from the mess into category bins. Phase 2: drags bins into ordinal positions (least → most) to sort the categories by count. | `pantry.categorization_completed` (payload: `categories`, `itemsPerCategory`), `pantry.sort_by_count_completed` (payload: `orderingCorrect`) | 5/3/3 standard |

---

## Concepts: Introduced vs Exercised

| Concept | Role | Lesson | Granularity | Notes |
|---|---|---|---|---|
| **K.MD.3** (classify and sort) | Introduces | `specs/lessons/k-md-3-classify-and-sort.md` | concept-wide | Lesson covers a `simple-pantry` round (3 categories) demonstrating both phases. |

### Registry impact

- `K.MD.3.introducedBy = care-pantry`

---

## Two Phases (universal to every round)

Like Build-a-Habitat, Care Pantry uses the two-phase round structure. Every round runs Phase 1 then Phase 2 in sequence.

### Phase 1 — Categorize (K.MD.3, classification part)

- **Goal**: drag every item from the central mess into its correct category bin.
- **Source**: a pile of mixed items on the workbench center.
- **Target**: 2–4 category bins along the bottom of the workbench, each labeled with an icon (treat-icon, bed-icon, toy-icon, grooming-icon).
- **Procedure**: kid drags items one at a time. Each item snaps to its correct bin (wrong-bin drops return). Counts visible on each bin.
- **Auto-fire**: transitions to Phase 2 after **3 s of stillness** once all items are in correct bins (per `k-activity-patterns.md`).

### Phase 2 — Sort by Count (K.MD.3, counting + sorting part)

- **Goal**: drag the bins themselves into ordinal positions — least, middle(s), most.
- **Target**: 2–4 **ordinal podium slots** along the bottom of the screen labeled "least" → "most" (or with numeric position 1, 2, 3, 4).
- **Procedure**: kid drags each bin (now full from Phase 1) to its rank position based on its item count.
- **Auto-fire**: round completes when all bins are in correct ordinal positions.

---

## Sub-Modes

### Sub-mode: `simple-pantry` (default)

- **What the kid does** — Phase 1: 2–3 categories with ≤5 items each. Phase 2: sort the 2–3 bins by count.
- **Pass condition** — Both phases complete correctly.

### Sub-mode: `full-pantry`

- **What the kid does** — Phase 1: 4 categories with up to 10 items each (per K.MD.3's `category counts ≤ 10` cap). Phase 2: sort the 4 bins by count.
- **Pass condition** — Both phases complete.

### Sub-mode: `unfamiliar-rules` *(challenge variant)*

- **What the kid does** — Phase 1: items must be sorted by an **unfamiliar criterion** — by color (red items / blue items / yellow items), by size (small / medium / large), or by texture (smooth / soft / spiky). Phase 2: sort bins by count as usual.
- **Reward bump** — Challenge chest per `reward-economy.md`.

### Sub-mode: `categorize-only` *(demotion floor)*

- **What the kid does** — Phase 1 only, with 2 categories. Round ends after Phase 1 (no sort-by-count).
- **Purpose** — Demotion target when the kid struggles with the full two-phase sequence at Concrete already.

---

## Visual Layout

### Phase 1 layout

```
+--------------------------------------------------------+
| [exit]                              [coins: 12]        |
|                                                        |
|   <supply hut interior — wood, cubbies, hay>          |
|                                                        |
|        🦴  🛏️  🧸  🪥  🦴  🛏️  🧸                      |
|        <mess of mixed items at center>                |
|                                                        |
|                                                        |
|   +--------+ +--------+ +--------+ +--------+          |
|   | treats | |  beds  | |  toys  | |grooming|         |
|   | 🦴 [3] | | 🛏️ [0] | | 🧸 [0] | |  🪥 [0]|          |
|   +--------+ +--------+ +--------+ +--------+          |
|                                                        |
|             [phase 1: tidy the supplies]              |
|                                                        |
|  [Buddy on basket]                     [notebook >]   |
|                                                        |
+--------------------------------------------------------+
```

### Phase 2 layout (bins now full)

```
+--------------------------------------------------------+
|   <supply hut interior; the mess is gone>             |
|                                                        |
|   +--------+ +--------+ +--------+ +--------+          |
|   | treats | |  beds  | |  toys  | |grooming|         |
|   | 🦴 [5] | | 🛏️ [2] | | 🧸 [7] | |  🪥 [3]|          |
|   +--------+ +--------+ +--------+ +--------+          |
|         (now draggable to podium positions)           |
|                                                        |
|                                                        |
|   +--------+ +--------+ +--------+ +--------+          |
|   |  least | |   2    | |   3    | |  most  |         |
|   +--------+ +--------+ +--------+ +--------+          |
|                                                        |
|             [phase 2: sort by count]                  |
|                                                        |
+--------------------------------------------------------+
```

- **Persistent scene anchors** — supply hut background, Buddy lower-left, HUD per K convention.
- **Interactive elements (Phase 1)** — items (draggable) and bins (drop targets, single-occupancy per drop).
- **Interactive elements (Phase 2)** — bins (now draggable) and podium slots (drop targets).
- **Count badges** — appear inside each bin in Phase 1, update as items are dropped. Stay visible in Phase 2 to support the sort.

---

## State Machine

```
[idle/intro] → narrator opens with the round's goal
   ↓
[phase1_setup] → mess of items appears at center; empty bins at bottom
   ↓
[phase1_active] → kid drags items into bins; counts update
   ↓ (all items correctly placed + 3 s stillness)
[phase1_complete] → mess gone; bins now full; transition cue
   ↓ (1 s)
[phase2_setup] → podium slots appear; bins highlight as draggable
   ↓
[phase2_active] → kid drags bins to ordinal positions
   ↓ (all bins correctly positioned + 3 s stillness)
[phase2_complete] → round-pass celebration
   ↓
[reward + Caretaker thanks]
   ↓
[next round queued]
```

**Failure branches**:
- Phase 1 timeout / Done with mis-categorized items → warm narrator + auto-complete demonstration (system shows the correct categorization with pointer animation) → transition to Phase 2 normally. Kid still gets K.MD.3 sort practice.
- Phase 2 timeout / Done with mis-sorted bins → warm narrator + auto-complete demonstration → round still ends with the sort displayed correctly (kid gets the visual reward).

**Exit conditions** — standard per K patterns. Manual exit mid-round saves Phase 1 progress; resume within 5 minutes.

---

## Stylus Interactions

| Mechanic | Where used | Local overrides |
|---|---|---|
| **Drag-and-Drop (snap-to-target)** | Both phases. Phase 1: items → category bins. Phase 2: bins → podium slots. | Snap radius 30 pt (slightly wider; items and bins are kid-targeted, more forgiving). Wrong-target drops return the item/bin to source. |

No other mechanics. The notebook is rarely used in Care Pantry.

---

## Number-Writing Modes

**Not used.** Care Pantry doesn't ask the kid to write numerals. Counts are auto-displayed on bins.

---

## Audio Cues

> **Runtime source**: narration cues live in [`content/strings/en-US/activities/care-pantry.json`](../../../content/strings/en-US/activities/care-pantry.json). The prose below is the design-time reference; the JSON is the authoritative source the TTS pipeline and runtime consume.

### Narrator lines (Sanctuary warm naturalist)

#### Round opening
- **Round start (simple-pantry)**: "Look at this mess. Let's tidy the supply hut. Sort the things into baskets, then put the baskets in order from least to most."
- **Round start (full-pantry)**: "Quite a mess today. Four kinds of supplies — sort them all."
- **Round start (unfamiliar-rules)**: "Today we sort by {color/size/texture} instead of what they are. Look at the basket labels."

#### Phase 1
- **Mid-progress hesitation (5 s)**: (visual hint via category-bin glow)
- **Mid-progress hesitation (10 s)**: "Drag the {item} to the {category} basket."
- **Phase 1 complete**: "All sorted. Now let's see which basket has the most."

#### Phase 2
- **Mid-progress hesitation (5 s)**: (visual hint via least/most podium glow)
- **Mid-progress hesitation (10 s)**: "Count the baskets — which has the fewest? Drag it to 'least'."
- **Phase 2 complete**: "Tidy and sorted! The Caretaker will be happy."

#### Round-pass
- **After all phases**: "{biggest_count} {biggest_category}, {next_count} {next_category}, {least_count} {least_category}. Nicely done."

#### Round-fail (per phase)
- **Phase 1 fail**: "A few in the wrong baskets. Let me show you." *(demo)*
- **Phase 2 fail**: "Let's look at the numbers — the basket with **{least_count}** goes in 'least'." *(demo)*

### SFX

| Event | SFX |
|---|---|
| Item drag | Light "pickup" |
| Item snap into bin | "Plop" + soft chime |
| Item drop on wrong bin | Soft "nope" puff; item returns |
| Bin drag (Phase 2) | Heavier "lift" cue |
| Bin snap to podium | "Settle" chime |
| Phase 1 complete | Brief "ahhh, tidy" stinger |
| Phase 2 complete | Sanctuary chime stinger |
| Round-pass (Caretaker thanks) | Warm "thank you" voice cue (brief, abstract) |

### Music

- Sanctuary midday bed with the "industrious" texture: gentle strings + soft tambourine + brush percussion, ~95 BPM.
- Slight intensity bump on Phase 1 → Phase 2 transition.
- Round-pass stinger over the bed.

---

## Scaffolding Triggers

Uses `ScaffoldQuery` per round, including `firstEncounterLesson` for K.MD.3 routing.

| Trigger | Response |
|---|---|
| **5 s of no input in Phase 1** | A random un-sorted item highlights with a soft halo; if same-category sorting has been happening, that category's bin also halos briefly. |
| **5 s of no input in Phase 2** | The lowest-count bin and the "least" podium both halo briefly. |
| **10 s of no input** | Narrator gives a phase-specific prompt (see Audio Cues). |
| **Kid drops item on wrong category bin** | Item returns to source with soft "nope" puff. No round-level penalty. |
| **Kid drops bin on wrong podium position** | Bin returns to source row with soft "nope" puff. |
| **Kid taps Done with errors at end of phase** | Phase fails; warm demonstration. |
| **2 consecutive round failures** | Apply the **staggered demotion** rule from `adaptive-scaffolding.md`: demote CPA layer first. If already at Concrete, demote sub-mode (`unfamiliar-rules` → `full-pantry` → `simple-pantry` → `categorize-only`). |

---

## CPA Progression

Care Pantry's CPA is about **how much category-and-sort scaffolding the kid gets**.

| Layer | What it looks like |
|---|---|
| **Concrete** | Bins are labeled with both an **icon and a text label** (e.g., "🦴 treats"). Count badges show **numeral + dot pattern** matching the count. Podium slots are labeled "least" / "most" with directional arrow icons. |
| **Pictorial** | Bins labeled with icon only (no text). Count badges show numeral only. Podium slots use ordinal numbers (1, 2, 3) instead of "least"/"most". |
| **Abstract** | Bins labeled with category color only (no icon). Count badges still show numerals. Podium slots show only the numerical ordinal (1=least, N=most, kid infers direction). |

- **Default starting layer (K, fresh kid)** — Concrete.
- **Promotion conditions** — 3 consecutive passes at the current layer.
- **Demotion conditions** — 2 consecutive failures at the current layer (staggered rule applies).

---

## Reward Emissions

| Event | Trigger | Reward (per `reward-economy.md`) |
|---|---|---|
| `round.passed` | Round passes | +2 coins |
| `round.notebook_bonus` | Notebook had ≥3 strokes (rare in this activity) | +1 coin |
| `streak.session_3` / `_5` / `_10` | Standard | Per shared spec |
| `milestone.problems_25` / `_100` | Lifetime in this activity | Per shared spec |
| `mastery.standard_practicing` / `_mastered` | Adaptive scaffolding emits | Per shared spec |
| `challenge.completed` | `unfamiliar-rules` round passes | Challenge chest (rare Sanctuary supply collectible guaranteed) |

### Activity-specific collectibles
- **Sanctuary Supply Items** — small decorative supplies earned by tidying the pantry. ~12 items at launch (a fancy treat jar, a knit blanket, a wooden toy, etc.). Drops at ~1 in 4 round-pass events.
- **Pantry decor for the Hub** — completed pantry runs unlock decorative cubbies and shelves the kid can place in their Hub home.
- Complete the supply set for a Hub trophy: the **Caretaker's Apprentice Badge**.

---

## Telemetry Events

(Beyond shared `scaffold.*`, `economy.*`, `lesson.*` events.)

| Event | Payload |
|---|---|
| `pantry.round_started` | `subMode`, `categoryCount`, `presentationLayer` |
| `pantry.phase1_started` | `itemCount`, `categories` |
| `pantry.item_dropped` | `itemKind`, `targetBin`, `correct: Bool`, `latencyMs` |
| `pantry.categorization_completed` | `categories`, `itemsPerCategory`, `attempts` |
| `pantry.phase2_started` | `binsToSort` |
| `pantry.bin_dropped_on_podium` | `binCategory`, `podiumPosition`, `correct: Bool`, `latencyMs` |
| `pantry.sort_by_count_completed` | `finalOrdering`, `attempts` |
| `pantry.round_completed` | `success`, `subMode`, `attemptsThisRound`, `hintsFired` |
| `pantry.collectible_dropped` | `itemId`, `setProgress` |

---

## Challenge Variant

**Unfamiliar Rules** — `unfamiliar-rules` sub-mode (categorize by color/size/texture instead of by function).

- **Entry point** — "Tricky Tidy!" banner appears on Care Pantry's tile in the Sanctuary 1× per day at launch (tunes post-launch).
- **Reward bump** — Challenge chest (rare Sanctuary supply collectible guaranteed).

---

## Edge Cases & Error Handling

- **Items that fit multiple categories** in challenge mode — at the unfamiliar-rules sub-mode, items are pre-tagged with the specific attribute for the round's rule (e.g., "red toy" for a sort-by-color round means it goes in the red bin regardless of being a toy). The same toy item has different correct bins in different rounds. Confirm in implementation that the item-to-bin mapping is round-specific.
- **Two bins with equal counts** in Phase 2 — possible (e.g., treats: 3, beds: 3, toys: 5). The sort accepts either order for the tied bins. Confirm acceptance logic.
- **Phase 1 has only 2 categories** — Phase 2's podium has only 2 positions (least / most). Skip the middle slots.
- **Kid drags an item onto an already-occupied bin** — item snaps in (bins hold multiple items, not single-occupancy unlike Build-a-Habitat's snap targets).
- **Kid drags an item back out of a bin** — supported: tap-to-remove item from bin (item returns to source). Useful for corrections.
- **Phase 2 starts before Phase 1 fully complete** — no, Phase 2 doesn't activate until Phase 1 auto-completes or the kid taps Done. Locked sequence.
- **Stylus disconnect mid-drag** — current drag cancels; item/bin returns to source.
- **App backgrounded** — pause and persist Phase + placements. Resume within 5 min restores; beyond that, restart current phase.

---

## Decisions Needed

*(None at launch — activity is structurally clear.)*

---

## Notes for Later

- **Item-to-category mapping pre-launch** — author the full item list (~30 items at launch) with their category memberships. The challenge `unfamiliar-rules` mode requires multi-attribute tags per item.
- **Tied-count handling at sort phase** — UX detail; playtest will inform whether to allow either ordering or require kid to choose deliberately.
- **Phase 1 → Phase 2 transition pacing** — 1 s wait + visual cue. Confirm in playtest this doesn't feel abrupt or rushed.
- **Caretaker's character** — voice-only at launch. Could embody in v1.1 if Storyteller's Pond's visible-narrator pattern proves popular.

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical across phases.


```
CarePantryView
├── PantryBackgroundLayer (parallax wood + hay + cubby shadows)
├── BuddyView (on basket; idle behaviors)
├── ItemMessView (Phase 1: the central jumble of items)
│    └── DraggableItem (per item; each tagged with category memberships)
├── CategoryBinsView (Phase 1: 2-4 drop targets)
├── PhaseTransitionLayer (animates between Phase 1 and Phase 2)
├── PodiumSlotsView (Phase 2: ordinal drop targets)
├── BinSorterView (Phase 2: bins become draggable)
├── PhaseIndicatorView (bottom-of-screen text)
├── DoneButtonView
├── HUDView
└── NotebookTab (collapsed; rarely used)
```

### Reusable opportunities

- **MultiPhaseRound coordinator** — already needed by Build-a-Habitat; Care Pantry is the second user. Should be a shared component.
- **DropTargetBin** — generalizes to Wundletown Census (1st), Mathopolis Buddy System (2nd) — anywhere bins receive items.
- **OrdinalPodium** — first activity to use ordinal positions. May reuse in 2nd-grade Crime Lab if data sorts surface there.
- **Auto-counter on a bin** — the bin's count badge that updates as items are dropped. Reusable for any sorting/counting activity.

### Performance

- Up to ~30 items + 4 bins on screen in `full-pantry`. Sprite atlases recommended.
- Phase 2's bin re-positioning involves moving a few large sprites (bins). Cheap.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — second K activity to use the two-phase round structure (after Build-a-Habitat); introduces the **ordinal podium** sorting pattern | |
