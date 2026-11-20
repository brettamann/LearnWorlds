// Sub-mode ids, one class per activity, as names the compiler checks.
//
// The ids are owned by the activity registry
// (assets/data/activity-registry/kindergarten.json), which also says which is
// the default, which is a challenge and which is a demotion floor;
// `activity_ids_test` fails if this file and the registry disagree. These
// used to be defined in twelve different files - some beside the words an
// activity speaks, some at the top of its runner widget - and typed out as
// raw strings in many more.
//
// Flutter-free on purpose: the narration script tool reads data files that
// use these.

import 'activity_ids.dart';

/// Counting Parade sub-modes, in registry order.
abstract final class CountingParadeModes {
  static const String countTheParade = 'count-the-parade';
  static const String countForwardFromN = 'count-forward-from-n';
  static const String countOutN = 'count-out-n';
  static const String countOnByOnes = 'count-on-by-ones';
  static const String longParade = 'long-parade';
  static const String tensParade = 'tens-parade';

  static const List<String> all = <String>[
    countTheParade,
    countForwardFromN,
    countOutN,
    countOnByOnes,
    longParade,
    tensParade,
  ];
}

/// Shape Garden sub-modes, in registry order.
abstract final class ShapeGardenModes {
  static const String findShape = 'find-shape';
  static const String flatOrSolid = 'flat-or-solid';
  static const String sortByAttribute = 'sort-by-attribute';
  static const String twoAttributeHunt = 'two-attribute-hunt';

  static const List<String> all = <String>[
    findShape,
    flatOrSolid,
    sortByAttribute,
    twoAttributeHunt,
  ];
}

/// Ten-Frame Pond sub-modes, in registry order.
abstract final class TenFramePondModes {
  static const String fillToTarget = 'fill-to-target';
  static const String twoWays = 'two-ways';
  static const String makeTen = 'make-ten';
  static const String tenPlusN = 'ten-plus-n';
  static const String threeFrames = 'three-frames';

  static const List<String> all = <String>[
    fillToTarget,
    twoWays,
    makeTen,
    tenPlusN,
    threeFrames,
  ];
}

/// Build-a-Habitat sub-modes, in registry order.
abstract final class BuildAHabitatModes {
  static const String simpleShelter = 'simple-shelter';
  static const String creatureHome = 'creature-home';
  static const String grandHabitat = 'grand-habitat';
  static const String frameOnly = 'frame-only';

  static const List<String> all = <String>[
    simpleShelter,
    creatureHome,
    grandHabitat,
    frameOnly,
  ];
}

/// Care Pantry sub-modes, in registry order.
abstract final class CarePantryModes {
  static const String categorizeOnly = 'categorize-only';
  static const String simplePantry = 'simple-pantry';
  static const String fullPantry = 'full-pantry';
  static const String unfamiliarRules = 'unfamiliar-rules';

  static const List<String> all = <String>[
    categorizeOnly,
    simplePantry,
    fullPantry,
    unfamiliarRules,
  ];
}

/// Scribe's Tower sub-modes, in registry order.
abstract final class ScribesTowerModes {
  static const String traceNumeral = 'trace-numeral';
  static const String writeFromCue = 'write-from-cue';
  static const String matchNumeral = 'match-numeral';
  static const String audioOnlyTeens = 'audio-only-teens';

  static const List<String> all = <String>[
    traceNumeral,
    writeFromCue,
    matchNumeral,
    audioOnlyTeens,
  ];
}

/// Storyteller's Pond sub-modes, in registry order.
abstract final class StorytellersPondModes {
  static const String addTo = 'add-to';
  static const String takeFrom = 'take-from';
  static const String putTogether = 'put-together';
  static const String takeApart = 'take-apart';
  static const String twoStep = 'two-step';

  static const List<String> all = <String>[
    addTo,
    takeFrom,
    putTogether,
    takeApart,
    twoStep,
  ];
}

/// Where's Buddy? sub-modes, in registry order.
abstract final class WheresBuddyModes {
  static const String findMode = 'find-mode';
  static const String placeMode = 'place-mode';
  static const String relationalMode = 'relational-mode';

  static const List<String> all = <String>[findMode, placeMode, relationalMode];
}

/// Caretaker's Bench sub-modes, in registry order.
abstract final class CaretakersBenchModes {
  static const String describeAttributes = 'describe-attributes';
  static const String compareTwo = 'compare-two';
  static const String orderThreeByLength = 'order-three-by-length';

  static const List<String> all = <String>[
    describeAttributes,
    compareTwo,
    orderThreeByLength,
  ];
}

/// Picnic Baskets sub-modes, in registry order.
abstract final class PicnicBasketsModes {
  static const String matchByLine = 'match-by-line';
  static const String countAndCompare = 'count-and-compare';
  static const String numeralCompare = 'numeral-compare';
  static const String threeWayCompare = 'three-way-compare';

  static const List<String> all = <String>[
    matchByLine,
    countAndCompare,
    numeralCompare,
    threeWayCompare,
  ];
}

/// Fluency Within 5 sub-modes, in registry order.
abstract final class FluencyWithin5Modes {
  static const String casual = 'casual';
  static const String speedRun = 'speed-run';

  static const List<String> all = <String>[casual, speedRun];
}

/// Every activity's sub-mode ids, in registry order.
const Map<String, List<String>> kSubModeIdsByActivity = <String, List<String>>{
  ActivityIds.countingParade: CountingParadeModes.all,
  ActivityIds.shapeGarden: ShapeGardenModes.all,
  ActivityIds.tenFramePond: TenFramePondModes.all,
  ActivityIds.buildAHabitat: BuildAHabitatModes.all,
  ActivityIds.carePantry: CarePantryModes.all,
  ActivityIds.scribesTower: ScribesTowerModes.all,
  ActivityIds.storytellersPond: StorytellersPondModes.all,
  ActivityIds.wheresBuddy: WheresBuddyModes.all,
  ActivityIds.caretakersBench: CaretakersBenchModes.all,
  ActivityIds.picnicBaskets: PicnicBasketsModes.all,
  ActivityIds.fluencyWithin5: FluencyWithin5Modes.all,
};
