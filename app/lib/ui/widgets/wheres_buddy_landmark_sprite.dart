// One place in the Sanctuary clearing, drawn the same way wherever it appears.
//
// Extracted from `wheres_buddy_runner` because the K.G.1 lesson now draws the
// same clearing, and the lesson and the round showing the same place two
// different ways would undo the point of the lesson. The lesson exists to
// introduce the round; if it introduces a slightly different tree, it has
// introduced nothing.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/wheres_buddy_landmarks.dart';
import 'playfield_area.dart';

/// How big Buddy is drawn on the clearing, as a fraction of its shorter side.
/// Shared for the same reason the landmark treatment is.
const double kClearingBuddySizeFraction = 0.16;

class WheresBuddyLandmarkSprite extends StatelessWidget {
  const WheresBuddyLandmarkSprite({
    super.key,
    required this.landmark,
    required this.size,
    required this.highlighted,
  });

  final WheresBuddyLandmark landmark;
  final double size;

  /// True for the place the prompt (or the lesson's narration) just named.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // A pool of warm light on the ground, not an outline. The
              // outline treatment is spoken for: an amber ring means "the
              // answer is here" on the target halo, and two rings meaning
              // different things is worse than one meaning nothing.
              boxShadow: highlighted
                  ? [
                      // Soft and negative-spread on purpose. At a bigger alpha
                      // with positive spread this read as a filled amber disc,
                      // which is very close to what the target halo looks like
                      // - and those two circles mean opposite things: one is
                      // the place being talked about, the other is the answer.
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 34,
                        spreadRadius: -8,
                      ),
                    ]
                  : null,
            ),
            child: Image.asset(landmark.spriteAsset, fit: BoxFit.contain),
          ),
        ),
        // Named only while it is the place under discussion.
        //
        // Every landmark used to carry its name all the time, which was the
        // whole of the landmark. Now the picture is, and six permanent
        // captions would be six pieces of text a pre-reader cannot use,
        // crowding a clearing she has to judge distances across. Showing it on
        // the one being talked about is what ties a spoken "the hollow tree"
        // to the tree, which is the only moment the word does any work.
        if (highlighted) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber.shade100.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade400, width: 2),
            ),
            child: Text(
              landmark.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Where Buddy stands for a position word, in normalized clearing space.
///
/// The landmark's centre plus the position word's vector, clamped inside the
/// frame. Shared with the runner so the lesson demonstrates the spot the round
/// will then ask her to drop him on - the same arithmetic, not a similar one.
Offset clearingSpotFor({
  required String landmarkId,
  required String positionId,
}) {
  final lm = wheresBuddyLandmark(landmarkId).position;
  final v = wheresBuddyPosition(positionId).vector;
  return Offset(
    (lm.dx + v.dx).clamp(0.05, 0.95),
    (lm.dy + v.dy).clamp(0.10, 0.92),
  );
}

/// Splits an authored zone id like `above-fountain` or `in-front-of-hollow-tree`
/// into its position and its landmark.
///
/// Both halves contain hyphens (`in-front-of`, `hollow-tree`), so this cannot
/// split on the dash. It matches the longest known position prefix instead,
/// and returns null for anything that is not a real position on a real
/// landmark - which is the only honest answer, because a zone the clearing
/// cannot place is a zone a touch cannot be tested against.
({String landmarkId, String positionId})? parseClearingZone(String zoneId) {
  for (final position in kWheresBuddyPositions) {
    final prefix = '${position.id}-';
    if (!zoneId.startsWith(prefix)) continue;
    final landmarkId = zoneId.substring(prefix.length);
    final known = kWheresBuddyLandmarks.any((l) => l.id == landmarkId);
    if (!known) continue;
    return (landmarkId: landmarkId, positionId: position.id);
  }
  return null;
}

/// The part of the clearing anything can actually be seen in.
///
/// Every position in Where's Buddy is a fraction of the clearing, and the
/// clearing was being mapped onto the whole window - including the strip along
/// the bottom that the caption band sits on. The band is opaque, so the bottom
/// tenth of the authored space was a place things could be put and not looked
/// at. The Buddy's own resting spot was in it: he waited at y 0.92 with the
/// band across his body, and he is the one thing on the screen she has to pick
/// up. "Below the mushroom" landed there too, and it is the answer to a
/// question.
///
/// The fix is to squeeze the clearing into the space above the band rather
/// than to nudge the things that fell foul of it. The landmark positions
/// encode a composition - which places are near which, what counts as a gap -
/// and `wheres_buddy_landmark_art_test.dart` checks it holds across every
/// window shape the game allows. Moving individual sprites out of the band
/// would have quietly changed that composition; scaling the whole thing keeps
/// every relationship exactly as authored.
///
/// Sprites size off [shortest], which is the shorter side *of the visible
/// clearing* rather than of the window, so they shrink with it and the
/// composition holds.
class ClearingGeometry {
  factory ClearingGeometry({required double width, required double height}) {
    // One definition of "the visible part", shared with every other
    // playfield - see `playfield_area.dart` for the three separate times a
    // runner worked this out for itself and got it wrong.
    final area = PlayfieldArea(width: width, height: height);
    return ClearingGeometry._(width: area.width, height: area.height);
  }

  const ClearingGeometry._({required this.width, required this.height});

  final double width;

  /// Excludes the caption band.
  final double height;

  double get shortest => math.min(width, height);

  double get buddySize => shortest * kClearingBuddySizeFraction;

  /// A normalized clearing position in pixels.
  Offset place(Offset normalized) =>
      Offset(normalized.dx * width, normalized.dy * height);

  double sizeOf(double sizeFraction) => shortest * sizeFraction;
}

/// Where the Buddy waits before she picks him up, and returns to after a miss.
///
/// Not the middle. At the bottom of the clearing the middle is the rock
/// cluster, and a Buddy who starts out standing on a landmark is already
/// arguably "next to" it before she has done anything - in the one activity
/// whose whole question is which thing he is next to. This is the widest part
/// of the bottom edge that no landmark reaches at any allowed window shape,
/// which `wheres_buddy_landmark_art_test.dart` now checks rather than trusts.
const Offset kClearingBuddyHome = Offset(0.30, 0.92);
