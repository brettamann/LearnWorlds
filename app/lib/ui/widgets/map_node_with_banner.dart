// Yellow lesson node + parchment banner pair, sized + positioned relative to
// the rendered map area. Both pieces are tappable and share a single onTap
// — kids can hit either without thinking about it.
//
// Sizing rule: the node is rendered at a fraction of the rendered map's
// shorter side so it scales gracefully across screen sizes. The banner is
// stretchable horizontally to accommodate long lesson names — we'd rather
// distort the parchment than make the text unreadable (per the user spec).
//
// Banner positioning sides: caller chooses (right/left/above/below) so the
// parent map can avoid overlaps with other nodes, dotted lines, or banners.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';
import 'read_aloud_gate.dart';

/// Which side of the node the banner sits on.
enum BannerSide { right, left, above, below }

/// Original-pixel dimensions of `banner_parchment.png`. The text-area inside
/// is at (35, 28) and 143x63; outside that the decorative border has 35 left
/// / 24 right / 28 top / 25 bottom. We keep those margins proportional when
/// the banner is scaled or stretched.
class _BannerArt {
  static const double sourceWidth = 202;
  static const double sourceHeight = 116;
  static const double textLeft = 35;
  static const double textTop = 28;
  static const double textWidth = 143;
  static const double textHeight = 63;
}

class MapNodeWithBanner extends StatelessWidget {
  const MapNodeWithBanner({
    super.key,
    required this.center,
    required this.label,
    required this.nodeDiameter,
    required this.onTap,
    this.bannerSide = BannerSide.right,
    this.numberInside,
    this.isCutscene = false,
  });

  /// Position of the node's centre in the parent stack's pixel coordinates.
  final Offset center;

  /// Lesson name (or short caption) to render on the banner.
  final String label;

  /// Display diameter of the yellow node (px in the rendered map). The
  /// banner scales to look proportional next to it.
  final double nodeDiameter;

  final VoidCallback onTap;

  final BannerSide bannerSide;

  /// Optional numeric label drawn inside the node (e.g. lesson "3").
  /// Mutually exclusive with `isCutscene`.
  final int? numberInside;

  /// Render a play-arrow glyph inside the node instead of a number. Use
  /// this for nodes that open a cutscene rather than a lesson — kids
  /// recognise the glyph from video players and learn that the node is
  /// "watch me, no math here."
  final bool isCutscene;

  // Banner display height scales with node diameter so the pair feels like
  // one composed sprite at any zoom level.
  double get _bannerHeight => nodeDiameter * 0.85;

  // Text font is fitted to the banner's text-area height with a small inset.
  double get _fontSize => _bannerHeight * 0.36;

  /// Compute the banner width such that the label fits inside the text area
  /// at the chosen font size; never shrink below the natural banner width.
  ///
  /// Stretch math: when we widen the banner past natural, BoxFit.fill scales
  /// the parchment horizontally too — so the text area inside is
  /// `textWidth/sourceWidth * bannerW` in destination pixels. We invert
  /// that to find the bannerW required to fit the rendered text width with
  /// a small safety margin (kerning + sub-pixel measurement slop).
  double _computeBannerWidth(BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: _fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final scale = _bannerHeight / _BannerArt.sourceHeight;
    final naturalWidth = _BannerArt.sourceWidth * scale;
    const safety = 10.0;
    final requiredBannerW = (tp.width + safety) *
        _BannerArt.sourceWidth /
        _BannerArt.textWidth;
    return math.max(naturalWidth, requiredBannerW);
  }

  Offset _bannerTopLeft(double bannerW, double bannerH) {
    const gap = 8.0;
    switch (bannerSide) {
      case BannerSide.right:
        return Offset(
          center.dx + nodeDiameter / 2 + gap,
          center.dy - bannerH / 2,
        );
      case BannerSide.left:
        return Offset(
          center.dx - nodeDiameter / 2 - gap - bannerW,
          center.dy - bannerH / 2,
        );
      case BannerSide.above:
        return Offset(
          center.dx - bannerW / 2,
          center.dy - nodeDiameter / 2 - gap - bannerH,
        );
      case BannerSide.below:
        return Offset(
          center.dx - bannerW / 2,
          center.dy + nodeDiameter / 2 + gap,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannerH = _bannerHeight;
    final bannerW = _computeBannerWidth(context);
    final bannerTL = _bannerTopLeft(bannerW, bannerH);

    // BoxFit.fill stretches the parchment to bannerW × bannerH, so the
    // decorative left/right curls (and the text area between them) stretch
    // horizontally with the same `hScale`. Vertical layout uses `vScale`.
    // Mixing the two — as the old code did — left "Counting" overlapping
    // the scroll curl on stretched banners.
    final hScale = bannerW / _BannerArt.sourceWidth;
    final vScale = bannerH / _BannerArt.sourceHeight;
    final textLeftPx = _BannerArt.textLeft * hScale;
    final textTopPx = _BannerArt.textTop * vScale;
    final textHeightPx = _BannerArt.textHeight * vScale;
    final textWidthPx = _BannerArt.textWidth * hScale;

    // Banner content (parchment + label text), no gesture handling.
    final bannerVisual = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Image.asset(
            AssetPaths.mapBannerParchment,
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          left: textLeftPx,
          top: textTopPx,
          width: textWidthPx,
          height: textHeightPx,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );

    // Node content (yellow circle + number OR play glyph), no gesture handling.
    final nodeVisual = Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          AssetPaths.mapNodeYellow,
          fit: BoxFit.contain,
        ),
        if (numberInside != null)
          // Number occupies most of the node interior — bounded by
          // ~60% of the diameter so descenders don't kiss the rim.
          FractionallySizedBox(
            widthFactor: 0.62,
            heightFactor: 0.62,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                '$numberInside',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ),
          )
        else if (isCutscene)
          FractionallySizedBox(
            widthFactor: 0.55,
            heightFactor: 0.55,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.black87,
                size: nodeDiameter,
              ),
            ),
          ),
      ],
    );

    // Split the two hit regions on purpose:
    //   - The **banner** is text and stays wrapped in ReadAloudGate, so a
    //     kid who can't read the lesson name still hears it spoken.
    //   - The **node** is *not* gated. Live testing showed that the
    //     node's tap-narration ("Welcome" / "Counting Parade" / …) was
    //     racing the destination screen's own opening narration on
    //     Chrome and the first line of dialog often got dropped. The
    //     node is visually self-explanatory (yellow disc + number or
    //     play glyph), so silencing it costs the kid nothing — the
    //     banner directly next to it still narrates if they want to
    //     hear the name.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner first so the node visually overlaps the banner edge slightly.
        Positioned(
          left: bannerTL.dx,
          top: bannerTL.dy,
          width: bannerW,
          height: bannerH,
          child: ReadAloudGate(
            label: label,
            onTap: onTap,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: bannerVisual,
            ),
          ),
        ),
        Positioned(
          left: center.dx - nodeDiameter / 2,
          top: center.dy - nodeDiameter / 2,
          width: nodeDiameter,
          height: nodeDiameter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: nodeVisual,
          ),
        ),
      ],
    );
  }
}
