# Stylus Mechanic Library

> The shared vocabulary of stylus interactions every activity uses. Activity specs reference mechanics by name and may override tolerances; otherwise defaults defined here apply.

**Platform contract:** Apple Pencil on iPad. Touch input (finger) is also supported but with relaxed tolerances; see *Touch vs Pencil* below.

Stylus input flows through the **`StylusInputProvider`** interface defined in `platform-architecture.md`. Activity code never touches platform APIs directly — it consumes `StylusPoint` events from the provider.

| Phase | Implementation |
|---|---|
| Phase 1 (Flutter) | Flutter `Listener` widget capturing `PointerEvent`. Pressure + tilt available on iOS. No native stroke prediction or palm rejection. |
| Phase 2 (native iPadOS, post-Mac) | `PKCanvasView` + `PKStrokePoint` from PencilKit. Full stroke prediction, palm rejection, sub-frame latency. |

---

## Global Behaviors

These apply to all mechanics unless overridden.

- **Latency budget** — stroke onset to first visible feedback: **≤16 ms** (one frame at 60 Hz). Phase 1 (Flutter): ≤25 ms typical, ≤40 ms worst case on older iPads. Phase 2 (PencilKit): ≤8 ms on supported iPads. Tolerated regression in Phase 1; tracked via `stylus.stroke_latency_ms` telemetry.
- **Palm rejection** — Phase 2 (PencilKit) handles natively. Phase 1 (Flutter) uses a heuristic fallback: discard touches with contact-area > 60 px² when a Pencil signal is also present. When a Pencil is detected, **ignore concurrent finger input** for 250 ms after Pencil up.
- **Touch vs Pencil** — Pencil is primary; finger input is allowed but uses **+25% tolerance bands** for all geometric checks (kids may not always have a stylus).
- **Visual feedback parity** — every mechanic gives feedback at three moments: **stroke start**, **during stroke**, and **stroke end (success or failure)**. None is silent.
- **No frustration spiral** — if the same mechanic fails 2× consecutively in an activity, the activity's scaffolding layer drops one CPA step *automatically*. See `adaptive-scaffolding.md`.
- **Undo** — a one-tap undo of the last stroke is always available within an activity. No multi-step undo at launch.
- **Accessibility** — every stylus mechanic has a tap-fallback equivalent. Motor-accessibility kids can complete every activity with simple taps. See `accessibility-fallbacks.md` (TBD).

---

## Mechanic: Tap-Pick

> Renamed from Tap-Count on 2026-05-30. The original "Tap-Count" name implied counting semantics; the mechanic actually supports both counting and selection. See changelog.

### Purpose
Tap discrete objects in a scene to **mark them**. Used for two semantic purposes:
- **Counting** — the goal is to tap all of N target objects, producing a count (e.g., Counting Parade).
- **Selection** — the goal is to tap a subset matching a criterion (e.g., Shape Garden's `find-shape`).

The mechanic itself is identical; activities declare the semantic in their spec and configure the badge/feedback accordingly.

### Visual affordances
- Objects are visibly tappable (subtle glow, scale animation on hover for Pencil).
- A small badge appears in the corner once the first tap lands. Activities choose the badge label:
  - Counting activities: `count: N`
  - Selection activities: `found: N of M`

### Input contract
- Single tap on or within **tolerance radius** of an object's bounding region.
- A tap that misses all objects has no effect (no penalty, no mark change).
- A tap on a **non-target** object (selection semantics — e.g., tapping a square when looking for triangles): no marking occurs; activities may opt into a soft "no" SFX. Logged as a false-positive in telemetry but not penalized.
- Each object can be tapped (marked) at most once per round.

### Tolerances & timings (starting values; playtest)
- Tap tolerance radius: **+12 pt** beyond object bounding box (Pencil); **+18 pt** (touch).
- Debounce same-object: **200 ms** (prevents double-tap marking same item).
- Hesitation threshold (triggers next-item hint if scaffolding wants it): **5 s** of no taps.

### Visual feedback
- On tap (target): object gets a sparkle, scales 1.0 → 1.15 → 1.0 over 200 ms, badge increments.
- On tap (non-target, selection mode): brief no-op shimmer; activity may add a soft "no" SFX.
- Marked object remains visually distinguished (slight tint) for the remainder of the round.

### Failure modes
- N/A at the mechanic level — wrongness only emerges at round-end if the marked set doesn't match the activity's expectation.

### Suggested component (Flutter widget Phase 1 / SwiftUI view Phase 2)
`TapPickableScene(items: [PickableItem], onItemTapped: (Item) -> Void)`

---

## Mechanic: Drag-and-Drop

### Purpose
Move an object from a source to a target zone. Heavily used in ten-frames, place value bundling, sorting bins, array building.

### Visual affordances
- Draggable items have a faint shadow and respond to Pencil hover with a slight lift.
- Valid drop targets glow when the dragged item is within the snap radius.
- Invalid drop targets are dim (no glow).

### Input contract
- Press, drag, release. Standard.
- If released within **snap radius** of a valid target, the item snaps into place.
- If released outside any valid target, the item returns to its source (or stays in mid-air for *Free-place* variants — see below).

### Variants
- **Snap-to-grid** — items snap to discrete cells (ten-frames, arrays, place value mat).
- **Snap-to-target** — items snap to specific named target zones (sorting bins).
- **Free-place** — items can rest anywhere; no snap (used in Build-a-Habitat free-form mode).

### Tolerances & timings
- Snap radius: **24 pt** from the cell/target center.
- Return-to-source animation: **250 ms** ease-out.
- Snap animation: **120 ms** ease-out.
- Max drag distance for an "intentional" drag: anything ≥ 8 pt counts; below is treated as a tap.

### Visual feedback
- On grab: item lifts (scale 1.05, shadow expands).
- During drag: target zone preview ghost in destination.
- On snap: brief pulse + soft "click" SFX.
- On return: a small "nope" wiggle.

### Failure modes
- Drop on invalid zone → return to source, no penalty, no error noise.
- Multiple items dragged to the same single-occupancy target → second item bumps the first back to its source.

### Suggested component (Flutter widget Phase 1 / SwiftUI view Phase 2)
`DraggableItem<Content>` + `DropTarget<Content>` with a `DragCoordinator` for state.

---

## Mechanic: Slash

### Purpose
Cross out an object — semantically "take from" / subtract / remove. Used in Story Pond, Vanishing Charms, Hero Missions.

### Input contract
- A roughly straight stroke across an object's bounding region.
- Stroke must be predominantly diagonal (not vertical or horizontal in a single dimension) to avoid confusion with other gestures.

### Tolerances & timings
- Minimum stroke length: **40 pt**.
- Maximum stroke deviation from straight line (per stroke length): **15%** (computed as max perpendicular distance from start-end line / stroke length).
- Angle range: between **20° and 70°** from horizontal (in either direction). Tighter range reduces false-positive vertical/horizontal scribbles.
- Stroke must intersect the object's bounding box; entry and exit points both required.

### Visual feedback
- During: a translucent stroke trail follows the Pencil.
- On success: the object gains a clean slash mark, then fades to 30% opacity over 300 ms with a soft "swoosh" SFX.
- On failure (stroke too short / wrong angle): trail dissolves, no effect.

### Failure modes
- Stroke off any object → trail dissolves, no effect.
- Stroke too short or too wobbly → trail dissolves, soft "miss" SFX, no penalty.

### Suggested component (Flutter widget Phase 1 / SwiftUI view Phase 2)
`SlashRecognizer` overlay on a `SlashableItem`.

---

## Mechanic: Circle

### Purpose
Enclose a group — semantically "put together" / "group these as one." Used in Counting Parade group-totaling, Sorting Bins early-mode, Wundle Census.

### Input contract
- A continuous stroke that approximates a closed loop.
- Loop must enclose at least one target item.

### Tolerances & timings
- Closure tolerance: distance from stroke end to stroke start ≤ **30 pt** (or stroke length × **0.1**, whichever is smaller).
- Minimum enclosed area: **600 pt²** (prevents accidental tiny circles).
- Convexity / self-intersection: a single self-intersection is allowed; more than one cancels.

### Visual feedback
- During: stroke trail in a soft color (teal default; activity-themed override allowed).
- On closure: the loop fills with a semitransparent tint, snapping to a tidy ellipse around the enclosed items.
- Enclosed items get a "grouped" badge.

### Failure modes
- Open loop (start-end distance too large) → stroke dissolves, no effect.
- No items enclosed → stroke dissolves with a soft "miss" SFX.

### Suggested component (Flutter widget Phase 1 / SwiftUI view Phase 2)
`CircleEncloseRecognizer` over an `EnclosableScene`.

---

## Mechanic: Trace

### Purpose
Guided writing of numerals or shapes along a dotted-line path. **No ML required** — purely geometric scoring.

### Input contract
- Kid follows a dotted path with stylus down.
- Multiple sub-strokes allowed (e.g., the "4" has two strokes); the system knows which sub-stroke is next.

### Scoring algorithm (geometric)
1. Sample the kid's stroke at 5 ms intervals.
2. For each sample, compute the minimum distance to the dotted path.
3. A sample is **on-path** if distance ≤ **tolerance band** (default **12 pt** wide).
4. Score = (on-path samples / total samples) × 100.
5. **Pass threshold: 80%**.

### Tolerances & timings
- Tolerance band: 12 pt (Pencil), 18 pt (touch).
- Maximum time per stroke: **8 s** before the system gently re-prompts.
- Min coverage: kid must cover **≥75% of the path length** (prevents tiny scribble passing).

### Visual feedback
- Dotted path glows on stroke start.
- During: the trail leaves a glowing ink behind the Pencil; off-path segments are visibly dimmer.
- On pass: numeral animates to life (per activity).
- On fail: trail fades; system prompts "let's try that one again" (audio).

### Failure modes
- Off-path > 20% of stroke length → fail; retry up to 3× before falling back to **Mode 1 Assisted** (the path itself wobbles to "show" the right shape).

### Suggested component (Flutter widget Phase 1 / SwiftUI view Phase 2)
`TraceCanvas(path: PathSpec, onScore: (Double) -> Void)`

---

## Mechanic: Free-Write

### Purpose
Recognize handwritten digits (0–9) at launch; equations in v1.1. Used in the math notebook and any "write the answer" prompt.

### Input contract
- Kid writes a digit in a designated write zone.
- Multiple strokes allowed; the system waits for **end-of-input timeout** before classifying.

### Tolerances & timings
- End-of-input timeout: **1.2 s** after last stroke.
- Confidence threshold: classifier score ≥ **0.70** to accept.
- Per-digit retry budget: **2 fails** before fallback to **tile selection** (numbered tiles appear; kid taps one).

### Visual feedback
- Write zone shows a subtle baseline.
- Strokes render in ink color (kid-selectable per home theme).
- On classify: digit pulses, shows as a confirmed numeral above the zone.
- On low-confidence: the system shows "I think I see a 7 — is that right?" with Yes / Try Again buttons.

### Failure modes
- Confidence < 0.70 → confirmation prompt.
- 2 confirmation failures → switch to tile selection for this prompt.

### Suggested component
`FreeWriteZone(expected: DigitSet, onClassify: (Digit, Confidence) -> Void)`

Phase 1: Flutter widget consuming `StylusInputProvider`. Phase 2: SwiftUI view backed by `PKCanvasView`.

### Tech
- Phase 1 (Flutter launch): TFLite-Flutter + custom CNN (trained on MNIST + kid-handwriting samples). Bundled on-device, no network.
- Phase 2 (native, post-Mac): same `.tflite` model converted to Core ML; same stroke-capture pipeline via PencilKit for sub-frame latency.
- v1.1: full equation parsing via Apple Math Notes APIs or MyScript (native-phase feature; deferred).

---

## Mechanic: Draw-Line

### Purpose
Draw a line connecting two items — semantically "match these." Used in Compare Baskets (matching items between sets), partition-line drawing on shapes.

### Input contract
- Continuous stroke from one anchor point to another.
- Stroke must start within **anchor tolerance** of one anchor and end within tolerance of another.

### Tolerances & timings
- Anchor tolerance: **20 pt**.
- Max stroke deviation from straight line: **25%** (looser than slash — kids are matching, not slashing).
- Multiple lines per round are allowed; existing lines persist visually.

### Visual feedback
- During: stroke trail in pairing color.
- On connection: the two anchors light up, line settles to a tidy bezier (slight curve allowed).
- On disconnect (tap an existing line): the line fades and is removed.

### Failure modes
- Stroke ends in empty space → trail dissolves, no effect.
- Stroke connects two already-matched anchors → existing line replaced (last wins).

### Suggested component (Flutter widget Phase 1 / SwiftUI view Phase 2)
`MatchLineCanvas(anchors: [Anchor], onMatch: (Anchor, Anchor) -> Void)`

---

## Mechanic: Cut-Along-Guides

### Purpose
Partition a 2D shape into equal shares using snap-to-attachment cuts. Used in Slice Bakery, Wundle Pastry, Layerton Bakery.

### Input contract
- Snap points are pre-placed on the shape's boundary (e.g., halves: top + bottom; thirds: three equally-spaced points).
- Kid draws a stroke from one snap point across the shape's interior to another snap point.
- Stroke must pass through the shape's interior; it cannot leave and re-enter.

### Tolerances & timings
- Snap-point activation radius: **24 pt** at each end.
- Stroke must cover **≥80%** of the chord between the two snap points (prevents partial cuts).
- Interior-respect: stroke samples must all lie within the shape ± 8 pt.

### Visual feedback
- Snap points glow when the Pencil approaches (Pencil hover or finger proximity).
- During the cut: the stroke trails as a glowing knife edge.
- On valid cut: a soft "slice" SFX, the shape visually separates into shares (slight gap appears between sides).
- On invalid cut: stroke dissolves; no penalty.

### Failure modes
- Stroke starts or ends off snap points → no effect.
- Stroke exits and re-enters the shape → no effect.
- Cut overlaps an existing cut → existing cut is preserved; new stroke ignored.

### Suggested component (Flutter widget Phase 1 / SwiftUI view Phase 2)
`PartitionableShape(snapPoints: [Point], onCut: (Point, Point) -> Void)`

---

## Mechanic: Drag-Tool

### Purpose
A virtual tool (ruler, scissors, measuring stick, balance scale) the kid positions and uses. Used in Caretaker's Bench, Spell Garden, Gadget Lab.

### Input contract
- Tool is in a fixed initial position.
- Kid drags it onto an object.
- Once positioned, the tool's measurement reading auto-updates.

### Tolerances & timings
- Position snap: rulers snap to align with objects' edges within **8 pt**.
- Tools cannot overlap each other (last placed wins; earlier tool returns to rest).

### Visual feedback
- Tool has a clear "handle" zone for dragging.
- When aligned to an object, tick marks light up at the relevant boundary.
- The reading display updates live.

### Failure modes
- Tool released in space (not on an object) → returns to rest position.
- Tool released mid-object (no clear edge) → reading shows "?" until the kid aligns better.

### Suggested component (Flutter widget Phase 1 / SwiftUI view Phase 2)
`DraggableTool<ToolType>(initialPosition: Point, alignableTo: [Alignable])`

---

## Mechanic Composition

Many activities use multiple mechanics in sequence (e.g., Counting Parade uses Tap-Pick, then later Drag-and-Drop for "count out N" mode). Activity specs declare the full sequence; this library defines each piece in isolation.

---

## Audio Cues — Global Defaults

Each mechanic has default audio cues that can be overridden per region's audio palette. Default events:

| Event | Default cue |
|---|---|
| Stroke start | Subtle "pen-down" tick |
| Snap (drag-and-drop, cut) | Soft "click" |
| Success (any mechanic completing its goal) | Warm "ding" |
| Miss / failure | Gentle "nope" puff |
| Round complete | Region-specific stinger (Sanctuary: chime; Wundletown: poof; Mathopolis: clean horn) |

Region overrides are declared in each region's audio-palette spec (TBD: `specs/shared/audio-palette-sanctuary.md`, etc.).

---

## Open Questions

- **Precise tolerance values** require Pencil-on-iPad playtesting to tune. Numbers above are starting positions, not final.
- **Touch vs Pencil tolerance multipliers** (currently +25%) should be validated with kids who don't have a Pencil.
- **Multi-Pencil scenarios** (kid swaps Pencil mid-stroke, two kids share a device) — Phase 2 (PencilKit) handles natively. Phase 1 (Flutter): track the most recently active Pencil ID and ignore the prior one.
- **Pencil pressure sensitivity** — none of the launch mechanics use pressure. Future activities (e.g., painting in the Hub) might. Out of scope for K–2 launch.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-29 | Initial draft | |
| 2026-05-30 | Renamed **Tap-Count → Tap-Pick** (supports both counting and selection semantics); added non-target tap handling for selection use cases | |
