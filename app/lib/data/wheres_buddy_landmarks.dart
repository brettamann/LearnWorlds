// Landmark + position vocabulary for Where's Buddy? (K.G.1).
//
// Each landmark sits at a fixed normalized (0..1) position on the
// Sanctuary clearing background. The K.G.1 standard names six position
// words; the activity exercises them by asking the kid to put the
// Buddy *in relation to* a landmark.
//
// Position vectors (`dx`, `dy`) are normalized offsets *from the
// landmark centre* — multiplied by the layer's shorter side at render
// time so the spacing feels consistent across screen sizes. `dy` is
// negative for "above"; positive for "below"; etc.

import 'package:flutter/material.dart';

class WheresBuddyLandmark {
  const WheresBuddyLandmark({
    required this.id,
    required this.displayName,
    required this.position,
  });

  /// Stable id used in narration cue ids.
  final String id;

  /// Words the narrator uses ("the unicorn fountain", "the hollow tree").
  final String displayName;

  /// Centre of the landmark in normalized 0..1 coordinates on the
  /// background image.
  final Offset position;
}

/// Six landmarks placed around the clearing. Locations are picked so
/// the kid can practise every position word against at least two
/// different landmarks (above the well + above the mushroom, etc.).
const List<WheresBuddyLandmark> kWheresBuddyLandmarks =
    <WheresBuddyLandmark>[
  WheresBuddyLandmark(
    id: 'fountain',
    displayName: 'the unicorn fountain',
    position: Offset(0.30, 0.46),
  ),
  WheresBuddyLandmark(
    id: 'hollow-tree',
    displayName: 'the hollow tree',
    position: Offset(0.72, 0.34),
  ),
  WheresBuddyLandmark(
    id: 'mushroom',
    displayName: 'the giant mushroom',
    position: Offset(0.18, 0.72),
  ),
  WheresBuddyLandmark(
    id: 'rock-cluster',
    displayName: 'the rock cluster',
    position: Offset(0.55, 0.78),
  ),
  WheresBuddyLandmark(
    id: 'cottage',
    displayName: 'the cottage',
    position: Offset(0.80, 0.68),
  ),
  WheresBuddyLandmark(
    id: 'pond',
    displayName: 'the pond',
    position: Offset(0.45, 0.30),
  ),
];

/// One of the six position vocabulary words. `vector` tells the
/// layout where the Buddy belongs *relative* to a landmark centre.
class WheresBuddyPosition {
  const WheresBuddyPosition({
    required this.id,
    required this.preposition,
    required this.vector,
  });

  /// Stable id used in narration cue ids.
  final String id;

  /// Word used in narration ("above", "behind", "next to").
  final String preposition;

  /// Direction + distance the Buddy lands relative to the landmark
  /// centre. Multiply by the layer's shorter side at render time.
  final Offset vector;
}

/// Vectors scale to ~16% of the shorter side at render time — far
/// enough that "above" and "below" read as visually different, close
/// enough that the Buddy stays "near" the landmark.
const List<WheresBuddyPosition> kWheresBuddyPositions =
    <WheresBuddyPosition>[
  WheresBuddyPosition(
    id: 'above',
    preposition: 'above',
    vector: Offset(0, -0.16),
  ),
  WheresBuddyPosition(
    id: 'below',
    preposition: 'below',
    vector: Offset(0, 0.16),
  ),
  WheresBuddyPosition(
    id: 'next-to',
    preposition: 'next to',
    vector: Offset(0.18, 0),
  ),
  WheresBuddyPosition(
    id: 'behind',
    preposition: 'behind',
    // "Behind" pushes the Buddy slightly up-left + scales it down a
    // touch at render time so the kid reads it as "tucked behind."
    vector: Offset(-0.05, -0.04),
  ),
  WheresBuddyPosition(
    id: 'in-front-of',
    preposition: 'in front of',
    vector: Offset(0, 0.10),
  ),
  WheresBuddyPosition(
    id: 'beside',
    preposition: 'beside',
    vector: Offset(-0.18, 0),
  ),
];

WheresBuddyLandmark wheresBuddyLandmark(String id) =>
    kWheresBuddyLandmarks.firstWhere(
      (l) => l.id == id,
      orElse: () => kWheresBuddyLandmarks.first,
    );

WheresBuddyPosition wheresBuddyPosition(String id) =>
    kWheresBuddyPositions.firstWhere(
      (p) => p.id == id,
      orElse: () => kWheresBuddyPositions.first,
    );
