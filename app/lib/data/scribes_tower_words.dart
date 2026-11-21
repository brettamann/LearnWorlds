// Scribe's Tower - its rounds and every word it says. K.CC.3.
//
// See ten_frame_words.dart for why rounds and words live together here.

import '../activities/sub_mode_ids.dart';
import 'number_words.dart';
import 'warm_lines.dart';

enum ScribeTask {
  /// Trace a numeral along its path.
  trace,

  /// Count the fireflies, then write that number over a faint guide.
  writeFromCue,

  /// Find the numeral she hears among three.
  match,
}

class ScribeRound {
  const ScribeRound(this.task, this.numeral);
  final ScribeTask task;
  final int numeral;
}

/// Numerals in the order children usually find them easy: straight lines
/// first, one curve next, two curves and the crossing eight last.
const List<int> kScribeEasy = <int>[1, 7, 4, 0];
const List<int> kScribeMedium = <int>[2, 5, 3, 6];
const List<int> kScribeHard = <int>[8, 9, 10];

/// Four rounds, drawn from the easy end first. Seeded by the visit, so that
/// the tower asks for different numerals on different days - the same four
/// every time would have her tracing "1" forever - while any one visit is
/// stable across rebuilds.
List<ScribeRound> scribeRoundsFor(String subMode, {required int seed}) {
  int pick(List<int> from, int salt) => from[(seed + salt).abs() % from.length];
  switch (subMode) {
    case ScribesTowerModes.matchNumeral:
      return <ScribeRound>[
        ScribeRound(ScribeTask.match, pick(<int>[1, 2, 3, 4, 5], 0)),
        ScribeRound(ScribeTask.match, pick(<int>[6, 7, 8], 1)),
        ScribeRound(ScribeTask.match, pick(<int>[0, 9, 10], 2)),
        ScribeRound(ScribeTask.match, pick(<int>[3, 5, 6, 8], 3)),
      ];
    case ScribesTowerModes.audioOnlyTeens:
      return <ScribeRound>[
        ScribeRound(ScribeTask.match, 11 + (seed.abs() % 3)),
        ScribeRound(ScribeTask.match, 14 + (seed.abs() % 3)),
        ScribeRound(ScribeTask.match, 17 + (seed.abs() % 3)),
      ];
    case ScribesTowerModes.writeFromCue:
      return <ScribeRound>[
        ScribeRound(ScribeTask.writeFromCue, pick(<int>[1, 4, 7], 0)),
        ScribeRound(ScribeTask.writeFromCue, pick(<int>[2, 3, 5], 1)),
        ScribeRound(ScribeTask.writeFromCue, pick(<int>[6, 10, 9], 2)),
        ScribeRound(ScribeTask.writeFromCue, pick(<int>[8, 3, 5], 3)),
      ];
    case ScribesTowerModes.traceNumeral:
    default:
      final easy = List<int>.of(kScribeEasy);
      final a = pick(easy, 0);
      easy.remove(a);
      final b = pick(easy, 1);
      return <ScribeRound>[
        ScribeRound(ScribeTask.trace, a),
        ScribeRound(ScribeTask.trace, b),
        ScribeRound(ScribeTask.trace, pick(kScribeMedium, 2)),
        ScribeRound(
          ScribeTask.trace,
          pick(<int>[...kScribeMedium, ...kScribeHard], 3),
        ),
      ];
  }
}

// ---- words ----------------------------------------------------------------

const String kScribeIntro =
    'Welcome to the Scribe\'s Tower! The fireflies '
    'need help writing their numbers. Trace with your finger, and the ink '
    'will glow.';
const String kScribeDemo = 'Watch the firefly. It shows you the way.';
const String kScribeStartHere = 'Start at the green dot.';
const String kScribeFollow = 'Follow the path with your finger.';
const String kScribeNextPart = 'Now this part.';
const String kScribeFinal =
    'What lovely numbers! The whole tower is '
    'glowing. Here are some coins for your writing.';

const List<String> kScribeKeeperLines = <String>[
  'Beautiful writing.',
  'The fireflies love it!',
  'Look how it glows.',
  'A real scribe!',
];

String scribeKeeperLine(int round) =>
    kScribeKeeperLines[round % kScribeKeeperLines.length];

String _cap(String s) => s[0].toUpperCase() + s.substring(1);

String scribePrompt(ScribeRound r) => switch (r.task) {
  ScribeTask.trace =>
    'Let us write ${spellNumber(r.numeral)}. Start at the green dot.',
  ScribeTask.writeFromCue => 'Count the fireflies. Then write that number.',
  ScribeTask.match => 'Find the number ${spellNumber(r.numeral)}.',
};

String scribeDone(ScribeRound r) => r.task == ScribeTask.match
    ? 'Yes! That says ${spellNumber(r.numeral)}.'
    : '${_cap(spellNumber(r.numeral))}! You wrote '
          '${spellNumber(r.numeral)}.';

/// Said once she has counted the fireflies in write-from-cue, so that the
/// writing is of a number she knows rather than a shape she is copying.
String scribeCueCount(int n) =>
    '${_cap(spellNumber(n))} fireflies. Write ${spellNumber(n)}.';

String scribeMatchMiss(int n, int rotation) =>
    '${warmMissLine(rotation)} Find ${spellNumber(n)}.';

List<String> scribeScriptLines() {
  final lines = <String>{
    kScribeIntro,
    kScribeDemo,
    kScribeStartHere,
    kScribeFollow,
    kScribeNextPart,
    kScribeFinal,
    ...kScribeKeeperLines,
    scribePrompt(const ScribeRound(ScribeTask.writeFromCue, 0)),
  };
  for (var n = 0; n <= 10; n++) {
    lines
      ..add(scribePrompt(ScribeRound(ScribeTask.trace, n)))
      ..add(scribeDone(ScribeRound(ScribeTask.trace, n)))
      ..add(scribeCueCount(n));
  }
  for (var n = 0; n <= 19; n++) {
    lines
      ..add(scribePrompt(ScribeRound(ScribeTask.match, n)))
      ..add(scribeDone(ScribeRound(ScribeTask.match, n)));
    for (var k = 0; k < 4; k++) {
      lines.add(scribeMatchMiss(n, k));
    }
  }
  return lines.toList();
}
