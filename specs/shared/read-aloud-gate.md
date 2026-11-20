# ReadAloudGate — first-tap-reads / second-tap-acts

> K and 1st grade kids can't read button labels reliably. Every interactive UI element in the game is wrapped in a `ReadAloudGate` that speaks the label on first tap (or hover, on desktop) and only fires the underlying action on the second tap within a 2.5 s window. 2nd grade onward turns it off via Settings. This doc captures the contract so future activities apply the pattern consistently.

References: `specs/shared/ui-affordances.md`, `app/lib/ui/widgets/read_aloud_gate.dart`, `app/lib/ui/screens/settings_screen.dart`.

---

## The three-state machine

```
        first tap / hover
idle ───────────────────► asked  (label narrated, halo glow appears)
                               │
                               │ second tap (within 2.5 s)
                               ▼
                              action fires (and gate resets to idle)
                               │
                               │ 2.5 s timeout
                               ▼
                              back to idle, no action taken
```

When the setting is off, the gate short-circuits — taps go directly to the wrapped child's own handler with no intermediate state.

---

## Where the gate is applied

Every interactive surface in the game wraps itself internally so callers don't have to think about it:

| Widget | Where the wrap lives |
|---|---|
| `NextArrowButton` | `app/lib/ui/widgets/next_arrow_button.dart` — `build()` returns `ReadAloudGate(label: …, onTap: …, child: <wiggling-arrow-visual>)`. |
| `MapScreen` regions (`_RegionHit`) | `app/lib/ui/widgets/map_screen.dart` — enabled regions wrap their hit area in a gate; disabled regions skip the wrap entirely. |
| `MapNodeWithBanner` | `app/lib/ui/widgets/map_node_with_banner.dart` — wraps each Positioned (banner + node) in its own gate sharing the same `label` + `onTap`. |

When you build a new interactive widget, do the same — wrap your visual + its own gesture handler in a `ReadAloudGate` and pass the user-facing label + the real action through. Callers should see no API change.

---

## Authoring rules

- **Don't wrap gameplay sprites.** Parade fawns, challenge animals, drag-and-drop tiles, stylus strokes — any element where the kid is *expressing* counting or solving the math — needs direct taps. The gate is for navigation / advance buttons / settings toggles, not for math interactions.
- **Provide a real label.** The gate is useless if the label is `null` or "Button". The TTS reads it verbatim. Use short imperative phrasing — "Continue", "Try again", "Mystic Sanctuary", "Counting Parade" — not full sentences.
- **Put the label somewhere the recording script can find it.** A rendered clip is looked up by the *words spoken*, never by `cueId` — see `specs/shared/voice-pipeline.md` — so a label typed inline in a screen has no clip and falls back to the OS synth voice, which is a jarring change of narrator rather than an obvious failure. Labels written in Dart belong in a Flutter-free catalog under `lib/data/` (`map_labels.dart` for the two maps) so `narration_script.dart` can enumerate them; labels that come from authored JSON are picked up by the dump tool instead. `test/map_labels_test.dart` enforces both, and fails if a `label:` string literal reappears in either map screen.
- **Use `speakWithoutCaption`.** The gate already does this so the caption overlay doesn't double the on-screen text. If you build a custom narration path that bypasses the gate, follow the same convention. (See `specs/shared/text-and-tts-deferral.md` for the deferral context.)
- **Wrap your own GestureDetector inside the gate.** Pattern is:
  ```dart
  ReadAloudGate(
    label: 'Whatever',
    onTap: realHandler,
    child: GestureDetector(
      onTap: realHandler,           // same handler so behavior matches when gate is off
      behavior: HitTestBehavior.opaque,
      child: <visual>,
    ),
  )
  ```
  The duplication is intentional: when the gate is off, the child's handler is the one that fires.
- **Don't wrap in a gate when the action is already disabled** (e.g., `MapRegion(enabled: false)`). Skip the wrap so the dim overlay doesn't trigger narration for a region the kid can't navigate to anyway.

---

## Settings + defaults

A single boolean toggle lives on `Settings → Read text aloud when tapped`, reached from the gear icon on the home / Sanctuary AppBar. Persistence rides in the same save blob as TTS-enabled and exploration progress.

**Defaults by grade** (planned, once the kid-profile selector ships):

| Grade | Default |
|---|---|
| K | on |
| 1st | on |
| 2nd | off |
| Any | parent override via Settings always wins |

Until the kid-profile system exists, the single-kid default is **on**.

---

## Hover semantics (desktop)

`MouseRegion.onEnter` triggers the same `_readAloud` path as a tap. So on a desktop trackpad / mouse:

- Hover over a button → label narrates, halo glow appears (gate enters "asked")
- Click within 2.5 s → action fires
- Click 3 s later → narration again + asked again, then click fires action

This gives the same kid-friendly behaviour as touch but cuts the "tap twice" annoyance for adults using a mouse.

---

## Visual cue

The `asked` state shows a soft amber halo (BoxShadow with ~30 px blur, 8 px spread, `#FFC53D` at 55 % alpha) around the wrapped element. The halo fades in over 220 ms via TweenAnimationBuilder so it doesn't snap into existence — kids see *"oh, my tap did something, now I can tap again"*.

When tuning a custom widget's appearance, do not paint over this halo — it's the universal "I'm armed" signal. If the underlying element already has a glow (NextArrowButton has its own pulsing one), letting them stack reads as "extra glow when armed" which is correct.

---

## Tests

Slice / integration tests that drive UI taps **must override** `readAloudGateEnabledProvider` to `false` so single-tap taps still fire the action — otherwise every `tester.tap(...)` only narrates and the test stalls. The convention is documented in `app/test/vertical_slice_test.dart`.

```dart
final container = ProviderContainer(overrides: [
  sanctuaryAnchorsProvider.overrideWith(...),
]);
container.read(readAloudGateEnabledProvider.notifier).set(false);
```

The gate itself should grow its own dedicated unit tests covering: timer reset on second tap, timer reset on disposal, hover→tap sequence, disabled-mode pass-through. (Punt list — none of those exist yet.)

---

## Known UX wart

**Per-element asked state, not per-logical-button.** A `MapNodeWithBanner` is conceptually one button but is wrapped as two gates (banner + node). Tapping the banner once arms the banner; tapping the node next narrates the node fresh (waste). Fixable by sharing asked state via a shared controller — punted because in practice kids tap the same region twice, not banner→node.

If we get playtest reports of kids "tapping a node and it just keeps narrating", revisit this. The fix is a small `ReadAloudGateGroup` that holds shared `asked` state and is provided down to its children via an `InheritedWidget` or a Riverpod family.

---

## Things NOT to do

- **Don't put the gate at the call site** — wrap inside the widget. Otherwise behaviour drifts across screens.
- **Don't use `speak()` (with caption).** The label is already shown on screen by the button / banner / region; doubling it in the caption overlay was the exact problem we removed for keeper bubbles.
- **Don't wrap a tiny tappable target inside a much larger gate region.** The gate sizes to its child; if the child is huge but the visible button is small, the kid's tap on the surrounding empty space also narrates. Wrap as tightly as the visual element.
- **Don't toggle the gate setting from inside a lesson.** The Settings screen is the only place; switching mid-lesson would change a kid's expectations mid-flow.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-06-07 | Initial draft — first-tap / second-tap pattern, gear-icon Settings, K/1st on default, retrofit to NextArrowButton + map regions + lesson nodes. | |
| 2026-09-02 | **A gated `label` is narration, and has to be enumerable.** Clips are keyed by the words spoken, so a label typed inline in a screen is invisible to every source the renderer reads and silently speaks in the OS synth voice instead. Authoring rule added: any string handed to `ReadAloudGate` as a `label` lives in a Flutter-free catalog under `lib/data/` (map labels are in `map_labels.dart`) or comes from authored JSON the dump tool walks. See specs/shared/voice-pipeline.md. | |
| 2026-09-04 | **Retrofitted to the sub-mode picker**, which had been outside the gate entirely. Two notes for anyone gating a *choice* rather than an action. First, speak-and-act does not help a child decide on the tap it happens; on a picker it is a teaching beat, not a reading one, and it only pays off across visits - if a screen genuinely needs its options read before she commits, that is a different widget and the queue caps at two lines anyway. Second, the sheet asks its question with a plain `speakWithoutCaption` on the first frame rather than `enqueue`: the line in flight is the map node's own name from the gate that opened the sheet, and waiting it out puts a second of silence in front of the question. | |
| 2026-09-04 | **Every label the gate speaks was in the browser's synth voice.** The gate has read a control's `label` aloud since it was written, but the labels were typed inline at each call site, and the literal sweep in `tool/narration_sources.dart` keeps only strings that end like a sentence - the filter that stops every semantic string in `lib/` becoming a clip, and which throws out "Done", "Nice!", "Continue", "Start", "Flat" and "Solid" with them. So the most-pressed control in the game answered in a robot voice one beat after the keeper had finished a sentence in the narrator's, once a round, on every screen. Two of those are not navigation at all: `Flat` and `Solid` are the buttons a child presses to *answer* a flat-or-solid round, so the word she heard at the moment she committed to an answer was the word being taught, read by a speech synthesiser. All of them now live in `lib/data/button_labels.dart` and are enumerated as their own script batch. `spoken_ui_test.dart` walks `lib/` and fails on any `label:` string literal outside the four catalogs that exist to hold them, because every fix here is one inline literal away from being undone and the symptom is never an error. Also gated: the lesson screen's "I've got this" pill, which skips the teaching and was not wrapped at all. | |
| 2026-09-04 | **The picker reads itself out, and that supersedes the note in the row above.** That row said a screen needing its options read before she commits would be "a different widget", and it was right that speak-and-act cannot do the job: this is the one screen in the game that asks her to *choose*, and speak-on-tap names what she picked after she has picked it. The gate's other affordance - hover to hear without acting - needs a mouse, and she plays on a touchscreen, so on her device the gate has exactly one behaviour and it is the wrong one here. `SubModePickerSheet` now asks the question and then names each option in turn with that card ringed in amber, the way an adult reads a menu to a child who cannot read it. It is not a gate: every card is live from the first frame, and any touch anywhere on the sheet stops the reading, because deciding is the signal that she is done listening. Driven by its own timer chain rather than `NarrationPlayer.enqueue`, which holds two lines and silently drops the rest - the queue is sized for a beat with something to add, and a menu being read out is not that. Skipped entirely when read-aloud is off, because a travelling highlight with no voice under it is a light moving across the screen for no stated reason. |  |
| 2026-09-05 | **The gate is what makes a control audible, so an ungated control is a silent one - and that is now a checked property.** `spoken_ui_test.dart` walks `lib/` and fails on a spoken string typed inline outside the four catalogs, and it had been written to look for `label:` only. The five side-rail buttons pass their words as `caption:` and went straight through it; because `MapRailButton` was not gated at all, they were not in the wrong voice, they were in no voice and made no sound. The guard names both parameters now. The general lesson is worth keeping: a guard that names one parameter catches only the parameter it names, and the interesting failures are always in the one it does not. |  |
