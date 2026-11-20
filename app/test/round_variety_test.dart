// A place she goes back to is not the same place every time.
//
// Five of the seven Sanctuary places added on 2026-09-24 played a fixed list:
// the same four stories with the same animals in the same order, on every
// visit, and repetition is the first thing this game was ever criticised for
// by the person it is for. Each now picks a visit from a pool (see
// round_pick.dart). These check that the pick varies, that it holds still
// within a visit, and that it keeps each place's shape - the rules that made
// the fixed lists the way they were.

import 'package:critmath/data/care_pantry_words.dart';
import 'package:critmath/data/caretakers_bench_words.dart';
import 'package:critmath/data/picnic_baskets_words.dart';
import 'package:critmath/data/round_pick.dart';
import 'package:critmath/data/storytellers_pond_words.dart';
import 'package:critmath/data/ten_frame_words.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every place's visit, as something comparable, keyed by activity/sub-mode.
final Map<String, List<Object> Function(int seed)> _visits =
    <String, List<Object> Function(int seed)>{
  for (final m in kStories.keys)
    'storytellers-pond/$m': (seed) => <Object>[
          for (final s in storiesFor(m, seed: seed))
            '${s.kind}${s.creature.singular}${s.a}${s.b}${s.c}',
        ],
  for (final m in kPondRounds.keys)
    'ten-frame-pond/$m': (seed) => <Object>[
          for (final r in pondRoundsFor(m, seed: seed))
            '${r.target}/${r.preset}/${r.differentWay}',
        ],
  for (final m in kPicnicRounds.keys)
    'picnic-baskets/$m': (seed) => <Object>[
          for (final r in picnicRoundsFor(m, seed: seed))
            '${r.treat.plural}${r.counts}',
        ],
  for (final m in kPantryRounds.keys)
    'care-pantry/$m': (seed) => <Object>[
          for (final r in pantryRoundsFor(m, seed: seed))
            r.crates.map((c) => '${c.name}${c.count}').join(','),
        ],
  for (final m in kBenchRounds.keys)
    'caretakers-bench/$m': (seed) => <Object>[
          for (final r in benchRoundsFor(m, seed: seed))
            '${r.task}${r.things.map((t) => t.name)}'
                '${r.cats.map((c) => c.segments)}',
        ],
};

void main() {
  const seeds = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  for (final entry in _visits.entries) {
    group(entry.key, () {
      test('is the same visit every time it is built', () {
        for (final s in seeds) {
          expect(entry.value(s), entry.value(s));
        }
      });

      test('is not the same visit every day', () {
        final distinct = <String>{
          for (final s in seeds) entry.value(s).join('|'),
        };
        expect(
          distinct.length,
          greaterThan(1),
          reason: 'twelve visits, one sequence of rounds',
        );
      });
    });
  }

  test('a visit is as long as it was when the lists were fixed', () {
    for (final s in seeds) {
      expect(storiesFor(kStorySubAddTo, seed: s), hasLength(4));
      expect(storiesFor(kStorySubTwoStep, seed: s), hasLength(3));
      expect(pondRoundsFor(kTenFrameSubFill, seed: s), hasLength(4));
      expect(pondRoundsFor(kTenFrameSubTwoWays, seed: s), hasLength(4));
      expect(pondRoundsFor(kTenFrameSubChallenge, seed: s), hasLength(3));
      expect(picnicRoundsFor(kPicnicSubMatch, seed: s), hasLength(4));
      expect(picnicRoundsFor(kPicnicSubThree, seed: s), hasLength(3));
      expect(pantryRoundsFor(kPantrySubSimple, seed: s), hasLength(4));
      expect(pantryRoundsFor(kPantrySubFull, seed: s), hasLength(3));
      expect(benchRoundsFor(kBenchSubDescribe, seed: s), hasLength(4));
      expect(benchRoundsFor(kBenchSubOrder, seed: s), hasLength(3));
    }
  });

  test('the first round of a visit is its gentlest', () {
    // It is also the one the "watch me" plays on.
    for (final s in seeds) {
      final stories = storiesFor(kStorySubAddTo, seed: s);
      for (final st in stories.skip(1)) {
        expect(
          stories.first.a + stories.first.b,
          lessThanOrEqualTo(st.a + st.b),
        );
      }
      final pond = pondRoundsFor(kTenFrameSubFill, seed: s);
      for (final r in pond.skip(1)) {
        expect(pond.first.target, lessThanOrEqualTo(r.target));
      }
    }
  });

  test('picnic: exactly one tie a visit, never the first round', () {
    for (final m in <String>[kPicnicSubMatch, kPicnicSubCount]) {
      for (final s in seeds) {
        final rounds = picnicRoundsFor(m, seed: s);
        expect(rounds.where((r) => r.same), hasLength(1), reason: '$m/$s');
        expect(rounds.first.same, isFalse, reason: '$m/$s');
      }
    }
  });

  test('picnic: three diners always have one most and one fewest', () {
    for (final r in kPicnicRounds[kPicnicSubThree]!) {
      final c = r.counts;
      expect(
        c.where((n) => n == c.reduce((a, b) => a > b ? a : b)),
        hasLength(1),
      );
      expect(
        c.where((n) => n == c.reduce((a, b) => a < b ? a : b)),
        hasLength(1),
      );
    }
  });

  test('pond: "a different way" always follows the same number', () {
    for (final s in seeds) {
      final rounds = pondRoundsFor(kTenFrameSubTwoWays, seed: s);
      for (var i = 0; i < rounds.length; i += 2) {
        expect(rounds[i].differentWay, isFalse);
        expect(rounds[i + 1].differentWay, isTrue);
        expect(rounds[i + 1].target, rounds[i].target);
      }
    }
  });

  test('bench: weighing and measuring take turns, weighing first', () {
    for (final m in <String>[kBenchSubDescribe, kBenchSubCompare]) {
      for (final s in seeds) {
        final rounds = benchRoundsFor(m, seed: s);
        for (var i = 0; i < rounds.length; i++) {
          expect(rounds[i].usesThings, i.isEven, reason: '$m/$s round $i');
        }
      }
    }
  });

  test('pantry: no crate is tied for the most or the fewest', () {
    for (final rounds in kPantryRounds.values) {
      for (final r in rounds) {
        final counts = r.crates.map((c) => c.count).toList();
        final most = counts.reduce((a, b) => a > b ? a : b);
        final fewest = counts.reduce((a, b) => a < b ? a : b);
        if (r.askMost) expect(counts.where((n) => n == most), hasLength(1));
        if (r.askFewest) {
          expect(counts.where((n) => n == fewest), hasLength(1));
        }
      }
    }
  });

  test('bench: no two things weigh the same, no two caterpillars match', () {
    for (final rounds in kBenchRounds.values) {
      for (final r in rounds) {
        final w = r.things.map((t) => t.weight).toSet();
        expect(w, hasLength(r.things.length));
        final l = r.cats.map((c) => c.segments).toSet();
        expect(l, hasLength(r.cats.length));
      }
    }
  });

  test('pickRounds takes distinct rounds from the pool', () {
    final pool = List<int>.generate(9, (i) => i);
    for (final s in seeds) {
      final picked = pickRounds(pool, count: 4, seed: s, ease: (n) => n);
      expect(picked.toSet(), hasLength(4));
      expect(picked.first, picked.reduce((a, b) => a < b ? a : b));
    }
  });
}
