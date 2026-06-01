# Activity Spec — Counting Parade

> Reference vertical-slice spec. The first activity built end-to-end. Other K activities follow this format.

---

## Header

| Field | Value |
|---|---|
| Activity name | Counting Parade |
| Activity slug | `counting-parade` |
| Region | Sanctuary |
| Grade | K |
| Standards | K.CC.1, K.CC.2, K.CC.3, K.CC.4a, K.CC.4b, K.CC.4c, K.CC.5 |
| Status | Draft |
| Last updated | 2026-05-29 |

---

## Setting & Tone

- **Scene** — A sunlit grassy clearing on a winding path through the Sanctuary. The kid's POV looks down the path toward a soft horizon. Wildflowers nod in a gentle breeze.
- **Atmosphere** — Warm afternoon light, soft strings + flute music bed, occasional birdsong. Palette anchors: spring greens, sun-yellow, soft sky-blue.
- **Buddy presence** — The Buddy sits at the kid's side (lower-left), watching the parade. Idle animations: blinks, occasional small movements. Reacts to round completion with a small celebratory hop.
- **Narrator** — Sanctuary warm naturalist voice (per the decisions doc). Soft, encouraging, never condescending.

---

## Standards Coverage

| Standard | What the kid does | Telemetry event | Mastery threshold |
|---|---|---|---|
| **K.CC.1** | Counts by ones (in Long Parade sub-mode, toward 100 across sessions) and by tens (in Tens Parade challenge) | `count.by_ones_completed`, `count.by_tens_completed`, `count.long_parade_target_reached` | 5 successes at Abstract, ≥3 sessions, ≥3 days |
| **K.CC.2** | Counts forward from a given starting number | `count.forward_from_n_completed` (payload: startN, targetCount) | Same |
| **K.CC.3** | Reads the displayed total numeral; writes it in Scribe's Tower link (deferred to that activity) | N/A in this activity (visual exposure only) | N/A here |
| **K.CC.4a** | Pairs each tap with one creature; no double-counting | `count.one_to_one_demonstrated` (payload: cleanTapCount, missedTaps, doubleTaps) | Same |
| **K.CC.4b** | Last tap's spoken total names the count; count is order-independent (kid succeeds regardless of order) | `count.cardinality_demonstrated` | Same |
| **K.CC.4c** | Sees each tap raise the count by exactly 1; the "+1" visual is part of feedback | `count.successor_demonstrated` (implicit in passes) | Same |
| **K.CC.5** | Counts arrangements: line / array / circle / scattered (cap 10 for scattered); counts out a given N | `count.arrangement_completed` (payload: arrangement type, N) | Same |

---

## Concepts: Introduced vs Exercised

Counting Parade is the K-canonical entry point for foundational counting concepts. It introduces three procedural concepts (each with its own MicroLesson) and exercises the rest.

| Concept | Role | Lesson | Notes |
|---|---|---|---|
| **K.CC.4a** (one-to-one correspondence) | Introduces | `specs/lessons/k-cc-4a-one-to-one.md` | The bedrock procedure. First lesson a K kid sees. |
| **K.CC.4b** (cardinality) | Introduces | `specs/lessons/k-cc-4b-cardinality.md` | "The last number you say is how many." Fires on the kid's 2nd Counting Parade round (after K.CC.4a's lesson + first practice). |
| **K.CC.2** (count forward from N) | Introduces | `specs/lessons/k-cc-2-count-forward-from-n.md` | Fires the first time the `count-forward-from-n` sub-mode is entered. |
| **K.CC.1** (count to 100, by tens) | Introduces (via challenge) | `specs/lessons/k-cc-1-count-by-tens.md` | Fires on first entry to the Tens Parade challenge variant. |
| **K.CC.1** (count to 100, by ones) | Exercises (via Long Parade sub-mode) | — (no new lesson; same procedure as K.CC.4a at higher number ranges) | Long Parade extends the by-ones count toward 100 across multiple sessions. No new lesson because the procedure is identical to small-N counting. |
| K.CC.4c (successor: each next is +1) | Exercises | — | Folded into K.CC.4a/4b lessons — successor is implicit in counting. Visual "+1" feedback per tap reinforces it. |
| K.CC.5 (arrangements; count out) | Exercises | — | Variations of K.CC.4a in different visual contexts. No new procedure. |
| K.CC.3 (read/write 0–20) | Exercises | — | Counting Parade exposes numerals visually only. Writing numerals is the canonical purview of **Scribe's Tower**. |

### Registry impact

This declares the following registry assignments (one canonical introducer per concept):
- `K.CC.4a.introducedBy = counting-parade`
- `K.CC.4b.introducedBy = counting-parade`
- `K.CC.2.introducedBy = counting-parade`
- `K.CC.1.introducedBy = counting-parade` (specifically the by-tens part)

If any other K activity spec later claims introducer role for these, the conflict is resolved in the concept registry. Counting Parade should keep these four.

---

## Sub-Modes

### Sub-mode: `count-the-parade` (default)

- **Standards targeted** — K.CC.4a, K.CC.4b, K.CC.4c, K.CC.5
- **What the kid does** — Creatures appear at the path entrance, walk into the visible area, and stop in formation. The kid taps each to count.
- **Pass condition** — Every visible creature tapped exactly once. The round **auto-fires** the "done" state after **3 s of no new taps** once all visible creatures have been counted. The visible Done button remains as an explicit tap shortcut.
- **Fail behavior** — If the kid taps "done" with a miscount (uncounted or double-counted creatures), narrator gently notes the gap and demonstrates one more layer down (see Scaffolding).

### Sub-mode: `count-forward-from-n`

- **Standards targeted** — K.CC.2
- **What the kid does** — A number `N` is announced (e.g., "Start at 7"). The first `N` creatures walk in pre-counted (faint numerals 1–N above them). The pre-counted numerals **fade out ~2 s after the kid taps past N**, leaving the parade visually uncluttered for the continuing count. New creatures join one by one; the kid continues counting from N+1 with taps.
- **Pass condition** — All new creatures tapped, total announced correctly.
- **Fail behavior** — Same as default; narrator re-states the starting N.

### Sub-mode: `count-out-n`

- **Standards targeted** — K.CC.5 (count out a given N)
- **What the kid does** — The Buddy is "hungry." The narrator says "Give the Buddy 6 berries." A basket of berries sits on the path; the kid drags N berries to the Buddy.
- **Pass condition** — Exactly N berries delivered to the Buddy's bowl.
- **Fail behavior** — Buddy looks at the bowl, narrator notes "That's 5 berries — we needed 6." Kid can adjust (drag one more or take one back). After 2 such fails, the system demonstrates by glowing N berries in the basket.

### Sub-mode: `long-parade`

- **Standards targeted** — K.CC.1 (count to 100 by ones); exercises K.CC.4a / 4b / 4c at extended number ranges
- **What the kid does** — Creatures arrive in **waves** along a longer-than-normal path. The kid taps each individually. The running count badge **persists across waves** within a single round. Targets escalate over sessions:
  - First Long Parade round: target **30**.
  - Subsequent sessions: target scales to **50**, then **75**, then **100** as the kid demonstrates competence.
- **Pacing** — Waves of 5–10 creatures arrive over time with brief pauses. Not a rush; the kid can take their time. A typical 30-target round runs ~2 min.
- **Pass condition** — Reaching the target count by individual tapping. Auto-fires "done" after 3 s of stillness once target reached.
- **Endurance** — A "**Stop**" button is available throughout. Stopping early credits the count at the moment of stop as a **partial pass** (proportional coin payout). Kids never get "punished" for choosing to stop a long round.
- **Fail behavior** — Miscount at Done → warm narrator + a slow re-walk of the most recent few creatures with the system counting aloud. Then a new wave continues from the same running total.
- **Lesson** — None required. The procedure is the same one-to-one correspondence and cardinality the kid already learned in K.CC.4a/4b; Long Parade just extends the number range. K.CC.1 by-ones is exercised, not introduced, by this sub-mode.

### Sub-mode: `tens-parade` (challenge variant)

- **Standards targeted** — K.CC.1 (count by tens)
- **What the kid does** — Creatures arrive in groups of 10, in pre-formed clusters. The kid taps each cluster (not each creature) and counts by tens: 10, 20, 30…
- **Pass condition** — All clusters tapped, total announced.
- **Fail behavior** — Same warm-then-demonstrate pattern; demonstration zooms on one cluster to show it's "10 inside this group."

---

## Visual Layout

```
+-------------------------------------------------------+
| [exit]                              [coins: 12]       |
|                                                       |
|                                                       |
|   <path horizon — creatures walk into view from top>  |
|                                                       |
|   <parade formation area — line/array/circle>        |
|                                                       |
|                          [count: 5]                   |
|                                                       |
|                                                       |
|  [Buddy idle]                          [notebook >]   |
|                                                       |
|                  [ done? ]                            |
+-------------------------------------------------------+
```

- **Persistent scene anchors** — sunlit path, sky horizon, gentle background motion (wind in grass, occasional cloud drift). Buddy in lower-left.
- **Interactive elements** — creatures (tappable per Tap-Pick); for `count-out-n`, berries (draggable per Drag-and-Drop snap-to-target onto Buddy bowl).
- **Math notebook tab** — collapsed on right edge. Optional relationship; +1 coin bonus if the kid sketches.
- **HUD elements**:
  - Top-left: exit button (small house icon)
  - Top-right: live coin count
  - Mid-right: live "count" badge that updates per tap (visible after first tap)
  - Bottom-center: "done?" button (appears when ≥1 tap has occurred)

---

## State Machine

```
[idle/intro] → narrator opens with the prompt
   ↓
[creatures_arriving] → parade walks in; counted badge hidden
   ↓
[counting_active] → kid taps; badge appears + ticks per tap
   ↓ (auto-fires after 3 s of stillness with all counted; Done button is an explicit shortcut)
[evaluating] → check tap count vs creature count
   ↓
[round_passed]                 [round_failed]
   ↓                              ↓
[reward + cardinality reveal]  [warm narrator + demonstrate one layer down]
   ↓                              ↓
[next round queued]            [retry same/similar problem at current layer]
                                  ↓
                              [if 2 consecutive fails: demote per scaffolding]
```

**Exit conditions:**
- Kid taps exit button → save progress, return to Hub.
- Daily Quest mode: 5 rounds then auto-exit with quest-completion reward.
- Free Play: continuous until kid exits or 30-min soft cap (gentle prompt to take a break).

---

## Stylus Interactions

| Mechanic | Where used | Local overrides |
|---|---|---|
| **Tap-Pick** | All sub-modes except `count-out-n` for the counting itself | Tap tolerance radius increased to +18 pt (creatures are kid-targeted, more forgiving) |
| **Drag-and-Drop (snap-to-target)** | `count-out-n`: berries → Buddy bowl | Standard snap radius (24 pt) |

No other mechanics used at launch.

---

## Number-Writing Modes

Counting Parade does **not** ask the kid to write numerals directly. The displayed count badge updates automatically from taps. Writing numerals is done in Scribe's Tower (separate activity).

The notebook is available for kids who want to sketch (free-draw only; no recognition zones declared by this activity).

---

## Audio Cues

> **Runtime source**: narration cues live in [`content/strings/en-US/activities/counting-parade.json`](../../../content/strings/en-US/activities/counting-parade.json). The prose below is the design-time reference; the JSON is the authoritative source the TTS pipeline and runtime consume.

### Narrator lines (Sanctuary voice)

#### `count-the-parade` (default)
- **Round start**: "Let's count the {creature_plural} coming up the path."
- **First tap**: (no line; just SFX)
- **Mid-count, hesitation**: "Take your time — count them one by one."
- **Round pass**: "{N}! There are {N} {creature_plural}."
- **Round pass, alt celebratory** (rotate): "Look at that — you counted {N} of them!"
- **Round fail (miscount)**: "Almost. Watch — I'll count them with you."

#### `count-forward-from-n`
- **Round start**: "We have {N} {creature_plural} already. Let's count the new ones from {N}."
- **Round pass**: "Yes — {total} all together."

#### `count-out-n`
- **Round start**: "{Buddy_name} would love {N} berries. Can you give them {N}?"
- **Mid-progress**: (no narration unless hesitation)
- **Round pass**: "Perfect — {N} berries for {Buddy_name}."
- **Round fail (too few)**: "{Buddy_name} has {actual} berries. They asked for {N}. Just {N - actual} more."
- **Round fail (too many)**: "{Buddy_name} has {actual}. They only need {N}. We can put {actual - N} back."

#### `tens-parade` (challenge)
- **Round start**: "Big herd today! They're coming in groups of ten. Let's count by tens."
- **Round pass**: "Beautiful — {N} {creature_plural} in {N/10} groups."

### SFX

| Event | SFX |
|---|---|
| Creature walking in | Soft footstep + species-specific cue (whinny for unicorn, chirp for dragon, etc.) |
| Tap success | Sparkle + soft chime (rising in pitch with each successive tap up to 10, then resets) |
| Done button tap | Confirmation chord |
| Round pass | Warm "Sanctuary chime" stinger |
| Round fail (gentle) | Soft, sad-but-warm chord (never harsh) |
| Demonstrate-down animation | Gentle "show" cue |
| Drag berry (count-out-n) | Light "whoosh"; on-snap to bowl: soft "plop" |

### Music

- Soft strings + flute loop, ~90 BPM, 60-second loop.
- Mild intensity bump during the parade arrival; settles during counting.
- Round-pass stinger plays *over* the bed without ducking.

---

## Scaffolding Triggers

The system uses `ScaffoldQuery` per round (see `adaptive-scaffolding.md`) to get a layer. Within-round behaviors:

| Trigger | Response |
|---|---|
| **Hesitation: 5 s of no taps after counting starts** | Glow the next-to-count creature (nearest to the last tapped, or the first if none tapped yet) for 1.5 s |
| **Hesitation: 10 s of no taps** | Narrator: "Tap each {creature} once — you can start anywhere." |
| **Double-tap on same creature** | Single count; no visual error, but the second tap is logged for telemetry. If repeated 3× in a round, narrator: "Each {creature} just gets one tap." |
| **Kid taps "done" early** (uncounted creatures remain) | Narrator: "I see {uncounted} more {creature_plural} that need counting." Highlight uncounted. |
| **Kid taps "done" with miscount** | Round fails; warm demonstration: parade re-walks slowly, system counts each aloud with the kid's earlier tapped-positions still visible. |
| **2 consecutive round failures at current arrangement type** | Demote arrangement: scattered → array → circle → line. Stay at this simpler arrangement until 2 successes. |
| **2 consecutive round failures at current count range** | Reduce count: e.g., from up-to-10 to up-to-5. |

---

## CPA Progression

| Layer | What it looks like in Counting Parade |
|---|---|
| **Concrete** | Counters are visible creatures; tapped ones stay visually distinct (sparkle + slight tint). Count badge shows each number large as it grows. Cardinality announced verbally on completion. |
| **Pictorial** | Same scene but the count badge displays both **numeral** and **tally marks** alongside. Reinforces "this many" → "the number." |
| **Abstract** | Same scene, only the **numeral** in the count badge (no tally). Cardinality still announced verbally. |

- **Default starting layer (K, fresh kid)** — Concrete.
- **Promotion conditions** — 3 consecutive passes at the current layer.
- **Demotion conditions** — 2 consecutive failures at the current layer.

### Species variety by layer

- **Concrete and low Pictorial** — **single species per round** (all unicorns, or all goats). Reduces visual cognitive load so the kid can focus on counting.
- **Abstract and challenge mode** — **mixed species allowed**. Ensures the kid's count isn't anchored to recognizing species — true cardinality regardless of the creatures involved.

---

## Reward Emissions

| Event | Trigger | Reward (per `reward-economy.md`) |
|---|---|---|
| `round.passed` | Round passes | +2 coins (base) |
| `round.notebook_bonus` | Notebook had ≥3 strokes during round | +1 coin |
| `streak.session_3` / `_5` / `_10` | Streak thresholds in one session | Per shared spec |
| `milestone.problems_25` / `_100` | Lifetime in this activity | Per shared spec |
| `mastery.standard_practicing` / `_mastered` | Adaptive scaffolding emits | Per shared spec |
| `challenge.completed` | Tens Parade round passes | Per shared spec |

### Activity-specific collectibles
- **Sanctuary Creature Cards** — one card per species the kid encounters during Counting Parade. A complete set (24 species at launch) earns a **Hub trophy: the Sanctuary Atlas**.
- Drop rate: ~1 in 5 round-pass events, weighted toward unseen cards.
- This is in addition to coin rewards, not instead.

---

## Telemetry Events

(Beyond the shared `scaffold.*` and `economy.*` events.)

| Event | Payload |
|---|---|
| `counting_parade.round_started` | `subMode`, `arrangement`, `targetCount`, `presentationLayer` |
| `counting_parade.tap_logged` | `creatureId`, `tapPosition`, `roundElapsedMs`, `isDoubleTap`, `isMissedTap` |
| `counting_parade.done_pressed` | `tapsRegistered`, `creaturesPresent`, `correct` |
| `counting_parade.round_completed` | `success`, `subMode`, `attemptsThisRound`, `hintsFired` |
| `counting_parade.collectible_dropped` | `cardId`, `setProgress` |

These feed both the standards-mastery system and the engagement dashboards.

---

## Challenge Variant

**Tens Parade** (Number Range Stretch, see `Challenge Modes` in the main plan).

- **What changes** — Creatures arrive in pre-formed groups of 10. Kid counts by tens up to 100. Counts target K.CC.1 specifically.
- **Entry point** — A "Tens Parade!" banner appears on Counting Parade's tile in the Sanctuary **1× per day at launch**. Frequency will be tuned post-launch based on engagement data (kids who engage with challenges may see them more often; kids who skip them may see them less, with a floor).
- **Reward bump** — Challenge chest on completion (rare Sanctuary creature card guaranteed; rest per `reward-economy.md`).

---

## Edge Cases & Error Handling

- **Stylus disconnect mid-round** — round pauses (creatures freeze); a small "reconnect your Pencil" prompt appears; resume on reconnect with state preserved.
- **App backgrounded mid-round** — pause and persist round state. On resume within 5 min, restore exactly. Beyond 5 min, discard round and return to activity entry.
- **Audio muted** — round still completes; visual count badge and animations carry the full information. Cardinality is shown numerically *and* spelled out at round-pass.
- **Kid mashes the screen rapidly** — debouncing in Tap-Pick (200 ms per object) prevents double-count. Logged for telemetry; if a kid does this >10× in a round, the system pauses briefly and the narrator gently restates the prompt.
- **Multi-Pencil scenarios** — only the most recent Pencil's input is honored. Switching mid-round is allowed.
- **Kid hides the count badge by tapping** — the count badge isn't tappable. Not an issue.
- **Buddy bowl already has berries** (count-out-n) — bowl resets at round start, so prior berries don't carry over.

---

## Open Questions

*(All initial open questions resolved 2026-05-29. New questions surfacing during implementation can be added here.)*

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. The decomposition (which boxes exist, what they contain) is identical across phases — only the framework names differ.


```
CountingParadeView
├── SceneBackgroundLayer (parallax path + sky)
├── BuddyView (idle behaviors)
├── ParadeView (creature spawning + animation)
│    └── TapCountableScene (uses shared TapCountableScene component)
├── CountBadgeView (live count + cardinality reveal)
├── DoneButtonView (visible after first tap)
├── HUDView (coin count, exit)
└── NotebookTab (shared math-notebook component, collapsed by default)
```

### Reusable opportunities surfaced by this spec

- `Parade` animation logic could be reused for any "X items walk into view" activity.
- The "demonstrate-down" pattern (slow re-walk + audio count) generalizes — should live in the shared scaffolding library.
- `CountBadgeView` is generic; reuse anywhere a live tap-count badge is needed.

### Performance considerations

- Up to 30 creatures on screen in the challenge variant (Tens Parade). Use sprite atlases; do not allocate views per creature.
- Particle effects on tap (sparkles) should pool, not allocate.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-29 | Initial draft (vertical-slice reference) | |
| 2026-05-29 | Locked open questions: Done auto-fires after 3 s; pre-counted numerals fade ~2 s after kid passes N; single-species rounds at Concrete/low-Pictorial layers (mixed at Abstract/challenge); challenge frequency tunes post-launch from engagement data | |
| 2026-05-29 | Added Concepts: Introduced vs Exercised section. Counting Parade introduces K.CC.4a, K.CC.4b, K.CC.2, and (via challenge) K.CC.1 by-tens; exercises K.CC.4c, K.CC.5, K.CC.3 | |
| 2026-05-29 | All four MicroLessons authored and linked (K.CC.4a, K.CC.4b, K.CC.2, K.CC.1 by-tens). Activity is now lesson-complete and ready-to-build | |
| 2026-05-30 | Renamed mechanic Tap-Count → Tap-Pick to match `stylus-mechanics.md`. Added `long-parade` sub-mode (exercises K.CC.1 by-ones toward 100 across sessions; no new lesson — same procedure as K.CC.4a at higher number ranges). Closes the coverage gap for K.CC.1 by-ones | |
