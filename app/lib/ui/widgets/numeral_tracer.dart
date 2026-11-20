// NumeralTracer - a numeral she writes by following it with her finger.
//
// The numeral is laid out as a soft path with a green dot where the pen goes
// down and a little arrow for which way. Her finger pulls glowing ink along
// the path; the ink only ever advances, and only while her finger is close to
// the part of the path just ahead of it.
//
// Chosen for a five-year-old specifically:
//
// - **Generous.** The finger may be a tenth of the numeral's height off the
//   line and still count. The skill is the order and direction of the
//   strokes, not precision, and a tracer that stops at every wobble teaches
//   her that writing is where she fails.
// - **Nothing is ever wrong.** Straying pauses the ink; it does not erase it
//   and it does not make a sound. Lifting her finger keeps what she has done.
//   Starting somewhere other than the dot gets one gentle reminder of where
//   to start.
// - **Direction counts.** The ink will not run backwards up a stroke, so
//   tracing a 7 from the bottom does nothing until she starts at the top.
// - **The firefly shows the way.** It sits on the green dot, and when she is
//   stuck it flies the stroke once in front of her - a demonstration she
//   watches, not a stroke drawn for her.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';
import 'numeral_strokes.dart';

class NumeralTracer extends StatefulWidget {
  const NumeralTracer({
    super.key,
    required this.numeral,
    required this.onDone,
    this.onStrokeDone,
    this.onStray,
    this.onProgress,
    this.guideOpacity = 1,
    this.ringStart = false,
    this.demoToken = 0,
    this.locked = false,
  });

  final int numeral;
  final VoidCallback onDone;

  /// A stroke finished and there is another to go.
  final VoidCallback? onStrokeDone;

  /// She put her finger down somewhere that is not the start.
  final VoidCallback? onStray;

  /// The ink moved - she is doing something.
  final VoidCallback? onProgress;

  /// 1 for tracing; lower for writing over a fainter guide.
  final double guideOpacity;
  final bool ringStart;

  /// Bumped to have the firefly fly the current stroke.
  final int demoToken;
  final bool locked;

  @override
  State<NumeralTracer> createState() => _NumeralTracerState();
}

class _NumeralTracerState extends State<NumeralTracer>
    with TickerProviderStateMixin {
  late final List<Stroke> _strokes = numeralStrokes(widget.numeral);
  int _stroke = 0;
  double _s = 0;
  bool _tracing = false;
  bool _finished = false;
  DateTime _lastStray = DateTime.fromMillisecondsSinceEpoch(0);

  late final AnimationController _demo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..addListener(() => setState(() {}));

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  /// Pixel geometry of the current layout.
  _TraceGeometry? _geo;

  @override
  void didUpdateWidget(NumeralTracer old) {
    super.didUpdateWidget(old);
    if (widget.demoToken != old.demoToken && !_finished) {
      _demo.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _demo.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _down(Offset p) {
    final g = _geo;
    if (g == null || widget.locked || _finished) return;
    final here = g.pointAt(_stroke, _s);
    if ((p - here).distance <= g.tolerance * 1.4) {
      _tracing = true;
      _move(p);
      return;
    }
    _tracing = false;
    final now = DateTime.now();
    if (now.difference(_lastStray) > const Duration(seconds: 3)) {
      _lastStray = now;
      widget.onStray?.call();
    }
  }

  void _move(Offset p) {
    final g = _geo;
    if (g == null || !_tracing || widget.locked || _finished) return;
    final next = g.advance(_stroke, _s, p);
    if (next <= _s) return;
    setState(() => _s = next);
    widget.onProgress?.call();
    if (_s >= g.length(_stroke) - g.tolerance * 0.5) {
      _s = g.length(_stroke);
      if (_stroke < _strokes.length - 1) {
        setState(() {
          _stroke += 1;
          _s = 0;
          _tracing = false;
        });
        widget.onStrokeDone?.call();
      } else {
        setState(() => _finished = true);
        widget.onDone();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final g = _TraceGeometry(box.biggest, _strokes, widget.numeral);
        _geo = g;
        final fireflyAt = _demo.isAnimating
            ? g.pointAt(_stroke, _demo.value * g.length(_stroke))
            : g.pointAt(_stroke, _s);
        final fly = g.tolerance * 1.5;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Where the finger went down, not where the drag won the gesture
          // arena 36 pixels later: a quick swipe that starts on the green dot
          // was otherwise judged to have started somewhere else.
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (d) => _down(d.localPosition),
          onPanUpdate: (d) => _move(d.localPosition),
          onPanEnd: (_) => _tracing = false,
          onTapDown: (d) => _down(d.localPosition),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TracePainter(
                    geo: g,
                    stroke: _stroke,
                    progress: _s,
                    finished: _finished,
                    guideOpacity: widget.guideOpacity,
                    demo: _demo.isAnimating ? _demo.value : null,
                    pulse: widget.ringStart ? _pulse : null,
                  ),
                ),
              ),
              if (!_finished)
                AnimatedPositioned(
                  duration: _demo.isAnimating
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  left: fireflyAt.dx - fly / 2 + g.tolerance * 0.6,
                  top: fireflyAt.dy - fly / 2 - g.tolerance * 0.9,
                  width: fly,
                  height: fly,
                  child: IgnorePointer(
                    child: Image.asset(
                      AssetPaths.countingParadeFireflySprite,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Where a point of [numeral]'s strokes (in the strokes' own 0..1 box) is
/// drawn inside a tracer of [size]. Public so the tests trace the numeral the
/// tracer draws rather than a copy of the arithmetic.
Offset numeralPointIn(Size size, int numeral, Offset p) {
  final aspect = numeralAspect(numeral);
  final h = math.min(size.height * 0.9, size.width / aspect * 0.9);
  final w = h * aspect;
  final origin = Offset((size.width - w) / 2, (size.height - h) / 2);
  return origin + Offset(p.dx * w, p.dy * h);
}

class _TraceGeometry {
  _TraceGeometry(Size size, List<Stroke> strokes, int numeral) {
    final aspect = numeralAspect(numeral);
    final h = math.min(size.height * 0.9, size.width / aspect * 0.9);
    tolerance = math.max(34, h * 0.1);
    thickness = math.max(26, h * 0.085);
    for (final s in strokes) {
      final pts = <Offset>[
        for (final p in s) numeralPointIn(size, numeral, p),
      ];
      final cum = <double>[0];
      for (var i = 1; i < pts.length; i++) {
        cum.add(cum.last + (pts[i] - pts[i - 1]).distance);
      }
      points.add(pts);
      cumulative.add(cum);
    }
  }

  final List<List<Offset>> points = <List<Offset>>[];
  final List<List<double>> cumulative = <List<double>>[];
  late final double tolerance;
  late final double thickness;

  double length(int stroke) => cumulative[stroke].last;

  Offset pointAt(int stroke, double s) {
    final pts = points[stroke];
    final cum = cumulative[stroke];
    if (s <= 0) return pts.first;
    for (var i = 1; i < pts.length; i++) {
      if (cum[i] >= s) {
        final seg = cum[i] - cum[i - 1];
        final t = seg == 0 ? 0.0 : (s - cum[i - 1]) / seg;
        return Offset.lerp(pts[i - 1], pts[i], t)!;
      }
    }
    return pts.last;
  }

  /// How far along [stroke] her finger at [p] has carried the ink, starting
  /// from [s]. Only looks a short way ahead: a finger that jumps to the far
  /// end of a stroke has not traced the middle of it.
  double advance(int stroke, double s, Offset p) {
    final pts = points[stroke];
    final cum = cumulative[stroke];
    // Far enough for a fast, confident swipe - a touchscreen reports a finger
    // every few milliseconds, so even a quick stroke arrives as steps well
    // under this - and not so far that a tap at the far end of a stroke
    // counts as having traced it.
    final lookahead = s + tolerance * 3.5;
    var best = s;
    var bestD = double.infinity;
    for (var i = 1; i < pts.length; i++) {
      if (cum[i] < s - 1) continue;
      if (cum[i - 1] > lookahead) break;
      final a = pts[i - 1];
      final b = pts[i];
      final ab = b - a;
      final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
      final t = len2 == 0
          ? 0.0
          : (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
      final q = a + ab * t;
      final d = (p - q).distance;
      final along = cum[i - 1] + (cum[i] - cum[i - 1]) * t;
      if (along < s - 1 || along > lookahead) continue;
      if (d < bestD) {
        bestD = d;
        best = along;
      }
    }
    return bestD <= tolerance ? math.max(s, best) : s;
  }

  Path pathOf(int stroke, {double upTo = double.infinity}) {
    final pts = points[stroke];
    final cum = cumulative[stroke];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      if (cum[i] <= upTo) {
        path.lineTo(pts[i].dx, pts[i].dy);
      } else {
        final end = pointAt(stroke, upTo);
        path.lineTo(end.dx, end.dy);
        break;
      }
    }
    return path;
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.geo,
    required this.stroke,
    required this.progress,
    required this.finished,
    required this.guideOpacity,
    required this.demo,
    required this.pulse,
  }) : super(repaint: pulse);

  final _TraceGeometry geo;
  final int stroke;
  final double progress;
  final bool finished;
  final double guideOpacity;
  final double? demo;
  final Animation<double>? pulse;

  static const Color _ink = Color(0xFFFFB300);
  static const Color _road = Color(0xFF8A6A48);

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = geo.thickness
      ..color = _road.withValues(alpha: 0.22 * guideOpacity);
    final centre = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = _road.withValues(alpha: 0.55 * guideOpacity);
    for (var i = 0; i < geo.points.length; i++) {
      final p = geo.pathOf(i);
      canvas.drawPath(p, road);
      _dashed(canvas, p, centre);
    }

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = geo.thickness * 1.25
      ..color = _ink.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = geo.thickness * 0.8
      ..color = _ink;
    for (var i = 0; i < geo.points.length; i++) {
      final done = finished || i < stroke;
      if (!done && i != stroke) continue;
      final p = done ? geo.pathOf(i) : geo.pathOf(i, upTo: progress);
      if (!done && progress <= 0) continue;
      canvas
        ..drawPath(p, glow)
        ..drawPath(p, ink);
    }

    if (demo != null) {
      final ghost = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = geo.thickness * 0.5
        ..color = const Color(0xFF7CE0A0).withValues(alpha: 0.75);
      canvas.drawPath(
        geo.pathOf(stroke, upTo: demo! * geo.length(stroke)),
        ghost,
      );
    }

    if (finished) return;
    // Where the pen goes down, and which way it goes.
    final start = geo.pointAt(stroke, progress);
    final r = geo.tolerance * 0.5 * (1 + 0.18 * (pulse?.value ?? 0));
    canvas
      ..drawCircle(
        start,
        r + 5,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      )
      ..drawCircle(start, r, Paint()..color = const Color(0xFF43C06B));
    if (progress <= 0) {
      final ahead = geo.pointAt(stroke, geo.tolerance * 1.6);
      final dir = ahead - start;
      if (dir.distance > 0) {
        final u = dir / dir.distance;
        final n = Offset(-u.dy, u.dx);
        final tip = start + u * (r + 34);
        final base = start + u * (r + 12);
        canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(base.dx + n.dx * 14, base.dy + n.dy * 14)
            ..lineTo(base.dx - n.dx * 14, base.dy - n.dy * 14)
            ..close(),
          Paint()..color = const Color(0xFF2E9A52),
        );
      }
    }
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final dash = metric.extractPath(d, math.min(d + 8, metric.length));
        canvas.drawPath(dash, paint);
        d += 18;
      }
    }
  }

  @override
  bool shouldRepaint(_TracePainter old) => true;
}
