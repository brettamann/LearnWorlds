// Ten-Frame Pond - its rounds and every word it says.
//
// Rounds and words live together, and outside the runner, for the reason the
// other `_words.dart` files give: the runner imports Flutter, the narration
// script has to compile under plain `dart run`, and a line the script cannot
// reach is spoken in the browser's synth voice. Keeping the round plans here
// too means the script enumerates exactly the sentences these rounds can
// produce - no more, so nothing is rendered for a round that does not exist,
// and no fewer.

import '../activities/sub_mode_ids.dart';
import 'number_words.dart';
import 'round_pick.dart';
import 'warm_lines.dart';

/// One round at the pond.
class PondRound {
  const PondRound({
    required this.target,
    this.preset = 0,
    this.twoColors = false,
    this.differentWay = false,
    this.askHowMany = false,
  });

  /// How many frogs the pads should hold when she is done.
  final int target;

  /// Frogs already sitting when the round opens (make-ten, the challenge).
  final int preset;

  /// Green and orange frogs wait on the bank; she chooses the mix.
  final bool twoColors;

  /// Two-ways, second visit to a target: the split must differ from last time.
  final bool differentWay;

  /// The challenge: the frogs are already sitting and she says how many.
  final bool askHowMany;

  /// A teen number needs a second pond.
  int get frames => (target > 10 || preset > 10) ? 2 : 1;
}

/// Every round each sub-mode can play. A visit plays four of them (the
/// challenge, three), picked by [pondRoundsFor].
///
/// Fill-to-target stays within nine, so the tenth frog - "the whole pond is
/// full" - is saved for make-ten, whose rounds all end on it. Two-ways lists
/// each target twice, once plain and once asking for a different way; a visit
/// takes both halves of a pair or neither.
final Map<String, List<PondRound>> kPondRounds = <String, List<PondRound>>{
  TenFramePondModes.fillToTarget: <PondRound>[
    for (var t = 3; t <= 9; t++) PondRound(target: t),
  ],
  // Five is one full row, which makes "four and one" and "two and three"
  // easy to see as the same five; the other targets let a return visit ask
  // for a number she has not split before.
  TenFramePondModes.twoWays: <PondRound>[
    for (final t in const <int>[4, 5, 6, 7]) ...<PondRound>[
      PondRound(target: t, twoColors: true),
      PondRound(target: t, twoColors: true, differentWay: true),
    ],
  ],
  TenFramePondModes.makeTen: <PondRound>[
    for (var p = 3; p <= 8; p++) PondRound(target: 10, preset: p),
  ],
  TenFramePondModes.tenPlusN: <PondRound>[
    for (var t = 11; t <= 19; t++) PondRound(target: t),
  ],
  TenFramePondModes.threeFrames: <PondRound>[
    for (var t = 11; t <= 19; t++)
      PondRound(target: t, preset: t, askHowMany: true),
  ],
};

/// The rounds for one visit, the gentlest first.
///
/// Never monotonic - the ramp the parade planner uses, for the same reason: a
/// count that only ever goes up is a mounting pressure, and one that dips is
/// a breather.
List<PondRound> pondRoundsFor(String subMode, {int seed = 0}) {
  final pool =
      kPondRounds[subMode] ?? kPondRounds[TenFramePondModes.fillToTarget]!;
  if (subMode == TenFramePondModes.twoWays) {
    final targets = pickRounds(
      <PondRound>[
        for (final r in pool)
          if (!r.differentWay) r,
      ],
      count: 2,
      seed: seed,
      ease: (r) => r.target,
    );
    return <PondRound>[
      for (final r in targets) ...<PondRound>[
        r,
        pool.firstWhere((d) => d.differentWay && d.target == r.target),
      ],
    ];
  }
  return pickRounds(
    pool,
    count: subMode == TenFramePondModes.threeFrames ? 3 : 4,
    seed: seed,
    // Make-ten is easiest when there is least to add.
    ease: (r) => r.preset > 0 && !r.askHowMany ? 10 - r.preset : r.target,
  );
}

// ---- words ----------------------------------------------------------------

const String kPondIntro = 'Welcome to the lily pond! The frogs want to sit on '
    'the lily pads. Tap a frog, and it hops on.';

const String kPondDemo = 'Watch. Tap a frog, and hop!';
const String kPondDemoBack = 'Back you go, little frog. Now it is your turn.';

const String kPondTopRowFull = 'Five! The top row is full.';
const String kPondFrameFull = 'Ten! The whole pond is full.';

/// The challenge's nudge: the full pond is a ten she does not have to count.
const String kPondCountOn = 'The full pond is ten. Count on from ten.';

/// A wrong card in the challenge. The warm line rotates; the nudge does not.
String pondMissLine(int n) => '${warmMissLine(n)} $kPondCountOn';

const String kPondSameWay =
    'That is the same way as last time. Let us find a new way!';

const String kPondFinal = 'Every frog found a lily pad. The pond is so happy! '
    'Here are some coins for your help.';

/// Between rounds, over the finished pond. Rotated by round.
const List<String> kPondKeeperLines = <String>[
  'The frogs love it. Ribbit!',
  'What a happy pond.',
  'Look at them all, sitting so nicely.',
  'Splendid. More frogs are coming.',
];

String pondKeeperLine(int round) =>
    kPondKeeperLines[round % kPondKeeperLines.length];

String _cap(String s) => s[0].toUpperCase() + s.substring(1);

/// What the round asks for.
String pondPrompt(PondRound r) {
  if (r.askHowMany) return 'How many frogs are on the lily pads?';
  if (r.preset > 0) {
    return '${_cap(spellNumber(r.preset))} frogs are here. '
        'Fill the pond to ten!';
  }
  if (r.twoColors) {
    return r.differentWay
        ? 'Now make ${spellNumber(r.target)} a different way.'
        : 'Make ${spellNumber(r.target)} with green frogs and orange frogs.';
  }
  return 'Put ${spellNumber(r.target)} frogs on the lily pads.';
}

/// What the round says when it is done. [green] is how many of the frogs on
/// the pads are green; only the two-colour rounds use it.
String pondDoneLine(PondRound r, {int green = 0}) {
  if (r.askHowMany || r.frames == 2) {
    final ones = r.target - 10;
    return 'Ten and ${spellNumber(ones)} make ${spellNumber(r.target)}!';
  }
  if (r.preset > 0) {
    return '${_cap(spellNumber(r.preset))} and '
        '${spellNumber(10 - r.preset)} make ten!';
  }
  if (r.twoColors) {
    return '${_cap(spellNumber(green))} green and '
        '${spellNumber(r.target - green)} orange make '
        '${spellNumber(r.target)}.';
  }
  return '${_cap(spellNumber(r.target))} frogs on the lily pads!';
}

/// Every sentence the pond can say, for the recording script.
List<String> tenFrameScriptLines() {
  final lines = <String>{
    kPondIntro,
    kPondDemo,
    kPondDemoBack,
    kPondTopRowFull,
    kPondFrameFull,
    kPondSameWay,
    kPondCountOn,
    for (var n = 0; n < 4; n++) pondMissLine(n),
    kPondFinal,
    ...kPondKeeperLines,
  };
  for (final rounds in kPondRounds.values) {
    for (final r in rounds) {
      lines.add(pondPrompt(r));
      if (r.twoColors) {
        for (var g = 0; g <= r.target; g++) {
          lines.add(pondDoneLine(r, green: g));
        }
      } else {
        lines.add(pondDoneLine(r));
      }
    }
  }
  return lines.toList();
}
