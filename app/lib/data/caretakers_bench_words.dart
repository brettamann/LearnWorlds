// Caretaker's Bench - its rounds and every word it says. K.MD.1, K.MD.2.
//
// See ten_frame_words.dart for why rounds and words live together here.

import 'asset_paths.dart';
import 'round_pick.dart';
import 'warm_lines.dart';

/// Something with a weight.
class BenchThing {
  const BenchThing(this.name, this.asset, this.weight);

  /// With its article, as spoken: "the pumpkin".
  final String name;
  final String asset;

  /// Arbitrary units; only the comparison matters, and the scale tips by it.
  final double weight;

  String get capName => name[0].toUpperCase() + name.substring(1);
}

const BenchThing kBenchPumpkin =
    BenchThing('the pumpkin', AssetPaths.caretakersPumpkin, 8);
const BenchThing kBenchWatermelon =
    BenchThing('the watermelon', AssetPaths.caretakersWatermelon, 9);
const BenchThing kBenchRock =
    BenchThing('the rock', AssetPaths.caretakersRock, 7);
const BenchThing kBenchApple =
    BenchThing('the apple', AssetPaths.carePantryApple, 3);
const BenchThing kBenchAcorn =
    BenchThing('the acorn', AssetPaths.carePantryAcorn, 1);
const BenchThing kBenchFeather =
    BenchThing('the feather', AssetPaths.rewardFeather, 0.2);
const BenchThing kBenchLeaf =
    BenchThing('the leaf', AssetPaths.caretakersLeaf, 0.3);

/// A caterpillar, measured in round segments. Drawn in code, so its length is
/// exactly what the round says it is.
class BenchCaterpillar {
  const BenchCaterpillar(this.colourName, this.argb, this.segments);
  final String colourName;
  final int argb;
  final int segments;
}

const BenchCaterpillar _green = BenchCaterpillar('green', 0xFF7CC242, 0);
const BenchCaterpillar _purple = BenchCaterpillar('purple', 0xFFA46BD8, 0);
const BenchCaterpillar _blue = BenchCaterpillar('blue', 0xFF4FA6E8, 0);

BenchCaterpillar _cat(BenchCaterpillar base, int n) =>
    BenchCaterpillar(base.colourName, base.argb, n);

enum BenchTask {
  pickHeavy,
  pickLight,
  pickLong,
  pickShort,
  weighHeavier,
  weighLighter,
  compareLonger,
  compareShorter,
  orderThree,
}

class BenchRound {
  const BenchRound(this.task, {this.things = const [], this.cats = const []});
  final BenchTask task;
  final List<BenchThing> things;
  final List<BenchCaterpillar> cats;

  bool get usesScale =>
      task == BenchTask.weighHeavier || task == BenchTask.weighLighter;
  bool get usesThings => things.isNotEmpty;

  /// Index of the right answer among [things] or [cats].
  int get answer {
    switch (task) {
      case BenchTask.pickHeavy:
      case BenchTask.weighHeavier:
        return things[0].weight > things[1].weight ? 0 : 1;
      case BenchTask.pickLight:
      case BenchTask.weighLighter:
        return things[0].weight < things[1].weight ? 0 : 1;
      case BenchTask.pickLong:
      case BenchTask.compareLonger:
        return cats[0].segments > cats[1].segments ? 0 : 1;
      case BenchTask.pickShort:
      case BenchTask.compareShorter:
        return cats[0].segments < cats[1].segments ? 0 : 1;
      case BenchTask.orderThree:
        return -1;
    }
  }
}

const String kBenchSubDescribe = 'describe-attributes';
const String kBenchSubCompare = 'compare-two';
const String kBenchSubOrder = 'order-three-by-length';

final Map<String, List<BenchRound>> kBenchRounds = <String, List<BenchRound>>{
  kBenchSubDescribe: <BenchRound>[
    const BenchRound(
      BenchTask.pickHeavy,
      things: <BenchThing>[kBenchFeather, kBenchPumpkin],
    ),
    BenchRound(
      BenchTask.pickLong,
      cats: <BenchCaterpillar>[_cat(_green, 7), _cat(_purple, 3)],
    ),
    const BenchRound(
      BenchTask.pickLight,
      things: <BenchThing>[kBenchRock, kBenchLeaf],
    ),
    BenchRound(
      BenchTask.pickShort,
      cats: <BenchCaterpillar>[_cat(_blue, 6), _cat(_green, 2)],
    ),
    const BenchRound(
      BenchTask.pickHeavy,
      things: <BenchThing>[kBenchWatermelon, kBenchAcorn],
    ),
    const BenchRound(
      BenchTask.pickLight,
      things: <BenchThing>[kBenchFeather, kBenchApple],
    ),
    BenchRound(
      BenchTask.pickLong,
      cats: <BenchCaterpillar>[_cat(_blue, 2), _cat(_purple, 6)],
    ),
    BenchRound(
      BenchTask.pickShort,
      cats: <BenchCaterpillar>[_cat(_purple, 3), _cat(_green, 7)],
    ),
  ],
  kBenchSubCompare: <BenchRound>[
    const BenchRound(
      BenchTask.weighHeavier,
      things: <BenchThing>[kBenchApple, kBenchPumpkin],
    ),
    BenchRound(
      BenchTask.compareLonger,
      cats: <BenchCaterpillar>[_cat(_purple, 4), _cat(_green, 6)],
    ),
    const BenchRound(
      BenchTask.weighLighter,
      things: <BenchThing>[kBenchRock, kBenchAcorn],
    ),
    BenchRound(
      BenchTask.compareShorter,
      cats: <BenchCaterpillar>[_cat(_blue, 5), _cat(_purple, 4)],
    ),
    const BenchRound(
      BenchTask.weighHeavier,
      things: <BenchThing>[kBenchWatermelon, kBenchApple],
    ),
    const BenchRound(
      BenchTask.weighLighter,
      things: <BenchThing>[kBenchLeaf, kBenchPumpkin],
    ),
    BenchRound(
      BenchTask.compareLonger,
      cats: <BenchCaterpillar>[_cat(_green, 5), _cat(_blue, 3)],
    ),
    BenchRound(
      BenchTask.compareShorter,
      cats: <BenchCaterpillar>[_cat(_purple, 3), _cat(_green, 6)],
    ),
  ],
  kBenchSubOrder: <BenchRound>[
    BenchRound(
      BenchTask.orderThree,
      cats: <BenchCaterpillar>[
        _cat(_green, 5),
        _cat(_purple, 2),
        _cat(_blue, 7),
      ],
    ),
    BenchRound(
      BenchTask.orderThree,
      cats: <BenchCaterpillar>[
        _cat(_blue, 3),
        _cat(_green, 6),
        _cat(_purple, 4),
      ],
    ),
    BenchRound(
      BenchTask.orderThree,
      cats: <BenchCaterpillar>[
        _cat(_purple, 7),
        _cat(_blue, 5),
        _cat(_green, 3),
      ],
    ),
    BenchRound(
      BenchTask.orderThree,
      cats: <BenchCaterpillar>[
        _cat(_green, 4),
        _cat(_blue, 7),
        _cat(_purple, 2),
      ],
    ),
    BenchRound(
      BenchTask.orderThree,
      cats: <BenchCaterpillar>[
        _cat(_purple, 6),
        _cat(_green, 2),
        _cat(_blue, 4),
      ],
    ),
  ],
};

/// The rounds for one visit.
///
/// The two-thing sub-modes take two weighing rounds and two measuring rounds
/// and alternate them, weight first - the scale is the part she likes best,
/// and alternating keeps "heavy" and "long" from blurring into one word for
/// "big". The biggest difference goes first within each.
List<BenchRound> benchRoundsFor(String subMode, {int seed = 0}) {
  final pool = kBenchRounds[subMode] ?? kBenchRounds[kBenchSubDescribe]!;
  if (subMode == kBenchSubOrder) {
    return pickRounds(
      pool,
      count: 3,
      seed: seed,
      ease: (r) => -_spread(r.cats.map((c) => c.segments.toDouble())),
    );
  }
  final weights = pickRounds(
    <BenchRound>[
      for (final r in pool)
        if (r.usesThings) r,
    ],
    count: 2,
    seed: seed,
    ease: (r) => -_spread(r.things.map((t) => t.weight)),
  );
  final lengths = pickRounds(
    <BenchRound>[
      for (final r in pool)
        if (!r.usesThings) r,
    ],
    count: 2,
    seed: seed + 1,
    ease: (r) => -_spread(r.cats.map((c) => c.segments.toDouble())),
  );
  return <BenchRound>[
    for (var i = 0; i < 2; i++) ...<BenchRound>[weights[i], lengths[i]],
  ];
}

double _spread(Iterable<double> xs) {
  final l = xs.toList()..sort();
  return l.last - l.first;
}

// ---- words ----------------------------------------------------------------

const String kBenchIntro = "Welcome to the Caretaker's bench! We have things "
    'to weigh and caterpillars to measure. Let us find out which is which.';
const String kBenchDownSide = 'Look at the scale. The heavy side goes down.';
const String kBenchLookEnds = 'Look where they end.';
const String kBenchFinal = 'Everything is weighed and measured. What a '
    'careful caretaker you are! Here are some coins.';

const List<String> kBenchOrderLines = <String>[
  'Shortest.',
  'Longer.',
  'Longest!',
];

const List<String> kBenchKeeperLines = <String>[
  'Well measured!',
  'A fine caretaker.',
  'You looked so carefully.',
  'Just right.',
];

String benchKeeperLine(int round) =>
    kBenchKeeperLines[round % kBenchKeeperLines.length];

String benchPrompt(BenchRound r) {
  switch (r.task) {
    case BenchTask.pickHeavy:
      return 'Which one is heavy?';
    case BenchTask.pickLight:
      return 'Which one is light?';
    case BenchTask.pickLong:
      return 'Which caterpillar is long?';
    case BenchTask.pickShort:
      return 'Which caterpillar is short?';
    case BenchTask.weighHeavier:
    case BenchTask.weighLighter:
      return 'Put ${r.things[0].name} and ${r.things[1].name} on the scale.';
    case BenchTask.compareLonger:
      return 'Which caterpillar is longer?';
    case BenchTask.compareShorter:
      return 'Which caterpillar is shorter?';
    case BenchTask.orderThree:
      return 'Tap the caterpillars from the shortest to the longest.';
  }
}

/// The weighing rounds ask their question once both are on the pans.
String benchWeighQuestion(BenchRound r) => r.task == BenchTask.weighHeavier
    ? 'Which one is heavier?'
    : 'Which one is lighter?';

String benchDone(BenchRound r) {
  final i = r.answer;
  switch (r.task) {
    case BenchTask.pickHeavy:
      return 'Yes! ${r.things[i].capName} is heavy. '
          '${r.things[1 - i].capName} is light.';
    case BenchTask.pickLight:
      return 'Yes! ${r.things[i].capName} is light. '
          '${r.things[1 - i].capName} is heavy.';
    case BenchTask.pickLong:
      return 'Yes! The ${r.cats[i].colourName} caterpillar is long. The '
          '${r.cats[1 - i].colourName} one is short.';
    case BenchTask.pickShort:
      return 'Yes! The ${r.cats[i].colourName} caterpillar is short. The '
          '${r.cats[1 - i].colourName} one is long.';
    case BenchTask.weighHeavier:
      return 'Yes! ${r.things[i].capName} is heavier than '
          '${r.things[1 - i].name}.';
    case BenchTask.weighLighter:
      return 'Yes! ${r.things[i].capName} is lighter than '
          '${r.things[1 - i].name}.';
    case BenchTask.compareLonger:
      return 'Yes! The ${r.cats[i].colourName} caterpillar is longer.';
    case BenchTask.compareShorter:
      return 'Yes! The ${r.cats[i].colourName} caterpillar is shorter.';
    case BenchTask.orderThree:
      return 'Shortest, longer, longest. Well done!';
  }
}

/// What to look at - the half of a miss line that is advice.
String benchLookHint(BenchRound r) => switch (r.task) {
      BenchTask.weighHeavier || BenchTask.weighLighter => kBenchDownSide,
      BenchTask.orderThree => 'Find the shortest one left.',
      BenchTask.pickHeavy || BenchTask.pickLight => 'Think about lifting it.',
      _ => kBenchLookEnds,
    };

String benchMiss(BenchRound r, int rotation) =>
    '${warmMissLine(rotation)} ${benchLookHint(r)}';

List<String> benchScriptLines() {
  final lines = <String>{
    kBenchIntro,
    kBenchDownSide,
    kBenchLookEnds,
    kBenchFinal,
    ...kBenchOrderLines,
    ...kBenchKeeperLines,
  };
  for (final rounds in kBenchRounds.values) {
    for (final r in rounds) {
      lines
        ..add(benchPrompt(r))
        ..add(benchDone(r));
      if (r.usesScale) lines.add(benchWeighQuestion(r));
      lines.add(benchLookHint(r));
      for (var k = 0; k < 4; k++) {
        lines.add(benchMiss(r, k));
      }
    }
  }
  return lines.toList();
}
