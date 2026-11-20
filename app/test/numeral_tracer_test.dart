// Can every numeral be written, and only the right way round?
//
// The tracer is the whole of Scribe's Tower, and the two ways it can fail are
// both invisible in a screenshot: a numeral whose path a real finger cannot
// finish (a curve sampled too coarsely, a stroke whose end the completion
// test never reaches), and a tracer that accepts a stroke drawn backwards,
// which would teach her to draw a picture of a number instead of writing one.
//
// Each test drives a finger along the tracer's own path - through
// `numeralPointIn`, the function the tracer draws with - rather than along a
// restatement of the strokes, so the test and the widget cannot disagree.

import 'package:critmath/data/scribes_tower_words.dart';
import 'package:critmath/engines/mastery/round_outcome.dart';
import 'package:critmath/ui/widgets/numeral_strokes.dart';
import 'package:critmath/ui/widgets/numeral_tracer.dart';
import 'package:critmath/ui/widgets/sanctuary_round_shell.dart';
import 'package:critmath/ui/widgets/scribes_tower_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _box = Size(560, 520);

Future<void> _mount(
  WidgetTester tester,
  int n, {
  required VoidCallback onDone,
  VoidCallback? onStroke,
}) async {
  tester.view.physicalSize = const Size(800, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(
            size: _box,
            child: NumeralTracer(
              numeral: n,
              onDone: onDone,
              onStrokeDone: onStroke,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Drag a finger along [stroke], with a slight wobble either side of the
/// line, because a five-year-old does not trace a perfect line.
Future<void> _trace(
  WidgetTester tester,
  int n,
  Stroke stroke, {
  bool reversed = false,
  double wobble = 12,
}) async {
  final origin = tester.getTopLeft(find.byType(NumeralTracer));
  final pts = reversed ? stroke.reversed.toList() : stroke;
  Offset at(Offset p) => origin + numeralPointIn(_box, n, p);
  final g = await tester.startGesture(at(pts.first));
  // Sampled every ~16 pixels, the way a touchscreen reports a moving finger.
  var step = 0;
  for (var i = 1; i < pts.length; i++) {
    final a = at(pts[i - 1]);
    final b = at(pts[i]);
    final n = ((b - a).distance / 16).ceil().clamp(1, 1000);
    for (var k = 1; k <= n; k++) {
      final side = (step++ % 8 < 4) ? wobble : -wobble;
      await g
          .moveTo(Offset.lerp(a, b, k / n)! + Offset(side * 0.7, side * 0.7));
    }
    await tester.pump(const Duration(milliseconds: 8));
  }
  await g.up();
  await tester.pump();
}

void main() {
  group('every numeral', () {
    for (var n = 0; n <= 10; n++) {
      testWidgets('$n can be written by following its path', (tester) async {
        var done = false;
        var strokes = 0;
        await _mount(
          tester,
          n,
          onDone: () => done = true,
          onStroke: () => strokes++,
        );
        final all = numeralStrokes(n);
        for (final s in all) {
          expect(done, isFalse, reason: 'finished before the last stroke');
          await _trace(tester, n, s);
        }
        expect(done, isTrue, reason: '$n could not be finished');
        expect(strokes, all.length - 1);
      });
    }
  });

  group('direction counts', () {
    for (final n in <int>[1, 2, 3, 5, 7, 9]) {
      testWidgets('$n traced backwards does not count', (tester) async {
        var done = false;
        await _mount(tester, n, onDone: () => done = true);
        for (final s in numeralStrokes(n)) {
          await _trace(tester, n, s, reversed: true);
        }
        expect(
          done,
          isFalse,
          reason: 'accepted $n written backwards - that is drawing a picture '
              'of a number, not writing it',
        );
      });
    }
  });

  testWidgets('a finger that jumps to the end has not traced the middle',
      (tester) async {
    var done = false;
    await _mount(tester, 7, onDone: () => done = true);
    final s = numeralStrokes(7).single;
    final origin = tester.getTopLeft(find.byType(NumeralTracer));
    final g =
        await tester.startGesture(origin + numeralPointIn(_box, 7, s.first));
    await g.moveTo(origin + numeralPointIn(_box, 7, s.last));
    await tester.pump();
    await g.up();
    expect(done, isFalse);
  });

  testWidgets('a fast, confident swipe from the dot counts', (tester) async {
    // The pan used to report its start where it won the gesture arena - past
    // the drag slop - rather than where the finger went down, so a quick
    // swipe that began on the green dot was judged to have begun somewhere
    // else, and nothing was drawn.
    var done = false;
    await _mount(tester, 1, onDone: () => done = true);
    final s = numeralStrokes(1).single;
    final origin = tester.getTopLeft(find.byType(NumeralTracer));
    final a = origin + numeralPointIn(_box, 1, s.first);
    final b = origin + numeralPointIn(_box, 1, s.last);
    final g = await tester.startGesture(a);
    for (var k = 1; k <= 6; k++) {
      await g.moveTo(Offset.lerp(a, b, k / 6)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('lifting the finger keeps the ink', (tester) async {
    var done = false;
    await _mount(tester, 1, onDone: () => done = true);
    final s = numeralStrokes(1).single;
    final mid = Offset.lerp(s.first, s.last, 0.5)!;
    await _trace(tester, 1, <Offset>[s.first, mid]);
    expect(done, isFalse);
    await _trace(tester, 1, <Offset>[mid, s.last]);
    expect(done, isTrue, reason: 'picking up where she left off must work');
  });

  group('count, then write', () {
    // The rounds are seeded by the session, so the ten-firefly round only
    // turns up some days. It laid out wider than the screen the first time it
    // was built; every count gets laid out here instead of waiting for it.
    for (var n = 1; n <= 10; n++) {
      testWidgets('$n fireflies fit on the screen', (tester) async {
        tester.view.physicalSize = const Size(1180, 820);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 980,
                  height: 560,
                  child: ScribeRoundBody(
                    round: ScribeRound(ScribeTask.writeFromCue, n),
                    c: RoundContext(
                      index: 0,
                      count: 1,
                      locked: false,
                      showDemo: false,
                      say: (_, {replay = true, queue = false}) {},
                      finish: (RoundResult _) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 30));
      });
    }
  });
}
