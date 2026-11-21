// BuddyWidget — renders the kid's customized Buddy by stacking the
// part sprites in the right paint order, and keeps it alive.
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
// Liveness
// --------
// This used to be a plain Stack of Image.asset with no animation of any kind:
// the character a child designs herself sat motionless everywhere it appeared,
// which is a lot of investment to spend on something that then never reacts.
// It now breathes, blinks, and plays one-shot mood reactions.
//
// The trick that makes this cheap: arms, legs, eyes and mouth are already
// separate `Positioned` layers, so each can take its own `Transform` without
// any new art. A blink is the eyes layer squashed vertically and back — from
// the single existing eye PNG. A bigger smile is the mouth layer scaled up.
// Only when genuinely expressive mouths are commissioned does
// `buddyMouthIdForMood` start returning anything but the default, and because
// `buddyMouthAsset()` falls back to the first entry, that art can land later
// with no code change.
//
// The fractional `_frac` coordinates are calibrated against the real art —
// don't "tidy" the numbers.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/buddy_parts_catalog.dart';
import '../../models/buddy_appearance.dart';
import '../../models/buddy_mood.dart';
import '../../providers/buddy_appearance_provider.dart';

/// Which mouth sprite a mood wants.
///
/// Returns ids that may not exist yet — `buddyMouthAsset()` falls back to the
/// default — so the expression range widens the moment the art lands, without
/// a code change and without ever rendering a missing asset.
String buddyMouthIdForMood(BuddyMood mood, String fallbackId) {
  switch (mood) {
    case BuddyMood.happy:
      return 'v2'; // open smile
    case BuddyMood.curious:
      return 'v3'; // small o
    case BuddyMood.thinking:
      return 'v4'; // flat
    case BuddyMood.idle:
    case BuddyMood.encouraging:
      return fallbackId;
  }
}

class BuddyWidget extends ConsumerStatefulWidget {
  const BuddyWidget({
    super.key,
    this.appearance,
    this.size = 240,
    this.mood = BuddyMood.idle,
    this.reactionToken = 0,
    this.facing = BuddyFacing.right,
    this.idleAnimations = true,
  });

  /// Optional override for previews. When null the widget reads the
  /// kid's saved appearance from `buddyAppearanceProvider`.
  final BuddyAppearance? appearance;

  /// Bounding-box side length in logical pixels. The Buddy is drawn
  /// square; parts position themselves as fractions of this size.
  final double size;

  /// Current emotional register. Changing this alone does not replay a
  /// one-shot — bump [reactionToken] for that.
  final BuddyMood mood;

  /// Bump to (re)play the reaction for [mood]. Two correct answers in a row
  /// should give two hops, not one, which a mood comparison alone can't do.
  final int reactionToken;

  final BuddyFacing facing;

  /// Turns off breathing and blinking. Left on nearly everywhere — including
  /// the character creator, where watching the Buddy come alive as you build
  /// it is the whole point. Exists for still contexts like thumbnails and
  /// golden-image tests, where a moving sprite is just noise.
  final bool idleAnimations;

  @override
  ConsumerState<BuddyWidget> createState() => _BuddyWidgetState();
}

class _BuddyWidgetState extends ConsumerState<BuddyWidget>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _blink;
  late final AnimationController _react;

  Timer? _blinkTimer;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );
    _blink = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _react = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    if (widget.idleAnimations) {
      _breath.repeat(reverse: true);
      _scheduleBlink();
    }
  }

  /// Blinks are irregular on purpose. A metronomic blink reads as a machine;
  /// a random gap reads as something that happens to be alive.
  void _scheduleBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(
      Duration(milliseconds: 3500 + _rng.nextInt(4500)),
      () {
        if (!mounted) return;
        _blink.forward(from: 0).whenComplete(() {
          if (mounted) _blink.reverse();
        });
        _scheduleBlink();
      },
    );
  }

  @override
  void didUpdateWidget(BuddyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reactionToken != oldWidget.reactionToken &&
        widget.mood != BuddyMood.idle) {
      _react
        ..duration = _reactionDuration(widget.mood)
        ..forward(from: 0);
    }
    if (widget.idleAnimations != oldWidget.idleAnimations) {
      if (widget.idleAnimations) {
        _breath.repeat(reverse: true);
        _scheduleBlink();
      } else {
        _breath.stop();
        _blinkTimer?.cancel();
      }
    }
  }

  Duration _reactionDuration(BuddyMood mood) {
    switch (mood) {
      case BuddyMood.happy:
        return const Duration(milliseconds: 900);
      case BuddyMood.curious:
        return const Duration(milliseconds: 600);
      case BuddyMood.encouraging:
        return const Duration(milliseconds: 1400);
      case BuddyMood.thinking:
        return const Duration(milliseconds: 1200);
      case BuddyMood.idle:
        return const Duration(milliseconds: 400);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breath.dispose();
    _blink.dispose();
    _react.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BuddyAppearance shown =
        widget.appearance ?? ref.watch(buddyAppearanceProvider);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_breath, _blink, _react]),
        builder: (context, _) => _buildPosed(shown),
      ),
    );
  }

  Widget _buildPosed(BuddyAppearance shown) {
    final pose = _Pose.of(
      mood: widget.mood,
      t: _react.value,
      breath: _breath.value,
      blink: _blink.value,
    );

    // Whole-body transforms are applied outside the layer stack so the parts
    // keep their calibrated relationships to one another.
    Widget body = Transform.translate(
      offset: Offset(
        pose.translateX * widget.size,
        pose.translateY * widget.size,
      ),
      child: Transform.rotate(
        angle: pose.tilt,
        alignment: Alignment.bottomCenter,
        child: Transform.scale(
          scaleX: pose.scaleX,
          scaleY: pose.scaleY,
          // Anchored at the feet so a breath lifts the head rather than
          // floating the whole sprite — same reasoning as AnimatedFawn.
          alignment: Alignment.bottomCenter,
          child: _BuddyLayers(
            shown: shown,
            size: widget.size,
            pose: pose,
            mouthId: buddyMouthIdForMood(widget.mood, shown.mouthId),
          ),
        ),
      ),
    );

    if (widget.facing == BuddyFacing.left) {
      // Facing is free: mirror the sprite rather than authoring a second set.
      body = Transform.scale(scaleX: -1, child: body);
    }
    return body;
  }
}

/// Per-frame transform state, computed from mood plus controller values so the
/// widget body stays declarative and every pose is described in one place.
class _Pose {
  const _Pose({
    this.scaleX = 1,
    this.scaleY = 1,
    this.translateX = 0,
    this.translateY = 0,
    this.tilt = 0,
    this.armRotate = 0,
    this.eyeSquash = 1,
    this.eyeNudgeX = 0,
    this.mouthScale = 1,
  });

  factory _Pose.of({
    required BuddyMood mood,
    required double t,
    required double breath,
    required double blink,
  }) {
    // Idle life: a slow vertical swell with a matching horizontal give, so the
    // Buddy reads as having volume rather than being stretched.
    final breathY = 1.0 + breath * 0.035;
    final breathX = 1.0 - breath * 0.015;
    final breathLift = -breath * 0.008;
    // Eyelids close and reopen. Bottoming out at 0.06 rather than 0 keeps a
    // sliver visible, so the face never reads as a blank gap for a frame.
    final eyeSquash = 1.0 - blink * 0.94;

    // `arc` peaks at 1 mid-reaction and returns to 0, so every one-shot ends
    // exactly at rest and can never strand the Buddy in a pose.
    final arc = t == 0 ? 0.0 : math.sin(t * math.pi);

    switch (mood) {
      case BuddyMood.idle:
        return _Pose(
          scaleX: breathX,
          scaleY: breathY,
          translateY: breathLift,
          eyeSquash: eyeSquash,
        );

      case BuddyMood.happy:
        // Two hops. abs(sin) at double frequency touches down in the middle,
        // which reads as bouncing rather than as one lazy float.
        final hop = t == 0 ? 0.0 : math.sin(t * math.pi * 2).abs();
        return _Pose(
          scaleX: breathX * (1 + arc * 0.06),
          scaleY: breathY * (1 + arc * 0.06),
          translateY: breathLift - hop * 0.07 * (1 - t * 0.4),
          armRotate: arc * 0.32,
          eyeSquash: eyeSquash,
          mouthScale: 1 + arc * 0.25,
        );

      case BuddyMood.curious:
        // A quick head-tilt. This is the entire wrong-answer reaction —
        // "hm, not that one". Never a frown, never a slump.
        return _Pose(
          scaleX: breathX,
          scaleY: breathY,
          translateY: breathLift,
          tilt: arc * 0.14,
          eyeSquash: eyeSquash,
          eyeNudgeX: arc * 0.012,
          mouthScale: 1 - arc * 0.15,
        );

      case BuddyMood.encouraging:
        // Leans toward the playfield with an arm up. This is the hint ladder's
        // second rung — help arriving from a friend who noticed.
        return _Pose(
          scaleX: breathX,
          scaleY: breathY,
          translateX: arc * 0.04,
          translateY: breathLift - arc * 0.015,
          tilt: arc * 0.06,
          armRotate: -arc * 0.85,
          eyeSquash: eyeSquash,
        );

      case BuddyMood.thinking:
        return _Pose(
          scaleX: breathX,
          scaleY: breathY,
          translateY: breathLift,
          tilt: arc * 0.10,
          armRotate: -arc * 0.45,
          eyeSquash: eyeSquash,
          mouthScale: 1 - arc * 0.1,
        );
    }
  }

  final double scaleX;
  final double scaleY;

  /// Fractions of the widget's size rather than pixels, so poses scale with it.
  final double translateX;
  final double translateY;
  final double tilt;
  final double armRotate;
  final double eyeSquash;
  final double eyeNudgeX;
  final double mouthScale;
}

/// The sprite stack. Split out from BuddyWidget so the layout math stays
/// readable next to the pose transforms that modify it.
class _BuddyLayers extends StatelessWidget {
  const _BuddyLayers({
    required this.shown,
    required this.size,
    required this.pose,
    required this.mouthId,
  });

  final BuddyAppearance shown;
  final double size;
  final _Pose pose;
  final String mouthId;

  @override
  Widget build(BuildContext context) {
    final arms = buddyArms(shown.armsId);
    final legs = buddyLegs(shown.legsId);

    return Stack(
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
        // Rotated about the shoulder (the inner top corner) so a raised arm
        // pivots where a shoulder would, not around the sprite's middle.
        _frac(
          left: 0.02,
          top: 0.30,
          width: 0.30,
          height: 0.42,
          child: Transform.rotate(
            angle: -pose.armRotate,
            alignment: Alignment.topRight,
            child: Image.asset(arms.leftAsset, fit: BoxFit.contain),
          ),
        ),
        _frac(
          left: 0.68,
          top: 0.30,
          width: 0.30,
          height: 0.42,
          child: Transform.rotate(
            angle: pose.armRotate,
            alignment: Alignment.topLeft,
            child: Image.asset(arms.rightAsset, fit: BoxFit.contain),
          ),
        ),
        // ---- Eyes (anchored above mid-body) --------------------
        // The blink lives here: squashing this one layer vertically reads as
        // eyelids closing, which is how the Buddy blinks with a single static
        // eye sprite and no new art.
        _frac(
          left: 0.28,
          top: 0.32,
          width: 0.44,
          height: 0.22,
          child: Transform.translate(
            offset: Offset(pose.eyeNudgeX * size, 0),
            child: Transform.scale(
              scaleY: pose.eyeSquash,
              child: Image.asset(
                buddyEyesAsset(shown.eyesId),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // ---- Mouth ---------------------------------------------
        _frac(
          left: 0.36,
          top: 0.54,
          width: 0.28,
          height: 0.14,
          child: Transform.scale(
            scale: pose.mouthScale,
            child: Image.asset(
              buddyMouthAsset(mouthId),
              fit: BoxFit.contain,
            ),
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
