// How each numeral is written, as the strokes a child's finger follows.
//
// Coordinates are fractions of the numeral's own box (x across, y down) and
// every stroke runs in the direction it is written - top first, the way a
// kindergarten teacher's arrow shows it. Direction is not decoration here:
// tracing is how the motor pattern for a numeral is learned, and a path that
// accepted either direction would be teaching her to draw a picture of a
// number rather than to write one.
//
// Curves are sampled into short straight segments. The tracer only ever
// measures distance along the path and distance to it, so a polyline is all
// it needs, and sampling here keeps the shapes readable as numbers.

import 'dart:math' as math;
import 'dart:ui';

typedef Stroke = List<Offset>;

Stroke _line(List<Offset> pts) => List<Offset>.of(pts);

/// An arc of an ellipse centred at [c], from [from] to [to] degrees, with y
/// pointing down: 0 is right, 90 is the bottom, -90 is the top.
Stroke _arc(Offset c, double rx, double ry, double from, double to) {
  final steps = math.max(8, ((to - from).abs() / 8).round());
  return <Offset>[
    for (var i = 0; i <= steps; i++)
      () {
        final a = (from + (to - from) * i / steps) * math.pi / 180;
        return Offset(c.dx + rx * math.cos(a), c.dy + ry * math.sin(a));
      }(),
  ];
}

Stroke _join(List<Stroke> parts) {
  final out = <Offset>[];
  for (final p in parts) {
    if (out.isNotEmpty &&
        p.isNotEmpty &&
        (out.last - p.first).distance < 1e-6) {
      out.addAll(p.skip(1));
    } else {
      out.addAll(p);
    }
  }
  return out;
}

/// The strokes of [n], 0 to 10. Width-to-height of the box is
/// [numeralAspect].
List<Stroke> numeralStrokes(int n) {
  switch (n) {
    case 0:
      // From the top, round to the left - anticlockwise, the way it is taught.
      return <Stroke>[_arc(const Offset(0.5, 0.5), 0.3, 0.42, -90, -450)];
    case 1:
      return <Stroke>[
        _line(const <Offset>[Offset(0.5, 0.08), Offset(0.5, 0.92)]),
      ];
    case 2:
      return <Stroke>[
        _join(<Stroke>[
          _arc(const Offset(0.5, 0.32), 0.26, 0.24, -165, 25),
          _line(const <Offset>[Offset(0.735, 0.42), Offset(0.24, 0.92)]),
          _line(const <Offset>[Offset(0.24, 0.92), Offset(0.8, 0.92)]),
        ]),
      ];
    case 3:
      return <Stroke>[
        _join(<Stroke>[
          _arc(const Offset(0.48, 0.29), 0.24, 0.21, -160, 90),
          _arc(const Offset(0.48, 0.71), 0.27, 0.21, -90, 160),
        ]),
      ];
    case 4:
      return <Stroke>[
        _line(const <Offset>[
          Offset(0.62, 0.08),
          Offset(0.2, 0.64),
          Offset(0.84, 0.64),
        ]),
        _line(const <Offset>[Offset(0.62, 0.08), Offset(0.62, 0.92)]),
      ];
    case 5:
      return <Stroke>[
        _join(<Stroke>[
          _line(const <Offset>[Offset(0.3, 0.08), Offset(0.27, 0.46)]),
          _arc(const Offset(0.48, 0.66), 0.28, 0.26, -130, 150),
        ]),
        _line(const <Offset>[Offset(0.3, 0.08), Offset(0.76, 0.08)]),
      ];
    case 6:
      return <Stroke>[
        _join(<Stroke>[
          _arc(const Offset(0.62, 0.62), 0.38, 0.54, -95, -175),
          _arc(const Offset(0.5, 0.7), 0.26, 0.22, 180, -180),
        ]),
      ];
    case 7:
      return <Stroke>[
        _line(const <Offset>[
          Offset(0.2, 0.08),
          Offset(0.8, 0.08),
          Offset(0.4, 0.92),
        ]),
      ];
    case 8:
      // One stroke: round the top loop to the left, cross, round the bottom
      // loop the other way, and back up the right side to where it began.
      return <Stroke>[
        _join(<Stroke>[
          _arc(const Offset(0.5, 0.28), 0.22, 0.2, -90, -270),
          _arc(const Offset(0.5, 0.7), 0.26, 0.22, -90, 270),
          _arc(const Offset(0.5, 0.28), 0.22, 0.2, 90, -90),
        ]),
      ];
    case 9:
      return <Stroke>[
        _join(<Stroke>[
          _arc(const Offset(0.46, 0.3), 0.24, 0.22, 0, -360),
          _line(const <Offset>[Offset(0.7, 0.3), Offset(0.66, 0.92)]),
        ]),
      ];
    case 10:
      return <Stroke>[
        _line(const <Offset>[Offset(0.2, 0.08), Offset(0.2, 0.92)]),
        _arc(const Offset(0.68, 0.5), 0.2, 0.42, -90, -450),
      ];
  }
  throw ArgumentError.value(n, 'n', 'only 0 to 10 are drawn');
}

/// Width over height of a numeral's box.
double numeralAspect(int n) => n == 10 ? 1.05 : 0.7;
