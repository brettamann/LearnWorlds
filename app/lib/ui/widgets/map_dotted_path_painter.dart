// CustomPainter that draws a dotted line connecting an ordered list of
// node positions. The dots are filled circles spaced at a regular interval
// along each segment; a small visual gap is left at each endpoint so the
// dots don't run into the yellow node sprites.

import 'package:flutter/material.dart';

class MapDottedPathPainter extends CustomPainter {
  const MapDottedPathPainter({
    required this.segments,
    required this.nodeDiameter,
    this.dotRadius = 4.5,
    this.dotSpacing = 22,
    this.color = const Color(0xCC4A3328),
  });

  /// Segments to draw, each a (start, end) point pair in canvas pixels.
  /// The screen passes only the segments whose **both** endpoint nodes are
  /// currently visible — so unexplored paths stay invisible until the kid
  /// has discovered the destination node.
  final List<(Offset, Offset)> segments;

  /// Diameter of the node sprites on screen. Used to leave a clear ring
  /// around each endpoint so the dots don't run into the node art.
  final double nodeDiameter;

  final double dotRadius;
  final double dotSpacing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final ring = nodeDiameter / 2 + dotRadius + 4;

    for (final (start, end) in segments) {
      final delta = end - start;
      final distance = delta.distance;
      if (distance <= ring * 2) continue; // Nodes too close to dot between.
      final unit = Offset(delta.dx / distance, delta.dy / distance);
      final usable = distance - ring * 2;
      final dotCount = (usable / dotSpacing).floor() + 1;
      if (dotCount < 1) continue;
      final actualSpacing = dotCount == 1 ? 0 : usable / (dotCount - 1);
      for (var d = 0; d < dotCount; d++) {
        final p = start + unit * (ring + d * actualSpacing);
        canvas.drawCircle(p, dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(MapDottedPathPainter old) {
    return old.segments != segments ||
        old.nodeDiameter != nodeDiameter ||
        old.color != color;
  }
}
