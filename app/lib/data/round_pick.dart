// Choosing a visit's rounds from a pool.
//
// The first thing the child said about this game, before any of the Sanctuary
// was built, was that it got repetitive; the counting parade's fixed lists
// were the first thing fixed. Five of the seven places added on 2026-09-24
// then shipped with fixed lists of their own - the same four stories, in the
// same order, with the same animals, on every visit - and a place she goes
// back to for its creature cards is a place she will see many times.
//
// So each of them authors a pool, a few rounds bigger than a visit, and a
// visit picks from it. Authored rather than generated because every sentence
// a round can say has to be in the recording script, which walks the pool;
// a generator would put lines in front of her that no voice has read.
//
// Pure Dart and deterministic in the seed, so a visit is the same visit
// every time it is rebuilt, and a test can name the rounds it will get.

import 'dart:math' as math;

/// [count] rounds from [pool], chosen and ordered by [seed].
///
/// The gentlest of the chosen rounds (the lowest [ease]) goes first, because
/// the first round of a visit is also the one the "watch me" plays on, and
/// the rest keep the shuffled order - which is what keeps a visit from being
/// a ramp that only goes up, the same reason the parade planner zig-zags.
List<T> pickRounds<T>(
  List<T> pool, {
  required int count,
  required int seed,
  required num Function(T round) ease,
}) {
  final rng = math.Random(seed);
  final picked = (List<T>.of(pool)..shuffle(rng)).take(count).toList();
  if (picked.isEmpty) return picked;
  var first = 0;
  for (var i = 1; i < picked.length; i++) {
    if (ease(picked[i]) < ease(picked[first])) first = i;
  }
  return <T>[picked.removeAt(first), ...picked];
}

/// A seed that differs between sub-modes of one visit, so two sub-modes that
/// share a pool shape do not pick in lockstep.
int roundSeed(Object session, String subMode) =>
    Object.hash(session, subMode) & 0x7fffffff;
