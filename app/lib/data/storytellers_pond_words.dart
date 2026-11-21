// Storyteller's Pond - its stories and every word it says. K.OA.2, K.OA.1.
//
// See ten_frame_words.dart for why rounds and words live together here.

import '../activities/sub_mode_ids.dart';
import 'asset_paths.dart';
import 'number_words.dart';
import 'round_pick.dart';
import 'warm_lines.dart';

class StoryCreature {
  const StoryCreature(this.singular, this.plural, this.asset);
  final String singular;
  final String plural;
  final String asset;
}

const StoryCreature kStoryDuckling = StoryCreature(
  'duckling',
  'ducklings',
  AssetPaths.storytellersDuckling,
);
const StoryCreature kStoryFrog = StoryCreature(
  'frog',
  'frogs',
  AssetPaths.tenFrameFrogGreen,
);
const StoryCreature kStoryBunny = StoryCreature(
  'bunny',
  'bunnies',
  AssetPaths.countingParadeMossBunny,
);

enum StoryKind { addTo, takeFrom, putTogether, takeApart, twoStep }

class Story {
  const Story(
    this.kind,
    this.creature,
    this.a,
    this.b, {
    this.other,
    this.c = 0,
  });

  final StoryKind kind;
  final StoryCreature creature;

  /// The starting group.
  final int a;

  /// How many arrive, leave, or (put-together) are in the second group.
  final int b;

  /// Two-step: how many leave after the arrivals.
  final int c;

  /// Put-together: the second kind of animal.
  final StoryCreature? other;

  int get answer => switch (kind) {
    StoryKind.addTo || StoryKind.putTogether => a + b,
    StoryKind.takeFrom => a - b,
    StoryKind.takeApart => a,
    StoryKind.twoStep => a + b - c,
  };
}

/// Every story each sub-mode can tell. A visit tells four of them (two-step,
/// three), picked by [storiesFor]. Within seven animals, which is what fits
/// on the pond at a size she can tap, and one kind of animal per story except
/// put-together, whose whole point is two kinds counted as one group.
const Map<String, List<Story>> kStories = <String, List<Story>>{
  StorytellersPondModes.addTo: <Story>[
    Story(StoryKind.addTo, kStoryDuckling, 2, 1),
    Story(StoryKind.addTo, kStoryFrog, 3, 1),
    Story(StoryKind.addTo, kStoryBunny, 2, 2),
    Story(StoryKind.addTo, kStoryFrog, 3, 2),
    Story(StoryKind.addTo, kStoryDuckling, 4, 2),
    Story(StoryKind.addTo, kStoryBunny, 3, 3),
    Story(StoryKind.addTo, kStoryDuckling, 5, 2),
    Story(StoryKind.addTo, kStoryFrog, 4, 3),
  ],
  StorytellersPondModes.takeFrom: <Story>[
    Story(StoryKind.takeFrom, kStoryFrog, 4, 1),
    Story(StoryKind.takeFrom, kStoryDuckling, 3, 1),
    Story(StoryKind.takeFrom, kStoryDuckling, 5, 2),
    Story(StoryKind.takeFrom, kStoryBunny, 4, 2),
    Story(StoryKind.takeFrom, kStoryBunny, 6, 3),
    Story(StoryKind.takeFrom, kStoryFrog, 5, 3),
    Story(StoryKind.takeFrom, kStoryDuckling, 6, 2),
    Story(StoryKind.takeFrom, kStoryFrog, 7, 3),
  ],
  StorytellersPondModes.putTogether: <Story>[
    Story(StoryKind.putTogether, kStoryDuckling, 2, 2, other: kStoryFrog),
    Story(StoryKind.putTogether, kStoryFrog, 3, 1, other: kStoryBunny),
    Story(StoryKind.putTogether, kStoryBunny, 2, 4, other: kStoryDuckling),
    Story(StoryKind.putTogether, kStoryDuckling, 4, 3, other: kStoryFrog),
    Story(StoryKind.putTogether, kStoryFrog, 2, 1, other: kStoryDuckling),
    Story(StoryKind.putTogether, kStoryBunny, 3, 2, other: kStoryFrog),
    Story(StoryKind.putTogether, kStoryDuckling, 3, 3, other: kStoryBunny),
  ],
  StorytellersPondModes.takeApart: <Story>[
    Story(StoryKind.takeApart, kStoryDuckling, 4, 0),
    Story(StoryKind.takeApart, kStoryFrog, 5, 0),
    Story(StoryKind.takeApart, kStoryDuckling, 6, 0),
    Story(StoryKind.takeApart, kStoryBunny, 5, 0),
    Story(StoryKind.takeApart, kStoryFrog, 3, 0),
    Story(StoryKind.takeApart, kStoryBunny, 7, 0),
  ],
  StorytellersPondModes.twoStep: <Story>[
    Story(StoryKind.twoStep, kStoryFrog, 3, 2, c: 1),
    Story(StoryKind.twoStep, kStoryDuckling, 4, 2, c: 3),
    Story(StoryKind.twoStep, kStoryBunny, 2, 3, c: 2),
    Story(StoryKind.twoStep, kStoryDuckling, 3, 1, c: 2),
    Story(StoryKind.twoStep, kStoryFrog, 4, 3, c: 2),
  ],
};

/// The stories for one visit, the gentlest first.
List<Story> storiesFor(String subMode, {int seed = 0}) {
  final pool = kStories[subMode] ?? kStories[StorytellersPondModes.addTo]!;
  return pickRounds(
    pool,
    count: subMode == StorytellersPondModes.twoStep ? 3 : 4,
    seed: seed,
    ease: (s) => s.a + s.b + s.c,
  );
}

// ---- words ----------------------------------------------------------------

String _n(int n) => spellNumber(n);
String _cap(String s) => s[0].toUpperCase() + s.substring(1);
String _of(int n, StoryCreature c) => n == 1 ? c.singular : c.plural;

const String kStoryIntro =
    'Hello, I am the storyteller turtle. Listen to '
    'my stories, and help the animals act them out!';
const String kStoryBye = 'Bye-bye!';
const String kStoryCountAgain = 'Count them again.';
const String kStoryDoneSplit = 'Tap the check when you are ready.';
const String kStoryFinal =
    'Thank you for helping with my stories. Here are '
    'some coins. Come back for more stories soon!';

const List<String> kStoryKeeperLines = <String>[
  'What a lovely story.',
  'The end! Well told.',
  'I have another story for you.',
  'Listen, here comes the next one.',
];

String storyKeeperLine(int round) =>
    kStoryKeeperLines[round % kStoryKeeperLines.length];

/// The story, told as the round opens.
String storyOpening(Story s) {
  final c = s.creature;
  switch (s.kind) {
    case StoryKind.addTo:
    case StoryKind.twoStep:
      return '${_cap(_n(s.a))} ${_of(s.a, c)} are at the pond. '
          '${_cap(_n(s.b))} more ${s.b == 1 ? 'wants' : 'want'} to play! '
          '${s.b == 1 ? 'Tap it to call it over.' : 'Tap them to call them over.'}';
    case StoryKind.takeFrom:
      return '${_cap(_n(s.a))} ${_of(s.a, c)} are at the pond. '
          '${_cap(_n(s.b))} ${s.b == 1 ? 'has' : 'have'} to go home. '
          'Tap ${_n(s.b)} to wave goodbye.';
    case StoryKind.putTogether:
      return '${_cap(_n(s.a))} ${_of(s.a, c)} and ${_n(s.b)} '
          '${_of(s.b, s.other!)} are at the pond. Tap each one to count them '
          'all.';
    case StoryKind.takeApart:
      return '${_cap(_n(s.a))} ${c.plural} want to swim. Tap some to send them '
          'into the water, but keep some on the grass.';
  }
}

/// Two-step, after the arrivals.
String storySecondPart(Story s) =>
    'Now ${_n(s.c)} ${s.c == 1 ? 'has' : 'have'} to go home. '
    'Tap ${_n(s.c)} to wave goodbye.';

/// She waved goodbye to more than were leaving.
String storyJustThat(int n) =>
    'Just ${_n(n)} ${n == 1 ? 'goes' : 'go'} home. The rest can stay.';

String storyQuestion(Story s) => switch (s.kind) {
  StoryKind.addTo ||
  StoryKind.twoStep => 'How many ${s.creature.plural} are there now?',
  StoryKind.takeFrom => 'How many ${s.creature.plural} are left?',
  StoryKind.putTogether => 'How many animals are there altogether?',
  StoryKind.takeApart => kStoryDoneSplit,
};

/// Said when she has the answer. [inWater] only matters for take-apart.
String storyDone(Story s, {int inWater = 0}) {
  final t = s.answer;
  switch (s.kind) {
    case StoryKind.addTo:
      return '${_cap(_n(t))}! ${_cap(_n(s.a))} and ${_n(s.b)} more make '
          '${_n(t)}.';
    case StoryKind.takeFrom:
      return '${_cap(_n(t))}! ${_cap(_n(s.a))} take away ${_n(s.b)} leaves '
          '${_n(t)}.';
    case StoryKind.putTogether:
      return '${_cap(_n(t))}! ${_cap(_n(s.a))} and ${_n(s.b)} make ${_n(t)}.';
    case StoryKind.takeApart:
      return '${_cap(_n(inWater))} in the water and ${_n(s.a - inWater)} on '
          'the grass make ${_n(s.a)}.';
    case StoryKind.twoStep:
      return '${_cap(_n(t))} ${_of(t, s.creature)} at the pond now!';
  }
}

/// The story as a number sentence, for the abstract layer. Written, never
/// spoken, so it is not in the recording script. Take-apart is written from
/// the split she chose: "5 = 2 + 3".
String storySentence(Story s, {int inWater = 0}) => switch (s.kind) {
  StoryKind.addTo || StoryKind.putTogether => '${s.a} + ${s.b} = ${s.answer}',
  StoryKind.takeFrom => '${s.a} − ${s.b} = ${s.answer}',
  StoryKind.twoStep => '${s.a} + ${s.b} − ${s.c} = ${s.answer}',
  StoryKind.takeApart => '${s.a} = $inWater + ${s.a - inWater}',
};

String storyMiss(int rotation) => '${warmMissLine(rotation)} $kStoryCountAgain';

List<String> storyScriptLines() {
  final lines = <String>{
    kStoryIntro,
    kStoryBye,
    kStoryCountAgain,
    kStoryDoneSplit,
    kStoryFinal,
    ...kStoryKeeperLines,
    for (var r = 0; r < 4; r++) storyMiss(r),
  };
  for (final stories in kStories.values) {
    for (final s in stories) {
      lines
        ..add(storyOpening(s))
        ..add(storyQuestion(s));
      if (s.kind == StoryKind.takeApart) {
        for (var w = 1; w < s.a; w++) {
          lines.add(storyDone(s, inWater: w));
        }
      } else {
        lines.add(storyDone(s));
      }
      if (s.kind == StoryKind.takeFrom) lines.add(storyJustThat(s.b));
      if (s.kind == StoryKind.twoStep) {
        lines
          ..add(storySecondPart(s))
          ..add(storyJustThat(s.c));
      }
    }
  }
  return lines.toList();
}
