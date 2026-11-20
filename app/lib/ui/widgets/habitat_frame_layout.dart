// Where a blueprint's corners, sticks and roof pieces land inside a box.
//
// Extracted from the picker card's `_HabitatThumb` because the K.G.5 lesson
// draws the same frame, and a lesson that shows a slightly different triangle
// from the one the round asks her to build has introduced the wrong thing.
// Three callers now share one piece of arithmetic: the picker card, the lesson
// stage, and (through them) the blueprint data the runner assembles.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/build_a_habitat_blueprints.dart';

class HabitatFrameLayout {
  /// Fits [blueprint]'s corner bounding box into a [width] x [height] box.
  ///
  /// [fill] is how much of the shorter side the build takes up. Blueprint
  /// coordinates only ever span about 0.18-0.80, so drawing them straight in
  /// would waste a third of the box - which at picker-card size left three
  /// sixty-pixel polygons to tell apart from each other.
  factory HabitatFrameLayout({
    required HabitatBlueprint blueprint,
    required double width,
    required double height,
    double fill = 0.90,
  }) {
    final corners = blueprint.corners;
    var minX = corners.first.dx;
    var maxX = corners.first.dx;
    var minY = corners.first.dy;
    var maxY = corners.first.dy;
    for (final c in corners) {
      minX = math.min(minX, c.dx);
      maxX = math.max(maxX, c.dx);
      minY = math.min(minY, c.dy);
      maxY = math.max(maxY, c.dy);
    }
    // One scale for both axes — a squashed pentagon is a different shape, and
    // the shape is the whole content of this picture.
    final span = math.max(maxX - minX, maxY - minY);
    final shortest = math.min(width, height);
    final scale = span == 0 ? shortest : (fill / span) * shortest;
    return HabitatFrameLayout._(
      blueprint: blueprint,
      scale: scale,
      offsetX: (width - (maxX - minX) * scale) / 2 - minX * scale,
      offsetY: (height - (maxY - minY) * scale) / 2 - minY * scale,
    );
  }

  const HabitatFrameLayout._({
    required this.blueprint,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  final HabitatBlueprint blueprint;
  final double scale;
  final double offsetX;
  final double offsetY;

  /// A normalized blueprint coordinate in box pixels.
  Offset place(Offset normalized) => Offset(
        normalized.dx * scale + offsetX,
        normalized.dy * scale + offsetY,
      );

  Offset corner(int index) => place(blueprint.corners[index]);

  // The two numbers below are the runner's own fractions, restated in
  // blueprint space so they survive the bbox fit.
  //
  // `build_a_habitat_runner` draws clay at 0.10 and sticks at 0.045 of its
  // canvas's shorter side, with the frame spanning 0.56 of it - so a clay ball
  // is 0.10/0.56 of the frame's width, which is 0.10 per unit of blueprint
  // space. Guessing instead gave clay half again too fat, and it showed the
  // moment the lesson was rendered beside a fawn: three brown boulders holding
  // up a triangle.

  /// How thick a stick is drawn.
  double get stickThickness => scale * 0.045;

  /// Diameter of a clay ball at a corner.
  double get clayDiameter => scale * 0.10;

  /// The square a roof piece occupies. `size` on a piece is a fraction of the
  /// runner's shortest canvas side, so it takes the same scale the geometry
  /// did.
  Rect roofRect(HabitatRoofPiece piece) {
    final centre = place(piece.position);
    final side = piece.size * scale;
    return Rect.fromCenter(center: centre, width: side, height: side);
  }

  /// One edge as (top-left, length, angle) for a mid-anchored rotated stick —
  /// the same construction `_EdgeWidget` uses in the runner.
  ({Offset topLeft, double length, double angle}) edge(int index) {
    final pair = blueprint.edges[index];
    final a = corner(pair[0]);
    final b = corner(pair[1]);
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final length = (b - a).distance;
    return (
      topLeft: Offset(mid.dx - length / 2, mid.dy - stickThickness / 2),
      length: length,
      angle: math.atan2(b.dy - a.dy, b.dx - a.dx),
    );
  }
}
