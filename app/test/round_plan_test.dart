// ParadeRoundPlanner — determinism, JSON overrides, and the distractor rules.
//
// The determinism tests matter more than they look: the planner shuffles so
// that a replay isn't identical, and the only thing keeping that testable (and
// keeping a mid-round rebuild from reshuffling under the kid) is the seed.

import 'package:critmath/engines/activity_runner/round_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const planner = ParadeRoundPlanner();

  group('ParadeRoundParameters.fromJson', () {
    test('null JSON yields playable defaults', () {
      final p = ParadeRoundParameters.fromJson(null);
      expect(p.counts, kDefaultParadeCounts);
      expect(p.roundCount, 5);
      expect(p.speciesPool, isNotEmpty);
      expect(p.distractors, isTrue);
    });

    test('explicit counts win over the default curve', () {
      final p = ParadeRoundParameters.fromJson(<String, dynamic>{
        'counts': <int>[4, 4, 9],
      });
      expect(p.counts, <int>[4, 4, 9]);
      expect(p.roundCount, 3);
    });

    test('legacy targetCount becomes the opening count', () {
      // The K.CC.4a lesson was authored before `counts` existed and pins a
      // single first-round target; honouring it keeps that content working.
      final p = ParadeRoundParameters.fromJson(<String, dynamic>{
        'targetCount': 6,
      });
      expect(p.counts.first, 6);
      expect(p.counts.length, kDefaultParadeCounts.length);
    });

    test('a named species leads the pool', () {
      final p = ParadeRoundParameters.fromJson(<String, dynamic>{
        'species': 'dragon',
      });
      expect(p.speciesPool.first, 'dragon');
      expect(p.speciesPool, contains('fawn'));
    });

    test('reads the authored hintThresholds spelling', () {
      final p = ParadeRoundParameters.fromJson(<String, dynamic>{
        'hintThresholds': <String, dynamic>{
          'highlightNextSec': 4,
          'narratorReminderSec': 9,
        },
      });
      expect(p.hints.highlightSec, 4);
      expect(p.hints.pointSec, 9);
    });
  });

  group('plan', () {
    test('same seed yields the same species order', () {
      final a = planner.plan(seed: 42);
      final b = planner.plan(seed: 42);
      expect(
        a.map((r) => r.species.id).toList(),
        b.map((r) => r.species.id).toList(),
      );
    });

    test('different seeds vary the order', () {
      // Guards the actual anti-repetition property. Scanning a range rather
      // than asserting one pair keeps this from being flaky on an unlucky
      // shuffle that happens to match.
      final base = planner.plan(seed: 1).map((r) => r.species.id).toList();
      final anyDifferent = List<int>.generate(20, (i) => i + 2).any((seed) {
        final other = planner
            .plan(seed: seed)
            .map((r) => r.species.id)
            .toList();
        return other.toString() != base.toString();
      });
      expect(anyDifferent, isTrue);
    });

    test('the lead species is never shuffled away', () {
      // A lesson that taught fawns must hand off to a round of fawns.
      final params = ParadeRoundParameters.fromJson(<String, dynamic>{
        'species': 'phoenix',
      });
      for (var seed = 0; seed < 10; seed++) {
        expect(
          planner.plan(params: params, seed: seed).first.species.id,
          'phoenix',
        );
      }
    });

    test('counts follow the authored curve', () {
      final rounds = planner.plan(seed: 3);
      expect(rounds.map((r) => r.targetCount).toList(), kDefaultParadeCounts);
    });

    test('a 3-streak quietly raises the counts', () {
      // Invisible escalation per adaptive-scaffolding.md — no message, the
      // groups just get a little bigger.
      final rounds = planner.plan(seed: 3, streak: 3);
      expect(rounds.first.targetCount, kDefaultParadeCounts.first + 2);
      expect(rounds.every((r) => r.targetCount <= kMaxParadeCount), isTrue);
    });

    test('counts never fall below the floor', () {
      final rounds = planner.plan(seed: 3, streak: -1);
      expect(rounds.every((r) => r.targetCount >= kMinParadeCount), isTrue);
    });
  });

  group('cells and distractors', () {
    test('creature cells match the target count', () {
      for (final round in planner.plan(seed: 7)) {
        final creatures = round.cells.where((c) => c.isCreature).length;
        expect(creatures, round.targetCount);
      }
    });

    test('creature indices are 0..n-1 in order', () {
      // The runner keys taps off creatureIndex, so a gap here would make a
      // creature untappable.
      for (final round in planner.plan(seed: 7)) {
        final indices = round.cells
            .where((c) => c.isCreature)
            .map((c) => c.creatureIndex)
            .toList();
        expect(indices, List<int>.generate(round.targetCount, (i) => i));
      }
    });

    test('round 1 has no distractors', () {
      // A kid meeting the activity should get one clean success before
      // anything can go wrong.
      final first = planner.plan(seed: 7).first;
      expect(first.cells.where((c) => !c.isCreature), isEmpty);
    });

    test('later rounds do have distractors', () {
      final rounds = planner.plan(seed: 7);
      final decorLater = rounds
          .skip(1)
          .expand((r) => r.cells)
          .where((c) => !c.isCreature);
      expect(decorLater, isNotEmpty);
    });

    test('a distractor is never the first thing on screen', () {
      // The eye lands leftmost; opening on a wrong-answer target is a trap.
      for (var seed = 0; seed < 25; seed++) {
        for (final round in planner.plan(seed: seed)) {
          expect(round.cells.first.isCreature, isTrue);
        }
      }
    });

    test('distractors: false makes the round unfailable', () {
      final params = ParadeRoundParameters.fromJson(<String, dynamic>{
        'distractors': false,
      });
      final rounds = planner.plan(params: params, seed: 7);
      expect(
        rounds.expand((r) => r.cells).where((c) => !c.isCreature),
        isEmpty,
      );
    });
  });
}
