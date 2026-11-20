// Picnic Baskets - its rounds and every word it says. K.CC.6, K.CC.7.
//
// See ten_frame_words.dart for why rounds and words live together here.

import 'asset_paths.dart';
import 'number_words.dart';
import 'round_pick.dart';
import 'warm_lines.dart';

class Picnicker {
  const Picnicker(this.name, this.asset);

  /// With its article: "the unicorn".
  final String name;
  final String asset;

  String get capName => name[0].toUpperCase() + name.substring(1);
}

const Picnicker kPicnicUnicorn =
    Picnicker('the unicorn', AssetPaths.countingParadeBabyUnicorn);
const Picnicker kPicnicDragon =
    Picnicker('the dragon', AssetPaths.countingParadeBabyDragon);
const Picnicker kPicnicCentaur =
    Picnicker('the centaur', AssetPaths.countingParadeBabyCentaur);

class PicnicTreat {
  const PicnicTreat(this.plural, this.asset);
  final String plural;
  final String asset;
}

const PicnicTreat kTreatCherries =
    PicnicTreat('cherries', AssetPaths.carePantryBerries);
const PicnicTreat kTreatApples =
    PicnicTreat('apples', AssetPaths.carePantryApple);
const PicnicTreat kTreatAcorns =
    PicnicTreat('acorns', AssetPaths.carePantryAcorn);
const PicnicTreat kTreatCarrots =
    PicnicTreat('carrots', AssetPaths.carePantryCarrot);

enum PicnicTask { match, count, numerals, three }

class PicnicRound {
  const PicnicRound(this.task, this.treat, this.counts);
  final PicnicTask task;
  final PicnicTreat treat;

  /// One count per picnicker, in seating order.
  final List<int> counts;

  List<Picnicker> get diners => counts.length == 3
      ? const <Picnicker>[kPicnicUnicorn, kPicnicDragon, kPicnicCentaur]
      : const <Picnicker>[kPicnicUnicorn, kPicnicDragon];

  bool get same => counts.length == 2 && counts[0] == counts[1];

  /// Index of the diner with the most; -1 if the two are the same.
  int get most {
    if (same) return -1;
    var best = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] > counts[best]) best = i;
    }
    return best;
  }

  int get fewest {
    var best = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] < counts[best]) best = i;
    }
    return best;
  }
}

const String kPicnicSubMatch = 'match-by-line';
const String kPicnicSubCount = 'count-and-compare';
const String kPicnicSubNumerals = 'numeral-compare';
const String kPicnicSubThree = 'three-way-compare';

/// Every round each sub-mode can play; [picnicRoundsFor] picks a visit's.
///
/// One round per two-diner visit is a tie, because "the same" is an answer
/// K.CC.6 asks for and a child who has only ever seen one side win will not
/// think to give it. So those pools keep their ties apart and a visit takes
/// exactly one. At most seven treats a row, which is what fits on the blanket
/// at a size she can tap.
const Map<String, List<PicnicRound>> kPicnicRounds =
    <String, List<PicnicRound>>{
  kPicnicSubMatch: <PicnicRound>[
    PicnicRound(PicnicTask.match, kTreatCherries, <int>[4, 3]),
    PicnicRound(PicnicTask.match, kTreatApples, <int>[2, 5]),
    PicnicRound(PicnicTask.match, kTreatCarrots, <int>[6, 4]),
    PicnicRound(PicnicTask.match, kTreatAcorns, <int>[3, 5]),
    PicnicRound(PicnicTask.match, kTreatCherries, <int>[5, 2]),
    PicnicRound(PicnicTask.match, kTreatCarrots, <int>[3, 6]),
    PicnicRound(PicnicTask.match, kTreatAcorns, <int>[4, 4]),
    PicnicRound(PicnicTask.match, kTreatApples, <int>[3, 3]),
    PicnicRound(PicnicTask.match, kTreatCherries, <int>[5, 5]),
  ],
  kPicnicSubCount: <PicnicRound>[
    PicnicRound(PicnicTask.count, kTreatApples, <int>[5, 3]),
    PicnicRound(PicnicTask.count, kTreatCherries, <int>[3, 6]),
    PicnicRound(PicnicTask.count, kTreatAcorns, <int>[7, 6]),
    PicnicRound(PicnicTask.count, kTreatCarrots, <int>[4, 6]),
    PicnicRound(PicnicTask.count, kTreatCherries, <int>[6, 4]),
    PicnicRound(PicnicTask.count, kTreatApples, <int>[5, 7]),
    PicnicRound(PicnicTask.count, kTreatCarrots, <int>[5, 5]),
    PicnicRound(PicnicTask.count, kTreatAcorns, <int>[6, 6]),
    PicnicRound(PicnicTask.count, kTreatCherries, <int>[4, 4]),
  ],
  kPicnicSubNumerals: <PicnicRound>[
    PicnicRound(PicnicTask.numerals, kTreatApples, <int>[7, 4]),
    PicnicRound(PicnicTask.numerals, kTreatApples, <int>[3, 8]),
    PicnicRound(PicnicTask.numerals, kTreatApples, <int>[6, 5]),
    PicnicRound(PicnicTask.numerals, kTreatApples, <int>[2, 9]),
    PicnicRound(PicnicTask.numerals, kTreatApples, <int>[5, 8]),
    PicnicRound(PicnicTask.numerals, kTreatApples, <int>[9, 6]),
    PicnicRound(PicnicTask.numerals, kTreatApples, <int>[4, 3]),
    PicnicRound(PicnicTask.numerals, kTreatApples, <int>[10, 7]),
  ],
  // A clear most and a clear fewest in every one: "and who has the fewest?"
  // must have an answer.
  kPicnicSubThree: <PicnicRound>[
    PicnicRound(PicnicTask.three, kTreatCherries, <int>[3, 5, 2]),
    PicnicRound(PicnicTask.three, kTreatAcorns, <int>[6, 4, 5]),
    PicnicRound(PicnicTask.three, kTreatApples, <int>[2, 3, 6]),
    PicnicRound(PicnicTask.three, kTreatCarrots, <int>[4, 2, 5]),
    PicnicRound(PicnicTask.three, kTreatCherries, <int>[5, 6, 3]),
  ],
};

/// The rounds for one visit.
///
/// Easiest first: the biggest difference, which matching or counting makes
/// most obvious. Two-diner visits then get one tie, somewhere after the first
/// round - a tie first would be a strange thing to open a picnic on.
List<PicnicRound> picnicRoundsFor(String subMode, {int seed = 0}) {
  final pool = kPicnicRounds[subMode] ?? kPicnicRounds[kPicnicSubMatch]!;
  num ease(PicnicRound r) {
    final sorted = List<int>.of(r.counts)..sort();
    return -(sorted.last - sorted.first);
  }

  if (subMode == kPicnicSubThree) {
    return pickRounds(pool, count: 3, seed: seed, ease: ease);
  }
  final ties = <PicnicRound>[
    for (final r in pool)
      if (r.same) r,
  ];
  final rounds = pickRounds(
    <PicnicRound>[
      for (final r in pool)
        if (!r.same) r,
    ],
    count: ties.isEmpty ? 4 : 3,
    seed: seed,
    ease: ease,
  );
  if (ties.isNotEmpty) {
    rounds.insert(1 + seed % 3, ties[seed % ties.length]);
  }
  return rounds;
}

// ---- words ----------------------------------------------------------------

String _cap(String s) => s[0].toUpperCase() + s.substring(1);

const String kPicnicIntro = 'It is a picnic! The unicorn and the dragon are '
    'sharing treats. Let us find out who has more.';
const String kPicnicLeftOver =
    'Look! Some have no partner. They are left over.';
const String kPicnicFinal = 'What a lovely picnic. Everyone had plenty! '
    'Here are some coins for you.';

const List<String> kPicnicKeeperLines = <String>[
  'Yum!',
  'What a feast.',
  'Everyone is so happy.',
  'Pass the cherries, please!',
];

String picnicKeeperLine(int round) =>
    kPicnicKeeperLines[round % kPicnicKeeperLines.length];

String picnicPrompt(PicnicRound r) => switch (r.task) {
      PicnicTask.match =>
        'Tap a treat to find it a partner. Who has more ${r.treat.plural}?',
      PicnicTask.count => 'Tap to count the ${r.treat.plural}. Who has more?',
      PicnicTask.numerals => 'Which number is bigger?',
      PicnicTask.three => 'Tap to count the ${r.treat.plural}. '
          'Who has the most?',
    };

String picnicAsk(PicnicRound r) => r.task == PicnicTask.three
    ? 'Who has the most ${r.treat.plural}?'
    : 'Who has more ${r.treat.plural}? Or is it the same?';

const String kPicnicAskFewest = 'And who has the fewest?';

String picnicDone(PicnicRound r) {
  if (r.task == PicnicTask.numerals) {
    final big = r.counts[0] > r.counts[1] ? r.counts[0] : r.counts[1];
    final small = r.counts[0] > r.counts[1] ? r.counts[1] : r.counts[0];
    return 'Yes! ${_cap(spellNumber(big))} is bigger than '
        '${spellNumber(small)}.';
  }
  if (r.same) {
    return 'Yes, the same! ${_cap(spellNumber(r.counts[0]))} and '
        '${spellNumber(r.counts[1])}.';
  }
  final d = r.diners[r.most];
  return 'Yes! ${d.capName} has more ${r.treat.plural}.';
}

String picnicDoneMost(PicnicRound r) =>
    'Yes! ${r.diners[r.most].capName} has the most.';
String picnicDoneFewest(PicnicRound r) =>
    'Yes! ${r.diners[r.fewest].capName} has the fewest.';

/// The advice half of a miss, also said on its own as a hint.
String picnicLookHint(PicnicRound r) => switch (r.task) {
      PicnicTask.numerals => 'Look at the dots.',
      PicnicTask.match => 'Look at the ones left over.',
      _ => 'Count them again.',
    };

String picnicMiss(PicnicRound r, int rotation) =>
    '${warmMissLine(rotation)} ${picnicLookHint(r)}';

List<String> picnicScriptLines() {
  final lines = <String>{
    kPicnicIntro,
    kPicnicLeftOver,
    kPicnicFinal,
    kPicnicAskFewest,
    ...kPicnicKeeperLines,
  };
  for (final rounds in kPicnicRounds.values) {
    for (final r in rounds) {
      lines
        ..add(picnicPrompt(r))
        ..add(picnicDone(r));
      if (r.task != PicnicTask.numerals) lines.add(picnicAsk(r));
      if (r.task == PicnicTask.three) {
        lines
          ..add(picnicDoneMost(r))
          ..add(picnicDoneFewest(r));
      }
      lines.add(picnicLookHint(r));
      for (var k = 0; k < 4; k++) {
        lines.add(picnicMiss(r, k));
      }
    }
  }
  return lines.toList();
}
