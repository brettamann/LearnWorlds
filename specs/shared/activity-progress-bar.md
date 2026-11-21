# Activity Progress Bar → Reward

> Every multi-round K activity shows the same affordance at the top of the screen: a horizontal bar that fills as the kid completes rounds, with a gold coin pinned at the right end. When the bar reaches 100%, the coin bounces excitedly for a couple of seconds before the keeper steps in to thank the kid and tell them their reward. Then — and only then — the "Continue / Finish" arrow appears.

This is the **single canonical "effort → progress → reward" loop**. Kids learn it once on the Counting Parade and recognise it on every other activity in the Sanctuary, Wundletown, and Mathopolis.

References: `specs/shared/ui-affordances.md`, `specs/shared/counting-sequence.md`, `app/lib/ui/rewards/progress_bar_to_reward.dart`.

---

## Shape of the loop

```
round 1 done ─► bar fills 1/N ─► keeper interstitial (transition) ─► round 2 …
…
round N done ─► bar fills N/N ─► coin bounces 2s ─► keeper interstitial (reward) ─► Finish arrow
```

The reward keeper line *names the reward* — "Here are 40 coins from the Sanctuary." Numbers are computed from actual coins earned, not from a placeholder string. If the activity grants a chest or a permanent fixture too, the line should mention it: "…and a Sanctuary Reef Cards chest." Keep it to one sentence or two short ones (per `specs/shared/counting-sequence.md` keeper-line rules).

---

## The widget

`app/lib/ui/rewards/progress_bar_to_reward.dart` — `ProgressBarToReward`.

Props:

| Prop | Meaning |
|---|---|
| `progress` | 0..1, fill amount. `TweenAnimationBuilder` eases the transition between values. |
| `celebrate` | Flip true to start the coin's bounce loop; flip false to stop it instantly. |
| `barHeight` | Visual height of the track (default 22 px). |
| `coinSize` | Diameter of the coin sprite (default 56 px). |
| `fillDuration` | How fast the fill animates to a new `progress` (default 500 ms). |

Place it inside a `SafeArea > Column` at the top of the activity body:

```dart
SafeArea(
  child: Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: ProgressBarToReward(
          progress: _sequenceProgress,
          celebrate: _phase == _Phase.celebrating,
        ),
      ),
      Expanded(child: phaseContent),
    ],
  ),
)
```

It owns its own celebrate animation. Don't drive the bounce from outside — just flip `celebrate`.

---

## The 4-phase machine every activity uses

```
intro ── Let's <verb>! ──► counting ── Done ──► interstitial (transition) ──► counting (N+1)
                                          │
                                          ╰─ if last round ─► celebrating (2s) ─► interstitial (reward) ─► Finish
```

- **intro** — Keeper sets the story context. Skipped when entering from a lesson handoff.
- **counting / playing** — The actual mechanic of the activity.
- **celebrating** — *Only fires on the final round.* `_phase = celebrating`, `progress = 1.0`, `celebrate = true`. Hold for ~2 seconds, then transition to `interstitial`. The Done button is **suppressed** during this phase (input is locked, the kid watches the coin).
- **interstitial** — Keeper appears. On non-final rounds: a brief "great, on to X" transition. On the final round: a reward-naming thank-you with the Continue arrow.

The 2-second celebration duration lives in `_kFinalCelebrationHold` next to the runner — adjust per-activity if a different beat feels right.

---

## Reward-line rules

The final interstitial keeper line MUST name the concrete reward (or the menu of rewards). Don't write "Wonderful job!" or "All done!" alone — the kid needs to know what the coin meant. Bad and good examples:

- ❌ "Beautifully done."
- ❌ "Thanks for your help!"
- ✅ "Thank you, friend! Here are 40 coins from the Sanctuary."
- ✅ "All counted! Here's 40 coins, and a Sanctuary Reef Cards chest."

If the reward is dynamic (depends on streak / challenge / chest tier), compute it in the runner state and interpolate into the line string. Hard-coding numbers that don't reflect actual reward is a worse failure than a slightly less polished phrasing.

---

## Authoring checklist (new activity)

When you stand up a new multi-round activity, walk through this list:

- [ ] **Top-level Column** layout: `ProgressBarToReward` at the top, phase content in `Expanded`.
- [ ] **Sequence-aware progress** — `_completedRounds / _sequenceLength`, not "this round's progress" (the count badge handles per-round).
- [ ] **`_Phase.celebrating`** added to the phase enum, distinct from `counting` and `interstitial`.
- [ ] **2-second `Timer`** owned by the State, cancelled in `dispose()` so a back-button mid-celebration doesn't leak.
- [ ] **Done button suppressed** during `celebrating`. Either pass `allTapped: false` to the counting layer or split a `showDone` flag.
- [ ] **Final keeper line names the reward** — coins, chests, fixtures, library entries. Computed, not hardcoded.
- [ ] **`Finish` button label** on the final interstitial (instead of `Let's go!`) so the kid knows the activity is wrapping.
- [ ] **NextArrowButton** for the Finish CTA per `ui-affordances.md` — same shape as Continue, just a different label.

---

## Things NOT to do

- **Don't show two progress bars.** The persistent ProgressBarToReward is the only progress affordance; activities like Build-a-Habitat that have a per-build progress should fold it into the same bar or the count badge, not stack a second bar.
- **Don't fire `onSequenceComplete` directly from the Done tap.** The 2-second celebration + reward interstitial must happen in between — they're the payoff for the kid's effort. Skipping them robs the loop of its emotional beat.
- **Don't pause narration during celebrating.** If the kid was mid-utterance ("Three.") when they tapped Done, let it finish; just keep the visuals going. Cancelling narration to make room for the next line is the NarrationPlayer's call, not the runner's.
- **Don't reuse the bounce animation for in-progress moments.** The coin bouncing means "you finished the whole thing." Bouncing it after just a single round trains the kid to expect rewards mid-activity and devalues the real finish.
- **Don't hide the bar during intro / interstitial.** It should be visible the entire time the kid is in the activity. Its presence at 0% is what teaches them what it's for.

---

## Test rule

Every new activity widget needs at least one widget test that verifies:

1. `ProgressBarToReward` is mounted from the moment the activity opens.
2. Its `progress` value is `0.0` before any round resolves.
3. Its `progress` value increases by `1 / sequenceLength` after each round completes.
4. Its `celebrate` flag is `true` between the final round's Done and the reward interstitial.

The Counting Parade's vertical slice test exercises (1)–(3) at [test/vertical_slice_test.dart](app/test/vertical_slice_test.dart). Copy that shape.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-06-06 | Initial draft — extracted from Counting Parade's multi-round sequence. Pattern is mandatory for all future multi-round K/1st/2nd activities. | |
| 2026-08-18 | **The between-round interstitial is no longer blocking.** The keeper now speaks over the live playfield in a non-blocking `KeeperAside` that retires itself and advances the round; no tap is required. The default Counting Parade sub-mode was firing ~16 full-screen modals per sitting, which stopped play every five taps and was a major source of "it gets repetitive". The FINAL beat is unchanged and still blocking — `celebrating` → reward interstitial → Finish is the payoff and is supposed to interrupt. | |
| 2026-08-21 | **Non-blocking transitions propagated to the remaining nine runners.** Shape Garden (find + flat-or-solid), sort-by-attribute, two-attribute hunt, where's-buddy, build-a-habitat, long-parade, count-on-by-ones, count-forward-from-n and count-out-n all now speak their between-round keeper line over the live playfield via `KeeperAside` and advance themselves. The final beat stays blocking everywhere, unchanged. Runners gained a `transition` phase between `celebrating` and `interstitial`; input is locked for its duration so a stray tap can't register a miss while the keeper is talking. | |
