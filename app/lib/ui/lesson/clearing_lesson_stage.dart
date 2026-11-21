// The K.G.1 lesson scene: Buddy in the Sanctuary clearing, being moved to the
// position words while the narrator names them.
//
// WHAT WAS THERE BEFORE
// ---------------------
// Three fawns. `lesson_screen` dispatches its iShow scene on `conceptId`, with
// `_FawnStage` as the fall-through, and K.G.1 matched nothing - so the lesson
// that introduces Where's Buddy, whose entire subject is where the Buddy is,
// showed three deer standing in a meadow and no Buddy at all. The same was
// true of K.G.1b. It is the hardest kind of bug to see: the default renders
// something plausible, so nothing looks broken, and the lesson is a phase most
// adults tap past.
//
// The scene was fully authored the whole time - five landmarks, a Buddy at
// centre stage, and steps that move him above the fountain, behind the tree
// and next to the mushroom, with narration to match. It was read by nothing.
//
// WHY IT SHARES THE ROUND'S PIECES
// --------------------------------
// The landmark sprite, the buddy size, and the arithmetic that turns
// (landmark, position word) into a spot on the ground are all imported from
// the same places the runner uses. A lesson that introduces the round has to
// introduce *that* round: a lesson tree that is not the round's tree, or a
// "next to" that lands somewhere else, teaches her something she then has to
// unlearn thirty seconds later.
//
// The scene draws her own Buddy, in the colours she chose, for the same reason
// the picker cards do.

import 'package:flutter/material.dart';

import '../../activities/wheres_buddy/wheres_buddy_landmark_sprite.dart';
import '../../data/asset_paths.dart';
import '../../data/wheres_buddy_landmarks.dart';
import '../characters/buddy_widget.dart';
import 'lesson_target_registry.dart';

/// Where Buddy is standing right now.
///
/// Null means centre stage, which is where he starts and where every
/// `buddy-return-to-center` step puts him back.
class ClearingSpot {
  const ClearingSpot({required this.landmarkId, required this.positionId});

  final String landmarkId;
  final String positionId;
}

class ClearingLessonStage extends StatelessWidget {
  const ClearingLessonStage({
    super.key,
    required this.landmarkIds,
    required this.facingLandmarkId,
    required this.spot,
    required this.pointerVisible,
    this.targets,
    this.zoneIds = const <String>{},
  });

  /// Which places are standing in the clearing, from the lesson's scene.
  final List<String> landmarkIds;

  /// The place the narrator is naming, lit with the same pool of warm light
  /// the round uses. Null between beats.
  final String? facingLandmarkId;

  /// Null while Buddy is centre stage.
  final ClearingSpot? spot;

  /// The demo hand rides on Buddy while he is being moved, so it is clear he
  /// is being *shown* somewhere rather than walking there himself.
  final bool pointerVisible;

  /// Where the We-Try phase should draw its halo and test her touch. Null
  /// outside that phase.
  final LessonTargetRegistry? targets;

  /// Zone ids the We-Try is asking about, in the authored
  /// `<position>-<landmark>` form ("above-well", "behind-tree"). Each one is
  /// given a box on the ground at the spot the round would accept, so the ring
  /// she is asked to touch is the place the answer actually is.
  final Set<String> zoneIds;

  /// Centre stage. Deliberately not the middle of the frame: the clearing's
  /// usable ground is the lower two thirds, and a Buddy at 0.5 stands in the
  /// treeline.
  static const Offset _centre = Offset(0.46, 0.60);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The clearing is the space above the caption band, not the whole
        // box - the same geometry the round lays out in, so the lesson
        // demonstrates the spot the round will accept.
        final clearing = ClearingGeometry(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );
        final w = clearing.width;
        final h = clearing.height;
        final shortest = clearing.shortest;
        final buddySize = clearing.buddySize;
        final target = spot == null
            ? _centre
            : clearingSpotFor(
                landmarkId: spot!.landmarkId,
                positionId: spot!.positionId,
              );
        // "Behind" tucks him back as well as up-left, so he reads as partly
        // hidden rather than merely displaced. Same trick the runner uses.
        final behind = spot?.positionId == 'behind';

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(
                AssetPaths.wheresBuddyBackground,
                fit: BoxFit.cover,
              ),
            ),
            // The places the We-Try is asking about, registered so the halo
            // can be drawn on them and her touch tested against them. Boxed
            // at the spot the round itself would accept, from the same
            // `clearingSpotFor` the demonstration glides Buddy to - so the
            // ring she is invited to touch is the answer, not an approximation
            // of it drawn a second time.
            for (final zoneId in zoneIds)
              Builder(
                builder: (_) {
                  final zone = parseClearingZone(zoneId);
                  final registry = targets;
                  if (zone == null || registry == null) {
                    return const SizedBox.shrink();
                  }
                  final at = clearingSpotFor(
                    landmarkId: zone.landmarkId,
                    positionId: zone.positionId,
                  );
                  return Positioned(
                    left: at.dx * w - buddySize / 2,
                    top: at.dy * h - buddySize / 2,
                    width: buddySize,
                    height: buddySize,
                    child: SizedBox(key: registry.keyFor(zoneId)),
                  );
                },
              ),
            // Buddy is drawn before the landmarks so that "behind the hollow
            // tree" is literally true on screen. It is the one position word
            // that a change of position alone cannot express.
            if (behind) _buddy(target, buddySize, w, h, behind),
            for (final id in landmarkIds)
              Builder(
                builder: (_) {
                  final lm = wheresBuddyLandmark(id);
                  final size = shortest * lm.sizeFraction;
                  return Positioned(
                    key: targets?.keyFor(id),
                    left: lm.position.dx * w - size / 2,
                    top: lm.position.dy * h - size / 2,
                    width: size,
                    child: WheresBuddyLandmarkSprite(
                      landmark: lm,
                      size: size,
                      highlighted: id == facingLandmarkId,
                    ),
                  );
                },
              ),
            if (!behind) _buddy(target, buddySize, w, h, behind),
            if (pointerVisible)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
                // Up and to the right, and smaller than Buddy. Down-right
                // was the obvious choice and wrong: Buddy stands above the
                // fountain for the first beat, so a hand below him covered
                // the very landmark the narrator was naming.
                left: target.dx * w + buddySize * 0.22,
                top: target.dy * h - buddySize * 0.52,
                width: buddySize * 0.62,
                height: buddySize * 0.62,
                child: IgnorePointer(
                  child: Image.asset(
                    AssetPaths.demoHandPointer,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buddy(Offset target, double size, double w, double h, bool behind) {
    // Animated rather than jumped: the *movement* is the lesson. A Buddy that
    // teleports to a spot shows her where he ended up; a Buddy that glides
    // there shows her the relationship, which is the thing the word names.
    final drawn = behind ? size * 0.82 : size;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      left: target.dx * w - drawn / 2,
      top: target.dy * h - drawn / 2,
      width: drawn,
      height: drawn,
      child: IgnorePointer(child: BuddyWidget(size: drawn)),
    );
  }
}
