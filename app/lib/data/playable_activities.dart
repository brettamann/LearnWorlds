// Which activities have a runner behind them today.
//
// This existed only as the if-chain in `activity_screen.dart`, which meant
// nothing else could ask the question — and the Sanctuary map badly needed to
// ask it. The map draws eleven lesson nodes in a fixed path and reveals each
// one when the node before it is *completed*; a node is completed when all its
// sub-modes are, which needs a runner. Node 3 is Ten-Frame Pond, which has
// none. So the path stopped dead at the third node, and Build-a-Habitat and
// Where's Buddy — both finished, both narrated, both with clips rendered —
// were unreachable in ordinary play. Two of the four built activities, walled
// off behind one that was never built, which is a fair part of why the game
// felt repetitive.
//
// Keeping this list honest matters more than it looks: `activity_screen.dart`
// falls through to a line of English on a blank screen, which to a pre-reader
// is indistinguishable from the app breaking. `test/sanctuary_path_test.dart`
// checks this set against what that screen actually dispatches, so the two
// cannot drift.

/// Activity ids that can be played end to end right now.
///
/// Add an id here in the same change that adds its runner — the map reads this
/// to decide which nodes are awake, so a runner nobody lists stays invisible,
/// and an id listed with no runner sends a child to a dead end.
const Set<String> kPlayableActivities = <String>{
  'counting-parade',
  'shape-garden',
  'wheres-buddy',
  'build-a-habitat',
  'ten-frame-pond',
  'care-pantry',
  'scribes-tower',
  'storytellers-pond',
  'caretakers-bench',
  'picnic-baskets',
  'fluency-within-5',
};

/// Tests only: stand in for [kPlayableActivities].
///
/// As of 2026-09-24 every Sanctuary node has a runner, so the map has no
/// sleeping node in it - but the asleep machinery (drawn differently, answers
/// a tap out loud, never walls off the nodes behind it) is exactly what the
/// next region will need on its first day. The tests that hold it set this to
/// the four-activity map they were written against.
Set<String>? debugPlayableOverride;

/// Whether [activityId] can be played.
bool isActivityPlayable(String activityId) =>
    (debugPlayableOverride ?? kPlayableActivities).contains(activityId);

/// The Sanctuary as it was before its other seven places were built. What the
/// asleep-node tests pretend the world is.
const Set<String> kFourActivitySanctuary = <String>{
  'counting-parade',
  'shape-garden',
  'wheres-buddy',
  'build-a-habitat',
};

/// A readable name for an activity the registry has never heard of.
///
/// Four of the eleven Sanctuary nodes (`care-pantry`, `caretakers-bench`,
/// `picnic-baskets`, `fluency-within-5`) have a spec and a place on the map but
/// no entry in `data/activity-registry/kindergarten.json`, so the map had
/// nothing to put on their banners and printed the raw id. A parchment scroll
/// in the middle of a storybook map reading "care-pantry" is the sort of thing
/// that only ever gets noticed by the person who wrote it.
String placeholderActivityName(String activityId) => activityId
    .split('-')
    .map(
      (word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
    )
    .join(' ');
