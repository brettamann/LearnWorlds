// The words Build-a-Habitat speaks.
//
// Split out of `build_a_habitat_blueprints.dart` for the same reason as
// `shape_words.dart` and `sort_attribute_words.dart`: the blueprint catalog
// imports `package:flutter/material.dart` for the `Offset`s that place each
// corner and stick, and `narration_script.dart` has to compile under plain
// `dart run`. A test walks the import graph and fails if Flutter creeps back
// in, because the moment it does the script stops building and every line in
// it silently reverts to the browser synth voice.
//
// The blueprint catalog reads these back through a getter rather than storing
// its own copy, so the script and the game cannot disagree about the wording.
// A drift here would be invisible: the clip would be filed under the old
// sentence, never looked up, and the line would quietly go back to the synth.
//
// Everything else the activity says is here too - the keeper's lines, the
// per-piece lines and which blueprints each sub-mode plays - so the
// recording script enumerates exactly what the runner speaks.

import '../activities/sub_mode_ids.dart';

/// Blueprint id -> the habitat as the narrator names it.
///
/// Phrased with the article ("a fawn shelter") because it lands mid-sentence
/// in the build prompt.
const Map<String, String> kHabitatDisplayNames = <String, String>{
  'fawn-triangle-shelter': 'a fawn shelter',
  'gryphon-square-roost': 'a gryphon roost',
  'unicorn-pentagon-gazebo': 'a unicorn gazebo',
};

/// The build instruction, naming the habitat being raised.
///
/// Three steps in one sentence. It stays one sentence because
/// `NarrationPlayer` has no queue — a second `speak` cancels the first
/// mid-word — so a beat gets exactly one spoken line.
String habitatBuildPrompt(String blueprintId) =>
    'Tap each glowing corner to place a clay ball. Then tap each '
    'side to lay a stick. Build ${habitatDisplayName(blueprintId)}!';

/// Falls back to the id rather than throwing: a typo should degrade to an odd
/// sentence, not a crash in a child's hands.
String habitatDisplayName(String blueprintId) =>
    kHabitatDisplayNames[blueprintId] ?? blueprintId;

/// The blueprints in catalog order: triangle, square, pentagon.
///
/// `build_a_habitat_blueprints.dart` holds the geometry (it needs Flutter for
/// its `Offset`s); this is the order, so the round table can be read without
/// it. `habitat_words_test.dart` checks the two agree.
const List<String> kHabitatBlueprintIds = <String>[
  'fawn-triangle-shelter',
  'gryphon-square-roost',
  'unicorn-pentagon-gazebo',
];

/// The blueprints a sub-mode builds, one per round.
///
/// `simple-shelter` runs the triangle; `creature-home` runs all three;
/// `grand-habitat` runs the pentagon; `frame-only` runs the triangle but
/// skips the roof.
List<String> habitatBlueprintIdsFor(String subMode) => switch (subMode) {
      BuildAHabitatModes.creatureHome => kHabitatBlueprintIds,
      BuildAHabitatModes.grandHabitat => <String>[kHabitatBlueprintIds[2]],
      _ => <String>[kHabitatBlueprintIds[0]],
    };

/// True for the demotion sub-mode: frame only, no roof (K.G.5 alone).
bool habitatSkipsRoof(String subMode) =>
    subMode == BuildAHabitatModes.frameOnly;

/// Blueprint id -> what the keeper says over the finished habitat.
const Map<String, String> kHabitatKeeperLines = <String, String>{
  'fawn-triangle-shelter': 'A fawn shelter! Beautifully built.',
  'gryphon-square-roost': 'A gryphon roost — four sides and a peaked roof!',
  'unicorn-pentagon-gazebo':
      'A unicorn gazebo — five sides and a starlit dome on top!',
};

const String kHabitatIntro =
    "Let's build a habitat together! Clay balls go in the corners, "
    'sticks go along the sides — then we add shapes on top to make '
    "the roof. Ready? Let's start.";

/// The second phase's instruction, once the frame is up.
const String kHabitatRaisePrompt =
    'Now raise the habitat — tap each ghost shape to drop the '
    'matching piece in place.';

const String kHabitatFinal =
    'Every habitat is built! The Sanctuary feels cosy and safe.';

/// Said as each corner gets its clay.
const String kHabitatCornerLine = 'Clay corner.';

/// Said as each stick is laid.
const String kHabitatStickLine = 'Stick.';

/// A stick tapped before both its corners have clay - the wrong answer K.G.5
/// actually cares about. Alternates so the third one is not the first again.
String habitatStickBlockedLine(int rotation) => rotation.isOdd
    ? 'Place clay in both corners first, then the stick.'
    : 'A stick needs a corner at each end. Clay first.';

/// Every 3D kind a roof uses. `habitat_words_test.dart` checks each
/// blueprint's roof against it, so a new kind cannot ship unscripted.
const List<String> kHabitatRoofKinds = <String>[
  'cube',
  'cone',
  'sphere',
  'cylinder',
];

/// Said as a roof piece drops into place.
String habitatRoofLine(String kind) => 'A $kind. It goes on top.';

/// Every line the activity speaks apart from the build prompt, for the
/// recording script.
List<String> habitatScriptLines() => <String>[
      kHabitatIntro,
      kHabitatRaisePrompt,
      kHabitatFinal,
      for (final id in kHabitatBlueprintIds) kHabitatKeeperLines[id]!,
      kHabitatCornerLine,
      kHabitatStickLine,
      habitatStickBlockedLine(1),
      habitatStickBlockedLine(0),
      for (final kind in kHabitatRoofKinds) habitatRoofLine(kind),
    ];
