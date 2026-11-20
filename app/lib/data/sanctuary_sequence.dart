// Sanctuary map sequence — single source of truth for the magenta anchor
// codes, the order in which they're drawn, and which activity id sits at
// each lesson code. Both the map screen and the activity screen consult
// this so they can't drift.
//
// When the placeholder art is replaced with the real Sanctuary map, only
// the rectangle positions in `sanctuary_map_screen.dart` need to change —
// these codes + activity ids stay valid.

import 'playable_activities.dart';

/// Magenta-anchor sequence codes in path order (`#FF00F0`..`#FF00FB`).
/// F0 is the story-kickoff cutscene; F1..FB are the 11 K lessons.
const List<int> kSanctuarySequence = [
  0xF0,
  0xF1,
  0xF2,
  0xF3,
  0xF4,
  0xF5,
  0xF6,
  0xF7,
  0xF8,
  0xF9,
  0xFA,
  0xFB,
];

/// First sequence code (the cutscene anchor). Marked explored automatically
/// after the kickoff cutscene plays.
const int kSanctuaryCutsceneCode = 0xF0;

/// Map from each non-cutscene anchor code to the activity id registered in
/// `data/activity-registry/kindergarten.json`. F0 is the cutscene and has
/// no activity id.
const Map<int, String> kSanctuaryActivityByCode = {
  0xF1: 'counting-parade',
  0xF2: 'shape-garden',
  0xF3: 'ten-frame-pond',
  0xF4: 'build-a-habitat',
  0xF5: 'care-pantry',
  0xF6: 'scribes-tower',
  0xF7: 'storytellers-pond',
  0xF8: 'wheres-buddy',
  0xF9: 'caretakers-bench',
  0xFA: 'picnic-baskets',
  0xFB: 'fluency-within-5',
};

/// Inverse of [kSanctuaryActivityByCode]. Lazily computed so it stays in
/// sync with the canonical map above.
final Map<String, int> kSanctuaryCodeByActivity = {
  for (final entry in kSanctuaryActivityByCode.entries) entry.value: entry.key,
};

/// Whether the node at [code] opens something the child can actually play.
///
/// The cutscene head counts as playable: it is completable (watching it marks
/// it explored) and it must gate the first lesson.
bool isSanctuaryNodePlayable(int code) {
  if (code == kSanctuaryCutsceneCode) return true;
  final activityId = kSanctuaryActivityByCode[code];
  return activityId != null && isActivityPlayable(activityId);
}

/// Whether the node at [code] should be drawn, given the set of nodes already
/// completed.
///
/// The rule is "one node ahead of where she has got to", so the path always
/// shows her somewhere to go next without revealing the whole region at once.
///
/// The subtlety is what "the node before it" means. Taken literally it meant
/// the previous entry in [kSanctuarySequence], and since a node is only ever
/// marked completed by finishing its sub-modes, an entry with no runner could
/// never be completed and every node after it stayed in the fog permanently.
/// The path dead-ended at Ten-Frame Pond — position three of eleven — hiding
/// Build-a-Habitat and Where's Buddy, both of which were finished.
///
/// So the walk skips over nodes that are asleep. They are still drawn (see
/// specs/shared/map-screens.md: unbuilt content stays on the map so the region
/// has a shape and filling it in reads as things opening up), they are simply
/// not allowed to be a wall.
bool isSanctuaryNodeVisible(int code, Set<int> explored) {
  if (explored.contains(code)) return true;
  final index = kSanctuarySequence.indexOf(code);
  if (index <= 0) return true; // the cutscene head is always there
  for (var i = index - 1; i >= 0; i--) {
    final earlier = kSanctuarySequence[i];
    if (!isSanctuaryNodePlayable(earlier)) continue;
    return explored.contains(earlier);
  }
  // Nothing completable before it at all. Show it rather than hide it: an
  // unreachable node is a content gap, and a blank map is worse than one with
  // a sleeping place on it.
  return true;
}
