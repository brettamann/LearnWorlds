# Activity Spec — Build-a-Habitat

> The K activity that introduces **modeling 2D shapes from components** (K.G.5) and **composing 3D shapes into composite structures** (K.G.6). Structurally novel for the project: **two phases within every round** (Sticks & Clay → Raise the Habitat). Every successful round earns a permanent Sanctuary fixture; the creature that moves in sends a thank-you collectible.

References: `specs/shared/stylus-mechanics.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/reward-economy.md`, `specs/shared/micro-lessons.md`, `specs/shared/k-activity-patterns.md`, `specs/activity-spec-template.md`.

---

## Header

| Field | Value |
|---|---|
| Activity name | Build-a-Habitat |
| Activity slug | `build-a-habitat` |
| Region | Sanctuary |
| Grade | K |
| Standards | K.G.5, K.G.6 |
| Status | Draft |
| Last updated | 2026-05-30 |

---

## Setting & Tone

- **Scene** — A grassy clearing in the Sanctuary, just off the main path. A pre-existing wooden sign nearby reads "Habitat Site" (icon, not text — pre-readers). The clearing is **empty at the start of each round**: bare grass, a flat foundation circle marked faintly. A creature waits patiently at the edge of the clearing (the resident-to-be of whatever habitat the kid builds).
- **Atmosphere** — Bright mid-afternoon Sanctuary light; warm shadows. Music bed is the Sanctuary string-and-flute palette, slightly more upbeat (this is a *building* activity — there's a sense of creative anticipation). Distant birdsong; occasional rustling leaves.
- **Buddy presence** — Per `k-activity-patterns.md`: Buddy at lower-left on a small log. During Phase 1, Buddy watches the framing. During Phase 2, Buddy occasionally hops between the Habitat and the resident-to-be creature, as if introducing them. On round-pass, Buddy hops with the resident creature.
- **Narrator** — Sanctuary warm naturalist.

---

## Standards Coverage

| Standard | What the kid does | Telemetry event | Mastery threshold |
|---|---|---|---|
| **K.G.5** (model shapes from sticks and clay balls) | Phase 1: drags sticks and clay balls into a target frame shape (triangle, square, rectangle, pentagon) | `habitat.phase1_frame_completed` (payload: `targetShape`, `sticksPlaced`, `claysPlaced`, `attempts`) | 5/3/3 standard |
| **K.G.6** (compose 3D shapes into a composite) | Phase 2: drags cubes, cones, cylinders, spheres onto the frame to compose the habitat structure | `habitat.phase2_structure_completed` (payload: `pieceTypesUsed`, `pieceCount`, `targetMatched`) | Same |

---

## Concepts: Introduced vs Exercised

| Concept | Role | Lesson | Notes |
|---|---|---|---|
| **K.G.5** (model shapes from sticks/clay) | Introduces | `specs/lessons/k-g-5-sticks-and-clay.md` | First lesson played here. Introduces the **two-phase rhythm** of Build-a-Habitat as well as the K.G.5 procedure (clay balls at vertices, sticks between them). |
| **K.G.6** (compose 3D shapes) | Introduces | `specs/lessons/k-g-6-compose-3d.md` | Fires the first time the kid reaches Phase 2. Per the **intra-round lesson chain override** declared by this activity, K.G.6's lesson fires in **Phase 2 of the same first round** as K.G.5 — the kid never encounters Phase 2 cold. See `micro-lessons.md`'s "Lesson Chaining" section. |

### Lesson chain declaration

Build-a-Habitat declares **`intra_round_lesson_chain: true`** for the K.G.5 + K.G.6 pair. Reasoning: the two concepts are structurally inseparable (K.G.5 builds the frame that K.G.6 composes onto), and encountering Phase 2 without a K.G.6 lesson would force scaffolding to do too much work pedagogically.

The first Build-a-Habitat round therefore runs:
1. **K.G.5 lesson plays** (I-Show / We-Try) → kid lands in Phase 1 of the round
2. **Kid completes Phase 1** (the lesson's You-Do is integrated as the actual Phase 1 round)
3. **Phase 1 → Phase 2 transition** (~1 s)
4. **K.G.6 lesson plays** (I-Show / We-Try) → kid lands in Phase 2 of the round
5. **Kid completes Phase 2** (lesson's You-Do = actual Phase 2)
6. **Round completes** with the resident creature moving in

Total first-round duration is longer than typical (~3–4 min including both lessons + both phases). The kid then plays subsequent rounds without lessons.

### Registry impact

- `K.G.5.introducedBy = build-a-habitat`
- `K.G.6.introducedBy = build-a-habitat`

---

## Two Phases (universal to every round)

**Build-a-Habitat is structurally different from other K activities**: every round has a fixed sequence of two phases. Sub-modes vary what's built; phases are always present.

### Phase 1 — Sticks & Clay (K.G.5)

- **Goal**: build the 2D frame of the habitat from sticks and clay balls.
- **Source pool**: sticks and clay balls drift in a corner of the scene.
- **Target**: a **ghost outline** of the frame shape is visible at the build site. Vertex positions are marked with faint "vertex" indicators (small empty circles where clay balls go).
- **Procedure**:
  1. Kid drags **clay balls** to vertex positions. Each clay ball snaps to its vertex.
  2. Kid drags **sticks** to edge positions (between two placed clay balls). Each stick snaps in.
  3. When all vertices have clay balls and all edges have sticks, Phase 1 completes.
- **Auto-fire**: when target is complete, transitions to Phase 2 after 2 s of stillness (gives the kid a moment to admire). A visible "next" indicator appears at 1 s.
- **Phase 1 only ends a round** if the activity is in `frame-only` sub-mode (see sub-modes below).

### Phase 2 — Raise the Habitat (K.G.6)

- **Goal**: compose the 3D structure on top of the completed frame.
- **Source pool**: 3D pieces (cubes, cones, cylinders, spheres) drift in a different corner.
- **Target**: a **second ghost outline** appears on top of the completed frame — the 3D structure to build.
- **Procedure**:
  1. Kid drags 3D pieces onto the target outline. Each piece snaps to its target position.
  2. When all target positions are filled with the correct piece *kind*, Phase 2 completes.
- **Round completes** on Phase 2 completion: the resident creature moves in, narrator celebrates, rewards fire.

---

## Sub-Modes

Sub-modes vary **what's being built**. The two-phase structure is constant.

### Sub-mode: `simple-shelter` (default)

- **Standards targeted** — K.G.5 (triangle frame), K.G.6 (1–2 piece composite)
- **What the kid does** — Phase 1: build a **triangle** frame (3 clay balls, 3 sticks). Phase 2: place **1 cube** on top (a fawn shelter — the cube is the shelter body). Resident: a baby fawn.
- **Pass condition** — Both phases complete; structure matches target.

### Sub-mode: `creature-home` (medium)

- **Standards targeted** — K.G.5 (square/rectangle frame), K.G.6 (3–4 piece composite)
- **What the kid does** — Phase 1: build a **square or rectangle** frame (4 clay balls, 4 sticks). Phase 2: place a **cube** body + a **cone** roof + optional **cylinder** chimney + **sphere** doorknob. Resident: a baby unicorn or hatchling dragon, depending on the round's flavor.
- **Pass condition** — Both phases complete.

### Sub-mode: `grand-habitat` (challenge variant)

- **Standards targeted** — K.G.5 (pentagon/hexagon frame), K.G.6 (5+ piece composite of varied kinds)
- **What the kid does** — Phase 1: build a **pentagon or hexagon** frame. Phase 2: compose a multi-piece structure (e.g., a unicorn's gazebo: hexagon frame, cylinder pillars, cone spires, sphere finial).
- **Pass condition** — Both phases complete.
- **Reward bump** — Challenge chest per `reward-economy.md`.

### Sub-mode: `frame-only` (scaffold demotion target)

- **Standards targeted** — K.G.5 only
- **What the kid does** — Phase 1 only. The kid builds a frame (triangle or square). Round completes after Phase 1.
- **Purpose** — This sub-mode exists primarily as a **demotion target** when a kid is struggling with full Build-a-Habitat. Per the staggered demotion rule in `adaptive-scaffolding.md`, a kid who fails twice at `simple-shelter` after their CPA layer is already Concrete will be demoted to `frame-only` for the next round. This lets them solidify Phase 1 before attempting Phase 2 again.

---

## Visual Layout

### Phase 1 (Sticks & Clay)

```
+--------------------------------------------------------+
| [exit]                              [coins: 12]        |
|                                                        |
|   <Sanctuary clearing — grass, distant trees>         |
|                                                        |
|         <ghost outline: triangle frame>               |
|         ○            ←  vertex indicators            |
|        / \                                            |
|       /   \                                           |
|      ○-----○                                          |
|                                                        |
|             [phase 1: build the frame]                |
|                                                        |
|   ~~~                            <waiting creature>   |
|   < sticks + clay balls >                            |
|   <source pool>                                       |
|                                                        |
|  [Buddy idle]                          [notebook >]   |
+--------------------------------------------------------+
```

### Phase 2 (Raise the Habitat)

```
+--------------------------------------------------------+
|         <completed triangle frame, solid lines>      |
|         /\                                            |
|        /  \                                           |
|       /----\                                          |
|      <ghost outline: 3D structure>                   |
|       [□]     ← cube target position                 |
|                                                        |
|             [phase 2: raise the habitat]              |
|                                                        |
|   ~~~                          <waiting creature>     |
|   < cubes, cones, cylinders >                        |
|                                                        |
+--------------------------------------------------------+
```

- **Persistent scene anchors** — clearing background, Buddy lower-left, HUD per K convention.
- **Phase indicator** — bottom of screen shows current phase ("phase 1: build the frame" → "phase 2: raise the habitat").
- **Source pools** — drift gently in their corner; visible only during their respective phase.
- **Resident creature** — visible at the edge of the clearing from the start; moves into the completed habitat at round-pass.

---

## State Machine

```
[idle/intro] → narrator opens with the round's habitat goal
   ↓
[phase1_setup] → ghost outline appears; source pool of sticks/clay drifts in
   ↓
[phase1_active] → kid drags clay balls + sticks; snaps register
   ↓ (target frame complete + 2 s stillness)
[phase1_complete] → frame solidifies; narrator transitions
   ↓ (1 s)
[phase2_setup] → ghost outline of 3D structure appears; 3D source pool drifts in
   ↓
[phase2_active] → kid drags 3D pieces; snaps register
   ↓ (target structure complete + 2 s stillness)
[phase2_complete] → resident creature walks in; round-pass celebration
   ↓
[reward + thank-you collectible from creature]
   ↓
[next round queued]
```

**Failure branches**:
- Phase 1 timeout / kid taps Done without target met → warm narrator + demonstration completes Phase 1 → transition to Phase 2 normally. (Kid still gets the K.G.6 practice.)
- Phase 2 timeout / Done with target unmet → warm narrator + demonstration completes Phase 2 → round still ends with the structure built (kid gets the visual reward, but mastery events don't fire for that round).

**Exit conditions** — standard per K patterns. Manual exit mid-round saves Phase 1 progress; resume on re-entry within 5 minutes.

---

## Stylus Interactions

| Mechanic | Where used | Local overrides |
|---|---|---|
| **Drag-and-Drop (snap-to-target)** | Both phases. Phase 1: clay balls → vertex positions, sticks → edge positions. Phase 2: 3D pieces → structure target positions. | Snap radius **30 pt** (slightly wider than the standard 24 pt; building components are larger and the snap should feel forgiving). Targets are single-occupancy. |

No other mechanics. No Tap-Pick, no Free-Write, no Cut-along-guides. Build-a-Habitat is entirely placement-based.

---

## Number-Writing Modes

**Not used.** Build-a-Habitat doesn't ask the kid to write numerals.

---

## Audio Cues

> **Runtime source**: narration cues live in [`content/strings/en-US/activities/build-a-habitat.json`](../../../content/strings/en-US/activities/build-a-habitat.json). The prose below is the design-time reference; the JSON is the authoritative source the TTS pipeline and runtime consume.

### Narrator lines (Sanctuary warm naturalist)

#### Round opening
- **Round start (simple-shelter)**: "Time to build a fawn shelter. First, the frame."
- **Round start (creature-home)**: "A baby {creature} needs a home. Let's build one. First the frame, then the structure on top."
- **Round start (grand-habitat)**: "A grand habitat today — a {hexagon} frame and a tall structure. Start with the frame."

#### Phase 1
- **Mid-progress hesitation (5 s)**: (no narration — visual hint via vertex glow)
- **Mid-progress hesitation (10 s)**: "Drag the clay balls to the corners, then the sticks between them."
- **Frame complete**: "Frame done. Now raise the habitat."

#### Phase 2
- **Mid-progress hesitation (5 s)**: (visual hint via target glow)
- **Mid-progress hesitation (10 s)**: "Drag the {piece} onto the {position}."
- **Structure complete**: "Done! Let's let {creature_name} move in."

#### Round-pass
- **After creature moves in**: "{creature_name} loves it. Look at that — you built a home."

#### Round-fail
- **Phase 1 fail**: "Let me show you how the frame goes." *(demo)*
- **Phase 2 fail**: "Let me show you how it stacks." *(demo)*

### SFX

| Event | SFX |
|---|---|
| Clay ball drag | Soft "shape" sound (clay being moved) |
| Clay ball snap | Warm "thunk" |
| Stick drag | Light "wood" sound |
| Stick snap into place | "Click" + soft chime |
| 3D piece drag | Subtle "lift" whoosh |
| 3D piece snap | Heavier "thud" + chime |
| Phase 1 complete | Brief "lift" stinger — frame solidifies visually |
| Phase 2 complete | Sanctuary chime stinger (per K patterns) |
| Resident creature walks in | Species-specific cue (whinny for unicorn, chirp for hatchling dragon, etc.) |

### Music

- Sanctuary mid-afternoon bed (slightly more upbeat than morning/morning beds): gentle strings + soft percussion + flute, ~95 BPM.
- Subtle intensity bump at Phase 1 → Phase 2 transition (a quiet "thank you, now the next step" feel).
- Round-pass stinger plays over the bed.

---

## Scaffolding Triggers

Uses `ScaffoldQuery` per round, including `firstEncounterLesson` for K.G.5 and K.G.6 routing.

| Trigger | Response |
|---|---|
| **5 s of no input** | Highlight the next target position (a vertex in Phase 1, a structure slot in Phase 2) with a soft glow for 1.5 s. |
| **10 s of no input** | Narrator gives a sub-mode-specific prompt (see Audio Cues). |
| **Kid drops a stick on a vertex position** (or any wrong type-position swap) | Component returns to source pool; brief "this goes elsewhere" puff. |
| **Kid drops a 3D piece on the wrong target slot** | Piece returns to source; no penalty. |
| **2 consecutive round failures** | Apply the **staggered demotion** rule from `adaptive-scaffolding.md`: demote CPA layer first (Abstract → Pictorial → Concrete). If already at Concrete, demote sub-mode (`grand-habitat` → `creature-home` → `simple-shelter` → `frame-only`) and CPA layer resets to Concrete for the simpler sub-mode. |
| **Kid abandons mid-Phase 1** | Save Phase 1 progress on exit; resume within 5 min restores partial-built frame. |

---

## CPA Progression

Build-a-Habitat's CPA is about **how much guidance the ghost outline gives**.

| Layer | What it looks like |
|---|---|
| **Concrete** | Ghost outline is **fully visible and bright**. Vertex indicators and target slots are clearly marked. Each component, when dragged, faintly "previews" where it'll snap before release. |
| **Pictorial** | Ghost outline is **faint** (low opacity). Vertex indicators and target slots visible but more subtle. No preview on drag. |
| **Abstract** | Ghost outline **disappears entirely** once Phase begins. The kid sees only the source pool and must build from memory / imagination, with snap behavior still helping at point-of-release. The narrator's prompt ("build a triangle frame for a fawn shelter") carries the target description. |

- **Default starting layer (K, fresh kid)** — Concrete.
- **Promotion conditions** — 3 consecutive passes at the current layer.
- **Demotion conditions** — 2 consecutive failures at the current layer (per staggered rule).

---

## Reward Emissions

| Event | Trigger | Reward (per `reward-economy.md`) |
|---|---|---|
| `round.passed` | Both phases complete (or `frame-only` Phase 1 complete) | +2 coins |
| `round.notebook_bonus` | Notebook had ≥3 strokes during round | +1 coin (likely rare here — Build-a-Habitat doesn't lend itself to notebook use) |
| `streak.session_3` / `_5` / `_10` | Standard | Per shared spec |
| `milestone.problems_25` / `_100` | Lifetime in this activity | Per shared spec |
| `mastery.standard_practicing` / `_mastered` | Adaptive scaffolding emits for K.G.5 (after Phase 1) and K.G.6 (after Phase 2) | Per shared spec |
| `challenge.completed` | `grand-habitat` round passes | Challenge chest (rare habitat-themed piece guaranteed) |
| **`habitat.permanent_fixture_built`** | **Round-pass on `simple-shelter`, `creature-home`, or `grand-habitat`** | **The built habitat becomes a permanent fixture in the Sanctuary**, viewable from the Hub. Each unique habitat layout earns a separate fixture; revisits don't duplicate. |

### Activity-specific collectibles
- **Resident Creature Thank-Yous** — when a creature moves into a built habitat, they send a small thank-you collectible (a feather from the fawn, a scale from the hatchling dragon, a gem from the baby unicorn, etc.) to the kid's Hub.
- **Habitat Permanence** — the kid's built habitats accumulate in a **Sanctuary Habitat Map** viewable from the Hub. Over time, the Sanctuary fills up with the kid's creations — a visible long-term progression.
- Complete the habitat map (build all ~12 habitat layouts at launch) for a Hub trophy: the **Sanctuary Keeper's Map**.

---

## Telemetry Events

(Beyond shared `scaffold.*`, `economy.*`, `lesson.*` events.)

| Event | Payload |
|---|---|
| `habitat.round_started` | `subMode`, `targetShape` (frame), `targetStructure` (3D layout), `residentCreature`, `presentationLayer` |
| `habitat.phase1_started` | `targetShape` |
| `habitat.phase1_component_placed` | `componentType` (clay/stick), `targetPosition`, `kidAttempt` (correct/incorrect), `latencyMs` |
| `habitat.phase1_frame_completed` | `targetShape`, `componentsPlaced`, `attempts` |
| `habitat.phase2_started` | `targetStructure` |
| `habitat.phase2_piece_placed` | `pieceType` (cube/cone/cylinder/sphere), `targetSlot`, `kidAttempt`, `latencyMs` |
| `habitat.phase2_structure_completed` | `pieceTypesUsed`, `pieceCount`, `targetMatched` |
| `habitat.round_completed` | `success`, `subMode`, `phasesCompleted`, `attemptsThisRound`, `hintsFired` |
| `habitat.permanent_fixture_built` | `habitatId`, `subMode`, `fixtureMapPosition` |
| `habitat.thank_you_collectible_dropped` | `creatureId`, `collectibleId`, `setProgress` |

---

## Challenge Variant

**Grand Habitat** — `grand-habitat` sub-mode (pentagon/hexagon frame + multi-piece 3D structure).

- **Entry point** — A "Grand Habitat!" banner appears on Build-a-Habitat's tile in the Sanctuary 1× per day at launch (tunes post-launch).
- **Reward bump** — Challenge chest on completion (rare habitat-themed piece guaranteed).

---

## Edge Cases & Error Handling

- **Kid drops a clay ball on a stick edge position** — clay returns to source with a "wrong slot" puff. Same for stick on vertex.
- **Kid drops a 3D piece type that doesn't match the target slot** (e.g., a cube on a cone target) — piece returns; no penalty. Slot indicates "cone" via subtle silhouette.
- **Kid completes Phase 1 frame but then drags a stick off** — frame solidifies on Phase 1 complete; once solidified, components are not removable. (Removable during active Phase 1, locked after transition.)
- **Phase 1 timeout with partial frame** — warm narrator + system auto-completes the frame (snaps remaining components into place with the pointer animation). Transitions to Phase 2 normally. Round still counts toward mastery if Phase 2 then succeeds.
- **Resident creature already lives in another habitat** — at launch, each round generates a fresh creature. No persistence requirement; the creature is a visual/audio reward, not a long-term character.
- **Stylus disconnect mid-build** — current drag cancels; component returns to source. State preserved.
- **App backgrounded mid-build** — pause and persist Phase + current placements. Resume within 5 min restores exact state; beyond that, restart current phase.
- **Audio muted** — visual cues (ghost outline, snap indicators, creature movement, phase indicator text) carry the full information.
- **The "next phase" transition** (1 s with the "next" indicator) — kid can tap to skip the 1-s wait if impatient. Confirm in playtest this doesn't make the transition feel jarring.

---

## Open Questions

- **Component drag-from-source affordance** — sticks and clay balls drift in a pool. Should there be one of each at a time visible, or many drifting? Suggest 4–6 visible at any moment; pool auto-refills.
- **Vertex indicator design at Concrete vs Pictorial** — Concrete is "bright empty circle"; Pictorial is "faint dot." Confirm both read clearly on backgrounds.
- **3D piece "target slot" visualization** — silhouettes proposed (cone target = cone-shaped faint outline). Confirm this reads better than text labels for K kids.
- **Permanent fixture map design** — the Hub view of the Sanctuary should show built habitats as small icons or in a map-overview. UX TBD.
- **Resident creature variety** — ~12 habitat layouts × 1 creature each = 12 creature options at launch. Confirm with art; some habitats may share residents (e.g., 2 different fawn shelters).
- **"Free composition" mode for older kids / Abstract layer** — current spec is snap-to-target (kid drops where the system expects). Could Abstract mode allow truly free placement (kid composes any habitat they want, system grades on shape-ness)? Probably out of scope for K launch; defer.
- ~~**The two-phase rhythm and lesson firing** — K.G.5's lesson plays in the kid's first Phase 1; K.G.6's lesson plays in their second round's Phase 2 (since multi-introduced-concepts queue per `micro-lessons.md`).~~ **Resolved 2026-05-30**: activity declares `intra_round_lesson_chain: true`. Both lessons fire within the first round (K.G.5 in Phase 1, K.G.6 in Phase 2). The kid never encounters Phase 2 cold. See Lesson Chain Declaration section above.

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical across phases.


```
BuildAHabitatView
├── ClearingBackgroundLayer (parallax grass + sky + trees)
├── BuddyView (idle, phase-reactive behaviors)
├── ResidentCreatureView (waits at edge, moves into completed habitat)
├── HabitatBuildAreaView (the central build zone)
│    ├── GhostOutlineLayer (target outline, varies by phase + layer)
│    ├── FrameLayer (Phase 1 outputs)
│    └── StructureLayer (Phase 2 outputs, sits on top of frame)
├── ComponentSourceView (drifting pool; varies by phase — sticks/clay in Phase 1, 3D pieces in Phase 2)
├── PhaseIndicatorView (bottom-of-screen text + icon)
├── DoneButtonView (rarely needed — auto-fire on phase completion handles most cases)
├── HUDView (coin count, exit)
└── NotebookTab (collapsed by default)
```

### Reusable opportunities surfaced by this spec

- **The two-phase round structure** — first activity with this pattern. Generalize as a reusable `MultiPhaseRound` component for any future activity with sequential within-round phases (e.g., 1st-grade `Coin Counter` could use Phase 1: recognize coin / Phase 2: add to running total; or 2nd-grade `Layerton Bakery` could use Phase 1: partition / Phase 2: distribute).
- **Ghost outline rendering at multiple opacities by CPA layer** — generalizes for any "build to a target" activity.
- **Drift-source pool** — already similar to Ten-Frame Pond's fish source pool. Could extract into a shared `DriftingSourcePool<Item>` component.
- **"Built fixture persists in the world"** — first activity with this. Generalizes for any creation activity where the kid's output should accumulate in the Hub view.

### Performance considerations

- Up to ~10 components on screen (sticks + clays in Phase 1; 3D pieces in Phase 2). Low overhead.
- 3D piece rendering uses simple shapes (cubes, cones, cylinders, spheres) — no complex geometry needed.
- Permanent-fixture habitat rendering in the Hub view: if the kid builds 12+ habitats, the Hub Sanctuary view should batch-render them. Consider sprite atlases for habitat thumbnails.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — first K activity with the **two-phase round** structure. Introduces the "permanent fixture" reward pattern (built habitats accumulate in the Hub Sanctuary view) | |
| 2026-05-30 | Both MicroLessons authored and linked (K.G.5, K.G.6). Activity is now lesson-complete and ready-to-build | |
| 2026-05-30 | Declared `intra_round_lesson_chain: true` for the K.G.5 + K.G.6 pair. Both lessons fire within the first round (K.G.5 in Phase 1, K.G.6 in Phase 2). Resolves the cold-Phase-2 concern from the K.G.6 lesson's open questions | |
