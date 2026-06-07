// Magenta anchor scanner. The artist embeds one-pixel marker dots in the
// map's PNG (no anti-aliasing) at positions where the game should render
// nodes / path waypoints / fog seeds. The scanner finds them once at map
// load and returns normalized 0..1 positions keyed by the last byte of the
// sentinel color, so coordinate authoring lives inside the art file rather
// than in code.
//
// Sentinel range used here: `#FF00F0` through `#FF00FB` (magenta-family —
// vanishingly rare in painted terrain, very obvious in code). The full
// 256-code range `#FF00xx` is available for future expansion (path
// waypoints, fog centers, etc.) using different bands.
//
// IMPORTANT for the artist:
//   - Map MUST be PNG (JPG compression destroys single-pixel markers).
//   - Brush MUST have anti-aliasing OFF and be 1 px wide.
//   - One pixel per anchor; multiple consecutive same-color pixels would
//     produce ambiguous positions — the scanner takes the first one found
//     and ignores the rest.

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

/// Result of a scan — found anchors with normalized 0..1 positions, plus the
/// source image dimensions for any consumer that needs them.
class MapAnchors {
  const MapAnchors({
    required this.anchors,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// Key: the last byte of the sentinel color (e.g. `0xF1` for `#FF00F1`).
  /// Value: normalized 0..1 position in the image (origin top-left).
  final Map<int, ui.Offset> anchors;
  final int imageWidth;
  final int imageHeight;

  double get aspectRatio => imageWidth / imageHeight;

  ui.Offset? operator [](int code) => anchors[code];
}

class MapAnchorScanner {
  const MapAnchorScanner();

  /// Loads `assetPath` as a PNG, decodes it, and returns every pixel whose
  /// color matches `R == 0xFF && G == 0x00 && B in [minBlue, maxBlue]`.
  /// Default sentinel band covers the 12-code range `#FF00F0..#FF00FB`.
  Future<MapAnchors> scan(
    String assetPath, {
    int minBlue = 0xF0,
    int maxBlue = 0xFB,
  }) async {
    final data = await rootBundle.load(assetPath);
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
      final found = <int, ui.Offset>{};
      _scan(
        bytes: byteData.buffer.asUint8List(),
        width: image.width,
        height: image.height,
        minBlue: minBlue,
        maxBlue: maxBlue,
        out: found,
      );
      // Always log the actual codes found + the codes still missing inside
      // the expected band — makes a drifted single anchor easy to spot.
      final foundCodes = found.keys.toList()..sort();
      final foundHex =
          foundCodes.map((c) => '0x${c.toRadixString(16)}').join(', ');
      final missingCodes = <String>[
        for (var c = minBlue; c <= maxBlue; c++)
          if (!found.containsKey(c)) '0x${c.toRadixString(16)}',
      ];
      developer.log(
        'MapAnchorScanner: $assetPath '
        '(${image.width}x${image.height}) '
        'found ${found.length} anchors [$foundHex]'
        '${missingCodes.isEmpty ? '' : ' — missing [${missingCodes.join(', ')}]'}',
        name: 'critmath.maps',
      );
      return MapAnchors(
        anchors: found,
        imageWidth: image.width,
        imageHeight: image.height,
      );
    } finally {
      image.dispose();
    }
  }

  void _scan({
    required Uint8List bytes,
    required int width,
    required int height,
    required int minBlue,
    required int maxBlue,
    required Map<int, ui.Offset> out,
  }) {
    // RGBA layout, 4 bytes per pixel, row-major.
    //
    // Tolerance: accept R ≥ 0xF0 and G ≤ 0x10 instead of exact 0xFF / 0x00.
    // PNG round-trips through some paint tools nudge channels by a couple
    // of bits; this captures those without admitting any natural-painted
    // colour (no plausible terrain colour has R ≥ 240 AND G ≤ 16).
    //
    // For the blue band we accept a 1-byte slop on each side of [minBlue,
    // maxBlue] and clamp the result back into the canonical range. So a
    // pixel that drifted to 0xEF still registers as 0xF0; 0xFC still
    // registers as 0xFB. Anything farther out is ignored.
    final pixelCount = width * height;
    for (var i = 0; i < pixelCount; i++) {
      final off = i * 4;
      if (bytes[off] < 0xF0) continue;
      if (bytes[off + 1] > 0x10) continue;
      final raw = bytes[off + 2];
      if (raw < minBlue - 1 || raw > maxBlue + 1) continue;
      // Snap to the canonical code.
      var code = raw;
      if (code < minBlue) code = minBlue;
      if (code > maxBlue) code = maxBlue;
      // First match per code wins; later duplicates ignored.
      if (out.containsKey(code)) continue;
      final x = i % width;
      final y = i ~/ width;
      out[code] = ui.Offset(x / width, y / height);
    }
  }
}
