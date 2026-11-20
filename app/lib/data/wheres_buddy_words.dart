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
}) =>
    placing
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
/// The pairing is checked in `wheres_buddy_relational_test.dart`.
const List<(String, String)> kWheresBuddyRelationalPairs = <(String, String)>[
  ('hollow-tree', 'mushroom'),
  ('pond', 'rock-cluster'),
  ('fountain', 'cottage'),
  ('rock-cluster', 'hollow-tree'),
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
