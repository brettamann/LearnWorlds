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

class MapRegion {
  const MapRegion({
    required this.id,
    required this.label,
    required this.rect,
    required this.onTap,
    this.enabled = true,
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
}

class MapScreen extends StatelessWidget {
  const MapScreen({
    super.key,
    required this.imageAsset,
    required this.aspectRatio,
    required this.regions,
    this.appBar,
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
  final PreferredSizeWidget? appBar;

  /// When true, region rectangles render with a faint border — handy when
  /// authoring a new map to visually verify hit-box coordinates against the
  /// underlying art. Should be false in shipping builds.
  final bool showHitOutlines;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
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
    final outline = showOutline
        ? Border.all(
            color: region.enabled
                ? Colors.greenAccent.withValues(alpha: 0.8)
                : Colors.redAccent.withValues(alpha: 0.8),
            width: 2,
          )
        : null;
    return Semantics(
      button: region.enabled,
      label: region.label,
      child: MouseRegion(
        cursor: region.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: region.enabled ? region.onTap : null,
          child: Container(
            decoration: BoxDecoration(
              border: outline,
              borderRadius: BorderRadius.circular(12),
              color: region.enabled
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.18),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
