// Which activities can be played today.
//
// The Sanctuary map needs to ask this: it reveals each node when the one
// before it is completed, and a node with no runner can never be completed.
// Such a node is drawn asleep and skipped over rather than walling off the
// path (see sanctuary_sequence.dart).
//
// An activity is playable exactly when it has a runner registered in
// `kActivityRunners`, so this set cannot drift from what ActivityScreen can
// actually open.

import '../activities/activity_ids.dart';
import '../activities/activity_runners.dart';

/// Activity ids that can be played end to end right now.
Set<String> get kPlayableActivities => kActivityRunners.keys.toSet();

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
  ActivityIds.countingParade,
  ActivityIds.shapeGarden,
  ActivityIds.wheresBuddy,
  ActivityIds.buildAHabitat,
};

/// A readable name for an activity the registry has not given a name for -
/// one that is on the map but not yet registered, or any node while the
/// registry is still loading. A parchment scroll on a storybook map reading
/// "care-pantry" is the sort of thing only the person who wrote it notices.
String placeholderActivityName(String activityId) => activityId
    .split('-')
    .map(
      (word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
    )
    .join(' ');
