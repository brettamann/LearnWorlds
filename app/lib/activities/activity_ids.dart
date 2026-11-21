// ActivityIds - every activity id in the game, as a name the compiler checks.
//
// The ids themselves are owned by the activity registry
// (assets/data/activity-registry/kindergarten.json); `activity_catalog_test`
// fails if this list and the registry disagree. Use these constants anywhere
// Dart code names an activity, so a typo is a compile error rather than a
// node that silently never opens.
//
// Flutter-free on purpose: the narration script tool imports data files that
// use these.

abstract final class ActivityIds {
  static const String countingParade = 'counting-parade';
  static const String shapeGarden = 'shape-garden';
  static const String tenFramePond = 'ten-frame-pond';
  static const String buildAHabitat = 'build-a-habitat';
  static const String carePantry = 'care-pantry';
  static const String scribesTower = 'scribes-tower';
  static const String storytellersPond = 'storytellers-pond';
  static const String wheresBuddy = 'wheres-buddy';
  static const String caretakersBench = 'caretakers-bench';
  static const String picnicBaskets = 'picnic-baskets';
  static const String fluencyWithin5 = 'fluency-within-5';

  static const List<String> all = <String>[
    countingParade,
    shapeGarden,
    tenFramePond,
    buildAHabitat,
    carePantry,
    scribesTower,
    storytellersPond,
    wheresBuddy,
    caretakersBench,
    picnicBaskets,
    fluencyWithin5,
  ];
}
