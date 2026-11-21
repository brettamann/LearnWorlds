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

import 'asset_paths.dart';
import 'wheres_buddy_words.dart';

class WheresBuddyLandmark {
  const WheresBuddyLandmark({
    required this.id,
    required this.position,
    required this.sizeFraction,
  });

  /// Stable id used in narration cue ids.
  final String id;

  /// Words the narrator uses ("the star fountain", "the hollow tree").
  ///
  /// Read from `wheres_buddy_words.dart` rather than stored, so the narration
  /// script and the running game cannot disagree about the wording - a drift
  /// there would render a clip nothing ever asks for and leave the real line
  /// in the synth voice, with nothing reporting it.
  String get displayName => kWheresBuddyLandmarkNames[id] ?? id;

  /// Centre of the landmark in normalized 0..1 coordinates on the
  /// background image.
  final Offset position;

  /// How wide to draw it, as a fraction of the clearing's shorter side —
  /// the same currency the Buddy is sized in (0.16), so the numbers below
  /// read as "about as big as Buddy" rather than as pixels.
  ///
  /// Per-landmark rather than one constant because these are objects with
  /// their own scale in the world: a cottage is bigger than a mushroom, and
  /// six sprites at one size read as six icons rather than as a place.
  ///
  /// Note the number is the *box*, and every sprite was drawn with a generous
  /// margin inside its canvas, so the object itself covers roughly three
  /// quarters of it. `wheres_buddy_landmark_art_test.dart` checks separation
  /// against the box, which is the conservative reading and keeps a little air
  /// between two landmarks rather than letting their artwork touch.
  final double sizeFraction;

  /// The picture of it. Every landmark has one; see
  /// [AssetPaths.wheresBuddyLandmarks] for why three come from the decor set.
  String get spriteAsset => AssetPaths.wheresBuddyLandmarks[id]!;
}

/// Six landmarks placed around the clearing. Locations are picked so
/// the kid can practise every position word against at least two
/// different landmarks (above the well + above the mushroom, etc.).
///
/// Each one is drawn. That is worth saying because for a long time none of
/// them were: the runner rendered the landmark's *name* on a white pill, six
/// of them, over a courtyard illustration with no fountain, no tree and no
/// cottage anywhere in it. An activity whose entire mechanic is "put Buddy
/// above the hollow tree" was, to the pre-reader it is written for, six
/// identical labels she could not read and no hollow tree. See
/// `wheres_buddy_landmark_art_test.dart`.
const List<WheresBuddyLandmark> kWheresBuddyLandmarks = <WheresBuddyLandmark>[
  WheresBuddyLandmark(
    id: 'fountain',
    position: Offset(0.30, 0.46),
    sizeFraction: 0.165,
  ),
  WheresBuddyLandmark(
    id: 'hollow-tree',
    position: Offset(0.72, 0.34),
    sizeFraction: 0.19,
  ),
  WheresBuddyLandmark(
    id: 'mushroom',
    position: Offset(0.18, 0.72),
    sizeFraction: 0.135,
  ),
  WheresBuddyLandmark(
    id: 'rock-cluster',
    position: Offset(0.55, 0.78),
    sizeFraction: 0.145,
  ),
  WheresBuddyLandmark(
    id: 'cottage',
    position: Offset(0.80, 0.68),
    sizeFraction: 0.18,
  ),
  WheresBuddyLandmark(
    id: 'pond',
    position: Offset(0.45, 0.30),
    sizeFraction: 0.165,
  ),
];

/// One of the six position vocabulary words. `vector` tells the
/// layout where the Buddy belongs *relative* to a landmark centre.
class WheresBuddyPosition {
  const WheresBuddyPosition({required this.id, required this.vector});

  /// Stable id used in narration cue ids.
  final String id;

  /// Word used in narration ("above", "behind", "next to"). See the note on
  /// [WheresBuddyLandmark.displayName] for why this is not a stored field.
  String get preposition => kWheresBuddyPrepositions[id] ?? id;

  /// Direction + distance the Buddy lands relative to the landmark
  /// centre. Multiply by the layer's shorter side at render time.
  final Offset vector;
}

/// Vectors scale to ~16% of the shorter side at render time — far
/// enough that "above" and "below" read as visually different, close
/// enough that the Buddy stays "near" the landmark.
const List<WheresBuddyPosition> kWheresBuddyPositions = <WheresBuddyPosition>[
  WheresBuddyPosition(id: 'above', vector: Offset(0, -0.16)),
  WheresBuddyPosition(id: 'below', vector: Offset(0, 0.16)),
  WheresBuddyPosition(id: 'next-to', vector: Offset(0.18, 0)),
  WheresBuddyPosition(
    id: 'behind',
    // "Behind" pushes the Buddy slightly up-left + scales it down a
    // touch at render time so the kid reads it as "tucked behind."
    vector: Offset(-0.05, -0.04),
  ),
  WheresBuddyPosition(id: 'in-front-of', vector: Offset(0, 0.10)),
  WheresBuddyPosition(id: 'beside', vector: Offset(-0.18, 0)),
];

WheresBuddyLandmark wheresBuddyLandmark(String id) => kWheresBuddyLandmarks
    .firstWhere((l) => l.id == id, orElse: () => kWheresBuddyLandmarks.first);

WheresBuddyPosition wheresBuddyPosition(String id) => kWheresBuddyPositions
    .firstWhere((p) => p.id == id, orElse: () => kWheresBuddyPositions.first);
