# Counting Parade — Multi-Round Sequence Pattern

> Why a single visit to Counting Parade plays 3 + 4 + 5 + ... + 10 = 52 counted creatures across 8 rounds with keeper interstitials, instead of one short round. The pattern generalises to any K activity where the kid needs repeated practice of the same concept at gradually-stretched difficulty.

References: `specs/activities/kindergarten/counting-parade.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/ui-affordances.md`.

---

## Why repeated practice in a single visit

The Counting Parade's K.CC.4a target — one-to-one correspondence — is the bedrock procedure of all early counting. A single 3-fawn round doesn't give the kid enough reps for the procedure to feel automatic, and forcing them to relaunch the activity 7 more times to get more reps is friction.

The multi-round sequence solves this by:

- **Auto-extending count range** — each successive round increases `targetCount` by 1, up to a cap. The kid practices counting 3, then 4, then 5, etc., naturally building stamina without a difficulty spike.
- **Varying species per round** — same procedure, different sprite. Kids can't memorise positions and they re-prove the *procedure* rather than the *picture*.
- **Keeper interstitials between rounds** — short narrative beats ("Great! All three fawns. Now the gryphon babies.") that celebrate the just-completed count and frame the next group. Keeps the kid emotionally engaged across what would otherwise feel like a worksheet of practice.

---

## How the sequence is wired

`app/lib/activities/counting_parade/counting_parade_runner.dart` owns the sequence. Constants near the top control the shape:

```dart
const int _startingCount = 3;
const int _maxCount = 10;
const _paradeSequence = <_ParadeCreature>[ ... 8 entries ... ];
```

Round N uses `_paradeSequence[N]` (sprite + species names) and counts `min(_startingCount + N, _maxCount)` creatures. The final entry's `keeperLine` is the wrap-up before `onSequenceComplete` fires.

### Phase state machine

```
intro ──Let's count!──► counting ──Done──► interstitial ──Continue──► counting (N+1)
                                              │
                                              └─ if last round ─► onSequenceComplete
```

- **intro** is only shown on direct-from-Sanctuary entries. Lesson hand-offs pass `skipIntro: true` and jump straight to counting (because the lesson already played the keeper intro).
- **counting** swaps the sprite asset + count target per round.
- **interstitial** is the same `KeeperIntroOverlay` widget the intro uses, with the round's transition line; the button label flips to "Finish" on the last round so the kid knows the celebration is coming.

### Per-round mastery + coins

Each completed round fires `RoundCoordinator.resolveRound(...)` so the K.CC.4a streak ticks up and the wallet earns its 5 coins per round. With 8 rounds in one visit:

- Streak goes 1 → 2 → 3 → promote Concrete → Pictorial → 1 → 2 → 3 → promote Pictorial → Abstract → 1 → 2 (per `adaptive-scaffolding.md` thresholds).
- Wallet earns 8 × 5 = 40 coins.

The sequence is the kid's first natural opportunity to climb the CPA ladder for K.CC.4a in a single sitting. Other activities that touch K.CC.4a (Storyteller's Pond) then pick up from the higher layer.

---

## Authoring a sequence for another activity

Future K activities that need the same "repeated practice with rising difficulty" shape (e.g. Picnic Baskets at K.CC.6 with compare counts of 3 → 10) should follow this pattern:

1. **Constants at the top of the runner file**: `_startingCount`, `_maxCount` or equivalent, `_sequence` list.
2. **A `_FooEntry` class** (or analogue) capturing per-round flavour: sprite, species names, keeper line.
3. **Three phases**: intro / round / interstitial. Reuse `KeeperIntroOverlay` for intro and interstitial.
4. **Per-round mastery firing**: call `RoundCoordinator.resolveRound` after each round, not at the end of the sequence.
5. **A single `onSequenceComplete` callback** that the host (`ActivityScreen`) wires to show the round-complete sheet.

The pattern is intentionally local to each activity widget — there's no shared "SequenceRunner" base class. Each activity's per-round shape (1 sprite vs 5, lay out in a line vs scattered, etc.) is different enough that a base class would force compromises. Copy the shape, not the code.

**To be clear about what this rule does *not* forbid:** it is about round-*sequencing structure*, not about shared primitives. Activities already share `GlitterBurst`, `NextArrowButton`, `ProgressBarToReward`, `KeeperIntroOverlay`, and `KeeperAside`, and they now also share `FeedbackEngine` (audio + haptics + Buddy reaction) and `AnswerFeedback` (the correct/wrong visual). Those are meant to be shared — a per-runner copy of "what a wrong answer looks like" is exactly how the app ended up with wrong taps that produced no feedback at all in most runners. Copy the *phase machine*; reuse the primitives.

---

## Keeper line voice + brevity

Keeper lines between rounds must be:

- **One sentence, or two short ones at most.** Kids don't read; they listen. Long lines drag the cadence.
- **Celebratory** (acknowledges the just-finished count) **and forward-looking** (names the next group). Both halves matter for the emotional arc.
- **Specific to the species**, not generic ("Great job!"). The names anchor the magical-sanctuary fiction.

The final round's `keeperLine` is celebratory only — no transition, since the round-complete sheet follows.

---

## Why sprite art lives outside `_paradeSequence`

Sprite paths are `AssetPaths` constants. The sequence references those constants by name (e.g. `AssetPaths.countingParadeBabyGryphon`). When official art replaces placeholders, only the constant changes — the sequence list, narration, and routing stay put. Don't inline raw asset path strings in the sequence; that defeats the indirection.

---

## Excluded sprites (current placeholder art)

`kitten.png` and `puppy.png` exist in `app/assets/activities/counting-parade/sprites/` but are deliberately not in `_paradeSequence`. The Sanctuary's fiction is mythical creatures; mundane pets break the theme. They stay in the folder for two reasons:

- Easy to flip in later if play-testing shows kids want more variety.
- A spec-reader can scan the folder and immediately see "8 are in the parade, 2 are unused" which is useful context.

If we want them in the parade later, add two `_ParadeCreature` entries at the end and either raise `_maxCount` (10 → 12) or repeat count=10 for the last two rounds. Both decisions are mechanical.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-06-06 | Initial draft — 8-round 3..10 sequence with keeper interstitials, per-round mastery + coins. | |
| 2026-08-18 | **Sequence rebuilt around `ParadeRoundPlanner`.** (1) Default is now 5 rounds on a deliberately non-monotonic curve `[3,5,4,7,6]` — 25 taps, ~2.5 min — instead of 8 rounds climbing 3→10 (52 taps), which overran a five-year-old's attention and read as an endless staircase. Escalation moved to the *session* level, driven by `ConceptState.currentStreak`. (2) The `_ParadeCreature` const list is gone; species live in `app/lib/data/parade_species.dart` and the order is shuffled off a session-derived seed, so a replay is no longer byte-identical. (3) Keeper transition lines are generated (`paradeTransitionLine`) rather than authored per-species, because a shuffled order cannot use a hardcoded "now the gryphons". (4) `youDo.roundParameters` is finally read — it was parsed and routed but dropped by every runner. (5) Non-creature decor (butterfly/frog/watering can) is mixed in from round 2 so the round CAN be failed; single-species-per-round is preserved because decor is scenery, not a rival species. | |
| 2026-08-21 | **Sibling counting sub-modes re-paced and given the shared feedback layer.** `long-parade` 8 rounds → 4 (`[3,5,7,10]` clusters; 52 taps → 25) and `count-on-by-ones` 9 → 4 sampled decades (90 taps → 40). Both still terminate at one hundred, which is the K.CC.1 point; what changed is that neither is a monotonic staircase of "the last round plus one" any more. count-on-by-ones now joins the parade at a *given* number rather than resuming wherever the previous round stopped — a truer reading of K.CC.2 and the reason its decades can be sampled at all. Every counting runner now sounds the pitch ladder per counted object, replaces its blocking between-round modal with `KeeperAside`, starts the scripted music bed, and puts `BuddyCompanion` on the playfield. `tens-parade` cycles the ladder every ten rather than clamping, so its run to one hundred marks each decade rollover audibly instead of flattening out after twelve notes. | |
| 2026-08-22 | **One spelled-number table, shared.** `counting_parade`, `count_on_by_ones`, `count_forward_from_n`, `count_out_n`, `long_parade` and `counting_challenge_layer` each kept a private capitalised 0–100 (or 0–20, or 0–12) word list, all of them consistent subsets of one another. They now read `kSpelledCounts` / `kSpelledTens` from `data/number_words.dart`. This is not tidying: recorded narration is keyed by the words spoken, so one take of "Seven." serves all five counting activities — and a drifting duplicate would silently split that into two recordings of one syllable. This does not conflict with this spec's "copy the shape, not the code" rule, which is about round *sequencing*; a word list is data. | |
| 2026-09-01 | **The between-round line no longer names the species coming next.** It read "Three fawns! Now the baby dragons"; it now reads "Three fawns! Beautifully counted." The line depended on three things at once - the count, the species finished and the species next - which is 1,792 sentences, of which a session speaks four. That put it permanently out of reach of a recorded voice, so it was the one beat in a round that switched back to the browser synth. Not naming the next species costs nothing pedagogically: the next creatures are on screen a second later and she can see them, and the line still carries the cardinality, which is the K.CC.4b point. The family is now count x species x rotation = 256, all voiced. | |
| 2026-09-02 | **Each sibling runner's round data moved into a catalog beside the line it fills.** `count_out_n`, `count_forward_from_n`, `count_on_by_ones` and `long_parade` each kept a private `_Round` class and `_kRounds` const inside the widget, and interpolated the counting prompt there too. That put the instruction out of reach of the recording script, so it spoke in the browser synth voice - see specs/shared/voice-pipeline.md. Each now has `lib/data/<activity>_rounds.dart` holding the rounds *and* the function that builds the prompt from them, which is the same reason `parade_species.dart` exists. The runners read them back; nothing about round content changed. Build-a-Habitat needed one extra step, because its blueprint catalog imports Flutter for the corner `Offset`s: the habitat names moved to a Flutter-free `habitat_words.dart` and `HabitatBlueprint.displayName` became a getter over it, so the script and the game name a habitat with the same string. | |
| 2026-09-02 | **The parade names what it is asking her to count, and Buddy walks.** Two gaps found by watching a five-year-old play. (1) Nothing ever named the creature: she would count fawns for a round and never learn they were fawns, because the sprite is a picture of an animal and no text on screen is readable to her. Every round now opens with a card — same furniture as the earned-card reveal, `ui/rewards/reveal_card.dart` — that shows the creature and says "This is a fawn! Let's count them next!". **It costs a beat per round**, which cuts against the KeeperAside work that removed ~16 blocking dialogs a sitting; it is paid for by auto-advancing on the spoken line's length and by taking a tap anywhere to skip, so it never *requires* an acknowledgement. (2) The hint ladder's point rung had Buddy gesturing from the corner it stood in, which connected the help to nothing. It now walks across the meadow and stands over the creature she has missed, reading the target's real position off the laid-out widget rather than recomputing the Wrap's arithmetic — a Buddy pointing at empty grass is worse than no hint. Buddy also went from 150px in a corner, where it read as part of the frame, to 208px standing in the meadow. | |
| 2026-09-02 | **Buddy walks back after demonstrating, and rests clear of the caption bar.** Two follow-ups from watching it run. The demonstrate rung is the one hint the child does not answer, so nothing sent Buddy home and it stood over the creature it had just counted for the rest of the round; it now lingers ~1.1s so she sees the touch, then leaves. And its resting spot was at the very bottom of the meadow, underneath the semi-transparent caption band — the one character in the scene spent every round behind a subtitle. Home now clears `kCaptionBandClearance`, shared from `caption_overlay.dart` so the two cannot drift. | |
