// BuddyWidget — renders the kid's customized Buddy by stacking the
// part sprites in the right paint order. Used everywhere the Buddy
// appears: the Hub, the character creator preview, the Where's Buddy
// activity, and the Build-a-Habitat resident creature.
//
// Paint order (bottom → top):
//   1. Body                         — drawn first; everything else
//                                    stacks on top so accessories /
//                                    limbs / facial features sit
//                                    cleanly over the silhouette.
//   2. Legs (left + right)          — sit at the body's base, overlap
//                                    the lower edge.
//   3. Arms (left + right)          — overlap the body's mid-section.
//   4. Eyes                         — face features over the body.
//   5. Mouth                        — anchored just under the eyes.
//   6. Hat (optional)               — top of the stack so it overlaps
//                                    the head outline.
//
// The widget is intentionally light: it pulls the current appearance
// from `buddyAppearanceProvider` (so future edits in the creator
// propagate without rewiring) and lays everything out using fractional
// `Positioned`s inside a square `LayoutBuilder`. Pass `appearance`
// explicitly to override the saved one (the creator does this so you
// can preview a not-yet-confirmed combination).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/buddy_parts_catalog.dart';
import '../../models/buddy_appearance.dart';
import '../../providers/buddy_appearance_provider.dart';

class BuddyWidget extends ConsumerWidget {
  const BuddyWidget({
    super.key,
    this.appearance,
    this.size = 240,
  });

  /// Optional override for previews. When null the widget reads the
  /// kid's saved appearance from `buddyAppearanceProvider`.
  final BuddyAppearance? appearance;

  /// Bounding-box side length in logical pixels. The Buddy is drawn
  /// square; parts position themselves as fractions of this size.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BuddyAppearance shown =
        appearance ?? ref.watch(buddyAppearanceProvider);
    final arms = buddyArms(shown.armsId);
    final legs = buddyLegs(shown.legsId);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        // Clip is `none` so generous Buddy art (eyes that peek above
        // the body, a tail that drops below) isn't cropped to the
        // bounding square.
        clipBehavior: Clip.none,
        children: [
          // ---- Body (bottom layer) -------------------------------
          // Everything else stacks on top so accessories, limbs, and
          // facial features all sit cleanly over the silhouette.
          _frac(
            left: 0.15,
            top: 0.15,
            width: 0.70,
            height: 0.70,
            child: Image.asset(
              buddyBodyAsset(shown.bodyId),
              fit: BoxFit.contain,
            ),
          ),
          // ---- Legs -----------------------------------------------
          _frac(
            left: 0.18,
            top: 0.62,
            width: 0.30,
            height: 0.35,
            child: Image.asset(legs.leftAsset, fit: BoxFit.contain),
          ),
          _frac(
            left: 0.52,
            top: 0.62,
            width: 0.30,
            height: 0.35,
            child: Image.asset(legs.rightAsset, fit: BoxFit.contain),
          ),
          // ---- Arms -----------------------------------------------
          _frac(
            left: 0.02,
            top: 0.30,
            width: 0.30,
            height: 0.42,
            child: Image.asset(arms.leftAsset, fit: BoxFit.contain),
          ),
          _frac(
            left: 0.68,
            top: 0.30,
            width: 0.30,
            height: 0.42,
            child: Image.asset(arms.rightAsset, fit: BoxFit.contain),
          ),
          // ---- Eyes (anchored above mid-body) --------------------
          _frac(
            left: 0.28,
            top: 0.32,
            width: 0.44,
            height: 0.22,
            child: Image.asset(
              buddyEyesAsset(shown.eyesId),
              fit: BoxFit.contain,
            ),
          ),
          // ---- Mouth ---------------------------------------------
          _frac(
            left: 0.36,
            top: 0.54,
            width: 0.28,
            height: 0.14,
            child: Image.asset(
              buddyMouthAsset(shown.mouthId),
              fit: BoxFit.contain,
            ),
          ),
          // ---- Hat (optional, top of stack) ----------------------
          if (shown.hatId != null)
            _frac(
              left: 0.15,
              top: -0.02,
              width: 0.70,
              height: 0.34,
              child: Image.asset(
                buddyHatAsset(shown.hatId!),
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  /// Helper that takes fractional coords and converts them to a
  /// `Positioned` against the surrounding `size`. Pulled out so each
  /// part call site reads as data instead of arithmetic.
  Widget _frac({
    required double left,
    required double top,
    required double width,
    required double height,
    required Widget child,
  }) {
    return Positioned(
      left: left * size,
      top: top * size,
      width: width * size,
      height: height * size,
      child: child,
    );
  }
}
