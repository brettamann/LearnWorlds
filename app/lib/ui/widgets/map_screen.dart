// MapScreen — a backdrop image with named clickable regions placed by
// normalized coordinates (0..1) so the map can be re-laid-out at any size
// without re-authoring the hit boxes.
//
// USE THIS for the Hub map, region maps (Sanctuary / Wundletown / Mathopolis),
// portal worlds, and any future "tap a place on this picture to go there"
// surface. The MapRegion list is the contract; the same widget renders all of
// them.
//
// Pattern documented at: specs/shared/map-screens.md.

import 'package:flutter/material.dart';

import '../../data/map_labels.dart';

import 'read_aloud_gate.dart';

/// What a region looks like on the painting behind it.
///
/// The island's four are circles, because the map has a medallion drawn at
/// each one - a flat disc with a heavy ring and a picture in it - and the
/// medallion is the only thing on that screen shaped like a button. Drawing
/// the dim-out as a rounded square over a circular badge reads as a smudge on
/// the painting rather than as a place that is closed.
///
/// The *hit* area stays rectangular either way. A slightly generous target is
/// the right way to be wrong for a five-year-old's aim.
enum MapRegionShape { rect, circle }

class MapRegion {
  const MapRegion({
    required this.id,
    required this.label,
    required this.rect,
    required this.onTap,
    this.enabled = true,
    this.shape = MapRegionShape.rect,
  });

  /// Stable identifier — used as Semantics label + test key.
  final String id;

  /// Human-readable label for accessibility (VoiceOver, hover tooltip).
  final String label;

  /// Hit rectangle in normalized image coordinates (0..1 on both axes).
  /// Origin is top-left of the rendered image.
  final Rect rect;

  /// Tap handler. Ignored when `enabled` is false (region is still drawn for
  /// future-proofing but tapping it does nothing).
  final VoidCallback onTap;

  /// When false, the region renders as a "coming soon" cue (subtle dim
  /// overlay) and ignores taps. Keeps disabled lessons / portal worlds
  /// honest about their state without removing them from the map.
  final bool enabled;

  /// How the region is drawn when it is dimmed or outlined. See
  /// [MapRegionShape].
  final MapRegionShape shape;
}

class MapScreen extends StatelessWidget {
  const MapScreen({
    super.key,
    required this.imageAsset,
    required this.aspectRatio,
    required this.regions,
    this.appBar,
    this.rail,
    this.showHitOutlines = false,
  });

  final String imageAsset;

  /// width / height of the underlying PNG. Required so the stack has a
  /// deterministic size (the image's intrinsic size isn't available until
  /// decode, which doesn't happen in unit tests, and the regions need a
  /// stable box to position against).
  final double aspectRatio;

  final List<MapRegion> regions;

  /// Optional AppBar (back button, TTS toggle, region title). Many maps want
  /// one; the home map typically doesn't.
  ///
  /// Controls a child has to *find* do not belong here — see [rail].
  final PreferredSizeWidget? appBar;

  /// Optional column of controls down the right-hand edge, normally a
  /// [MapSideRail].
  ///
  /// The map draws as a centred box at a fixed aspect ratio, so on any
  /// landscape screen there is unused space either side of it. The rail puts
  /// one of those columns to work rather than stretching the map into it —
  /// region rectangles are normalised against the *image*, so widening the
  /// image would drag every hit box off the artwork it was authored against.
  ///
  /// It sits outside the AspectRatio for the same reason.
  final Widget? rail;

  /// When true, region rectangles render with a faint border — handy when
  /// authoring a new map to visually verify hit-box coordinates against the
  /// underlying art. Should be false in shipping builds.
  final bool showHitOutlines;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(child: _map()),
            if (rail != null) rail!,
          ],
        ),
      ),
    );
  }

  Widget _map() {
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.fill,
                  ),
                ),
                for (final region in regions)
                  Positioned(
                    key: ValueKey('map-region-${region.id}'),
                    left: region.rect.left * w,
                    top: region.rect.top * h,
                    width: region.rect.width * w,
                    height: region.rect.height * h,
                    child: _RegionHit(
                      region: region,
                      showOutline: showHitOutlines,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RegionHit extends StatelessWidget {
  const _RegionHit({required this.region, required this.showOutline});

  final MapRegion region;
  final bool showOutline;

  @override
  Widget build(BuildContext context) {
    final circle = region.shape == MapRegionShape.circle;
    final outline = showOutline
        ? Border.all(
            color: region.enabled
                ? Colors.greenAccent.withValues(alpha: 0.8)
                : Colors.redAccent.withValues(alpha: 0.8),
            width: 2,
          )
        : null;
    final visual = MouseRegion(
      cursor:
          region.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: region.enabled ? region.onTap : null,
        child: Container(
          decoration: BoxDecoration(
            border: outline,
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circle ? null : BorderRadius.circular(12),
            // Dimmed rather than hidden, and now that the region sits on the
            // badge this dims the badge - which is what makes the spoken line
            // ("try one of the bright ones") true of what she is looking at.
            // It used to darken a rectangle of jungle several inches away.
            color: region.enabled
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.38),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
    return Semantics(
      button: region.enabled,
      label: region.label,
      // A disabled region is gated too, and says why rather than saying its
      // own name. It used to be bare: `onTap: null` under an opaque hit test,
      // which swallowed the touch and returned nothing at all - no sound, no
      // voice, no movement. On the first screen of every session, two of the
      // four places a child can press did that.
      //
      // It names no place, deliberately, exactly as the Sanctuary's sleeping
      // nodes do: one clip covers every dark place on both maps, and she
      // already knows which one she touched. What she does not know is that
      // nothing is broken and where to go instead.
      child: ReadAloudGate(
        label: region.enabled ? region.label : kAsleepPlaceLine,
        onTap: region.enabled ? region.onTap : () {},
        child: visual,
      ),
    );
  }
}
