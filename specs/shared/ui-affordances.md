# UI Affordances

> The shared visual vocabulary kids learn once and recognise everywhere. New activities should reach for these widgets first before authoring custom buttons / labels / icons; the consistency is what makes the game feel like a game and not a stack of independent screens.

References: `specs/shared/art-direction.md`, `specs/shared/system-architecture.md`.

---

## Continue / Next / Proceed → `NextArrowButton`

**File**: `app/lib/ui/common/next_arrow_button.dart`.

**Use it for**: every moment where the kid has *finished the current thing* and the game wants them to advance — lesson Continue, round-complete sheet, sub-mode end, foundry confirmation, daily-quest finish, mastery-reached celebration, portal-chapter complete.

**Why it's a glowing wiggling arrow**: K kids can't read. The arrow says "forward." The pulsing glow says "tap me." The wiggle says "I'm waiting for you." Together they communicate *"this is the thing to press next"* without language. Once a kid learns the shape once, they recognise it across every Sanctuary, Wundletown, and Mathopolis activity.

**Behaviour**:
- Big circular button (default 96 px diameter; bump via `size:` for hero moments).
- Right-facing arrow glyph centred in white on a warm-amber body.
- Two stacked breathing shadows pulse on a 1.1 s loop.
- Whole button gently wiggles ±5° on a 1.4 s sine loop.
- Optional `label:` shows a small captioned pill below (for parents / older siblings reading over a kid's shoulder).

**Don't use it for**:
- **In-progress calls-to-action** like the keeper's "Let's count!" — those are activity-specific framing buttons, not "you finished, go" affordances. Mixing the two will train kids to tap-and-leave too early.
- **Skip / dismiss / cancel** affordances. Use a small text pill in the corner (see `_PillButton` in `lesson_screen.dart`) so the kid never confuses "I'm skipping ahead" with "I'm done."
- **Anything mid-activity that hasn't been completed yet.** The next arrow should be **absent** (not disabled-greyed) until the kid is ready to advance. Disabled buttons are visual noise; missing buttons mean "you're not done, keep playing."

**Authoring rule for new activities**:
> If your activity ends with a "tap to proceed" moment, instantiate `NextArrowButton`. If you feel tempted to write a custom button for this, you're wrong — extend `NextArrowButton` (size, label, color) or push the difference back through `art-direction.md`. Don't make a sibling.

---

## Skip / "I've got this" → `_PillButton`

A small tucked-corner text button on a translucent pill. Visually quiet on purpose — it's an "advanced kid / repeat player" shortcut, not the headline action. If you find yourself making the skip more prominent than the proceed arrow, redesign.

---

## Count / progress badges → big and bottom-out

Whenever you show "X of N" progress (counting badge, ten-frame fill, array complete count, etc.), the numerals are **40 pt minimum**. Kids scan numerals long before they parse words. Place the badge near the top of the activity area so it's visible at a glance and doesn't compete with the actor space.

---

## Captions → `CaptionOverlay`

Bottom-pinned read-only text bubble that mirrors whatever the `NarrationPlayer` is speaking. Wrapped in `IgnorePointer` so it never eats taps meant for what's beneath. Don't roll your own — captions need to be consistent across activities so a parent reading aloud knows where to look.

---

## Demonstrations → see `lesson-demonstration.md`

The hand-pointer + glitter-burst + actor-hop grammar lives in `specs/shared/lesson-demonstration.md`. Treat that doc as part of this one when authoring iShow phases.

---

## Authoring checklist for a new activity

When you stand up a new activity widget, walk through this list:

- [ ] Does it have a "you finished, go next" moment? → `NextArrowButton`, no exceptions.
- [ ] Does it have a "skip / I've got this" moment? → `_PillButton`-style small pill, never as prominent as the next arrow.
- [ ] Does it show progress? → 40 pt+ badge, top of the activity area.
- [ ] Does the narrator speak? → `NarrationPlayer.speak()`, never `flutter_tts` direct.
- [ ] Are captions shown? → `CaptionOverlay`, not a custom text widget.
- [ ] Does an iShow phase use a demo pointer? → Follow `lesson-demonstration.md`.

If you can answer "yes, via the shared widget" to every applicable line, you're done. If you wrote a custom widget for any of them, justify it in your PR description.

---

## Minimum tap target → `kMinTouchTarget`

**File**: `app/lib/ui/common/touch_target.dart`.

**60 logical pixels**, about 12.6mm on the iPad Air this is built for. Apple's
44 points and Material's 48 are adult minimums; the player here is five, and
`specs/shared/k-activity-patterns.md` and the engagement plan both say the same
thing in words - "large tap targets; motor skills are still developing."

It is a floor, not a size. Most things she taps are creatures and shapes drawn
at 120-150 and they should stay that way.

**Grow the hit area, not the drawing.** Where a drawn size is load-bearing -
a habitat stick's thickness is the proportion the round, the lesson and the
picker card all share; a map node's diameter is what lands it on the painted
path - pad the touch box and leave the art alone:

```dart
GestureDetector(
  behavior: HitTestBehavior.opaque,
  child: Center(child: SizedBox(width: drawnW, height: drawnH, child: visual)),
)
```

inside a `Positioned` sized to `max(drawn, kMinTouchTarget)`. Note the nesting:
a detector *inside* a larger box is still only as big as itself.

App-bar buttons come from `critMathTheme`, which sets `toolbarHeight`,
`leadingWidth` and an `IconButton` minimum together - the leading slot caps the
button's width regardless of the button's own minimum, so setting one without
the other leaves a target tall enough and still too narrow.

`app/test/touch_target_test.dart` checks every playfield and both maps.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-06-06 | Initial draft — `NextArrowButton` as the canonical "advance" CTA, plus skip / badge / caption conventions. | |
| 2026-08-18 | Added `KeeperAside` — the non-blocking counterpart to `KeeperIntroOverlay`, for a line the keeper says *while play continues*. Use `KeeperIntroOverlay` only where the kid genuinely must stop (activity intro, end-of-sub-mode reward). Between-round chatter belongs in a `KeeperAside`. | |
| 2026-08-21 | **Documented exception to "missing buttons, not disabled buttons" for the two collections.** The Buddy shop shows parts the kid can't afford (dimmed, with a price chip) and the creature-card album shows cards she hasn't found (as silhouettes of the exact sprite). In a shop or an album, the thing you don't have yet is the reason to come back — hiding it removes the mechanic. The rule holds unchanged everywhere else, including the character creator's `create` mode, which shows owned parts only so a first-run kid can tap every tile and have every tile work. An unaffordable tap is a soft refusal reusing the wrong-answer beat (shake + soft cue), never an error tone. | |
| 2026-09-02 | **Second documented instance of the locked-but-visible exception.** The decor tray shows every item, dimmed with a price chip when unowned, exactly as the Buddy shop and the creature-card album do. The rule ("missing buttons, not disabled buttons") still holds everywhere it was written for; in a shop or a collection, hiding what she cannot have yet removes the only reason to come back. The decorate mode's exit is a large green tick rather than the word "Done" — she cannot read it, and it is the only control that leaves the mode. | |
| 2026-09-02 | **The Continue arrow gets a dark ring, and stops nagging after five.** Warm amber on the Counting Parade meadow — which is bright yellow-green — left the disc dissolving into the leaves, for the one control that means "go" on the screen where a stuck child has nothing else to aim at. It now carries a 4px near-black ring, and the label pill a 2px one. Separately, the idle nudge ("Tap the arrow to continue!") fired every ten seconds indefinitely: five is a minute of a voice asking a child to do something, and past that she is not there — a game that keeps calling out to an empty room is worse than one that waits quietly. It gives up after `kMaxIdleHints`, keeps the wiggle and glow so there is still something moving to aim at when she comes back, and resets the moment the line changes, which is the signal that she got somewhere by doing something. | |
| 2026-09-03 | **Volume for music and effects is finally reachable from Settings, and the two halves of a level slider do different jobs.** The engine, the providers, the save blob and the listeners that push a level into a playing bed had all shipped; the only missing piece was any way to move them, so "turn the music down" was a code change and a rebuild — and 33% got chosen in one room, on one pair of speakers. `onChanged` fires per frame and goes straight to the provider (a slider you cannot hear while dragging is a slider you cannot set), `onChangeEnd` persists and, for effects, plays one clip to hear the new level against. Twenty divisions rather than a continuous value, so a remembered number can be found again. A channel switched off takes its slider with it, which is the ordinary rule and not the shop exception. The Settings screen claims the music bed for the same reason: a music slider tuned against silence is not a control. | |
| 2026-09-04 | **A label is not an affordance when the player cannot read.** Two rounds shipped with their core distinction carried entirely by on-screen words - Where's Buddy's six landmarks and Shape Garden's sorting baskets - and in both the words were standing in for art that was never drawn. The rule this leaves behind: if telling two things apart *is* the task, they must be told apart by picture, and any text is a second channel for the adult sitting next to her. Both now draw the thing and keep the caption small. Note the corollary for narration: a clip rendered for a beat that does not exist is invisible in every check we have - the seven basket labels were in the recording script, on disk, and unplayable, because nothing listened for the tap the script note described. | |
| 2026-09-04 | **The Buddy can be poked.** Tapping the companion makes him chirp and hop; nothing is scored, nothing can be got wrong, and it is the only interaction in the game like that - the engagement plan's own rubric scored agency, "is there anywhere with no right answer?", as absent. The tap surface is a circle over his body rather than his whole layout box, and that is a correctness constraint rather than a nicety: the companion stands in the corner of a live playfield, its box is much larger than he is, and an opaque hit test across it would eat taps on the shapes, creatures and replay button beside him. Over his body it costs nothing, because anything under there is behind an opaque sprite and was already untappable. | |
| 2026-09-04 | **A picker symbol is a miniature of the round, not a mascot.** Six of the sixteen cards were marked in their own source as stop-gaps: Where's Buddy's three options were a toucan, a phoenix and a unicorn, and Build-a-Habitat's three were grey outline solids that differ from each other about as much as three grey outline solids can. Two of the six were also *the same sprite as a Counting Parade option* - the baby phoenix meant "Count by ones" on one node and "Put Buddy there" on another - so a child learning which picture opens which game was being taught a contradiction between two screens she never sees together. The rule this leaves behind: a symbol is drawn from the same data the round is drawn from. Where's Buddy shows *her* Buddy hiding behind the hollow tree, standing on the rocks, or between two toadstools, using the landmark sprites the playfield uses; Build-a-Habitat draws the finished build out of `kHabitatBlueprints`, so the three cards differ by the thing the three sub-modes differ by - a triangle, a square, a pentagon. Shape Garden and Counting Parade keep one sprite each, because there one sprite is already honest. The symbol box went 96 -> 118 and the card 160 -> 176 for one measured reason: at 96 a Buddy at half the box is 34 pixels once BoxFit and his transparent margin come out, and two elements only both read when one is clearly the subject. The sheet is bounded to 86% of the viewport and scrolls inside that - it used to size itself to its content, so six larger cards over three rows on a small screen would have overflowed into a striped bar and a card she can see and cannot touch. |  |
| 2026-09-05 | **Two whole classes of control on the map screens were silently dead.** A `MapRegion` with `enabled: false` had `onTap: null` under an *opaque* hit test and no `ReadAloudGate`, so a tap on it was swallowed and returned nothing at all - no sound, no voice, no movement. Two of the four places on the island do that, and the island is the first screen of every session. Separately, `MapRailButton` was a bare `InkWell`: all five rail buttons across both maps made no sound (`Sfx.uiTap` lives inside the gate) and said nothing, under 12pt captions she cannot read - and two of the five are the game's entire reward economy (shop, card album) while a third is the only open-ended play in it (decorate mode). The rail exists precisely because four 24px icons in an app bar is the least reachable place on the screen for this player; having moved them somewhere she can hit, nobody gave them a voice. Both are gated now. A dark region says [kAsleepPlaceLine] rather than its own name - the same sentence, and the same clip, the Sanctuary's sleeping nodes use, because one clip covers every dark place on both maps and she already knows which one she touched. |  |
| 2026-09-07 | **Nine of the ten playfields had something she has to touch underneath the caption band.** Swept after finding the same bug twice in a row by eye - the Counting Parade companion, then the Where's Buddy Buddy - on the reasoning that a defect which has shipped twice is not an accident. It had shipped nine more times. `CaptionOverlay` is opaque and 96 pixels tall and `activity_screen` mounts it over the runner, so the box a playfield lays out in is taller than the space it can use, and every runner had worked that out for itself or not at all. **`BuddyCompanion` in eight activities** - nine call sites had written `Positioned(left: 12, bottom: 12, child: BuddyCompanion())` and every one was wrong by the height of the band; he is 150 tall and the band is 96, so it was most of him, and he is the character she designs so there is somebody to be doing the math for. **Shape Garden's scatter** put the bottom row of a 4x3 grid behind the band - two of the three circles in a round whose whole instruction is "tap all the circles". **Shape Garden's three sorting baskets** each had eighty pixels of drop target under it, in a game about dragging shapes into baskets. Counting Parade was clear, because it is the runner that hit this first and fixed it locally; nothing carried that from the one runner that knew to the nine that did not. Fixed by three shared pieces rather than nine patches: `PlayfieldScaffold` (which eleven runners had written out identically, differing only in two expressions) reserves the band for column layouts, `PlayfieldArea` gives fractional layouts the visible box, and `BuddyCompanionCorner` holds the one number the corner placement needs. The durable part is `playfield_caption_band_test.dart`: it mounts every playfield the way the activity screen does, at the reference size and a shorter one, and fails if anything touchable reaches into the band. It deliberately does not check that anyone uses the helpers - there is more than one right way to stay clear, and what matters is the child being able to reach the thing. All three fixes mutated and confirmed. | |
| 2026-09-07 | **Four things a five-year-old has to hit were too small to hit.** Measured rather than noticed, using the harness built for the caption-band sweep the same day - mount every playfield and both maps, and report every touch target under 60 logical pixels. The number is new and now written down as `kMinTouchTarget`: about 12.6mm on the iPad, against Apple's 44 points and Material's 48, both of which are adult figures. **The habitat's sticks** were the worst: she taps an edge of the shelter frame to place a stick, and the tap box was the drawn bar - 28 pixels thick, roughly 6mm, lying at an angle, so placing a stick was a precision task. **The "?" replay button** was 56, and that is the control a child reaches for when she is already stuck. **The Sanctuary map's nodes and banners** were 53 and 45 - the map is the first screen of every session and the nodes are how she gets anywhere. **The app-bar back arrow** was 40, under Apple's adult minimum, on six screens including the activity screen, which is the way out of a round. Every fix grows the hit area and leaves the drawing alone, because in three of the four the drawn size is load-bearing - a stick's thickness is the proportion `HabitatFrameLayout` gives the round, the lesson and the picker card, and a node's diameter is what lands it on the painted path. One subtlety cost a round trip and is written into the spec: a `GestureDetector` inside a bigger box is still only as big as itself, so the detector has to wrap the padding rather than sit in it. The app-bar case is fixed once in `critMathTheme`, which had to set `leadingWidth` as well as the button minimum - the leading slot caps the width whatever the button asks for - and the theme is now named so tests mount screens under the same one the child gets. `touch_target_test.dart` covers ten playfields and both maps; all five fixes mutated and confirmed. | |
