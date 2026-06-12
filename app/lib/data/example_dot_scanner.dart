// ExampleDotScanner — finds the magenta side-locator dots embedded in the
// `*-example` 2D shape sprites and returns them as normalized 0..1 positions
// the lesson can use to drive the hand pointer around the shape's actual
// painted sides. Replaces the regular-polygon math that the K.G.2 intro
// originally used (which was a pixel or two off real edges for non-regular
// shapes — rectangles, right triangles, half/quarter circles).
//
// Color sentinel: `#FF00F0` exact, with a small tolerance band (see _scan).
// The artist places ONE dot per side at the side's midpoint. For circles,
// no dots are present (no sides). For the imperfect-circle shapes
// (semicircle_half / semicircle_quarter) the artist places dots on the
// flat side(s) AND on the curved side — those are valid "sides" at K.
//
// Clustering: PNG export from various tools occasionally produces a 2×2 or
// L-shaped sentinel cluster (one author dot blurred at compression). The
// scanner unions matching pixels within `_clusterRadius` of each other and
// returns the centroid per cluster, so a slightly-bled dot still counts as
// one position rather than four.
//
// Ordering: dots are returned sorted clockwise around the shape's centroid
// starting from "north" (the topmost dot). The hand pointer walks them in
// that order so the count narration ("One. Two. Three.") visually matches
// a kid's instinct of going around the shape from the top.

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

/// Scanned dot positions for a single shape's example PNG, plus the source
/// image's aspect ratio so callers rendering with `BoxFit.contain` can map
/// the normalized 0..1 dot positions into the actual painted rect inside
/// their bounding box (otherwise non-square sprites — half-circle, quarter
/// circle, anything not 1:1 — see the hand pointer drift into the
/// letterboxed margin).
class ShapeDots {
  const ShapeDots({required this.dots, required this.aspectRatio});

  /// Side-locator positions normalized to the *source image's* dimensions —
  /// i.e. (0, 0) is the top-left of the PNG, (1, 1) is the bottom-right.
  final List<ui.Offset> dots;

  /// `imageWidth / imageHeight` of the source sprite. Used to compute the
  /// contained rect inside a square bounding box.
  final double aspectRatio;

  static const ShapeDots empty = ShapeDots(dots: <ui.Offset>[], aspectRatio: 1);
}

class ExampleDotScanner {
  const ExampleDotScanner();

  /// Pixels within this Chebyshev radius of each other belong to the same
  /// dot cluster. 2 is enough for any 1-px PNG bleed without merging genuinely
  /// distinct side markers (the smallest real side on any K.G.2 sprite is far
  /// larger than ~5 px).
  static const int _clusterRadius = 2;

  Future<ShapeDots> scan(String assetPath) async {
    final ByteData data;
    try {
      data = await rootBundle.load(assetPath);
    } catch (e) {
      // Missing example sprite is non-fatal — the intro layer will fall back
      // to algorithmic side positions for polygons, or to "no sides" for
      // circles.
      developer.log(
        'ExampleDotScanner: $assetPath not found ($e) — returning no dots',
        name: 'critmath.shapes',
      );
      return ShapeDots.empty;
    }
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw StateError(
          'Failed to read pixels from $assetPath (toByteData returned null)',
        );
      }
      final pixels = <_Pixel>[];
      _scan(
        bytes: byteData.buffer.asUint8List(),
        width: image.width,
        height: image.height,
        out: pixels,
      );
      final clusters = _cluster(pixels);
      final ordered = _orderClockwiseFromTop(clusters);
      final normalized = ordered
          .map((p) => ui.Offset(p.dx / image.width, p.dy / image.height))
          .toList(growable: false);
      developer.log(
        'ExampleDotScanner: $assetPath '
        '(${image.width}x${image.height}) '
        'found ${pixels.length} pixel(s) → ${normalized.length} dot(s)',
        name: 'critmath.shapes',
      );
      return ShapeDots(
        dots: normalized,
        aspectRatio: image.width / image.height,
      );
    } finally {
      image.dispose();
    }
  }

  void _scan({
    required Uint8List bytes,
    required int width,
    required int height,
    required List<_Pixel> out,
  }) {
    // Sentinel: #FF00F0. Same tolerance philosophy as MapAnchorScanner —
    // accept R ≥ 0xF0, G ≤ 0x10, B in [0xEF..0xF1]. Painted art doesn't
    // produce this combination naturally.
    final pixelCount = width * height;
    for (var i = 0; i < pixelCount; i++) {
      final off = i * 4;
      if (bytes[off] < 0xF0) continue;
      if (bytes[off + 1] > 0x10) continue;
      final b = bytes[off + 2];
      if (b < 0xEF || b > 0xF1) continue;
      // Require non-trivial alpha so a fully-transparent stray pixel can't
      // false-trigger.
      if (bytes[off + 3] < 0x80) continue;
      out.add(_Pixel(i % width, i ~/ width));
    }
  }

  /// Union-find style clustering. Two pixels are in the same cluster if any
  /// two members are within _clusterRadius (Chebyshev) of each other. Returns
  /// centroids in pixel space.
  List<ui.Offset> _cluster(List<_Pixel> pixels) {
    if (pixels.isEmpty) return const <ui.Offset>[];
    final parent = List<int>.generate(pixels.length, (i) => i);
    int find(int x) {
      while (parent[x] != x) {
        parent[x] = parent[parent[x]];
        x = parent[x];
      }
      return x;
    }

    void union(int a, int b) {
      final ra = find(a);
      final rb = find(b);
      if (ra != rb) parent[ra] = rb;
    }

    // O(n^2) is fine — even a hexagon-example PNG yields a handful of pixels.
    for (var i = 0; i < pixels.length; i++) {
      for (var j = i + 1; j < pixels.length; j++) {
        final dx = (pixels[i].x - pixels[j].x).abs();
        final dy = (pixels[i].y - pixels[j].y).abs();
        if (dx <= _clusterRadius && dy <= _clusterRadius) {
          union(i, j);
        }
      }
    }
    final buckets = <int, List<_Pixel>>{};
    for (var i = 0; i < pixels.length; i++) {
      buckets.putIfAbsent(find(i), () => <_Pixel>[]).add(pixels[i]);
    }
    return buckets.values.map((cluster) {
      var sx = 0.0;
      var sy = 0.0;
      for (final p in cluster) {
        sx += p.x;
        sy += p.y;
      }
      return ui.Offset(sx / cluster.length, sy / cluster.length);
    }).toList(growable: false);
  }

  /// Sorts dots clockwise around their centroid starting from the topmost
  /// one. Result: a hand walking these positions traces the shape's perimeter
  /// in a predictable, kid-readable order.
  List<ui.Offset> _orderClockwiseFromTop(List<ui.Offset> dots) {
    if (dots.length <= 1) return List<ui.Offset>.from(dots);
    var cx = 0.0;
    var cy = 0.0;
    for (final d in dots) {
      cx += d.dx;
      cy += d.dy;
    }
    cx /= dots.length;
    cy /= dots.length;

    // Angle from centroid. We measure with atan2(y - cy, x - cx) which is in
    // (-π, π], with -π/2 = "due north" in screen coords (y grows downward).
    // We want north first, then go clockwise (which in this convention means
    // increasing angle).
    double normalisedAngle(ui.Offset d) {
      final a = math.atan2(d.dy - cy, d.dx - cx);
      // Re-zero so north (-π/2) = 0, clockwise increases.
      var t = a + math.pi / 2;
      if (t < 0) t += 2 * math.pi;
      return t;
    }

    final indexed = List<ui.Offset>.from(dots)
      ..sort((a, b) => normalisedAngle(a).compareTo(normalisedAngle(b)));
    return indexed;
  }
}

class _Pixel {
  const _Pixel(this.x, this.y);
  final int x;
  final int y;
}
