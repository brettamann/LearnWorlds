# K Activity Patterns

> Cross-activity conventions specific to the **Sanctuary (K)** region. Stated once here so future K activity specs can reference rather than re-state. Some patterns generalize to 1st (Wundletown) and 2nd (Mathopolis) and may be promoted to a broader `activity-patterns.md` when those regions get their first specs.

References: `specs/shared/adaptive-scaffolding.md`, `specs/shared/micro-lessons.md`, `specs/shared/math-notebook.md`, `specs/shared/reward-economy.md`, `specs/shared/stylus-mechanics.md`.

---

## Scope

This file captures patterns observed across at least two K activity specs (currently Counting Parade and Ten-Frame Pond) that should be **consistent across all K activities**. New K activity specs declare conformance to these patterns and only specify deviations.

Patterns that already live in shared specs (CPA thresholds, hesitation timings, mastery rules) are **not** restated here — they're cross-grade and live in their original specs. This file is the K-specific layer above those.

---

## Voice & Narration

- **One narrator across the region.** All Sanctuary activities use the **warm naturalist** voice. No villager-of-the-week voices.
- **Audio is primary; text is supplemental.** K kids are pre-literate or early-readers. Every instruction, prompt, and feedback line is voiced. On-screen text exists only as labels and is never required for play.
- **Real math language alongside accessible analogies.** "The last number is *how many*" — not "the magic number." Cardinality, decomposition, ten — these are real words and we use them. Analogies live in setting metaphors (a pond, fawns) not in math vocabulary.
- **Rotation across celebratory lines.** Round-pass narration draws from 2–4 alternative phrasings to avoid monotony. Activity specs list the alternatives.
- **No fake stakes.** "Almost — let's try again" is the canonical fail line. Never "Oh no!" or "Try harder!"

---

## Buddy Presence

The Math Buddy is part of every Sanctuary activity's scene. Conventions:

- **Position**: lower-left of the playfield, on a small scene-appropriate perch (mossy stone for Ten-Frame Pond, grassy mound for Counting Parade, etc.).
- **Idle behaviors**: blinks, occasional small movements (paw dip, head tilt, looking around). Idle every ~6–12 seconds.
- **Round-pass reaction**: small celebratory hop or wiggle synchronized with the chime stinger.
- **Round-fail reaction**: empathetic tilt of head; no sad sounds.
- **Hesitation reaction (after kid is idle ~10 s)**: looks toward the action area (cues kid attention) but does *not* perform the kid's action.
- **The Buddy never speaks in scenes**; it only "talks" in the Hub (and in lessons, when explicitly scripted). The narrator does all in-activity verbalization.

---

## Single Species per Round (Counting Activities, at Concrete)

K's **counting / quantity** activities minimize visual cognitive load at the Concrete layer so the kid focuses on cardinality, not on species recognition:

- **Single species per round** at Concrete and low Pictorial in counting-based activities (Counting Parade, Storyteller's Pond, Fluency Within 5). All fawns, all baby gryphons, all koi.
- **Mixed species** are allowed at Abstract and in challenge variants — ensures cardinality isn't anchored to species recognition.
- **Scope**: this rule applies to **counting / quantity** activities where the kid is producing a count. Activities where shapes / objects ARE the thing being identified (Shape Garden, Care Pantry) intentionally show variety per round — the variety is the point of the activity, not a distraction.
- Sub-modes that **require a visible split** (e.g., Ten-Frame Pond's `two-ways` decomposition) override this rule by using two species: see "Decomposition Coloring" below.

---

## Decomposition Coloring by CPA Layer

When an activity asks the kid to **see two distinct groups** within a count (decomposition, sums-of-10, two-frame teens), the visual treatment of the two groups varies by CPA layer:

| Layer | Treatment |
|---|---|
| **Concrete** | Two different species (e.g., 3 blue koi + 2 yellow tetras). The kid *sees* the decomposition. |
| **Pictorial** | Same species, but a **visible divider** (subtle line, color tint, or gap) separates the groups. |
| **Abstract** | Same species, no divider. The kid sees the split mentally — or writes the equation in the notebook. |

This is the K convention for "visual scaffolds drop as the kid graduates" applied to decomposition. Originated in Ten-Frame Pond's `two-ways` sub-mode.

---

## Sub-Mode Complexity Demotion (Staggered)

K activities with multiple progressively-complex sub-modes (e.g., Ten-Frame Pond's `fill-to-target` → `two-ways` → `make-ten` → `ten-plus-n`) participate in the **staggered demotion** rule defined in `adaptive-scaffolding.md`.

**How it works:**
- **2 consecutive failures** with `currentLayer > Concrete` → demote **CPA layer** first (smaller change; kid sees more concrete representation).
- **2 more consecutive failures** (now at Concrete) → demote **sub-mode** to the next-simpler one; CPA layer resets to the activity's default starting layer (typically Concrete for K).
- **2 successes at the demoted sub-mode** → the activity may promote back through its session-design logic (sub-mode promotion isn't automatic; activities choose per-round whether to step back up).

Demotion is invisible to the kid (no UI message); the next round just looks slightly simpler. The principle is **prefer demoting to skipping** — kids always get another problem, just easier.

---

## Done-Button Auto-Fire (3 s Stillness Rule)

K activities where the kid decides "I'm done" by behavior rather than by explicit signal:

- **Auto-fire**: when the kid has reached the round's target state and shows **3 s of no new interactions**, the system auto-fires the "Done" state and proceeds to round evaluation.
- **Done button**: still visible as an explicit tap shortcut for kids who want to confirm.
- This rule was locked in Counting Parade and has been replicated in Ten-Frame Pond. New K activities should default to this unless they have a structural reason not to.

---

## HUD Layout Convention (K)

K activities share a standard HUD layout to build "I know where everything is" intuition:

```
+--------------------------------------------------------+
| [exit]                              [coins: count]     |
|                                                        |
|                                                        |
|                <activity playfield>                    |
|                                                        |
|                                                        |
|             [count badge / progress]                   |
|                                                        |
|  [Buddy idle]                          [notebook >]    |
|                                                        |
|                  [ done? ]                             |
+--------------------------------------------------------+
```

- **Top-left**: exit (small house icon) — returns to Hub.
- **Top-right**: live coin count.
- **Center-below-playfield**: the activity's primary progress indicator (count badge, fill ratio, etc.).
- **Lower-left**: Buddy.
- **Lower-right**: notebook tab (collapsed by default).
- **Bottom-center**: Done button (appears once the kid has begun the round).

Deviations are allowed when a specific activity needs them (e.g., Build-a-Habitat's two-phase structure may need different bottom-center treatment). Spec them explicitly.

---

## Count Badge Rendering by CPA Layer

When a K activity displays a "current count" badge (most do), the badge's content varies by CPA layer:

| Layer | Badge content |
|---|---|
| **Concrete** | Large numeral + dot pattern matching the count (e.g., "5" with 5 dots arranged in a ten-frame pattern) |
| **Pictorial** | Large numeral only (no dots) |
| **Abstract** | Numeral + the relevant equation form (e.g., "3 + 2 = 5") when the round has decomposition; just the numeral when it doesn't |

The badge always announces cardinality verbally at round-pass regardless of layer.

---

## Round-Pass Celebration Pattern

Every K activity's successful round ends with a consistent micro-celebration:

1. **Cardinality announcement** (audio): narrator says the result in full sentence ("Five! There are five fawns").
2. **Visual reward**: the round's result element (count badge, ten pearl, completed habitat) pulses briefly with a soft halo.
3. **Buddy hop** synchronized with the chime stinger.
4. **Sanctuary chime stinger** (~1 s): warm, plays over the music bed without ducking.
5. **Coin payout fly-up**: small coin icons fly from the result element toward the top-right coin count (per `reward-economy.md`).

Total celebration duration: ~2 s. The next round queues immediately after.

---

## Failure Presentation Pattern

Every K activity's failed round follows the universal "warm acknowledgment + demonstrate one layer down + retry" pattern from `adaptive-scaffolding.md`. K-specific application:

- **Warm narrator line** (varies per activity, drawn from a rotation of 2–3 alternatives).
- **Demonstration** is an animated walk-through of the correct solution with the glowing pointer used in MicroLessons. The kid watches; no input is taken during the demonstration.
- **Retry** delivers a *new* problem of the same type at the kid's current layer (not the same problem to avoid memorize-the-answer).
- Two consecutive failures trigger the CPA demote per `adaptive-scaffolding.md`.

The Buddy's empathetic-tilt reaction happens during the warm narrator line, not during the demonstration.

---

## Math Notebook Usage in K

K activities typically use the notebook in the **Optional** relationship (per `math-notebook.md`):

- Notebook is **collapsed by default**.
- A small notebook hint icon may appear (per-activity choice).
- Non-trivial notebook use earns +1 coin bonus per round (per `reward-economy.md`).
- The notebook is not used for digit recognition in K at launch — K activities don't ask the kid to write a numeral as the answer. (Number Tracing Studio / Scribe's Tower is the K-canonical place for writing numerals, and uses Mode 1 Trace per `number-writing-modes.md`.)

Free-draw scratching in the notebook is the typical K use case: kids drawing fish or stars as they think. This counts toward the notebook bonus.

---

## Region Narrator Convention

- **Every K activity uses the Sanctuary warm naturalist narrator.** No exceptions.
- The narrator's voice carries from activity to activity, from lessons to free play, building familiarity.
- The narrator does not appear visually — they're an unseen guide. (Compare with 1st-grade Wundletown wizards who may visually appear in scenes as part of the comedic premise.)

---

## Music Variation Per Activity (added 2026-05-30)

While the Sanctuary palette unifies K audio, **every activity must have a distinctive instrumental signature** so kids can hear-recognize where they are without looking. The K review flagged "Sanctuary palette across 11 activities risks sameness" as a real concern; this section defines the mitigation.

### Required differentiation axes

Every K activity's music bed must vary from every other K activity on **at least two** of these axes:

1. **Lead instrument** — what carries the melody (flute, harp, strings, brush percussion, fingerpicked guitar, light brass, ocarina, wind chimes, plucked koto, etc.).
2. **Tempo** — at least ±10 BPM apart from sibling activities.
3. **Rhythmic texture** — flowing legato vs. measured staccato vs. percussion-forward vs. ambient sustain.
4. **Decorative element** — characteristic ear-print (the "industrious quill scratching" in Scribe's Tower; the "frog/cricket bed" in Storyteller's Pond; etc.).

### K activity signatures (locked targets for audio team)

| Activity | Lead | BPM | Texture | Ear-print |
|---|---|---|---|---|
| Counting Parade | Soft strings + flute | 90 | Flowing pastoral | Distant birdsong |
| Ten-Frame Pond | Gentle strings + harp | 85 | Rippling legato | Water plip, distant lap |
| Scribe's Tower | Strings + harp + soft brass | 75 | Contemplative slow | **Quill-scratching** texture under bed |
| Storyteller's Pond | Strings + harp + frog/cricket | 80 | Storyteller-slow | **Frog and cricket** chorus |
| Shape Garden | Gentle strings + harp | 85 | Mid-morning calm | Distant bee buzz around hexagon flowers |
| Where's Buddy? | Strings + harp + **wind chime** | 80 | Searching, unhurried | **Wind chime tinkle** near cottage |
| Build-a-Habitat | Strings + flute + **soft percussion** | 95 | Creative anticipation | Distant **woodwork tap** |
| Care Pantry | Strings + **tambourine + brush percussion** | 95 | **Industrious tidy** | Light wood-tapping |
| Picnic Baskets | Strings + **fingerpicked guitar** + flute | 80 | Picnic-warmth | Occasional wind chime, plucked guitar |
| Caretaker's Bench | Strings + brush percussion + **wood-tapping** | 85 | Workshop-quiet | **Lantern-creak** ambient cue |
| Fluency Within 5 | **Light flute + soft brush + finger-snap** | 100 (110 in Speed Run) | Upbeat practice | Snap-percussion accent on combo |

Confirm with audio direction; tune in playtest. The rule is that no two K activities should sound interchangeable in the first 5 seconds.

### Why this matters

K kids spend many hours per week in these activities over their K year. Hearing the same instrumental texture across 11 activities flattens the imaginative landscape — the kid stops noticing the music, which removes one of the strongest emotional anchors of the experience.

The narrator stays the same; the **scoring** carries the variation.

---

## Concept-to-Region Mapping

For canonical-introducer purposes (per `micro-lessons.md`), **all K concepts are introduced in the Sanctuary**. There is no cross-region introduction of a K concept. If a kid first encounters a K concept while playing a portal world (e.g., the kid jumped into a portal that uses K-level math), the lesson still plays in **Sanctuary style** — the canonical region is preserved regardless of where the kid is when the lesson fires (per the `micro-lessons.md` "lesson identity is stable" rule).

---

## Visible Narrator Character (opt-in)

Most K activities use the Sanctuary narrator as an **unseen** voice. Some activities embody the narrator as a **scene character** — first introduced by Storyteller's Pond (the Storyteller turtle on a lectern).

**When to embody the narrator:**
- The activity is **story-driven** and a narrator's presence is part of the experience (storytelling, briefing, reading).
- The character can add charm without distracting from the math.
- The character has a clear visual presence and idle behaviors that don't compete with the playfield.

**When to keep the narrator unseen:**
- The activity is primarily procedural (counting, sorting, tracing).
- A character would compete with the activity's central interactive element.

**Authoring requirements when embodying the narrator:**
- Mouth-sync animation synced to narration.
- A consistent character design within the activity (no character swap mid-round).
- The character's identity is region-flavored (Sanctuary turtle, future Wundletown chatty raven, Mathopolis news anchor, etc.).
- Voice is still the standard region narrator; the character just gives the voice a face.

**Currently used by:** Storyteller's Pond (Sanctuary turtle).

---

## Two-Phase Round Structure (opt-in)

Most K activities use sub-modes (alternatives across rounds). Some activities have **phases** — sequential parts of every round. First introduced by Build-a-Habitat (Phase 1: Sticks & Clay → Phase 2: Raise the Habitat).

**Phases vs sub-modes:**
- **Sub-modes** are *alternatives* — different round shapes the activity might present (e.g., Counting Parade's `count-the-parade`, `count-forward-from-n`, `count-out-n`).
- **Phases** are *sequential* — every round runs Phase 1, then Phase 2 (then maybe Phase 3) in order.
- Activities can have both. Build-a-Habitat has sub-modes (`simple-shelter`, `creature-home`, etc.) AND phases (Sticks & Clay → Raise the Habitat).

**When phases are appropriate:**
- The activity has a natural sequential structure (build, then test; partition, then distribute).
- Each phase contributes meaningfully to the round's completion.
- The phases together fit within a reasonable round duration (~3 minutes).

**Authoring requirements:**
- State machine explicitly names each phase as a state.
- Auto-fire transitions between phases (kid doesn't need to manually advance).
- Per-phase scaffolding triggers (each phase can have its own hesitation rules).
- Per-phase failure handling (a Phase 1 failure auto-completes to Phase 2; doesn't fail the whole round).

**Currently used by:** Build-a-Habitat (Phase 1 K.G.5 → Phase 2 K.G.6).

---

## Replay-Content Button (opt-in)

Activities with **time-bounded content the kid might miss** (a narrated story, a long instruction, a multi-step prompt) should offer a **Replay** button that re-plays the content without restarting the round.

**When to include a Replay button:**
- The round prompt is delivered as a one-time playback (story, animation, multi-step instruction).
- The kid might not catch it on the first listen (attention drift, audio glitch, slow processing).
- Restarting the entire round would feel like punishment.

**When NOT to include:**
- The prompt is always visible (text, badge, persistent visual).
- Replay would skip the math (e.g., re-revealing the answer mid-round).

**Authoring requirements:**
- Replay button is always visible once the content has played at least once.
- Replay events are logged for telemetry; high replay counts may signal the kid needs more comprehension support.
- Replay doesn't reset round state (the answer phase is still pending after replay).

**Currently used by:** Storyteller's Pond (replay the story).

---

## Permanent Fixture Rewards (opt-in)

Some activities produce **outputs that persist in the Hub view** between sessions — the kid's accumulated creations populate their world. First introduced by Build-a-Habitat (the Sanctuary Habitat Map fills with the kid's built habitats over time).

See `reward-economy.md` for the full Permanent Fixture reward type spec. K-specific guidance:

- Fixtures earned in K activities populate **Hub displays in the Sanctuary region** of the Hub view.
- Each fixture has a region-appropriate aesthetic (Sanctuary fixtures look like outdoor builds; future Wundletown fixtures would look like magical contraptions).
- Hub displays support **completion trophies** (e.g., complete the Habitat Map for a Sanctuary Keeper's Map trophy).

**Currently used by:** Build-a-Habitat (built habitats accumulate in the Sanctuary Habitat Map).

---

## Per-Instance Mastery (opt-in)

Most K concepts use **concept-wide mastery** — one mastery state per concept per kid. Some concepts use **per-instance mastery** — multiple mastery states per concept, one per declared instance key.

See `adaptive-scaffolding.md` for the full Mastery Granularity spec. K-specific examples:

- **K.CC.3** (write numerals 0–20) — 21 instances, one per numeral. The kid earns a stamp per numeral mastered; concept-wide mastery rolls up when all 21 are mastered.
- **K.OA.5** (fluency within 5) — would naturally use per-fact instances (e.g., `2+3`, `4+1`, etc.) if the activity opts in.

**When per-instance is appropriate:**
- The concept has a small finite set of sub-elements (≤ 50 typically).
- Each sub-element has independent learning trajectories (some easy, some hard).
- The dashboard benefits from per-sub-element visibility.

**Currently used by:** Scribe's Tower (per-numeral mastery for K.CC.3).

---

## Bar Model Representation (used in word-problem activities)

Word-problem activities use the **bar model** as a K-friendly visual representation of math structure. First introduced by Storyteller's Pond.

See `bar-model.md` for the full Bar Model component spec. K-specific guidance:

- Bar models appear at Concrete and Pictorial CPA layers in word-problem activities.
- Colors are accessibility-safe and consistent across activities.
- Bar lengths correspond proportionally to counts.

**Currently used by:** Storyteller's Pond (K.OA.1 / K.OA.2 word problems).

---

## What's *not* in this file (and where to find it)

- **CPA layer thresholds (3 promote / 2 demote)** — `adaptive-scaffolding.md`
- **MicroLesson template (I-Show / We-Try / You-Do)** — `micro-lessons.md`
- **Stylus mechanic tolerances** — `stylus-mechanics.md`
- **Reward emission events and chest tiers** — `reward-economy.md`
- **First-encounter forgiveness (3 attempts in You-Do)** — `micro-lessons.md`
- **Hesitation hint timings (5 s visual hint, 10 s narrator prompt)** — `adaptive-scaffolding.md` (referenced from `stylus-mechanics.md` global behaviors)

---

## Open Questions

- **Coin payout fly-up animation** — currently described as "small coin icons fly from the result element toward the top-right coin count." Confirm visual style with art; specify duration and easing.
- **Buddy's pre-launch personality** — the Buddy is part-customizable. Some K activities reference "the Buddy" generically; specs should not depend on the Buddy looking a specific way. Confirm that idle and reaction animations are parametric over the parts library.
- **Notebook hint icon visibility** — should it appear by default in K (encouraging notebook use) or only in activities with a more obvious notebook use case? Suggest default-off; activities that want it declare it.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — extracted patterns from Counting Parade and Ten-Frame Pond | |
| 2026-05-30 | Sub-mode demotion now references the staggered rule in `adaptive-scaffolding.md` (CPA layer demotes first, then sub-mode); single-species rule scoped explicitly to counting-based activities so Shape Garden and similar don't read as violations | |
| 2026-05-30 | Added 6 new K patterns extracted from activities 4–7: **Visible Narrator Character** (Storyteller's Pond turtle), **Two-Phase Round Structure** (Build-a-Habitat), **Replay-Content Button** (Storyteller's Pond), **Permanent Fixture Rewards** (Build-a-Habitat → Sanctuary Habitat Map), **Per-Instance Mastery** (Scribe's Tower per-numeral), **Bar Model Representation** (Storyteller's Pond word problems) | |
| 2026-05-30 | Added **Music Variation Per Activity** section with a locked signature table for all 11 K activities (lead instrument / BPM / texture / ear-print). Closes the K-review concern that Sanctuary palette risked sameness across activities | |
