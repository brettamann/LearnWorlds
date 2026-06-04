# Lesson Runtime Actions Catalog

> The complete vocabulary of `action` names that lesson runtime JSON files use in their `animationSteps` and `choreography` arrays. The lesson runner implements each action; this is the source-of-truth catalog for "what must the runtime know how to do."

References: `schemas/lesson-runtime.schema.json`, `data/lesson-runtime/`, `specs/shared/micro-lessons.md`.

---

## Why this catalog exists

The 21 K lesson runtime JSON files use ~80 distinct action names (e.g., `pointer-touch`, `count-badge-update`, `frame-collapse-to-ten-pearl`). Without a single catalog:

- Implementer can't easily list "what the lesson runner needs to render."
- Lesson authors might invent similar-but-different action names (`fade-out` vs `pointer-fade-out` vs `disappear`).
- QA can't grep for unused actions.

This file is **the authoritative list**. Lesson authors pick from here; if a needed action isn't here, the author adds it (with a sub-spec entry below) before referencing it in JSON.

---

## Action categories

| Category | Purpose | Naming prefix |
|---|---|---|
| Scene lifecycle | Fade in/out, music in/out, narrator on/off | `scene-`, `music-`, `narrator-` |
| Pointer | The glowing pointer that demonstrates in I-Show / We-Try | `pointer-` |
| Object manipulation | Specific to creatures/items/shapes/fish in K activities | varies by activity |
| Count + badge | The HUD count badge | `count-badge-` |
| Tile + UI | Tiles, indicators, podium slots, bins | varies |
| Sparkle / visual reward | Celebration micro-animations | `sparkle`, `pulse`, `glow` |
| Phase + lesson lifecycle | Start, end, transitions, skip buttons | `phase-`, `ive-got-this-` |
| Audio cue | One-shot SFX | `sfx-`, `chime`, `stinger` |
| Narration | Speak a script cue or text | `narration` |
| Hesitation / scaffolding | Halo, brighten, auto-complete | `halo-`, `auto-` |

---

## Action reference

For each action: name, params, description, expected duration.

### Scene lifecycle

| Action | Params | Description | Duration |
|---|---|---|---|
| `scene-fade-up` | `(none)` | Fade the scene from black to the configured background. | 0.5–1 s |
| `scene-fade-out` | `(none)` | Fade to black. | 0.5–1 s |
| `music-bed-in` | `variant?: string` | Start the music bed; variant for sub-mode tones. | 1–2 s ramp |
| `music-bed-out` | `(none)` | Stop the bed gracefully. | 1 s ramp |
| `narrator-begin` | `(none)` | Marker indicating the narrator's first line begins; no visual side effect. | instant |
| `phase-end` | `(none)` | Marks the end of a lesson phase; the runner transitions to the next phase. | instant |
| `ive-got-this-button-show` | `(none)` | Reveals the "I've got this" skip-to-You-Do button. | 0.3 s |
| `ive-got-this-button-hide` | `(none)` | Hides the button (e.g., on phase end). | instant |

### Pointer

| Action | Params | Description |
|---|---|---|
| `pointer-appear` | `position?: string \| target?: string \| style?: string` | Render the glowing pointer at the given location. Default style: amber glow with wisp trail. |
| `pointer-fade-out` | `(none)` | Pointer fades away. |
| `pointer-touch` | `target: string` | Pointer drifts to and "touches" the target (small contact animation). |
| `pointer-tap` | `target: string` | Pointer performs a tap on the target (e.g., a tile). |
| `pointer-pickup` | `tile: string \| itemType: string` | Pointer picks up a draggable item from a source. |
| `pointer-place` | `target: string \| tile: string` | Pointer drops/places the held item onto a target. |
| `pointer-drag` | `from: string, to: string` | Composite of pickup + drag-with-glow + place. |
| `pointer-trace` | `strokePath: string, durationSec: number` | Pointer traces along a defined stroke path. |
| `pointer-lift` | `(none)` | Pointer lifts off the surface mid-trace (signals end of stroke 1, start of stroke 2). |
| `pointer-pickup-from-pool` | `itemType: string` | Pointer reaches into the source pool, picks up an item of the given type. |
| `pointer-drag-fish-to-pad` | `frame: string, pad: string` | Specific shorthand for Ten-Frame Pond pointer drag (fish from source to lily pad). |
| `pointer-touch-drag` | `from: string, to: string` | Shape Garden / Care Pantry shorthand for a single drag motion. |
| `pointer-drop` | `tag: string, target: string` | Drops a held tag onto a target. |
| `pointer-place-clay` | `target: string` | Build-a-Habitat shorthand for placing a clay ball at a vertex. |
| `pointer-place-stick` | `target: string` | Build-a-Habitat shorthand for placing a stick on an edge. |
| `pointer-move-buddy` | `to: string, durationSec?: number` | Where's Buddy? — pointer drags Buddy to a position relative to a landmark. |
| `pointer-auto-tap` | `target: string` | Used in We-Try when the system auto-completes a kid action. |
| `pointer-auto-tap-sequence` | `targets: string[], spacingSec: number` | Multiple auto-taps in sequence. |
| `pointer-auto-tap-remaining-triangles` | `(none)` | Shape Garden helper. |
| `pointer-auto-drag-fish` | `count: integer` | Ten-Frame Pond helper for auto-completing fish placement. |
| `pointer-auto-drag-remaining` | `count: integer` | Generic auto-complete for placement activities. |
| `pointer-auto-draw-line` | `from: string, to: string` | Picnic Baskets auto-draw for We-Try completion. |
| `pointer-auto-touch-sequence` | `targets: string[], spacingSec: number` | Alias for `pointer-auto-tap-sequence` (older lessons used this name). |
| `pointer-auto-complete-on-pause` | `pauseThresholdSec: number` | Schedules an auto-complete if kid pauses. |
| `pointer-auto-sweep-remaining` | `(none)` | Care Pantry helper for auto-completing remaining items. |
| `pointer-auto-place-clay-on-third-vertex` | `(none)` | Build-a-Habitat helper. |
| `pointer-auto-place-remaining-sticks` | `(none)` | Build-a-Habitat helper. |
| `pointer-auto-place-remaining-bins` | `(none)` | Care Pantry helper. |
| `pointer-auto-sort-remaining` | `(none)` | Shape Garden / Care Pantry helper. |
| `pointer-auto-drop-remaining-applicable` | `(none)` | Caretaker's Bench helper. |
| `pointer-drag-bin-to-podium` | `bin: string, podium: string` | Care Pantry Phase 2 helper. |
| `pointer-drag-rapid` | `from: string, to: string[], spacingSec: number` | Burst-drop helper (multiple drops in quick succession). |
| `pointer-drag-to-bin` | `from: string, to: string` | Generic drop-into-bin animation. |
| `pointer-place-stick` (alias) | see above | |

### Count badge

| Action | Params | Description |
|---|---|---|
| `count-badge-show` | `value: integer` | Reveal the count badge with an initial value. |
| `count-badge-update` | `value: integer` OR `topLine: string, bottomLine: string` | Update the badge's displayed number(s). |
| `count-badge-pulse-glow` | `value?: integer` | Visual pulse + glow on the badge for cardinality emphasis. |
| `count-badge-pulse` | `(none)` | Smaller pulse, less emphatic. |
| `count-badge-glow` | `(none)` | Hold a glow without pulsing. |
| `count-badge-hide` | `(none)` | Hide the badge. |
| `count-badge-top-line-pulse` | `(none)` | Pulse only the top line of the two-line badge variant. |

### Object manipulation (per activity)

| Action | Params | Description |
|---|---|---|
| `sparkle` | `target: string` | Brief sparkle effect on a target (counted creature, traced numeral, etc.). |
| `sparkle-on-target` | `(none)` | Variant when the target is the last-touched element. |
| `sparkle-on-frog` | `(none)` | Storyteller's Pond shorthand. |
| `pulse-glow` | `target: string, reason?: string` | Soft pulsing glow on an element. |
| `pulse-glow-multi` | `targets: string[]` | Multi-target pulse. |
| `glow-soft` | `targets: string[]` | Sustained soft glow (e.g., pond creatures rotating). |
| `numeral-comes-to-life` | `numeral: string, personality?: string, animation?: string` | Scribe's Tower's signature animation. |
| `frame-solidify` | `(none)` | Build-a-Habitat frame transitions from ghost to solid. |
| `frame-solidify-with-lift-stinger` | `(none)` | With audio stinger overlay. |
| `frame-collapse-to-ten-pearl` | `(none)` | Ten-Frame Pond signature collapse. |
| `frame-clear-wave-animation` | `(none)` | Frame clears (fish swim back to source) between decomposition demos. |
| `frame-brighten` | `(none)` | Brighten the frame at lesson close. |
| `ghost-outline-fade-out` | `(none)` | Build-a-Habitat ghost outline disappears once filled. |
| `ghost-numeral-glow` | `numeral: string` | Scribe's Tower — the dotted ghost numeral glows. |
| `ten-pearl-pulse` | `(none)` | Ten-Frame Pond — the collapsed ten pearl pulses. |
| `ten-label-rise` | `cluster: string, label?: string` | Counting Parade (tens-parade variant) — a "10" label rises above a cluster. |
| `cluster-pulse` | `cluster: string` | Counting Parade (tens-parade) — cluster acknowledgment pulse. |
| `cluster-collapse-tight` | `cluster: string` | Visually compresses 10 creatures into one cluster unit. |
| `cluster-reveal-sparkle-sequence` | `cluster: string, sparkleCount: integer, totalDurationSec: number` | Briefly reveals individual members of a cluster (the "look — really 10" demo). |
| `successor-sparkle-sequence` | `targets: string[], spacingSec: number, purpose?: string` | K.CC.4b — the +1 callout sparkle sequence. |
| `firefly-pulse-sequence` | `count: integer, totalDurationSec: number` | Scribe's Tower — pulses fireflies one at a time. |
| `dot-pattern-pulse` | `target: string` | Picnic Baskets — dot pattern under a numeral pulses. |
| `dot-pattern-pulse-both` | `(none)` | Pulse both dot patterns simultaneously. |
| `wide-side-glow` | `symbol: string` | Picnic Baskets `numeral-compare` — wide side of `>` or `<` glows. |
| `wide-side-arrow` | `from: string, to: string` | An arrow draws from a symbol's wide side toward the bigger number. |
| `wide-side-glow-and-arrow` | `symbol: string, pointTo: string` | Combined effect. |
| `directional-arrow` | `from?: string, to?: string, direction?: string, between?: string[], style?: string, at?: string` | Where's Buddy? — directional arrow scaffolding at Concrete layer. |
| `halo-intensify-on-speak-word` | `target: string, word: string` | Where's Buddy? — landmark halo intensifies when the narrator says its name. |
| `tag-settle-in-stack-with-chime` | `(none)` | Caretaker's Bench — attribute tag drops onto applied stack. |
| `nope-puff-tag-returns` | `tag: string` | Caretaker's Bench — wrong tag puffs back to source. |
| `applied-tags-pulse-together` | `(none)` | Caretaker's Bench — all applied tags pulse on lesson close. |
| `shape-lift-and-rotate-reveal` | `target: string` | Shape Garden — picked-up 3D shape rotates to reveal 3D-ness. |
| `highlight-wash` | `targets: string[]` | Shape Garden — soft wash sweeps across targets. |
| `glow-mark-ends` | `targets: string[]` | Caretaker's Bench — soft glow at the right end of objects on the measuring stick. |
| `soft-glow-mark-ends` | (alias) | |
| `scale-tip-dramatic` | `towardHeavierSide: string, durationSec: number, sfx?: string` | Caretaker's Bench — balance scale tips. |
| `thunk-sfx` | `(none)` | Object placed on a pan. |
| `thunk-sfx-and-pan-dip-slightly` | `(none)` | Combined. |
| `soft-glow` | `target: string` | Generic soft sustained glow. |
| `halo-pulse` | `target: string` | Single-target halo pulse. |
| `halo-pulse-pair` | `targets: string[]` | Pulse two related targets together. |
| `halo-pulse-multi` | `targets: string[]` | Pulse N targets together. |
| `halo-pulse-next-vertex` | `(none)` | Build-a-Habitat helper. |
| `halo-pulse-next-triangle` | `(none)` | Shape Garden helper. |
| `halo` | `target: string` | Sustained halo (no pulse). |
| `halo-tag` | `tag: string` | Caretaker's Bench — halo around a tag. |
| `halo-tile` | `tile: integer \| string` | Fluency Within 5 — halo around a numeral tile. |
| `halo-button` | `target: string` | Picnic Baskets indicator halo. |
| `halo-correct-tile-brighter` | `tile: integer` | After incorrect tap, the correct tile brightens. |
| `halo-next-applicable-tag` | `(none)` | Caretaker's Bench shorthand. |
| `halo-next-empty-cell` | `(none)` | Ten-Frame Pond shorthand. |
| `empty-cells-pulse` | `count: integer` | Ten-Frame Pond — pulse all empty cells together. |

### Tile + UI

| Action | Params | Description |
|---|---|---|
| `tiles-fade-in` | `tiles: integer[]` | Fluency Within 5 — tile row fades in. |
| `tile-feedback` | `passCue?: string, failCue?: string, passCueByTag?: object, failCueByTag?: object` | Generic tile-result feedback router. |
| `indicator-buttons-show` | `buttons?: string[]` | Picnic Baskets — show the more/less/equal buttons. |
| `indicator-feedback` | `passCue?: string, failCue?: string` | Picnic Baskets — feedback router. |
| `symbol-tile-row` (set-up only) | `tiles: string[], draggable: bool, position: string` | Picnic Baskets numeral-compare initial state. |
| `symbol-snap-settle-chime` | `(none)` | Picnic Baskets — symbol drops into the gap. |
| `symbol-feedback` | `passCue?: string, wrongGreaterCue?: string, wrongEqualsCue?: string` | Picnic Baskets numeral-compare router. |
| `numeral-tile-row-show` | `tiles: integer[]` | K.CC.4b — tile row appears for cardinality question. |
| `selection-ring-bright-chime` | `(none)` | Fluency Within 5 — tap-tile feedback. |
| `progress-badge-update` | `value: string` | Shape Garden — "found N of M" badge update. |
| `bar-model-appear` | `parts: object[], result?: object` | Storyteller's Pond — bar model renders with parts + result. |
| `bar-model-appear-with-placeholder` | `parts: integer[], resultPlaceholder: bool` | Bar model with a `?` placeholder for the result. |
| `bar-model-fill-result` | `value: integer` | Fills the placeholder. |
| `podium-slots-fade-in` | `labels?: string[]` | Care Pantry Phase 2. |
| `bins-lift-slightly-draggable` | `(none)` | Care Pantry Phase 2 — bins become draggable. |
| `bins-lift-draggable` | (alias) | |
| `bin-count-update` | `bin: string, value: integer` | Care Pantry / Counting Parade. |
| `drop-feedback` | `passCue?: string, failCue?: string` | Generic drop-result router. |
| `tap-feedback` | `passCue?: string, failCue?: string` | Generic tap-result router. |
| `auto-tap-correct-tile-after` | `delaySec: number` | After incorrect taps, auto-tap correct tile. |

### Camera + scene

| Action | Params | Description |
|---|---|---|
| `camera-nudge` | `to: string` | Slight camera shift toward an element. |
| `camera-nudge-between-baskets` | `(none)` | Picnic Baskets shorthand. |
| `camera-nudge-between-numerals` | `(none)` | Picnic Baskets shorthand. |
| `camera-nudge-each` | `targets: string[]` | Caretaker's Bench shorthand. |
| `camera-attention-shift` | `to: string` | Shape Garden shorthand. |

### Specific scene actors

| Action | Params | Description |
|---|---|---|
| `buddy-return-to-center` | `(none)` | Where's Buddy? — Buddy returns to home position. |
| `buddy-turn-toward` | `target: string` | Buddy orientation cue. |
| `buddy-wiggle-celebrate` | `(none)` | Fluency Within 5 — Buddy wiggles after correct answer. |
| `buddy-wiggle` | `(none)` | Smaller wiggle. |
| `fawn-walk-toward-habitat` | `(none)` | K.G.6 — resident fawn approaches built habitat. |
| `fawn-enter-habitat` | `(none)` | Resident fawn enters and nestles in. |
| `ducks-swim-in` | `count: integer, from: string` | Storyteller's Pond. |
| `frogs-appear-on-lily-pad` | `count: integer` | Storyteller's Pond. |
| `frogs-leap-in` | `count: integer` | Storyteller's Pond. |
| `fireflies-rearrange-to-five-shape` | `(none)` | Scribe's Tower — fireflies form a "5" shape. |
| `new-fawns-walk-in` | `count: integer, fadeOldNumerals?: bool, fadeOldNumeralsAfterSec?: number` | Counting Parade (count-forward-from-n) — new arrivals. |
| `third-cluster-walks-in` | `(none)` | Counting Parade tens-parade shorthand. |

### Audio

| Action | Params | Description |
|---|---|---|
| `sanctuary-chime-stinger` | `(none)` | The K round-pass stinger. |
| `phase-1-complete-stinger` | `(none)` | Care Pantry phase transition stinger. |
| `snap-thunk` | `(none)` | Object snaps into target. |
| `snap-thunk-chime` | `(none)` | Snap + light chime. |
| `line-settle-chime` | `(none)` | Picnic Baskets drawn-line settle. |
| `chalkboard-show-problem` | `problem: string, sfx?: string` | Fluency Within 5 — write problem to board. |
| `chalkboard-reveal-answer` | `value: integer` | Reveal the answer on the board. |
| `chalkboard-fade-to-blank` | `(none)` | Clear board for next problem. |

### Narration

| Action | Params | Description |
|---|---|---|
| `narration` | `cueId: string` | Dispatch the script cue to `NarrationPlayer`. Default behavior: show text caption + play pre-rendered audio if available + fall back to system TTS if parent enabled. During the TTS deferral (per `text-and-tts-deferral.md`) only the caption path runs (plus system TTS if enabled). The animation timeline still advances on the cue's `at` mark regardless of whether audio plays. |
| `narration-cue` | (alias for `narration`) | |
| `narration-if-monochrome` | `cueId: string` | Speak only if condition met (We-Try color-distribution check). |
| `narration-transition-to-decomposition` | `(none)` | Specific transition cue in K.OA.3. |
| `storyteller-mouth-open-narrate` | `(none)` | Storyteller's Pond — turtle's mouth animates. |
| `storyteller-question-pause` | `(none)` | Pause beat after the question is asked. |
| `silent-beat-for-mental-count` | `(none)` | Storyteller's Pond — silent pause for kid mental work. |

### Scene-fade variants

| Action | Params | Description |
|---|---|---|
| `scene-fade-up-midround` | `(none)` | Used when the scene continues from a prior phase (no full fade, just brightening). |
| `line-settle-chime` | (see audio) | |

---

## Choreography-specific types

Choreography steps in We-Try phases use a `type` field (defined in `schemas/lesson-runtime.schema.json`):

| Type | Description |
|---|---|
| `system-action` | The system runs an action; same vocabulary as above. |
| `kid-action-expected` | The system pauses for kid input; defines `expectedAction`, target(s), tolerance. |
| `auto-complete-on-pause` | Combined: kid is expected to act, but if they pause >threshold, the system completes. |

### `kid-action-expected` params

Recognized `expectedAction` values:
- `tap` (with `expectedTarget`)
- `tap-frog-to-count`
- `tap-heavier-object`
- `tile-tap` (with `expectedValue` or `expectedTarget`)
- `drag-to-bin` (with `item`, `expectedBin`)
- `drag-fish-to-pad`
- `drag-fish-to-empty-cell`
- `drag-fish-to-right-frame`
- `drag-buddy` (with `expectedZone`)
- `drag-symbol-to-gap` (with `expectedSymbol`)
- `drag-tag-to-object`
- `drag-object-to-pan`
- `drag-clay-to-vertex` / `drag-stick-to-edge`
- `drag-3d-piece-to-target`
- `drag-bin-to-podium`
- `draw-line` (with `fromAnchor`, `toAnchor`)
- `trace-stroke` (with `strokeId`, `scoringMode`, `passThreshold`)

Optional tolerance flags: `tolerantOfMiss`, `tolerantOfTargetSwap`, `wrongReturns`, `wrongPieceReturns`.

---

## How to add a new action

When authoring a new lesson and a needed action isn't in this catalog:

1. **Check first**: search the catalog for a synonym (`fade-out` → `pointer-fade-out` or `scene-fade-out`).
2. **If genuinely new**: add an entry to this file in the appropriate category, with params and a one-line description.
3. **Implement**: the lesson runner team adds the action to the runtime.
4. **Reference**: use the new action in your lesson runtime JSON.

The lesson runner SHOULD fail loudly (visible warning + log) when it encounters an unknown action name, so authors find mismatches early.

---

## Test-fixture requirement

The lesson runner ships with a **smoke-test harness** that loads every lesson JSON and walks every action through a no-op renderer. Catches missing actions, malformed params, and stale schema usage before they hit playtest.

The harness lives at `tests/lesson-runtime-smoke.swift` (TBD path).

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — extracted catalog from all 22 existing K lesson runtime JSONs (including K.G.1b added in the K-review pass). ~95 distinct action names cataloged across 10 categories. | |
