// Fog-of-war cloud overlay. Tiles cloud sprites across the map area at
// half-cloud spacing, skipping any cell whose centre is within a node-and-
// a-half of a revealed node or revealed dotted-path segment. Clouds breathe
// gently (squash/stretch) on a shared controller — phase-offset per cloud so
// they don't pulse in unison.
//
// Cheap enough at the spacing we use (a couple dozen clouds per map at
// typical screen sizes); the squash animation uses a single ticker shared
// across every cloud rather than one controller per cloud.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';

class MapFogLayer extends StatefulWidget {
  const MapFogLayer({
    super.key,
    required this.size,
    required this.revealedNodes,
    required this.revealedSegments,
    required this.nodeDiameter,
    this.cloudWidth = 220,
    this.cloudHeight = 148,
  });

  /// Pixel dimensions of the map render area.
  final Size size;

  /// Centres of nodes that should be cloud-free.
  final List<Offset> revealedNodes;

  /// Pairs of (start, end) points; the dotted path between them is
  /// considered revealed. Clouds within a node-and-a-half of any point on
  /// these segments are suppressed.
  final List<(Offset, Offset)> revealedSegments;

  final double nodeDiameter;
  final double cloudWidth;
  final double cloudHeight;

  @override
  State<MapFogLayer> createState() => _MapFogLayerState();
}

class _MapFogLayerState extends State<MapFogLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  /// True if a cloud centred at `p` should be suppressed because it's near
  /// a revealed node or path segment.
  ///
  /// Suppression checks whether the cloud's *rendered rectangle* would come
  /// within `visibleClear` of the revealed point — not just the cell centre.
  /// Without this, adjacent non-suppressed cells render clouds whose sprite
  /// edges leak back into the supposed clearance, and the kid sees a solid
  /// wall of clouds with at most a pinprick of hole.
  ///
  /// `visibleClear` is intentionally generous (2.5× nodeDiameter) so the
  /// hole around a revealed node is unmistakably an island in the fog.
  bool _isNearReveal(Offset p) {
    final visibleClear = widget.nodeDiameter * 2.5;
    // Shrink the rect a bit because the cloud PNG has transparent edges —
    // the visible shape is smaller than the sprite box.
    final cloudRect = Rect.fromCenter(
      center: p,
      width: widget.cloudWidth * 0.85,
      height: widget.cloudHeight * 0.85,
    );
    for (final n in widget.revealedNodes) {
      if (_rectNearPoint(cloudRect, n, visibleClear)) return true;
    }
    for (final seg in widget.revealedSegments) {
      // Sample along each segment so any point along the dotted path
      // protects the cloud that overlaps it.
      const samples = 24;
      for (var i = 0; i <= samples; i++) {
        final t = i / samples;
        final point = Offset.lerp(seg.$1, seg.$2, t)!;
        if (_rectNearPoint(cloudRect, point, visibleClear)) return true;
      }
    }
    return false;
  }

  /// Closest distance from a rectangle to a point.
  bool _rectNearPoint(Rect rect, Offset point, double clearance) {
    final clx = point.dx.clamp(rect.left, rect.right);
    final cly = point.dy.clamp(rect.top, rect.bottom);
    final dist = (Offset(clx, cly) - point).distance;
    return dist < clearance;
  }

  @override
  Widget build(BuildContext context) {
    final cellW = widget.cloudWidth / 2;
    final cellH = widget.cloudHeight / 2;
    final cols = (widget.size.width / cellW).ceil() + 1;
    final rows = (widget.size.height / cellH).ceil() + 1;

    final cells = <Widget>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        // Offset every other row half a cell to break the grid pattern.
        final xOffset = (row.isOdd ? cellW / 2 : 0.0);
        final cx = col * cellW + xOffset;
        final cy = row * cellH;
        if (cx < 0 ||
            cx > widget.size.width ||
            cy < 0 ||
            cy > widget.size.height) {
          continue;
        }
        final centre = Offset(cx, cy);
        if (_isNearReveal(centre)) continue;
        // Phase offset: pseudo-random per cell so neighbouring clouds breathe
        // at different points in the cycle.
        final phase = ((col * 17 + row * 31) % 100) / 100.0;
        cells.add(
          _BreathingCloud(
            key: ValueKey('cloud-$row-$col'),
            breath: _breath,
            phase: phase,
            centre: centre,
            width: widget.cloudWidth,
            height: widget.cloudHeight,
          ),
        );
      }
    }

    return IgnorePointer(
      child: SizedBox.fromSize(
        size: widget.size,
        child: Stack(clipBehavior: Clip.hardEdge, children: cells),
      ),
    );
  }
}

class _BreathingCloud extends StatelessWidget {
  const _BreathingCloud({
    super.key,
    required this.breath,
    required this.phase,
    required this.centre,
    required this.width,
    required this.height,
  });

  final AnimationController breath;
  final double phase;
  final Offset centre;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breath,
      builder: (context, child) {
        final t = math.sin((breath.value + phase) * 2 * math.pi);
        // Volume-ish preservation: when squashed vertically (smaller scaleY),
        // grow scaleX. Range stays small so it reads as breathing not bouncing.
        final scaleY = 1.0 + t * 0.07;
        final scaleX = 1.0 - t * 0.05;
        return Positioned(
          left: centre.dx - width / 2,
          top: centre.dy - height / 2,
          width: width,
          height: height,
          child: Transform.scale(
            scaleX: scaleX,
            scaleY: scaleY,
            child: child,
          ),
        );
      },
      child: Opacity(
        opacity: 0.92,
        child: Image.asset(
          AssetPaths.mapCloud,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
