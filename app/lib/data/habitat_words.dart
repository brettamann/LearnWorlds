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
