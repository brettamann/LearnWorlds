// Shape Garden's finding sub-mode (K.G.2): the rounds and the keeper's lines.
//
// Flutter-free, like every other activity's words, so the narration tools
// can read the lines. The prompt, hit, hint and miss lines are the shared
// shape lines scripted in narration_script.dart ('shape-target',
// 'shape-miss').

/// One round of the garden hunt.
class GardenRound {
  const GardenRound({
    required this.targetKind,
    required this.targetCount,
    required this.distractorCount,
    required this.keeperLine,
  });

  final String targetKind;
  final int targetCount;
  final int distractorCount;

  /// What the keeper says over the finished board, setting up the next shape.
  final String keeperLine;
}

/// Eight rounds, one shape each, easy to harder - the same ladder the K.G.2
/// lesson teaches. The round count is not what made this drag (it is twenty
/// taps in all); the eight blocking keeper modals were, and those are gone.
/// Trimming it would cost shape coverage for no pacing gain.
const List<GardenRound> kGardenRounds = <GardenRound>[
  GardenRound(
    targetKind: 'circle',
    targetCount: 3,
    distractorCount: 4,
    keeperLine: 'Wonderful! All the circles. Now find the triangles.',
  ),
  GardenRound(
    targetKind: 'triangle',
    targetCount: 3,
    distractorCount: 4,
    keeperLine: "Nice work! Let's find the squares next.",
  ),
  GardenRound(
    targetKind: 'square',
    targetCount: 3,
    distractorCount: 4,
    keeperLine: 'Great squares! How about the rectangles?',
  ),
  GardenRound(
    targetKind: 'rectangle',
    targetCount: 3,
    distractorCount: 4,
    keeperLine: "Lovely! Let's hunt some pentagons.",
  ),
  GardenRound(
    targetKind: 'pentagon',
    targetCount: 2,
    distractorCount: 4,
    keeperLine: 'Pentagons found! Now the hexagons.',
  ),
  GardenRound(
    targetKind: 'hexagon',
    targetCount: 2,
    distractorCount: 4,
    keeperLine: "Excellent! Let's spot the right triangles.",
  ),
  GardenRound(
    targetKind: 'triangle-right',
    targetCount: 2,
    distractorCount: 5,
    keeperLine: 'You got them! One more — half circles.',
  ),
  GardenRound(
    targetKind: 'semicircle_half',
    targetCount: 2,
    distractorCount: 5,
    keeperLine: "You found every shape in the garden! That's amazing.",
  ),
];

const String kGardenIntro =
    'Look — some plants in the garden have grown into shapes! Help me find '
    "them all, won't you? We'll start with the circles.";

/// Said as each shape is found (all but the last of a round).
const String kShapeFoundLine = "There's one!";

const String kGardenStartLabel = "Let's hunt!";

/// The visit's last beat. It used to announce "Here are 40 coins" - eight
/// rounds at the clean-round rate - which overstated the payout whenever a
/// round needed help, and could never be recorded because the number was
/// computed. Every other place says "some coins"; so does this one now.
const String kGardenFinal =
    'You found every shape in the garden! Here are some coins for your help.';
