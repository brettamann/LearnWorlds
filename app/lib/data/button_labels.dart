// The words a button says out loud.
//
// Every interactive element in the game goes through `ReadAloudGate`, which
// speaks its `label` on the tap that acts. That has been true since the gate
// was written. What was not true is that any of those words could be recorded:
// the labels were typed inline at each call site, and the literal sweep in
// `tool/narration_sources.dart` throws away anything that does not end like a
// sentence — which is the filter that stops every semantic string in `lib/`
// from becoming a voice clip, and which rejects "Done", "Nice!", "Flat" and
// "Continue" along with them.
//
// So the most-tapped control in the game spoke in the browser's synth voice.
// Not silence — a robot saying "Done" a beat after the keeper has finished a
// sentence in the narrator's, once per round, on every screen. This is the
// third time that failure has been found in the same shape (see the note in
// map_labels.dart, and the picker labels in sub_mode_picker_data.dart), and
// the shape is always the same: a spoken string somewhere no enumeration can
// reach it.
//
// Two of these are answers rather than navigation. `Flat` and `Solid` are the
// two buttons a child presses to answer a flat-or-solid round, so the word she
// hears when she commits to an answer is the word being taught. Those in
// particular had no business being read by a speech synthesiser.

/// Ends a round the kid finished by counting; the "I am done" button.
const String kLabelDone = 'Done';

/// Ends a round the kid finished by building or placing.
const String kLabelNice = 'Nice!';

/// Moves on from a lesson beat or a gift presentation.
const String kLabelContinue = 'Continue';

/// Begins a demo or a challenge run.
const String kLabelStart = 'Start';

/// Dismisses the reward-track flavour dialog.
const String kLabelOkay = 'Okay';

/// The two answers in a flat-or-solid round.
const String kLabelFlat = 'Flat';
const String kLabelSolid = 'Solid';

/// Leaves decorate mode on the Sanctuary map.
const String kLabelFinishDecorating = 'Finish decorating';

/// Plays the round's instructions again.
const String kLabelReplayDirections = 'Replay the directions';

/// The small corner escape from a lesson demo, straight to the You-Do.
///
/// It is not a control a pre-reader should be pressing by accident, and until
/// now it was a white pill with four unreadable words on it and no voice at
/// all - so pressing it to find out was the only way to learn what it did, and
/// what it does is skip the teaching. Speaking it does not stop that; it makes
/// the second press an informed one.
const String kLabelIveGotThis = "I've got this";

/// The start button on every activity built on `SanctuaryRoundShell`. One
/// shared label rather than a new exclamation per activity, because each one
/// is a clip and a pre-reader learns a button by its sound.
const String kLabelLetsGo = "Let's go!";

/// Plays a challenge through again from its finale (Tens Parade, the
/// two-attribute hunt). It was typed inline at both, so it was never recorded.
const String kLabelAgain = 'Again!';

/// Default on a `NextArrowButton` with no label of its own.
const String kLabelNext = 'Next';

/// The one on the round-complete sheet when more of the activity remains.
const String kLabelNextBang = 'Next!';

/// The one on the round-complete sheet when it does not.
const String kLabelSanctuary = 'Sanctuary';

/// Decade chips in the counting-by-tens layers: 10, 20 ... 100.
///
/// Written as digits because the numeral is the curriculum — K.CC.3 is about
/// reading them — and Kokoro reads "10" as "ten", so the clip says the word
/// while the button shows the symbol. That pairing is the whole point of the
/// chip; a chip labelled "Ten" would be teaching the word she already has.
String decadeLabel(int decadeIndex) => '${(decadeIndex + 1) * 10}';

/// Every label above, for the recording script.
List<String> spokenButtonLabels() => <String>[
  kLabelDone,
  kLabelNice,
  kLabelContinue,
  kLabelStart,
  kLabelOkay,
  kLabelFlat,
  kLabelSolid,
  kLabelFinishDecorating,
  kLabelReplayDirections,
  kLabelIveGotThis,
  kLabelNext,
  kLabelNextBang,
  kLabelSanctuary,
  kLabelLetsGo,
  kLabelAgain,
  for (var i = 0; i < 10; i++) decadeLabel(i),
];
