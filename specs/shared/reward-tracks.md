# Reward Tracks (grade-spanning collectibles)

> A grade-spanning reward that evolves as the kid finishes lessons, lives in the corner of the region map, and graduates into a permanent home fixture at the end of the grade. K gets the **Mystery Egg** (Haddock hands it to you after Counting Parade; it shakes / cracks / hatches over the curriculum). 1st gets a wand spark, 2nd a hero badge, etc.
>
> This doc captures the contract so future grades author their own track without re-deriving the state machine.

References: `app/lib/models/reward_track.dart`, `app/lib/ui/rewards/reward_overlay.dart`, `specs/shared/reward-economy.md`.

---

## Why a track per grade

Per-round coins and per-chest collectibles are short-cycle rewards (5 s feedback loop). A track adds a **long-cycle** loop spanning weeks of play: the kid sees the corner sprite at every map visit, watches it change shape as they progress, and has something to point at when a parent asks "what are you working on?" That long-cycle reward is what carries the kid through the dry middle of the curriculum.

The track is intentionally tied to **specific lessons**, not just total problems solved, so kids can't grind a single activity to advance — they have to actually move across the curriculum.

---

## The K mystery egg, concretely

8 stages + 1 "complete" state. Stage grants:

| Lesson (map order) | Activity id | Grants stage |
|---|---|---|
| 1 | counting-parade | 1 (egg appears) |
| 2 | shape-garden | — |
| 3 | ten-frame-pond | — |
| 4 | build-a-habitat | — |
| 5 | care-pantry | 2 |
| 6 | scribes-tower | 3 |
| 7 | storytellers-pond | 4 |
| 8 | wheres-buddy | 5 |
| 9 | caretakers-bench | 6 |
| 10 | picnic-baskets | 7 |
| 11 | fluency-within-5 | 8 (final) |

Lessons 2–4 don't advance the track — the egg sits still while the kid does shape / pond / habitat work. Then every lesson from F5 onwards bumps the egg by one stage. F11 is the final advancement; the next map visit graduates the track to the hatched-dragon "complete" sprite.

Each stage has a one-line flavour message kids hear by tapping the corner sprite. Messages always end with forward-looking encouragement ("keep going", "almost there") — never just a status read-out.

---

## State machine

```
                      activity completed
nothing  ───────────────────────────────────►  stage N (target)
                                                     │
                                                     │ next map mount
                                                     ▼
                                              advancement animation
                                                     │
                                                     ▼
                                              stage N (last seen)
                                                     │
                                                     │ if N == finalStage,
                                                     │ next map mount
                                                     ▼
                                              graduated (complete sprite)
```

Three persisted values per track in the save blob:

| Field | Meaning |
|---|---|
| `completedActivities` | Set of activity ids that count toward this track's grant table. |
| `lastSeenStage` | Highest stage the kid has watched on the map. The overlay only plays the fanfare when `targetStage > lastSeenStage`. |
| `graduated` | Flipped to true on the **next** map mount after stage 8 is seen. The complete-stage sprite replaces stage 8 thereafter. |

The two-step "see stage 8 → next mount → graduate" exists so the kid watches the stage-7 → stage-8 fanfare on the visit they earned it, then comes back later and sees the hatched dragon — the egg isn't allowed to "graduate during the same animation" because that would steal both beats from the kid.

---

## Mount points

| Where | What |
|---|---|
| `ActivityScreen.onSequenceComplete` | calls `rewardProgressProvider.markActivityCompleted(...)` for **every** completed activity (whether or not it grants a stage). Failing to call it would silently break advancement. |
| `SanctuaryMapScreen` | mounts `RewardOverlay(track: kMysteryEggTrack)` as the topmost layer. The overlay reads the saved progress, computes the target stage, and plays the fanfare if it has to. |

Other regions will mount their own track overlays the same way. Multiple tracks per region are supported by stacking multiple `RewardOverlay`s in different corners.

---

## Authoring a new track

1. **Sprites** at `app/assets/rewards/{trackId}/{slug}-stage-{n}.png` (1..N) plus `{slug}-stage-complete.png`.
2. **Asset paths** as `static const` / `static String foo(int n)` entries in `AssetPaths`.
3. **`RewardTrack` config** in `lib/models/reward_track.dart` (or `lib/data/reward_tracks.dart` once we have several):
   - Ordered list of stages (sprite, message, ambient level).
   - `stageGrants` map: which activity-id grants which stage. Activities not in the map don't advance.
   - `completeStage` shown after graduation.
4. **Mount** the overlay on the region's map screen.
5. **Hook activity completion** if the track's activities don't already flow through `ActivityScreen.onSequenceComplete` (they should).

The state machine and animation are reusable — no track-specific code in the overlay widget.

---

## Animation contract

`RewardOverlay` plays a ~3.2 s fanfare on advance. Phases:

| Phase | t range | What happens |
|---|---|---|
| Grow | 0.00 – 0.25 | Sprite glides + scales from upper-left corner to centre. Map behind dims to ~35 % black. |
| Shake | 0.25 – 0.50 | Old-stage sprite shakes in place (±12 px random translate). |
| Swap | 0.50 – 0.55 | White circular flash, sprite swaps from old → new. |
| Settle | 0.55 – 0.75 | New-stage sprite finishes a tail-end shake. |
| Return | 0.75 – 1.00 | Sprite shrinks + glides back to the corner. Backdrop dim fades. |

Input is **fully blocked** for the duration via an `AbsorbPointer` over the overlay — kids can't tap the map or any node while it plays. On animation complete the overlay records `lastSeenStage = target`, persists, and switches back to corner-mode.

For the special first-advance case (`fromStage == 0`, no previous sprite), the animation uses the new sprite from the start and the white flash registers the "arrival" rather than the "transformation."

### Ambient (corner-mode) wiggle

The corner sprite breathes per its stage's ambient level:

| Ambient | translate amp | scale amp | feel |
|---|---|---|---|
| `still` | 0 | 0 | inert (early stages) |
| `gentle` | 3 px | 2 % | barely-there hop |
| `moderate` | 6 px | 4.5 % | clearly alive |
| `energetic` | 10 px | 8 % | "I'm about to hatch" |
| `gentleHatched` | 4 px | 3 % | content idle |

All amplitudes are capped low enough that the tap target stays predictable. K kids can't reliably hit a violently bouncing button.

---

## Things NOT to do

- **Don't replace the corner with a centre HUD.** The corner is the contract: kids learn to glance there and the same place always tells them the long-cycle progress.
- **Don't tie advancement to coins or rounds.** It must be lesson-completion-keyed so the kid can't grind a single screen to advance. (The reward-economy doc reinforces this for chests, too.)
- **Don't fanfare on the wallet-only payouts.** Coins jingle; the egg track ignores them. The track fanfare is reserved for the long-cycle progression.
- **Don't show two fanfares per visit.** If a kid somehow jumps two stages in one session (skipped a grant lesson, then did two grant lessons offline?), the overlay plays a single combined fanfare from old → newest target. (Stage 6 just appears with the same flash; no double-celebration.)
- **Don't allow the track to skip backwards.** `markStageSeen` is monotonic. There's no UI for "undo my egg progress."

---

## Open ends

- **Home-region interaction with the hatched creature.** The complete sprite teases "visit your home to find them!" — that home interaction lands when the Home region ships.
- **Parent dashboard view.** Surfacing track progress alongside per-standard mastery is a `parent-teacher-dashboard.md` follow-up.
- **Cross-grade tracks.** If 1st graders should keep their dragon visible while doing 1st-grade lessons, the track persists across grade transitions. Confirm at the time we ship 1st-grade content.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-06-07 | Initial draft — K mystery egg with 8 stages + graduated state, overlay widget on Sanctuary map. | |
| 2026-08-21 | **Tracks now advance per cleared sub-mode, not only per cleared activity.** `RewardTrack.eventsPerStage` counts `RewardTrackState.completionEvents` (one key per sub-mode, deduped so a replay cannot farm the track) and takes `max(...)` against the existing `stageGrants`, which stays as a floor — so a save written before this change lands on exactly the stage it always did. The K mystery egg is set to 2 events per stage. Grants alone meant Haddock first handed the egg over after *all five* non-challenge Counting Parade sub-modes, roughly thirty-one rounds in; this spec calls the track what "carries the kid through the dry middle of the curriculum" and at that cadence it was very nearly a static picture. Two is a deliberate compromise: one-per-sub-mode would put the gift around round five but would hatch the eight-stage egg inside the first week and leave the rest of K with no track running. `eventsPerStage` is the dial to turn if the egg still feels static. | |
| 2026-08-21 | **Coins are spendable and the creature-card set exists.** Two of the three things this spec promised a kid were unimplemented: `walletProvider` paid 5 coins a round into a balance no kid-facing screen showed and nothing could spend, and the Sanctuary Creature Cards set declared in `data/reward-catalog/kindergarten.json` had no runtime at all. Now: the character creator gains a `shop` mode (`buddy_shop_catalog.dart`, `buddy_wardrobe_provider.dart`, `Wallet.spend`) selling the body colours, eye variants and hats already in `app/assets/buddy/`, priced against the ~25-coin sub-mode payout so the first purchase lands on day one; and eight of the set's cards are implemented over the existing Counting Parade sprites (`creature_card_catalog.dart`), dropping on one weighted roll per passed round. Both follow this spec's own reasoning that what sustains a kid is "a new outfit on their character" and a world that changes, not an incrementing counter. A `CoinHud` now sits on both maps and in every activity, and `coin_fly_layer.dart` flies the payout into it. | |
| 2026-09-01 | **The ninth creature card, and a card set that can hold a card the parade does not supply.** `creature-card-rare-tens-parade-unicorn` (“Cloud Unicorn”) has been authored in `data/reward-catalog/kindergarten.json` since the first sprint — it is the ninth member of `sanctuary-creature-cards-set`, its only source is `{ type: challenge, challengeActivityId: counting-parade }`, and `challenge-counting-parade-chest` guarantees one card from a pool containing only it. The runtime could not express it: `CreatureCard.speciesId` was a non-nullable String naming a parade species, and this creature is not in the parade. The field is now nullable, which is what its own doc comment had always claimed (“or null for cards with their own art”). Cards also gained `CardSource`: `roundDrop` cards are rolled for on a passed round as before, `challenge` cards never enter that pool and are granted outright by the challenge that earns them. Finishing the Tens Parade now grants the Cloud Unicorn and the keeper's hundredth-tap line names it. Granting rather than rolling is deliberate — a rare that a hundred taps might still fail to produce is a worse reward than no card at all, and it matches the authored chest, which guarantees the card rather than rolling for it. | |
| 2026-09-01 | **The album says the names out loud.** Tapping a found card in `/collection` speaks the creature's name; tapping a silhouette says it has not been found yet. The screen was built to carry almost no text because it is for a pre-reader, which left the name under a found card — the one thing a collection is actually for — unreadable by the only person who plays. The silhouette case speaks for the same reason wrong answers do: a tap that produces nothing is indistinguishable from a frozen app. The reveal overlay deliberately stays silent and this is not an inconsistency — it shares its beat with the keeper, and `NarrationPlayer` has no queue, so a second `speak` cancels the first mid-word. Nothing else on the album screen speaks. | |
| 2026-09-02 | **The new-friend card speaks, and waits.** It showed a name in text a pre-reader cannot read and took itself away after five seconds, so the whole content of the reward was a picture she got no name for and might not have finished looking at. It now says `cardRevealLine` — enqueued rather than spoken, because the beat lands while the keeper is still finishing the round — shows a pulsing hand and "Tap anywhere", and waits for her. A child who does not tap gets the prompt spoken after six seconds, once, in the only channel she has. The auto-dismiss survives at 30 seconds rather than 5: the card being more patient does not make it safe to strand a child who wandered off. | |
| 2026-09-03 | **The mystery egg could not hatch, and the cadence is now checked against content rather than against a plan.** `eventsPerStage` was 2, tuned for the K curriculum as authored — eleven activities, far more sub-modes than the egg has stages, so one-per-sub-mode "would hatch in the first week". Four of those eleven are built, and their non-optional sub-modes come to thirteen events against the sixteen that eight stages at two apiece require. A child could clear every last thing in the game and stop at stage six, never seeing the egg hatch and never even reaching stage eight ("It's about to hatch any second!"). The one long-cycle reward in the game, unreachable. Now 1: the egg moves every time she finishes a sitting and hatches at eight of the thirteen, with a real tail of five sub-modes plus four challenges played out afterwards — a smaller cost than a carrot nobody can reach. It also moves the gift to the end of her *first* sitting rather than her second, which is taken deliberately: a first session ending with someone handing her a mystery to look after is the hook. `egg_can_hatch_test.dart` derives the event count from the registry and the playable-activity set, so it is both the guard and the signal for turning the dial back up when the remaining seven activities land. Challenges are excluded from the count on purpose: they are opt-in, and an arc that only closes when every challenge is played makes "optional" a lie. | |
| 2026-09-04 | **The egg's story was written down and never told, and its movement was invisible.** Three faults, one beat. (1) The eight stage messages - a jump, a crack, a snout - are the entire narrative of the game's long-cycle reward, and not one had ever been said out loud in any voice: they live on `kMysteryEggTrack` in `lib/models/`, which the literal sweep does not read, so the renderer could not see them. What a child got when she tapped her egg was a paragraph of prose and a button reading "Close". They are a script batch now, rendered, spoken on tap, and the button is the same arrow that ends every other beat in the game. (2) `RewardOverlay` plays a real advancement fanfare, but it lives on the Sanctuary map, and the end-of-sub-mode sheet usually routes straight into the next sub-mode without passing it - so since the track was retuned to advance once per cleared sub-mode, the egg had been moving after every sitting with almost nobody there to see it. The sheet shows the egg at its new stage now, and bursts only when *this* sitting is what moved it. (3) That sheet was previously a Material `Icons.celebration` glyph over "Nicely counted!" at 32 point, silent - which said "counted" at the end of a sorting round, made the words the only content, and made no sound for a child who cannot read them. | |
| 2026-09-24 | **The mystery egg slowed to two sub-modes a stage, and can never move backwards.** The track's own comment said to turn the dial back up when the other seven Sanctuary places landed: at one a stage, with ~30 chain sub-modes now, it hatched a quarter of the way along the path. The first sub-mode is still worth a stage on its own, so Haddock still hands the egg over at the end of her first sitting. `computeTargetStage` now takes the highest stage she has already seen as a floor, so a child whose egg was further along than the new pace puts it keeps what she saw. Separately, the 24 creature cards were all owned by Counting Parade, so three of the four built places could never drop one; they now live where they belong (the frog at the frog pond, the Star Turtle at the storyteller's, the squirrel in the pantry) and every playable activity has at least one. | |
| 2026-09-25 | **Four sub-modes a stage.** At two, walking the path in map order put stage eight in Care Pantry - place five of eleven - and the hatch straight after; at four there is roughly one stage per place finished and the egg reaches stage eight in Picnic Baskets, which is the arc the table at the top of this file draws. `egg_can_hatch_test.dart` now walks the map in order and fails if the last stage arrives before the last three places. It also had a bug that the pace change exposed: it treated every sub-mode marked `isDemotionFloor` as optional, and eight activities' entry points are marked that, so it was counting 23 of the 31 required sub-modes. | |
