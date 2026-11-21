// WeTryRunner on its own clock: a gate always resolves, her touch is never
// graded with the miss sound, and the phase hands off when it runs out.

import 'package:critmath/models/lesson_runtime.dart';
import 'package:critmath/models/we_try_script.dart';
import 'package:critmath/ui/lesson/lesson_scene.dart';
import 'package:critmath/ui/lesson/we_try_runner.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

WeTryPhase _phase({bool autoCompletes = false}) => WeTryPhase(
  durationSec: 20,
  narrationByCueId: const {},
  initialGlowTarget: null,
  landmarkIds: const [],
  creatureCount: 3,
  framePrebuilt: false,
  showsRoof: false,
  script: WeTryScript(
    hesitation: WeTryHesitation(
      after: const Duration(seconds: 5),
      autoCompletes: autoCompletes,
    ),
    beats: const <WeTryBeat>[
      WeTrySay(
        cueId: 'ask',
        text: 'Touch the first fawn.',
        delay: Duration.zero,
        when: WeTryWhen.always,
      ),
      WeTryGate(
        targets: ['fawn-0'],
        passText: 'Yes, that one!',
        failText: 'This one is first.',
        delay: Duration.zero,
        when: WeTryWhen.always,
      ),
      WeTrySay(
        cueId: 'after-pass',
        text: 'One.',
        delay: Duration.zero,
        when: WeTryWhen.onPass,
      ),
      WeTrySay(
        cueId: 'after-fail',
        text: 'Watch me.',
        delay: Duration.zero,
        when: WeTryWhen.onFail,
      ),
    ],
  ),
);

class _Harness {
  _Harness({bool autoCompletes = false, bool hit = true}) {
    runner = WeTryRunner(
      phase: _phase(autoCompletes: autoCompletes),
      scene: scene,
      say: (text, _) => said.add(text),
      chime: () => chimes++,
      pop: () => pops++,
      hits: (_, __) => hit,
      onFinished: () => finished = true,
    );
  }

  final scene = LessonScene();
  late final WeTryRunner runner;
  final said = <String>[];
  var chimes = 0;
  var pops = 0;
  var finished = false;
}

void main() {
  test('her touch on the target passes, pops, and the pass line follows', () {
    fakeAsync((clock) {
      final h = _Harness();
      h.runner.start();
      clock.elapse(const Duration(seconds: 3));
      expect(h.runner.waiting, isTrue);
      expect(h.scene.haloed, {'fawn-0'});

      h.runner.touch(Offset.zero);
      expect(h.runner.waiting, isFalse);
      expect(h.pops, 1);
      expect(h.scene.sparkled, {'fawn-0'});
      clock.elapse(const Duration(seconds: 10));
      expect(h.said, ['Touch the first fawn.', 'Yes, that one!', 'One.']);
      expect(h.finished, isTrue);
    });
  });

  test(
    'a touch elsewhere gets the corrective line, still not the miss sound',
    () {
      fakeAsync((clock) {
        final h = _Harness(hit: false);
        h.runner.start();
        clock.elapse(const Duration(seconds: 3));
        h.runner.touch(Offset.zero);
        clock.elapse(const Duration(seconds: 10));
        expect(h.pops, 1);
        expect(h.said, contains('This one is first.'));
        expect(h.said, contains('Watch me.'));
        expect(h.said, isNot(contains('One.')));
      });
    },
  );

  test('a child who does nothing gets urgency, then a nudge, then her turn '
      'completes itself', () {
    fakeAsync((clock) {
      final h = _Harness(autoCompletes: true);
      h.runner.start();
      clock.elapse(const Duration(seconds: 3));
      expect(h.runner.waiting, isTrue);

      clock.elapse(const Duration(seconds: 5));
      expect(h.runner.urgent, isTrue);
      expect(h.chimes, 0);

      clock.elapse(const Duration(seconds: 5));
      expect(h.chimes, 1, reason: 'the nudge at twice the threshold');

      clock.elapse(const Duration(seconds: 5));
      expect(h.runner.waiting, isFalse, reason: 'rescued at three times');
      expect(h.pops, 0, reason: 'she did not touch anything');

      clock.elapse(const Duration(seconds: 10));
      expect(h.finished, isTrue);
    });
  });

  test('disposing stops every timer', () {
    fakeAsync((clock) {
      final h = _Harness(autoCompletes: true);
      h.runner.start();
      clock.elapse(const Duration(seconds: 3));
      h.runner.dispose();
      clock.elapse(const Duration(minutes: 1));
      expect(h.finished, isFalse);
      expect(h.chimes, 0);
      expect(clock.pendingTimers, isEmpty);
    });
  });
}
