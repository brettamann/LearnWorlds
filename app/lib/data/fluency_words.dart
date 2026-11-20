// Fluency Within 5 - its puzzles and every word it says. K.OA.5.
//
// See ten_frame_words.dart for why rounds and words live together here.

import 'dart:math' as math;

import 'number_words.dart';
import 'warm_lines.dart';

const String kFluencySubCasual = 'casual';
const String kFluencySubSpeed = 'speed-run';

class FluencyFact {
  const FluencyFact(this.a, this.b, {required this.plus});
  final int a;
  final int b;
  final bool plus;
  int get answer => plus ? a + b : a - b;
}

/// Every fact within five: 21 sums and 21 differences, which is the whole of
/// K.OA.5.
final List<FluencyFact> kFluencyFacts = <FluencyFact>[
  for (var a = 0; a <= 5; a++)
    for (var b = 0; a + b <= 5; b++) FluencyFact(a, b, plus: true),
  for (var a = 0; a <= 5; a++)
    for (var b = 0; b <= a; b++) FluencyFact(a, b, plus: false),
];

/// Three puzzles to a round - quick-fire inside the round, a keeper beat
/// between rounds - so that the flow is three tries, a breath, three more.
const int kFluencyPerRound = 3;

/// The puzzles for a visit, seeded so a visit is stable and different days
/// are not. The first round is sums only, because adding is where a child is
/// surest; zero turns up now and then, never as the very first puzzle.
List<List<FluencyFact>> fluencyRoundsFor(String subMode, {required int seed}) {
  final rng = math.Random(seed);
  final rounds = subMode == kFluencySubSpeed ? 4 : 3;
  final sums = kFluencyFacts.where((f) => f.plus && f.a > 0).toList();
  final all = kFluencyFacts.where((f) => f.a > 0).toList();
  final out = <List<FluencyFact>>[];
  for (var r = 0; r < rounds; r++) {
    final pool = List<FluencyFact>.of(r == 0 ? sums : all)..shuffle(rng);
    final picked = <FluencyFact>[];
    for (final f in pool) {
      if (picked.length == kFluencyPerRound) break;
      if (r == 0 && picked.isEmpty && f.b == 0) continue;
      if (picked.any((p) => p.a == f.a && p.b == f.b && p.plus == f.plus)) {
        continue;
      }
      picked.add(f);
    }
    out.add(picked);
  }
  return out;
}

// ---- words ----------------------------------------------------------------

String _cap(String s) => s[0].toUpperCase() + s.substring(1);

const String kFluencyIntro = "Welcome to Buddy's practice clearing! Let us do "
    'some quick number puzzles together.';
const String kFluencyCount = 'Count the acorns.';

/// The same nudge for the numbers-only challenge, which has no acorns to
/// count - telling her to count them there pointed at nothing.
const String kFluencyNumbersHint = 'Say the numbers out loud.';
const String kFluencyStreak = 'Three in a row! Buddy is so happy.';
const String kFluencyFinal = 'What a practice! Buddy is so proud of you. '
    'Here are some coins.';

const List<String> kFluencyKeeperLines = <String>[
  'Quick thinking!',
  'So fast!',
  'Buddy loves this game.',
  'Ready for more?',
];

String fluencyKeeperLine(int round) =>
    kFluencyKeeperLines[round % kFluencyKeeperLines.length];

String fluencyQuestion(FluencyFact f) => f.plus
    ? '${_cap(spellNumber(f.a))} plus ${spellNumber(f.b)}?'
    : '${_cap(spellNumber(f.a))} take away ${spellNumber(f.b)}?';

String fluencyRight(FluencyFact f) => f.plus
    ? '${_cap(spellNumber(f.a))} plus ${spellNumber(f.b)} is '
        '${spellNumber(f.answer)}!'
    : '${_cap(spellNumber(f.a))} take away ${spellNumber(f.b)} is '
        '${spellNumber(f.answer)}!';

String fluencyMiss(int rotation, {bool numeralsOnly = false}) =>
    '${warmMissLine(rotation)} '
    '${numeralsOnly ? kFluencyNumbersHint : kFluencyCount}';

List<String> fluencyScriptLines() => <String>{
      kFluencyIntro,
      kFluencyCount,
      kFluencyStreak,
      kFluencyFinal,
      ...kFluencyKeeperLines,
      kFluencyNumbersHint,
      for (var r = 0; r < 4; r++) fluencyMiss(r),
      for (var r = 0; r < 4; r++) fluencyMiss(r, numeralsOnly: true),
      for (final f in kFluencyFacts) ...<String>[
        fluencyQuestion(f),
        fluencyRight(f),
      ],
    }.toList();
