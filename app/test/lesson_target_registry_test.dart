// Whether her touch counted, and what happens when nobody knows.
//
// The We-Try asks a question and then has to decide which of two authored
// lines to answer with. It decides by asking this registry whether the touch
// landed on the thing the stage lit up. Most of the interesting behaviour is
// in the "nobody knows" case: eleven of the twenty-two lessons introduce
// activities that have no runner yet, so their stages draw a generic scene and
// register nothing, and several gates in the lessons that *do* have runners
// name a gesture rather than a target ("drag-fish-to-pad") because their own
// passCondition says any drag passes.
//
// In all of those, the honest answer to "did she hit it" is yes. A screen that
// never showed her a target cannot then tell her she missed it - and it would,
// silently and in the warmest possible voice, every single time.

import 'package:critmath/ui/lesson/lesson_target_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mounts boxes at known places and hands back the registry that knows them.
Future<LessonTargetRegistry> stage(
  WidgetTester tester,
  Map<String, Rect> boxes,
) async {
  final registry = LessonTargetRegistry();
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(800, 600)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            for (final entry in boxes.entries)
              Positioned.fromRect(
                rect: entry.value,
                child: SizedBox(key: registry.keyFor(entry.key)),
              ),
          ],
        ),
      ),
    ),
  );
  return registry;
}

void main() {
  testWidgets('a touch on the target counts', (tester) async {
    final registry = await stage(tester, {
      'fawn-1': const Rect.fromLTWH(100, 100, 80, 80),
    });
    expect(registry.hits(['fawn-1'], const Offset(140, 140)), isTrue);
  });

  testWidgets('and a touch well away from it does not', (tester) async {
    final registry = await stage(tester, {
      'fawn-1': const Rect.fromLTWH(100, 100, 80, 80),
    });
    expect(registry.hits(['fawn-1'], const Offset(600, 500)), isFalse);
  });

  testWidgets('a near miss counts, because the finger is five', (tester) async {
    // Sprites are drawn at their natural size and a five-year-old aims at the
    // middle of what she can see. A touch a few pixels off a fawn's flank is a
    // touch on the fawn, and calling it a miss teaches her the opposite of
    // what the round is about.
    final registry = await stage(tester, {
      'fawn-1': const Rect.fromLTWH(100, 100, 80, 80),
    });
    expect(registry.hits(['fawn-1'], const Offset(92, 140)), isTrue);
    expect(registry.hits(['fawn-1'], const Offset(188, 140)), isTrue);
  });

  testWidgets('any one of several named targets counts', (tester) async {
    // "Any vertex acceptable" - the habitat gates deliberately refuse to fix
    // an order.
    final registry = await stage(tester, {
      'vertex-1': const Rect.fromLTWH(0, 0, 40, 40),
      'vertex-2': const Rect.fromLTWH(300, 300, 40, 40),
    });
    expect(
      registry.hits(['vertex-1', 'vertex-2'], const Offset(320, 320)),
      isTrue,
    );
  });

  testWidgets('a target nothing drew is a target she cannot miss', (
    tester,
  ) async {
    // The load-bearing one, and the one no widget test caught: flipping this
    // answer turns every gate on an unregistered target into a permanent,
    // silent miss - she would be corrected every time, in a phase whose own
    // content says there is nothing to correct.
    final registry = await stage(tester, {
      'fawn-1': const Rect.fromLTWH(100, 100, 80, 80),
    });
    expect(
      registry.hits(['pond-3'], const Offset(600, 500)),
      isTrue,
      reason: 'the screen never showed it, so it cannot have been missed',
    );
    expect(
      registry.hits(const <String>[], const Offset(600, 500)),
      isTrue,
      reason: 'a gate naming no target accepts any touch, as authored',
    );
  });

  testWidgets('but one real target among unknowns is still judged', (
    tester,
  ) async {
    // Mixed lists must not be waved through on the strength of the unknown
    // half, or a named target stops meaning anything the moment a lesson adds
    // a second id the stage does not draw.
    final registry = await stage(tester, {
      'fawn-1': const Rect.fromLTWH(100, 100, 80, 80),
    });
    expect(
      registry.hits(['fawn-1', 'pond-3'], const Offset(600, 500)),
      isFalse,
    );
  });

  testWidgets('a key that was never mounted has no rect', (tester) async {
    final registry = await stage(tester, const <String, Rect>{});
    expect(registry.rectOf('nothing'), isNull);
  });

  testWidgets('and the same id keeps the same key across rebuilds', (
    tester,
  ) async {
    // A fresh GlobalKey per frame would detach and re-attach every target on
    // every tick, and lose the rect at exactly the moment of a tap.
    final registry = LessonTargetRegistry();
    expect(
      identical(registry.keyFor('fawn-1'), registry.keyFor('fawn-1')),
      isTrue,
    );
  });
}
