# Activity Spec — Where's Buddy?

> The K activity that introduces **positional language** (K.G.1) — above, below, beside, behind, in front of, next to. A hide-and-seek game with the Math Buddy. Vocabulary-first, not math-procedural — validates that the activity template handles non-numerical content cleanly.

References: `specs/shared/stylus-mechanics.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/reward-economy.md`, `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activity-spec-template.md`.

---

## Header

| Field | Value |
|---|---|
| Activity name | Where's Buddy? |
| Activity slug | `wheres-buddy` |
| Region | Sanctuary |
| Grade | K |
| Standards | K.G.1 |
| Status | Draft |
| Last updated | 2026-05-30 |

---

## Setting & Tone

- **Scene** — A whimsical Sanctuary clearing with **landmarks** arranged across the playfield: a hollow tree, a small stone well, a giant mushroom, a rock cluster, a tiny cottage. Background is soft grass with wildflowers. Landmarks have clear silhouettes and obvious "front/back/above/below" geography (the tree has a wide canopy you can be behind; the well has a low rim you can be next to; the mushroom is tall enough to be hidden under).
- **Atmosphere** — Late-afternoon Sanctuary light, golden hour. Music bed is the warm Sanctuary palette, slightly playful (this is a game, not a chore). Distant birdsong; occasional wind chime tinkle (associated with the cottage).
- **Buddy presence** — The Buddy is **central to this activity** (rather than a side observer). In `find-mode` the Buddy hides; in `place-mode` the kid moves the Buddy around. The Buddy is dragable and tappable (the mechanic targets it directly).
- **Narrator** — Sanctuary warm naturalist.

---

## Standards Coverage

| Standard | What the kid does | Telemetry event | Mastery threshold |
|---|---|---|---|
| **K.G.1** (describe relative positions using "above, below, beside, in front of, behind, next to") | In `find-mode`: hears a positional cue ("the Buddy is behind the tree") and taps the matching location. In `place-mode`: drags the Buddy to a stated position relative to a landmark. | `position.find_completed` (payload: `positionWord`, `referenceLandmark`, `correct`), `position.place_completed` (payload: `positionWord`, `referenceLandmark`, `dropZone`, `correct`) | 5/3/3 standard |

---

## Concepts: Introduced vs Exercised

| Concept | Role | Lesson | Notes |
|---|---|---|---|
| **K.G.1** (positional language) | Introduces | `specs/lessons/k-g-1-positional-language.md` | First lesson covers **three** clear positional words (`above`, `behind`, `next to`) with visual demonstrations. The remaining three (`below`, `in front of`, `beside`) are exercised through subsequent rounds at the Concrete layer (directional cue handles scaffolding). |

### Registry impact

- `K.G.1.introducedBy = wheres-buddy`

Note: per `k-activity-patterns.md`, positional language is also woven into **Hub navigation** ("hop behind the unicorn fountain to find your hat!") as ambient exposure. By the time the kid hits Where's Buddy?, they've likely heard the vocabulary in passing — Where's Buddy? formalizes the testing.

---

## Sub-Modes

### Sub-mode: `find-mode` (default)

- **Standards targeted** — K.G.1
- **What the kid does** — Buddy is hidden somewhere in the clearing. Narrator says: "The Buddy is *behind* the tree." (or another positional cue.) The kid taps the landmark indicated, or the area around it matching the positional word. On a successful tap, the Buddy reveals and waves.
- **Pass condition** — Kid taps within the **target zone** of the cued landmark+position pair. Each landmark has pre-defined zones for each applicable positional word (e.g., the tree has zones for `behind`, `in front of`, `beside`, `next to`).
- **Fail behavior** — Kid taps a non-target zone → soft "no" SFX, narrator gently repeats: "The Buddy is *behind* the tree. Try again." After 3 wrong taps, narrator demonstrates by glowing the correct zone and revealing the Buddy there.

### Sub-mode: `place-mode`

- **Standards targeted** — K.G.1
- **What the kid does** — Buddy starts at a fixed "starting position" (the lower-left, near where they normally sit). Narrator says: "Put the Buddy *above* the well." The kid drags the Buddy to a position matching the cue.
- **Pass condition** — Kid drops the Buddy within the **target zone** of the cued landmark+position pair.
- **Fail behavior** — Buddy snaps back to starting position. Narrator: "Put the Buddy *above* the well — that means higher than the well." After 3 wrong drops, narrator demonstrates: ghost-Buddy moves to the correct zone and Buddy auto-snaps there.

### Sub-mode: `relational-mode` *(challenge variant)*

- **Standards targeted** — K.G.1 extended to two-reference relational reasoning
- **What the kid does** — Narrator names two landmarks plus a positional word: "Put the Buddy *between* the tree and the well." The kid drags the Buddy to the spatial midpoint.
- **Pass condition** — Buddy is dropped in the target zone defined by both landmarks (typically the midpoint area, with tolerance).
- **Reward bump** — Challenge chest per `reward-economy.md`.

---

## Visual Layout

### `find-mode` and `place-mode` (same playfield)

```
+--------------------------------------------------------+
| [exit]                              [coins: 12]        |
|                                                        |
|   <late-afternoon Sanctuary clearing, soft grass>     |
|                                                        |
|     <tree>          <mushroom>           <cottage>    |
|       🌳              🍄                    🏡         |
|                                                        |
|              <well>            <rock cluster>         |
|               🪨                  🗿                   |
|                                                        |
|             [phase indicator if relevant]             |
|                                                        |
|  [Buddy starting position]              [notebook >]  |
|     <Buddy>                                            |
|                                                        |
|                  [ done? ]                             |
+--------------------------------------------------------+
```

- **Persistent scene anchors** — 5 landmarks scattered with clear geography. Buddy starts in lower-left for `place-mode`; hides somewhere for `find-mode`.
- **Interactive elements**:
  - In `find-mode`: landmarks are **tap targets** (kid taps the zone matching the narrator's cue). Buddy is hidden — not visible until found.
  - In `place-mode`: Buddy is **draggable**. Landmarks are not tappable but serve as visual reference.
- **No count badge** — this activity isn't about quantity. A small "found: N of M" or "placed: N of M" indicator may appear for multi-round sessions.
- **Math notebook tab** — collapsed by default. Rarely used in this activity (no notation to write).

---

## State Machine

```
[idle/intro] → narrator opens with the round's positional cue
   ↓
[setup] → landmarks visible; Buddy hides (find-mode) or starts at home (place-mode)
   ↓
[active] → kid taps (find-mode) or drags (place-mode)
   ↓
[evaluating] → check tap zone / drop position against target
   ↓
[round_passed]                       [round_failed]
   ↓                                    ↓
[reward + Buddy reveal/celebrate]    [warm narrator + demonstration]
   ↓                                    ↓
[next round queued]                  [retry at current layer]
                                        ↓
                                    [if 2 consecutive fails: demote per staggered rule]
```

**Exit conditions** — standard per K patterns.

---

## Stylus Interactions

| Mechanic | Where used | Local overrides |
|---|---|---|
| **Tap-Pick** (selection semantic) | `find-mode` — kid taps the landmark zone matching the cue | Tap on a non-target zone: no marking, soft "no" SFX. Per the canonical Tap-Pick selection-semantic behavior in `stylus-mechanics.md`. |
| **Drag-and-Drop** (snap-to-target with **zone-based snap**) | `place-mode` and `relational-mode` — kid drags Buddy to a target zone | Snap is **zone-based**, not point-based: the Buddy snaps to a position within the target zone if dropped anywhere inside it. Wrong-zone drop → Buddy returns to start. |

No Free-Write, no Cut-along-guides.

---

## Number-Writing Modes

**Not used.** Where's Buddy? doesn't involve numerals at all. The activity is entirely about spatial vocabulary.

---

## Audio Cues

> **Runtime source**: narration cues live in [`content/strings/en-US/activities/wheres-buddy.json`](../../../content/strings/en-US/activities/wheres-buddy.json). The prose below is the design-time reference; the JSON is the authoritative source the TTS pipeline and runtime consume.

### Narrator lines (Sanctuary warm naturalist)

#### `find-mode`
- **Round start**: "The Buddy is *{position_word}* the {landmark}." (e.g., "The Buddy is *behind* the tree.")
- **Mid-progress hesitation (5 s)**: (visual hint via landmark glow)
- **Mid-progress hesitation (10 s)**: "Look {position_word} the {landmark}." (repeats the cue with slight emphasis)
- **Round pass**: "Yes! The Buddy was {position_word} the {landmark}."
- **Round fail (wrong tap)**: "Almost. The Buddy is {position_word} the {landmark} — try again."
- **Round fail (3rd attempt missed)**: "Watch — the Buddy is right here." *(demonstrate)*

#### `place-mode`
- **Round start**: "Put the Buddy *{position_word}* the {landmark}."
- **Mid-progress hesitation (5 s)**: (visual hint via landmark glow)
- **Mid-progress hesitation (10 s)**: "Drag the Buddy {position_word} the {landmark}."
- **Round pass**: "Perfect — the Buddy is {position_word} the {landmark}."
- **Round fail (wrong drop)**: "The Buddy is {actual_position}. We needed {target_position} the {landmark}. Try again."
- **Round fail (3rd attempt missed)**: "Watch — like this." *(demonstrate)*

#### `relational-mode` (challenge)
- **Round start**: "Put the Buddy *{position_word}* the {landmark1} and the {landmark2}." (e.g., "Put the Buddy *between* the tree and the well.")
- **Round pass**: "Yes — the Buddy is {position_word} the {landmark1} and the {landmark2}."

### SFX

| Event | SFX |
|---|---|
| Tap on a landmark zone (target) | Soft "yes" chime + sparkle |
| Tap on a non-target zone | Soft "no" puff |
| Drag start (place-mode) | Light "pick up" cue |
| Drag drop on correct zone | Warm "settle" chime |
| Drag drop on wrong zone | Soft "no" puff; Buddy slides back to start |
| Buddy reveal (find-mode round-pass) | Brief sparkle + Buddy's signature "tada" sound |
| Round pass | Sanctuary chime stinger |
| Round fail | Soft sad-but-warm chord |

### Music

- Sanctuary late-afternoon bed: gentle strings + harp + occasional wind chime, ~80 BPM, 80-second loop.
- Slight intensity shift on round-pass (Buddy reveal moment).
- No intensity push during the round itself — this is a thinking/searching activity, not a rushed one.

---

## Scaffolding Triggers

Uses `ScaffoldQuery` per round, including `firstEncounterLesson` for K.G.1 routing.

| Trigger | Response |
|---|---|
| **5 s of no input** | Highlight the cued landmark with a soft glow for 1.5 s. |
| **10 s of no input** | Narrator gently repeats the cue. |
| **Kid taps / drops in a wrong zone** | Soft "no" SFX; round doesn't immediately fail. Narrator hint after 2nd wrong attempt. |
| **3 wrong attempts in a single round** | Round fails; warm demonstration animates the correct answer (Buddy revealed or auto-placed). |
| **2 consecutive round failures** | Apply the **staggered demotion** rule from `adaptive-scaffolding.md`: demote CPA layer first. If already at Concrete, demote sub-mode (`relational-mode` → `place-mode` → `find-mode`) and CPA resets to Concrete. |

---

## CPA Progression

Where's Buddy?'s CPA isn't about representation form (no numerals here); it's about **how much spatial scaffolding the kid gets**.

| Layer | What it looks like |
|---|---|
| **Concrete** | When the narrator says a positional word, a **visual arrow or directional cue** briefly appears showing what "behind" / "above" / etc. means relative to the cued landmark, *before* the kid acts. (e.g., a soft arrow points to the area behind the tree as the narrator says "behind.") |
| **Pictorial** | The cued landmark **highlights with a soft halo** when the position word is said. No directional arrow. Kid uses the landmark cue to figure out where. |
| **Abstract** | Only the audio cue. Landmark not pre-highlighted. Kid relies on memory of vocabulary + scene geography. |

- **Default starting layer (K, fresh kid)** — Concrete.
- **Promotion conditions** — 3 consecutive passes at the current layer.
- **Demotion conditions** — 2 consecutive failures at the current layer (per staggered rule).

---

## Reward Emissions

| Event | Trigger | Reward (per `reward-economy.md`) |
|---|---|---|
| `round.passed` | Round passes | +2 coins |
| `round.notebook_bonus` | (rarely earned in this activity; notebook not naturally used) | +1 coin if applicable |
| `streak.session_3` / `_5` / `_10` | Standard | Per shared spec |
| `milestone.problems_25` / `_100` | Lifetime in this activity | Per shared spec |
| `mastery.standard_practicing` / `_mastered` | Adaptive scaffolding emits | Per shared spec |
| `challenge.completed` | `relational-mode` round passes | Challenge chest (rare hideout-themed item guaranteed) |

### Activity-specific collectibles
- **Hide-and-Seek Hats** — small Buddy-wearable hats earned through play (e.g., a leaf cap, a tiny chef's hat, a bow). Drops at ~1 in 4 round-pass events.
- **Hideout Decorations** — small decorative items for the Hub: a tiny mushroom, a pebble pile, a wind chime. Drops at ~1 in 6 round-pass events.
- Complete the hat set (8 hats at launch) for a Hub trophy: the **Hide-and-Seek Wardrobe**.

---

## Telemetry Events

(Beyond shared `scaffold.*`, `economy.*`, `lesson.*` events.)

| Event | Payload |
|---|---|
| `position.round_started` | `subMode`, `positionWord`, `referenceLandmark(s)`, `presentationLayer` |
| `position.tap_logged` | `tappedZone`, `landmark`, `correct`, `latencyMs` |
| `position.drag_logged` | `dropZone`, `landmark`, `correct`, `latencyMs` |
| `position.round_completed` | `success`, `subMode`, `attemptsThisRound`, `hintsFired` |
| `position.collectible_dropped` | `itemId`, `setProgress`, `itemType` (hat or decoration) |

---

## Challenge Variant

**Relational Hunt** — `relational-mode` (two-landmark positional reasoning).

- **What changes** — Positional cue references two landmarks ("between," "near both," etc.). Kid drags Buddy to the spatial relationship spanning both.
- **Entry point** — "Relational Hunt!" banner appears on Where's Buddy?'s tile in the Sanctuary 1× per day at launch (tunes post-launch).
- **Reward bump** — Challenge chest on completion (rare hideout decoration guaranteed).

---

## Edge Cases & Error Handling

- **Multiple valid positions for a position word** — "beside the rock" has two valid sides (left and right). Both count. The system accepts either.
- **Overlapping target zones** — "beside the tree" and "next to the tree" have very similar zones. The activity uses one or the other in a given round (not both), and the system tracks which was cued.
- **Kid taps Buddy in `find-mode` before the round starts** — Buddy is hidden, not visible; no tap registers.
- **Kid drags Buddy outside any landmark zone in `place-mode`** — Buddy snaps back to starting position. Soft "no" puff.
- **Landmark obscured by Buddy mid-drag** — Buddy is rendered semi-transparent while being dragged to keep the underlying scene visible.
- **Scene geography ambiguity** — confirm during art direction that each landmark has clearly identifiable "above / below / behind / in front of / beside / next to" zones. Some landmarks (mushroom: hard to be "behind") may not support all six words; the activity per-round picks a landmark+word combo that makes sense.
- **Audio muted** — visual cues (landmark glow, directional arrow at Concrete layer) carry the position cue. Without audio, the kid sees the position-word as on-screen text (kid-friendly font, large).
- **Color-blind accessibility** — landmarks differ in shape and size, not just color. Position-zone overlays use pattern (dashed border) rather than color alone.

---

## Open Questions

- **Landmark count and selection** — 5 proposed (tree, well, mushroom, rock, cottage). Confirm with art that all 5 can support multiple positional words clearly. Some words (e.g., "behind" only works if the landmark has visible front/back).
- **Position-zone tolerance** — generous enough that small kids can succeed without precise drops, tight enough that "between" and "next to" are meaningfully different. Playtest to tune.
- **Number of position words covered** — six standard ones (above, below, beside, behind, in front of, next to). Should we also cover "inside" or "on top of"? Probably out of scope for the canonical K.G.1 lesson; possible later round expansion.
- **`find-mode` vs `place-mode` lesson coverage** — the K.G.1 lesson likely covers both modes by demonstration. Confirm in the lesson design whether the I-Show should show both modes or just one (and rely on the kid encountering the other naturally).
- **Buddy's "tada" reveal in `find-mode`** — should this be a consistent sound or vary by what hat the Buddy is wearing? Suggest consistent at launch; vary later.

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical across phases.


```
WheresBuddyView
├── ClearingBackgroundLayer (parallax grass + wildflowers + soft sky)
├── LandmarksLayer (5 landmark sprites at fixed positions, each with declared position-zones)
├── BuddyView (draggable in place-mode, hidden in find-mode until revealed)
├── DirectionalCueLayer (Concrete layer only: arrow / directional cue overlay)
├── PositionZoneOverlay (debug / authoring only — hidden in production but useful in development)
├── DoneButtonView (rarely needed — tap or drop resolves the round)
├── HUDView
└── NotebookTab (collapsed)
```

### Reusable opportunities surfaced by this spec

- **Position-zone system** — a generic spatial-zone definition per landmark could generalize to any activity needing "above / below / behind" reasoning. Useful for 1st-grade Wundletown if any wizard mishap activities need spatial logic.
- **Buddy as central interactive element** — first activity where Buddy is the *primary* interaction target. Other activities have Buddy as a side observer. The Buddy's draggable/hidable behaviors here may generalize for future Buddy-centric activities (e.g., a Buddy customization mini-game).
- **Vocabulary-first activity template** — Where's Buddy? validates that the activity spec template handles non-numerical content. The same pattern could support a future "color names" or "size words" activity if needed.

### Performance considerations

- 5 landmark sprites + 1 Buddy sprite + a few decorative elements. Very low overhead.
- Position-zone definitions are static per landmark; precompute at load time, not per-tap.
- Directional cue overlay (Concrete layer) — animated arrow can be a simple sprite tween.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first K activity with **vocabulary-first** content (no numerals, no shape sorting). Buddy is the central interactive element | |
| 2026-05-30 | K.G.1 MicroLesson authored and linked. Activity is now lesson-complete and ready-to-build (with the caveat that the lesson covers 3 of 6 position words; the others are exercised through play) | |
