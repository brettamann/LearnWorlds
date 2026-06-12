// Sanctuary map sequence — single source of truth for the magenta anchor
// codes, the order in which they're drawn, and which activity id sits at
// each lesson code. Both the map screen and the activity screen consult
// this so they can't drift.
//
// When the placeholder art is replaced with the real Sanctuary map, only
// the rectangle positions in `sanctuary_map_screen.dart` need to change —
// these codes + activity ids stay valid.

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
