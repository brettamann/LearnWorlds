// The words Where's Buddy speaks: six position prepositions, six landmarks.
//
// Split out of `wheres_buddy_landmarks.dart` because that file holds `Offset`
// coordinates and therefore imports flutter/material. The narration script has
// to stay free of Flutter so `dart run tool/dump_narration_script.dart` can
// compile it, and without these words it could not enumerate the restate line
// ("Here - Buddy is above the pond. Right there."), which is the line the
// activity's own spec mandates after three wrong taps.
//
// The landmark and position catalogs read their words from here through
// getters rather than repeating them, so the two cannot drift. A duplicated
// word list would fail silently: the clip would be rendered under the old
// wording and the game would speak the new one in the synth voice.
//
// The rounds and the keeper's lines live here too, so the recording script
// enumerates exactly what the runner plays.

import '../activities/sub_mode_ids.dart';

/// Landmark id -> the words the narrator uses for it.
/// Landmark id -> the words the narrator says for it.
///
/// These have to agree with the pictures. The fountain was "the unicorn
/// fountain" for as long as there was no fountain drawn; the clearing now
/// reuses the star fountain from the decor set, which has no unicorn on it,
/// and a landmark whose name argues with its picture is worse for a
/// pre-reader than one with no picture at all - she has the picture and the
/// spoken word and nothing else to go on. Renaming was free; drawing a second
/// fountain to preserve an adjective was not worth it, since the word doing
/// the teaching here is the position, not the epithet.
///
/// The mushroom was the same mistake and outlived the fountain's fix by a
/// week: "the giant mushroom", singular and giant, over `toadstool-cluster.
/// png` - three ordinary toadstools, the same picture the decor tray sells
/// her as "Toadstools". Its own sibling in this map is "the rock cluster", so
/// the convention for a clump of things was already here. `shared_names_test.
/// dart` is the check now: where two catalogs name one sprite, they have to
/// share a noun.
const Map<String, String> kWheresBuddyLandmarkNames = <String, String>{
  'fountain': 'the star fountain',
  'hollow-tree': 'the hollow tree',
  'mushroom': 'the toadstools',
  'rock-cluster': 'the rock cluster',
  'cottage': 'the cottage',
  'pond': 'the pond',
};

/// Position id -> the preposition spoken for it.
const Map<String, String> kWheresBuddyPrepositions = <String, String>{
  'above': 'above',
  'below': 'below',
  'next-to': 'next to',
  'behind': 'behind',
  'in-front-of': 'in front of',
  'beside': 'beside',
};

/// The instruction. Two modes: place Buddy somewhere, or find where Buddy is.
///
/// Here rather than in the runner because it interpolates, and the literal
/// sweep in `tool/narration_sources.dart` drops interpolated strings - a
/// template is not a line. Left in the widget it was unreachable by every
/// source that renders a voice, so the sentence telling a pre-reader what to
/// do spoke in the browser synth while the restate line right after it spoke
/// in the narrator's.
///
/// Thirty-six positions times two modes is seventy-two clips for one sentence,
/// which is worth it: this is the sentence, and there is nothing on screen
/// that says it instead.
String wheresBuddyPrompt({
  required String preposition,
  required String landmark,
  required bool placing,
}) => placing
    ? 'Put Buddy $preposition $landmark.'
    : 'Find Buddy — they are $preposition $landmark.';

/// The challenge sub-mode's one extra position word.
///
/// Deliberately NOT in [kWheresBuddyPrepositions]. Every word in that map is a
/// single-landmark offset with a vector in `kWheresBuddyPositions`, and the
/// narration script enumerates it against all six landmarks in both modes — so
/// adding "between" there would render thirty-six clips for sentences the game
/// can never say ("Find Buddy - they are between the pond."). "Between" needs
/// two landmarks or it means nothing, which is the whole point of the
/// challenge, and it gets its own vocabulary here.
const String kWheresBuddyBetween = 'between';

/// The landmark pairs the challenge asks about, in play order.
///
/// Pairs are chosen to be far apart on the clearing and roughly opposed
/// across it, so the midpoint lands in open grass rather than on top of a
/// third landmark — a target sitting on the mushroom would teach "put Buddy on
/// the mushroom", which is the wrong answer to a question about between-ness.
/// The pairing is checked in `wheres_buddy_relational_test.dart`. Read off
/// [kWheresBuddyRelationalRounds], so the two cannot disagree.
final List<(String, String)> kWheresBuddyRelationalPairs = <(String, String)>[
  for (final r in kWheresBuddyRelationalRounds)
    (r.landmarkId, r.secondLandmarkId!),
];

/// "Put Buddy between the hollow tree and the giant mushroom."
///
/// Here rather than in the runner for the same reason as [wheresBuddyPrompt]:
/// it interpolates, and an interpolated string is a template rather than a
/// line, so the literal sweep in `tool/narration_sources.dart` cannot see it.
/// Left in the widget, the one sentence that tells a pre-reader what the
/// challenge even is would have spoken in the browser synth voice.
String wheresBuddyRelationalPrompt(String landmarkIdA, String landmarkIdB) =>
    'Put Buddy $kWheresBuddyBetween '
    '${kWheresBuddyLandmarkNames[landmarkIdA]} and '
    '${kWheresBuddyLandmarkNames[landmarkIdB]}.';

/// What the narrator says after three wrong drops, while showing her.
///
/// The activity spec requires a demonstration rather than a repeated cue, and
/// "right in the middle" is the part a five-year-old can act on — "between" is
/// the word being taught, so restating it alone teaches nothing.
String wheresBuddyRelationalRestate(String landmarkIdA, String landmarkIdB) =>
    'Here — right in the middle, $kWheresBuddyBetween '
    '${kWheresBuddyLandmarkNames[landmarkIdA]} and '
    '${kWheresBuddyLandmarkNames[landmarkIdB]}.';

/// "Here — Buddy is above the pond. Right there."
///
/// What the narrator says after three wrong attempts, while the zone glows -
/// wheres-buddy.md mandates it.
String wheresBuddyRestate({
  required String preposition,
  required String landmark,
}) => 'Here — Buddy is $preposition $landmark. Right there.';

/// One round.
///
/// Ordinarily one landmark and one position word; the six rounds rotate the
/// six K.G.1 prepositions across the clearing. The challenge instead names
/// *two* landmarks and no position word, and the target becomes the point
/// between them.
class WheresBuddyRound {
  const WheresBuddyRound({
    required this.landmarkId,
    required this.keeperLine,
    this.positionId,
    this.secondLandmarkId,
  });

  final String landmarkId;

  /// Null on a relational round: "between" is not an offset from anything, so
  /// there is no vector to apply and no single preposition to speak.
  final String? positionId;

  /// The other end of a relational round, or null for the ordinary ones.
  final String? secondLandmarkId;

  /// What the keeper says over the finished clearing.
  final String keeperLine;

  bool get isRelational => secondLandmarkId != null;
}

const List<WheresBuddyRound> kWheresBuddyRounds = <WheresBuddyRound>[
  WheresBuddyRound(
    landmarkId: 'fountain',
    positionId: 'above',
    keeperLine: 'Above! Right where I asked.',
  ),
  WheresBuddyRound(
    landmarkId: 'mushroom',
    positionId: 'below',
    keeperLine: 'Below the mushroom — perfect.',
  ),
  WheresBuddyRound(
    landmarkId: 'hollow-tree',
    positionId: 'next-to',
    keeperLine: 'Right next to the tree!',
  ),
  WheresBuddyRound(
    landmarkId: 'cottage',
    positionId: 'behind',
    keeperLine: 'Behind the cottage. Sneaky!',
  ),
  WheresBuddyRound(
    landmarkId: 'rock-cluster',
    positionId: 'in-front-of',
    keeperLine: 'In front of the rocks. Nice spot.',
  ),
  WheresBuddyRound(
    landmarkId: 'pond',
    positionId: 'beside',
    keeperLine: 'Beside the pond — you got it.',
  ),
];

/// The challenge: four rounds, each naming two landmarks.
const List<WheresBuddyRound> kWheresBuddyRelationalRounds = <WheresBuddyRound>[
  WheresBuddyRound(
    landmarkId: 'hollow-tree',
    secondLandmarkId: 'mushroom',
    keeperLine: 'Right in the middle. That is what between means!',
  ),
  WheresBuddyRound(
    landmarkId: 'pond',
    secondLandmarkId: 'rock-cluster',
    keeperLine: 'Between the pond and the rocks. Exactly.',
  ),
  WheresBuddyRound(
    landmarkId: 'fountain',
    secondLandmarkId: 'cottage',
    keeperLine: 'Halfway between the two. Well done.',
  ),
  WheresBuddyRound(
    landmarkId: 'rock-cluster',
    secondLandmarkId: 'hollow-tree',
    keeperLine: 'You found the middle again. Buddy is impressed.',
  ),
];

/// How many of the six words a single sitting plays.
const int kWheresBuddyRoundsPerSitting = 4;

/// The sub-mode a launch actually plays. place-mode for anything
/// unrecognised: dragging Buddy somewhere is the safer thing to hand a child
/// than a mode she cannot finish.
String wheresBuddyMode(String subMode) => switch (subMode) {
  WheresBuddyModes.findMode => WheresBuddyModes.findMode,
  WheresBuddyModes.relationalMode => WheresBuddyModes.relationalMode,
  _ => WheresBuddyModes.placeMode,
};

/// The rounds this sub-mode plays, offset by mode.
///
/// find-mode takes words 0-3, place-mode takes 2-5. Both modes still teach
/// four prepositions, all six are covered across the activity, and a kid who
/// plays both doesn't get the same six-item list twice in a row - which was
/// a large part of why the activity felt like a worksheet.
List<WheresBuddyRound> wheresBuddyRoundsFor(String subMode) {
  final mode = wheresBuddyMode(subMode);
  if (mode == WheresBuddyModes.relationalMode) {
    return kWheresBuddyRelationalRounds;
  }
  final offset = mode == WheresBuddyModes.findMode
      ? 0
      : kWheresBuddyRounds.length - kWheresBuddyRoundsPerSitting;
  return kWheresBuddyRounds.sublist(
    offset,
    offset + kWheresBuddyRoundsPerSitting,
  );
}

String _prepositionOf(WheresBuddyRound r) =>
    kWheresBuddyPrepositions[r.positionId ?? 'above'] ??
    r.positionId ??
    'above';

String _landmarkOf(String id) => kWheresBuddyLandmarkNames[id] ?? id;

/// The round's instruction - the whole task, since nothing on screen says it.
String wheresBuddyRoundPrompt(WheresBuddyRound r, {required bool placing}) =>
    r.isRelational
    ? wheresBuddyRelationalPrompt(r.landmarkId, r.secondLandmarkId!)
    : wheresBuddyPrompt(
        preposition: _prepositionOf(r),
        landmark: _landmarkOf(r.landmarkId),
        placing: placing,
      );

/// What the narrator says while showing her the answer.
String wheresBuddyRoundRestate(WheresBuddyRound r) => r.isRelational
    ? wheresBuddyRelationalRestate(r.landmarkId, r.secondLandmarkId!)
    : wheresBuddyRestate(
        preposition: _prepositionOf(r),
        landmark: _landmarkOf(r.landmarkId),
      );

String wheresBuddyIntro(String subMode) => switch (wheresBuddyMode(subMode)) {
  WheresBuddyModes.findMode =>
    "The Buddy loves to play hide-and-seek. I'll tell you "
        'where they are hiding — tap the right spot!',
  WheresBuddyModes.relationalMode =>
    'Here is a tricky one. I will name two things, and you put '
        'Buddy right in the middle of them.',
  _ =>
    "I'll tell you where the Buddy should go. Drag the "
        'Buddy next to, above, or behind the things in the meadow.',
};

String wheresBuddyFinal(String subMode) =>
    wheresBuddyMode(subMode) == WheresBuddyModes.relationalMode
    ? 'Every middle found. Between is a hard one, and you have it.'
    : 'Every position found! You really know your above, below, and '
          'beside.';

/// Every keeper line the activity can say, for the recording script.
List<String> wheresBuddyKeeperScriptLines() => <String>[
  for (final mode in WheresBuddyModes.all) wheresBuddyIntro(mode),
  wheresBuddyFinal(WheresBuddyModes.placeMode),
  wheresBuddyFinal(WheresBuddyModes.relationalMode),
  for (final r in kWheresBuddyRounds) r.keeperLine,
  for (final r in kWheresBuddyRelationalRounds) r.keeperLine,
];
