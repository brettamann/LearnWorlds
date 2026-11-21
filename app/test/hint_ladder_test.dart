// HintLadder — the escalating idle-help that a stuck kid gets.
//
// Before this existed there was no math hint anywhere in the game: a child who
// didn't know the answer could sit in front of a round indefinitely with
// nothing happening at all. These tests pin the timings and, importantly, that
// any input resets the whole ladder.

import 'package:critmath/engines/scaffolding/hint_ladder.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HintLadder', () {
    test('climbs highlight → point → demonstrate at the thresholds', () {
      fakeAsync((async) {
        final seen = <HintLevel>[];
        HintLadder(onLevel: seen.add).start();

        async.elapse(const Duration(seconds: 4));
        expect(seen, isEmpty, reason: 'still inside the 5s think-time');

        async.elapse(const Duration(seconds: 2));
        expect(seen, <HintLevel>[HintLevel.highlight]);

        async.elapse(const Duration(seconds: 5));
        expect(seen, <HintLevel>[HintLevel.highlight, HintLevel.point]);

        async.elapse(const Duration(seconds: 5));
        expect(seen, <HintLevel>[
          HintLevel.highlight,
          HintLevel.point,
          HintLevel.demonstrate,
        ]);
      });
    });

    test('stops climbing at the top rung', () {
      fakeAsync((async) {
        final seen = <HintLevel>[];
        HintLadder(onLevel: seen.add).start();
        async.elapse(const Duration(minutes: 2));
        expect(seen.where((l) => l == HintLevel.demonstrate).length, 1);
      });
    });

    test('poke() before a threshold resets the clock', () {
      fakeAsync((async) {
        final seen = <HintLevel>[];
        final ladder = HintLadder(onLevel: seen.add)..start();

        async.elapse(const Duration(seconds: 4));
        ladder.poke();
        async.elapse(const Duration(seconds: 4));
        expect(seen, isEmpty, reason: 'the tap restarted the 5s window');

        async.elapse(const Duration(seconds: 2));
        expect(seen, <HintLevel>[HintLevel.highlight]);
      });
    });

    test('poke() mid-ladder drops back to rung zero', () {
      fakeAsync((async) {
        final seen = <HintLevel>[];
        final ladder = HintLadder(onLevel: seen.add)..start();

        async.elapse(const Duration(seconds: 11));
        expect(seen, <HintLevel>[HintLevel.highlight, HintLevel.point]);

        ladder.poke();
        async.elapse(const Duration(seconds: 6));
        // Starts over from highlight rather than resuming at demonstrate.
        expect(seen.last, HintLevel.highlight);
      });
    });

    test('hintsUsed counts demonstrations only', () {
      fakeAsync((async) {
        // A round that merely glowed or pointed still resolves as a clean
        // success; only doing one FOR her makes it a soft pass.
        final ladder = HintLadder(onLevel: (_) {})..start();
        async.elapse(const Duration(seconds: 11));
        expect(ladder.hintsUsed, 0);

        async.elapse(const Duration(seconds: 5));
        expect(ladder.hintsUsed, 1);
      });
    });

    test('pause() stops the climb but keeps hintsUsed', () {
      fakeAsync((async) {
        final seen = <HintLevel>[];
        final ladder = HintLadder(onLevel: seen.add)..start();
        async.elapse(const Duration(seconds: 16));
        expect(ladder.hintsUsed, 1);

        ladder.pause();
        async.elapse(const Duration(minutes: 1));
        expect(seen.length, 3, reason: 'nothing fires while paused');
        expect(ladder.hintsUsed, 1);
      });
    });

    test('honours authored thresholds', () {
      fakeAsync((async) {
        final seen = <HintLevel>[];
        HintLadder(
          onLevel: seen.add,
          thresholds: HintThresholds.fromJson(const <String, dynamic>{
            'highlightNextSec': 2,
            'narratorReminderSec': 4,
            'demonstrateSec': 6,
          }),
        ).start();

        async.elapse(const Duration(seconds: 2));
        expect(seen, <HintLevel>[HintLevel.highlight]);
        async.elapse(const Duration(seconds: 4));
        expect(seen.last, HintLevel.demonstrate);
      });
    });

    test('dispose() cancels a pending rung', () {
      fakeAsync((async) {
        final seen = <HintLevel>[];
        HintLadder(onLevel: seen.add)
          ..start()
          ..dispose();
        async.elapse(const Duration(seconds: 30));
        expect(seen, isEmpty);
      });
    });
  });
}
