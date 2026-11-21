# Lesson Demonstration Pattern

> How iShow phases visualise "the system is touching this target for you" — the demo hand pointer, the glitter impact, and how they coordinate with the actor's response (a fawn hopping, a frog jumping into a lily pad, etc.). This is the visual grammar every iShow phase should follow so kids learn the language of the game in one place and apply it everywhere.

References: `specs/shared/lesson-runtime-actions.md`, `specs/shared/adaptive-scaffolding.md` (the "I-Show" section), `data/lesson-runtime/*.json`.

---

## The grammar (read the demo like a sentence)

A demonstration of "the system touches X" reads as four coordinated beats:

1. **Approach** — a glide pose. The hand pointer fades in near the actor but offset to one side ("left-of-fawn-1"). Tells the kid where the next touch is coming.
2. **Touch** — the poke. The hand glides to centred-on-actor and thrusts down a few px, then recovers. The pointer art doesn't switch sprites for the "impact" — instead, a **GlitterBurst** fires from the actor.
3. **Impact** — the glitter. A short radial star/sparkle burst originating from the actor's centre. Punctuates the touch so the kid sees it as a single moment.
4. **Response** — the actor reacts. The fawn hops. The frog leaps onto a lily pad. The shape rotates. Whatever the activity needs.

Every one of these beats should be present in every demo so the pattern is unmistakable. Drop any one and the kid loses the read.

---

## Why one hand sprite (no "with-rays" variant)

Earlier drafts considered a second "hand with rays" version of the sprite that the pointer would briefly switch to at impact. We dropped that approach in favour of the GlitterBurst because:

- **Reusable** — GlitterBurst works for any actor (fawns, frogs, fruit, gems, etc.) without sprite-pair authoring per actor.
- **Cleaner read** — the glitter is *adjacent* to the actor, not pinned to the pointer. Kids see "the actor was touched," not "the pointer changed."
- **One asset** — `assets/shared/ui/hand_pointer.png` is the only sprite we ship for this purpose.

When commissioning new demo art, **do not** ask for a second "with-rays" variant. If a future activity wants a different impact effect (e.g., a water-splash for Ten-Frame Pond), author it as a separate burst widget that consumes the same trigger — not as a pointer sprite variant.

---

## Engine pieces

| Widget | File | Role |
|---|---|---|
| `LessonHandPointer` | `app/lib/ui/lesson/lesson_hand_pointer.dart` | Glides between targets (AnimatedPositioned), pokes on demand (AnimationController). Visibility, target, and pokeKey are owned by the LessonScreen state. |
| `GlitterBurst` | `app/lib/ui/common/glitter_burst.dart` | One-shot radial star burst, self-running. Spawn a fresh instance per impact by keying it on a generation counter. |
| `AnimatedFawn` (or actor-equivalent) | `app/lib/ui/characters/animated_fawn.dart` | The actor's "I got touched" response. Flipping `active` from false→true plays a squash/stretch/hop. |
| `_LessonStage` in `LessonScreen` | `app/lib/ui/screens/lesson_screen.dart` | Owns the Stack, computes actor positions via LayoutBuilder, derives the hand's target Offset from `_pointerTarget` + `_handAtTarget`. |

---

## How the lesson-runtime JSON drives it

`animationSteps` in an iShow phase already describe the timeline. The renderer maps them like this:

| `animationStep.action` | What the renderer does |
|---|---|
| `pointer-appear` (`position: "left-of-fawn-N"`) | Hand fades in offset-left of actor N. `_pointerVisible = true`, `_handAtTarget = false`. |
| `pointer-touch` (`target: "fawn-N"`) | Hand glides to centred over actor N and pokes. `_handAtTarget = true`, `_pokeCounter++`. |
| `sparkle` (`target: "fawn-N"`) | GlitterBurst spawns at actor N's centre. Actor's `active` flips on, so the squash/stretch/hop animation also fires here. `_burstCounters[N]++`. |
| `pointer-fade-out` | Hand fades out. `_pointerVisible = false`. |
| `pointer-auto-touch-sequence` (`targets: [...]`, `spacingSec: …`) | Render schedules a touch+sparkle pair per target with the given spacing. (TODO: not yet implemented; lands when a weTry phase needs it.) |

Spec authors don't have to think about hand movement directly — they write `pointer-touch` at the time they want the impact, and the renderer animates the glide + poke + glitter + actor response automatically.

---

## Adding the pattern to a new activity

1. **Actor widget** — author or reuse an `AnimatedFoo` that exposes a `bool active` flipping false→true to play its response animation.
2. **Lesson stage** — build a `_LessonStage` analogue that:
   - Uses `LayoutBuilder` to compute each actor's centre in stack-local coordinates.
   - Lays out the actors and `LessonHandPointer` in the same `Stack`.
   - Spawns `GlitterBurst` instances keyed on `burstCounters[i]` per actor.
3. **State machine** — reuse the `pointer-appear` / `pointer-touch` / `sparkle` / `pointer-fade-out` cases from the existing `_applyAnimationStep` switch. New action types should be added as new cases, not folded into existing ones, so authoring stays composable.
4. **JSON timing** — leave at least 0.5 s between `pointer-appear` and `pointer-touch` so the kid sees the approach pose; leave ≥ 2 s between successive `pointer-touch` events so the previous glitter has time to dissipate.

---

## Tuning knobs

These constants live alongside their widgets and are safe to tweak per-activity. Reach for them before authoring a new sprite or burst widget:

- `LessonHandPointer.glideDuration` — default 650 ms. Shorten for snappier demos, lengthen if the hand has to travel a long way and the glide looks rushed.
- `LessonHandPointer.pokeDuration` — default 220 ms. Keep tight; the kid's brain registers the impact more clearly with a quick poke.
- `GlitterBurst.particleCount` / `maxRadius` / `duration` — defaults 8 / 80 / 750 ms. More particles or larger radius for "big deal" moments (e.g. a final mastery beat).
- `AnimatedFawn.hopHeight` — 50 px default. Per-actor sizing: a frog hops higher than a shape rotates.

---

## Things NOT to do

- **Don't switch the pointer sprite for impact.** Use a burst widget. (See "Why one hand sprite" above.)
- **Don't fire `pointer-touch` and `sparkle` from independent timer callbacks at slightly different times.** They should be on the same `at:` mark in the JSON so the poke, glitter, and actor hop visually align. Compositors notice the desync.
- **Don't animate the hand to *every* actor on screen.** Demonstration is a narrow window — show the pattern on a few actors, then let the kid try.
- **Don't ship a second hand-pointer asset.** If someone proposes one, redirect them to this doc.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-06-06 | Initial draft — hand pointer + glitter burst pattern, replacing the considered "with rays" sprite variant. | |
| 2026-09-06 | **A lesson has to show the activity it introduces, and two of them showed a different one.** `lesson_screen` picks its iShow scene from `conceptId` and falls through to `_FawnStage` - three fawns in a meadow - for anything it does not recognise. K.G.1 and K.G.1b, the two lessons that introduce Where's Buddy, matched nothing: the lessons whose entire subject is *where the Buddy is* drew three deer and no Buddy at all. Their scenes had been fully authored the whole time (five landmarks, a Buddy centre stage, and steps moving him above the fountain, behind the tree and next to the mushroom) and were read by nothing. This is the hardest class of bug in the app to notice, and the reason `lesson_scene_test.dart` now exists: the default renders something *plausible*, so nothing throws and nothing is blank, and the lesson is the phase an adult taps through to get to the game - the least-watched screen in the app by the person who could report it, and the most-watched by the person who cannot. It was found by rendering the lesson to a PNG and looking at it. `ClearingLessonStage` draws it properly now, importing the landmark sprite, the Buddy size, and the (landmark + position word) → spot arithmetic from the same places the runner uses, because a lesson tree that is not the round's tree introduces nothing. The two Build-a-Habitat lessons are still on the fallback; the test carries them as a named ledger that can only shrink, and fails if one is dropped from it *or* left on it after being fixed. |  |
| 2026-09-06 | **The fallback ledger is empty: both Build-a-Habitat lessons build the shelter now.** K.G.5 and K.G.6 were the last two lessons drawing three fawns in a meadow for a scene that is not fawns. `HabitatLessonStage` lays the frame piece by piece - clay at each corner, sticks along each side, the ghost halo on whatever is not down yet - and K.G.6 opens on that finished frame, raises the cube onto it, and walks the resident fawn in, which is the only thing on either screen that says why the building mattered. Three things now share `HabitatFrameLayout`: the picker card, the lesson, and (through the blueprint) the round. That extraction is the point - a lesson triangle that is not the round's triangle introduces the wrong thing - and `habitat_frame_layout_test.dart` guards it, because a shared helper with no test is a single point of drift rather than a single source of truth. It pins the piece proportions to the runner's own 0.10 / 0.045 fractions: those were guessed at first, came out half again too fat, and showed the instant the lesson was rendered beside a fawn as three brown boulders holding up a triangle. The demo hand also stays on screen between placements - tied to what it was carrying, it blinked out as each piece landed, so the demonstration read as pieces appearing by themselves rather than as somebody putting them there, which is the entire content of an I-Show. |  |
| 2026-09-06 | **The We-Try runs. All 22 lessons authored one; nothing had ever executed one.** Every lesson is written as I-Show / We-Try / You-Do and the middle third - watch it, then do it with help, before being graded on it - existed only on disk: `LessonScreen` went straight from the demonstration to the activity. It was easy to miss for a specific reason worth recording: `WeTryPhase` *did* parse the phase's narration, so anything auditing for missing content found none. What it skipped was `choreography`, the key that says when to speak those lines and where she has to touch. Parsed words with an unparsed script look identical from every direction except running it. (I had also reported the phase as blocked on 49 unwritten narration lines. That was wrong - all 107 We-Try lines are authored, in each phase's own `narrationScript`, keyed by cueId in the `at` field where a timestamp normally goes, and Kokoro has been rendering clips for every one of them all along because the dumper walks every `narrationScript` array in the lesson JSON.) **It is one interpreter, not 22 mini-games, because that is what the content says the phase is:** all 22 `passCondition` lines say the same thing in their own words - "any tap passes", "even a tap on the wrong cluster passes", "even one drag is enough; system completes the rest" - so her touch is never graded. It selects which of two already-authored warm lines she hears, and the demonstration carries on either way. `we_try_script.dart` compiles the three authored timing forms (`4s`, `+0.5s`, `on-kid-input`, plus `on-correct` / `on-incorrect`) into flat beats, and `lesson_screen` runs them against the same stages the I-Show uses. Two rules are added on top of the data and both exist so the screen never goes quiet on her: no beat starts before the previous line has finished speaking (`NarrationPlayer.enqueue` holds two and silently drops the rest, and the lines it would drop are the ones answering what she just did), and a gate always resolves - the authored hesitation rule re-lights the target at 5s and the step completes itself at twice that, because "highlight and keep waiting" has no floor. Absolute times are discarded once she has touched anything: `22s phase-end` is right for a kid who watched the whole demonstration and strands one who tapped at 11s in front of a finished scene. K.G.2, K.G.3 and K.G.4 are excluded and pinned in both directions by name and by file - all three already have an interactive body of their own, and K.G.4's is literally `enum _Beat { iShow, weTry, done }`. | |
| 2026-09-06 | **What rendering the new phase caught, none of which was visible in the code.** (1) *The Buddy did not move.* "Put the Buddy above the star fountain", she touches the ring, nothing happens - which reads as the touch not registering and is the likeliest way a five-year-old abandons the phase. The scene now settles into the state the prompt asked for, on a miss as well as a hit, which is what the content means by "correct steers; incorrect corrects". (2) *Her turn opened on the demonstration's leftovers.* Three fawns still lit while she was asked to touch the first one, and - worse - K.G.5's We-Try asking her to place a corner on a triangle the I-Show had already finished. Both scenes declare their own opening state and neither was read: K.G.5 says `ghostOutline: bright-triangle`, K.G.6 says `completedFrame: triangle-solid`. (3) *The We-Try scenes count one higher than the I-Show on purpose* - three fawns shown, four hers - and `_FawnStage` had `_fawnCount = 3` hardcoded, so the narrator said "Three. Four." over three fawns. (4) *The halo washed out the thing it was pointing at.* A `BoxShadow` on a circle is a blurred filled disc drawn behind the box, so the haloed fawn was the palest one on screen and the highlight read as "this one is disabled"; it is a stroked ring now. (5) *And it was a circle*, sized by the shorter side, so on a column of ten baby gryphons in the lesson about groups of ten it ringed two of them. It is a stadium that becomes a circle when the target is square. (6) *The first ring landed on the keeper's staff*, because it measured its target once on mount and the keeper's PNG had not decoded yet - everything to its right moved when it did. The halo re-measures every frame now, which is also what keeps it on a target that animates. Recorded as README trap five. | |
| 2026-09-06 | **K.G.1's We-Try asked for a well that is not in the clearing.** "Put the Buddy above the well" over a picture of a star fountain, and `well` / `tree` are not landmark ids at all - the catalog has `fountain` and `hollow-tree` - so the zone `above-well` resolved to nothing and could not be drawn or touched. The I-Show half of the same drift was fixed last turn; this is the other half. Nine clips re-rendered and nine orphans pruned, which through Kokoro costs about twenty seconds. One line deduplicated into an existing I-Show clip, which is the clip key being a hash of the text doing exactly what it is for. | |
| 2026-09-08 | **The We-Try was doing her turn for her, and the first real play session said so.** Reported verbatim: "I selected the first two and then suddenly the last two automatically selected themselves and continued. that was very jarring given the player had been instructed to do the tapping." Two faults stacked. **The content:** four counting lessons - K.CC.4a, K.CC.4b, K.CC.1, K.CC.2 - ended their We-Try with `pointer-auto-tap` / `pointer-auto-tap-sequence` over the countables she was in the middle of counting. K.CC.4b's own prompt is "Your turn. Touch each fawn", and then it touched two of them for her. As a reading of guided practice that is defensible; as an experience it takes the controls out of a five-year-old's hands mid-task, and one-to-one correspondence is the one standard where her finger has to land on each one. Every countable now has its own `kid-action-expected`. **The interpreter:** `pointer-auto-*` lit every named target in a single frame, with no hand and ignoring the authored `spacingSec` - so even the intended version, keeper's hand at one per second, arrived as two fawns flashing on at once. It now walks the demonstrator's hand across the targets at the authored pace, which is the same affordance the I-Show uses to mean "watch me". **And the hesitation rule was the same fault in miniature:** `action: auto-complete` resolved the gate outright at `thresholdSec`, so five seconds of a child deciding which fawn is the first one ended her turn silently. It is now the three rungs the rest of the game uses, per `adaptive-scaffolding.md` - highlight at the threshold, a spoken nudge at twice it, a demonstration with the hand at three times - and what the rule's two spellings choose is what the last rung does, not how soon it fires. Twelve lessons still auto-complete a *construction* at the end (the frame standing, the bins sweeping clear); those name no targets and are payoff beats rather than her task. `we_try_handover_test.dart` holds the line in both forms: no `pointer-auto-*` may name a target, and nothing may be made to react as though touched unless a gate asked her for it. | |
