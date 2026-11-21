// The K.G.5 / K.G.6 lesson scene: the fawn shelter being built, piece by
// piece, out of the blueprint the round will then hand to the kid.
//
// These two were the last entries on `lesson_scene_test.dart`'s fallback
// ledger. Both drew three fawns in a meadow, because `lesson_screen`
// dispatches its iShow scene on `conceptId` and anything unrecognised lands on
// `_FawnStage` — a default that renders something plausible, which is why it
// survived so long. The lessons that introduce Build-a-Habitat showed no
// build site, no clay, no sticks and no habitat.
//
// Everything they needed was authored: a ghost triangle frame with three
// vertex indicators and three edge indicators, a pool of five clay balls and
// five sticks, a baby fawn waiting at the edge of the clearing for somewhere
// to live, and steps that place each piece in order while the narrator counts
// them. Read by nothing.
//
// It draws `kHabitatBlueprints[0]` — the triangle `simple-shelter` actually
// runs — through `HabitatFrameLayout`, the same geometry the picker card uses.
// The lesson's triangle, the card's triangle and the round's triangle are one
// triangle. That is the whole point of a lesson: it introduces *this* round.
//
// The two phases are one widget because they are one build. K.G.5 lays the
// frame; K.G.6 opens with that frame already solid and adds the cube on top,
// which is exactly what `creature-home` does across its rounds.

import 'package:flutter/material.dart';

import '../../activities/build_a_habitat/habitat_frame_layout.dart';
import '../../data/asset_paths.dart';
import '../../data/build_a_habitat_blueprints.dart';
import '../characters/buddy_widget.dart';
import 'lesson_target_registry.dart';

/// What the demo hand is currently holding, if anything.
enum HabitatCarry { none, clay, stick, roofPiece }

/// Where the build site sits on the stage, in normalized stage coordinates.
///
/// Public because the lesson screen has to map a blueprint coordinate back out
/// into stage space to park the demo hand on the piece it just placed, and a
/// second copy of these four numbers would drift the hand off the frame.
const Rect kHabitatSiteRect = Rect.fromLTWH(0.29, 0.34, 0.33, 0.46);

class HabitatLessonStage extends StatelessWidget {
  const HabitatLessonStage({
    super.key,
    required this.blueprint,
    required this.placedCorners,
    required this.placedEdges,
    required this.placedRoof,
    required this.showRoof,
    required this.carrying,
    required this.handVisible,
    required this.pointerTarget,
    required this.fawnHome,
    this.targets,
  });

  final HabitatBlueprint blueprint;

  /// Corner indices with a clay ball on them. The rest show the amber ghost
  /// halo — the same "tap here" language the runner uses.
  final Set<int> placedCorners;
  final Set<int> placedEdges;
  final Set<int> placedRoof;

  /// Whether the roof piece is drawn at all, ghost included.
  ///
  /// False for K.G.5, which is "let's build the frame" from first word to
  /// last. A ghost cube hovering over the triangle while the narrator counts
  /// corners is a second thing to look at during a lesson with one subject.
  final bool showRoof;

  final HabitatCarry carrying;

  /// Whether the demo hand is on screen at all.
  ///
  /// Separate from [carrying] because the hand stays between placements. Tied
  /// to carrying, it blinked out the instant each piece landed and back in at
  /// the next pickup - so the demonstration read as pieces appearing by
  /// themselves rather than as somebody putting them there, which is the
  /// entire content of an I-Show.
  final bool handVisible;

  /// Where the hand is, in normalized stage coordinates. Null parks it over
  /// the source pool.
  final Offset? pointerTarget;

  /// True once the resident has walked into its finished shelter — the payoff
  /// beat of K.G.6, and the reason the whole build was worth doing.
  final bool fawnHome;

  /// Where each corner and stick ended up, so the We-Try can ring the one it
  /// is asking for. Null outside that phase.
  final LessonTargetRegistry? targets;

  /// The build site occupies the middle of the stage; the pool sits lower
  /// right and Buddy lower left, as the scene block asks.
  static const Offset _poolCentre = Offset(0.85, 0.76);
  static const Offset _buddySpot = Offset(0.12, 0.78);

  /// On the grass, not in the canopy. The first attempt put it at 0.28 of the
  /// stage height, which on this background is the middle of a tree.
  static const Offset _fawnWaiting = Offset(0.87, 0.62);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final shortest = w < h ? w : h;
        final siteRect = Rect.fromLTWH(
          kHabitatSiteRect.left * w,
          kHabitatSiteRect.top * h,
          kHabitatSiteRect.width * w,
          kHabitatSiteRect.height * h,
        );
        final layout = HabitatFrameLayout(
          blueprint: blueprint,
          width: siteRect.width,
          height: siteRect.height,
        );
        final fawnSize = shortest * 0.16;
        final buddyBox = shortest * 0.20;
        final fawnAt = fawnHome
            ? Offset(
                (siteRect.left + layout.place(const Offset(0.5, 0.62)).dx) / w,
                (siteRect.top + layout.place(const Offset(0.5, 0.62)).dy) / h,
              )
            : _fawnWaiting;

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(
                AssetPaths.buildAHabitatBackground,
                fit: BoxFit.cover,
              ),
            ),
            // The resident. It waits at the edge of the clearing for the whole
            // lesson and walks in at the end, which is the only thing on this
            // screen that says why any of the building mattered.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1600),
              curve: Curves.easeInOut,
              left: fawnAt.dx * w - fawnSize / 2,
              top: fawnAt.dy * h - fawnSize / 2,
              width: fawnSize,
              height: fawnSize,
              child: IgnorePointer(
                child: Image.asset(
                  AssetPaths.countingParadeFawn,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned.fromRect(
              rect: siteRect,
              child: _BuildSite(
                layout: layout,
                placedCorners: placedCorners,
                placedEdges: placedEdges,
                placedRoof: placedRoof,
                showRoof: showRoof,
                targets: targets,
              ),
            ),
            _SourcePool(
              centre: _poolCentre,
              width: w,
              height: h,
              unit: shortest * 0.075,
            ),
            Positioned(
              left: _buddySpot.dx * w - buddyBox / 2,
              top: _buddySpot.dy * h - buddyBox / 2,
              width: buddyBox,
              height: buddyBox,
              // Watching, not building. He is the reason the shelter is being
              // made in the other two Where's-Buddy-adjacent scenes, and here
              // he is simply present so the clearing is somewhere she knows.
              child: IgnorePointer(child: BuddyWidget(size: buddyBox)),
            ),
            if (handVisible)
              _Hand(
                target: pointerTarget ?? _poolCentre,
                width: w,
                height: h,
                size: shortest * 0.1,
                carrying: carrying,
                blueprint: blueprint,
              ),
          ],
        );
      },
    );
  }
}

class _BuildSite extends StatelessWidget {
  const _BuildSite({
    required this.layout,
    required this.placedCorners,
    required this.placedEdges,
    required this.placedRoof,
    required this.showRoof,
    required this.targets,
  });

  final HabitatFrameLayout layout;
  final Set<int> placedCorners;
  final Set<int> placedEdges;
  final Set<int> placedRoof;
  final bool showRoof;

  /// Registered as `edge-1` / `vertex-1`, the ids the lesson JSON uses - one
  /// based, because the content counts corners the way a person does.
  final LessonTargetRegistry? targets;

  @override
  Widget build(BuildContext context) {
    final blueprint = layout.blueprint;
    final clay = layout.clayDiameter;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // Sticks first so the clay balls sit on top of the joins, which is
        // how a real frame goes together and how the runner draws it.
        for (var i = 0; i < blueprint.edges.length; i++)
          Builder(
            builder: (_) {
              final e = layout.edge(i);
              return Positioned(
                key: targets?.keyFor('edge-${i + 1}'),
                left: e.topLeft.dx,
                top: e.topLeft.dy,
                width: e.length,
                height: layout.stickThickness,
                child: Transform.rotate(
                  angle: e.angle,
                  child: placedEdges.contains(i)
                      ? Image.asset(
                          AssetPaths.buildAHabitatStick,
                          fit: BoxFit.fill,
                        )
                      : _ghostBar(layout.stickThickness),
                ),
              );
            },
          ),
        for (var i = 0; i < blueprint.corners.length; i++)
          Positioned(
            key: targets?.keyFor('vertex-${i + 1}'),
            left: layout.corner(i).dx - clay / 2,
            top: layout.corner(i).dy - clay / 2,
            width: clay,
            height: clay,
            child: placedCorners.contains(i)
                ? Image.asset(
                    AssetPaths.buildAHabitatClayBall,
                    fit: BoxFit.contain,
                  )
                : _ghostDot(),
          ),
        if (showRoof)
          for (var i = 0; i < blueprint.roof.length; i++)
            Builder(
              builder: (_) {
                final piece = blueprint.roof[i];
                final r = layout.roofRect(piece);
                return Positioned(
                  // `phase2-ghost-cube` is what K.G.6's We-Try scene calls the
                  // first one, and the id it asks her to touch.
                  key: targets?.keyFor(
                    i == 0 ? 'phase2-ghost-cube' : 'roof-${i + 1}',
                  ),
                  left: r.left,
                  top: r.top,
                  width: r.width,
                  height: r.height,
                  child: Image.asset(
                    placedRoof.contains(i)
                        ? piece.placedAsset
                        : piece.outlineAsset,
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
      ],
    );
  }

  /// An empty corner: the amber ghost halo `_CornerWidget` draws in the round,
  /// so "a piece goes here" looks the same in the lesson and in the game.
  Widget _ghostDot() => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.amber.shade400.withValues(alpha: 0.85),
        width: 3,
      ),
      color: Colors.amber.withValues(alpha: 0.15),
    ),
  );

  Widget _ghostBar(double thickness) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.amber.withValues(alpha: 0.20),
      border: Border.all(
        color: Colors.amber.shade400.withValues(alpha: 0.85),
        width: 2,
      ),
      borderRadius: BorderRadius.circular(thickness / 2),
    ),
  );
}

/// The clay and sticks she will be picking up in a moment.
class _SourcePool extends StatelessWidget {
  const _SourcePool({
    required this.centre,
    required this.width,
    required this.height,
    required this.unit,
  });

  final Offset centre;
  final double width;
  final double height;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: centre.dx * width - unit * 1.5,
      top: centre.dy * height - unit * 1.2,
      width: unit * 3,
      height: unit * 2.4,
      child: IgnorePointer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  SizedBox(
                    width: unit * 0.8,
                    height: unit * 0.8,
                    child: Image.asset(
                      AssetPaths.buildAHabitatClayBall,
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
            SizedBox(height: unit * 0.2),
            SizedBox(
              width: unit * 2.4,
              height: unit * 0.5,
              child: Image.asset(
                AssetPaths.buildAHabitatStick,
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The demo hand, holding whatever it just picked out of the pool.
///
/// The piece rides *under* the hand rather than the hand pointing at an empty
/// spot: what the lesson is teaching is that a thing moves from the pool to
/// the frame, and a pointer with nothing in it shows only half of that.
class _Hand extends StatelessWidget {
  const _Hand({
    required this.target,
    required this.width,
    required this.height,
    required this.size,
    required this.carrying,
    required this.blueprint,
  });

  final Offset target;
  final double width;
  final double height;
  final double size;
  final HabitatCarry carrying;
  final HabitatBlueprint blueprint;

  @override
  Widget build(BuildContext context) {
    final asset = switch (carrying) {
      HabitatCarry.clay => AssetPaths.buildAHabitatClayBall,
      HabitatCarry.stick => AssetPaths.buildAHabitatStick,
      HabitatCarry.roofPiece =>
        blueprint.roof.isEmpty
            ? AssetPaths.buildAHabitatClayBall
            : blueprint.roof.first.placedAsset,
      HabitatCarry.none => null,
    };
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      left: target.dx * width - size * 0.3,
      top: target.dy * height - size * 0.3,
      width: size * 1.6,
      height: size * 1.6,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (asset != null)
              Positioned(
                left: 0,
                top: 0,
                width: size * 0.7,
                height: size * 0.7,
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
            Positioned(
              left: size * 0.42,
              top: size * 0.38,
              width: size,
              height: size,
              child: Image.asset(
                AssetPaths.demoHandPointer,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
