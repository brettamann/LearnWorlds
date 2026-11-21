// The one piece of arithmetic three things now depend on.
//
// `HabitatFrameLayout` turns a blueprint's normalized corners into pixels. The
// picker card draws the finished habitat with it, the K.G.5 lesson lays the
// frame piece by piece with it, and both are supposed to match the triangle
// `build_a_habitat_runner` asks the kid to build. It was extracted precisely
// so those three could not drift; a shared helper with no test is a single
// point of drift rather than a single source of truth.
//
// It also carries a number that was wrong until it was rendered and looked at:
// clay balls were sized by guess at 0.15 per blueprint unit, which is half
// again fatter than the runner's own 0.10/0.56, and the lesson came out as
// three brown boulders holding up a triangle. Those two fractions are the
// runner's, restated, and the first test below is what stops them drifting
// back.

import 'package:critmath/activities/build_a_habitat/habitat_frame_layout.dart';
import 'package:critmath/data/build_a_habitat_blueprints.dart';
import 'package:flutter_test/flutter_test.dart';

/// `build_a_habitat_runner`'s own constants. Restated rather than imported
/// because they are private to it — and if they are made public, this should
/// import them instead of copying them.
const double kRunnerClayFraction = 0.10;
const double kRunnerStickFraction = 0.045;

/// How much of the runner's canvas a blueprint frame spans. Every blueprint
/// keeps its corners inside 0.20–0.80, so the widest is 0.56–0.60.
const double kRunnerFrameSpan = 0.56;

void main() {
  HabitatFrameLayout layoutFor(HabitatBlueprint b, {double side = 400}) =>
      HabitatFrameLayout(blueprint: b, width: side, height: side);

  test('a piece is the size the round draws it', () {
    // The ratio that matters is piece-to-frame, not piece-to-box: the lesson
    // and the card fit the frame to their own box, so only the proportion
    // survives. Anything much fatter and the corners stop reading as joints.
    for (final blueprint in kHabitatBlueprints) {
      final layout = layoutFor(blueprint);
      final frameWidth = 0.56 * layout.scale;
      expect(
        layout.clayDiameter / frameWidth,
        closeTo(kRunnerClayFraction / kRunnerFrameSpan, 0.02),
        reason: 'clay is not the size the runner draws it',
      );
      expect(
        layout.stickThickness / frameWidth,
        closeTo(kRunnerStickFraction / kRunnerFrameSpan, 0.02),
        reason: 'sticks are not the thickness the runner draws them',
      );
    }
  });

  test('and it is never zero', () {
    // The blunt one. A piece scaled to nothing is invisible rather than
    // wrong-looking, so it survives every check that only asks whether the
    // asset exists — which is what the picker's tests ask.
    for (final blueprint in kHabitatBlueprints) {
      final layout = layoutFor(blueprint);
      expect(layout.clayDiameter, greaterThan(4));
      expect(layout.stickThickness, greaterThan(2));
      for (final piece in blueprint.roof) {
        expect(layout.roofRect(piece).width, greaterThan(4));
      }
    }
  });

  test('every corner lands inside the box it was fitted to', () {
    const side = 400.0;
    for (final blueprint in kHabitatBlueprints) {
      final layout = layoutFor(blueprint, side: side);
      for (var i = 0; i < blueprint.corners.length; i++) {
        final c = layout.corner(i);
        expect(c.dx, inInclusiveRange(0, side), reason: blueprint.id);
        expect(c.dy, inInclusiveRange(0, side), reason: blueprint.id);
      }
    }
  });

  test('and the fit fills the box without distorting the shape', () {
    // One scale for both axes. A squashed pentagon is a different shape, and
    // on the picker card the shape is the whole content of the picture — it
    // is the only thing telling the three Build-a-Habitat options apart.
    const side = 400.0;
    for (final blueprint in kHabitatBlueprints) {
      final layout = layoutFor(blueprint, side: side);
      final xs = <double>[];
      final ys = <double>[];
      for (var i = 0; i < blueprint.corners.length; i++) {
        xs.add(layout.corner(i).dx);
        ys.add(layout.corner(i).dy);
      }
      final spanX =
          xs.reduce((a, b) => a > b ? a : b) -
          xs.reduce((a, b) => a < b ? a : b);
      final spanY =
          ys.reduce((a, b) => a > b ? a : b) -
          ys.reduce((a, b) => a < b ? a : b);
      // The longer side fills 90% of the box; the shorter one is whatever the
      // shape says it is, never stretched to match.
      expect(
        spanX > spanY ? spanX : spanY,
        closeTo(side * 0.90, 1.0),
        reason: blueprint.id,
      );
      final normalisedRatio = (spanX / spanY);
      final blueprintRatio = _blueprintAspect(blueprint);
      expect(normalisedRatio, closeTo(blueprintRatio, 0.001));
    }
  });

  test('an edge runs between the two corners it names', () {
    // The stick is drawn mid-anchored and rotated, the same construction the
    // runner uses, so getting this wrong lays sticks across the middle of the
    // frame rather than along its sides.
    for (final blueprint in kHabitatBlueprints) {
      final layout = layoutFor(blueprint);
      for (var i = 0; i < blueprint.edges.length; i++) {
        final pair = blueprint.edges[i];
        final a = layout.corner(pair[0]);
        final b = layout.corner(pair[1]);
        final e = layout.edge(i);
        expect(
          e.length,
          closeTo((b - a).distance, 0.01),
          reason: '${blueprint.id} edge $i is not as long as its side',
        );
        // Midpoint of the drawn bar is the midpoint of the side.
        final mid = Offset(
          e.topLeft.dx + e.length / 2,
          e.topLeft.dy + layout.stickThickness / 2,
        );
        expect(mid.dx, closeTo((a.dx + b.dx) / 2, 0.01));
        expect(mid.dy, closeTo((a.dy + b.dy) / 2, 0.01));
      }
    }
  });
}

double _blueprintAspect(HabitatBlueprint b) {
  var minX = b.corners.first.dx;
  var maxX = b.corners.first.dx;
  var minY = b.corners.first.dy;
  var maxY = b.corners.first.dy;
  for (final c in b.corners) {
    if (c.dx < minX) minX = c.dx;
    if (c.dx > maxX) maxX = c.dx;
    if (c.dy < minY) minY = c.dy;
    if (c.dy > maxY) maxY = c.dy;
  }
  return (maxX - minX) / (maxY - minY);
}
