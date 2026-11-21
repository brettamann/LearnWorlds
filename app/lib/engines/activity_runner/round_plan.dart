// ParadeRoundPlanner — builds the round list for a Counting Parade sub-mode.
//
// Two problems this solves.
//
// 1. Every playthrough was identical. The rounds lived in a Dart `const` list,
//    so the species, their order, and the counts never varied. A child who
//    replayed the activity got the exact same eight rounds, which is the
//    "it gets repetitive" complaint in its most literal form.
//
// 2. `youDo.roundParameters` was dead data. Lesson JSON has always carried a
//    roundParameters block; LessonScreen parsed it, ActivityScreen routed it,
//    and no runner ever read it. Authored content could not influence a round.
//
// Determinism matters as much as variety: the same (params, seed) always
// yields the same list, so widget tests can assert exact content while play
// still varies session to session. Seed from `sessionIdProvider`.

import 'dart:math' as math;

import '../../data/asset_paths.dart';
import '../../data/parade_species.dart';
import '../scaffolding/hint_ladder.dart';

/// Typed view over `phases.youDo.roundParameters`.
///
/// Every field is optional and defaults to sane behaviour, so a direct tap
/// from the Sanctuary map — no lesson, no params at all — still produces a
/// full round list.
class ParadeRoundParameters {
  const ParadeRoundParameters({
    this.counts = kDefaultParadeCounts,
    this.speciesPool = kAllParadeSpeciesIds,
    this.singleSpecies = true,
    this.arrangement = 'line',
    this.shuffleSpecies = true,
    this.distractors = true,
    this.hints = const HintThresholds(),
  });

  factory ParadeRoundParameters.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ParadeRoundParameters();

    // `counts` is the modern key. `targetCount` is what the K.CC.4a lesson
    // authored originally — a single first-round count — so honour it as the
    // opening count and let the curve continue from there.
    List<int>? counts;
    final rawCounts = json['counts'];
    if (rawCounts is List && rawCounts.isNotEmpty) {
      counts = rawCounts.whereType<num>().map((n) => n.toInt()).toList();
    } else if (json['targetCount'] is num) {
      final first = (json['targetCount'] as num).toInt();
      counts = <int>[first, ...kDefaultParadeCounts.skip(1)];
    }

    final roundCount = (json['roundCount'] as num?)?.toInt();
    if (counts != null && roundCount != null && roundCount > 0) {
      counts = counts.take(roundCount).toList();
    }

    List<String>? pool;
    final rawPool = json['speciesPool'];
    if (rawPool is List && rawPool.isNotEmpty) {
      pool = rawPool.whereType<String>().toList();
    } else if (json['species'] is String) {
      // Single-species lessons name one creature; keep it as the opener and
      // let the rest of the pool follow so later rounds still vary.
      final lead = json['species'] as String;
      pool = <String>[lead, ...kAllParadeSpeciesIds.where((s) => s != lead)];
    }

    return ParadeRoundParameters(
      counts: counts ?? kDefaultParadeCounts,
      speciesPool: pool ?? kAllParadeSpeciesIds,
      singleSpecies: json['singleSpecies'] as bool? ?? true,
      arrangement: json['arrangement'] as String? ?? 'line',
      // Authored lessons pin the opening species on purpose, so a lesson that
      // names one keeps it first; only the remainder gets shuffled.
      shuffleSpecies: json['shuffleSpecies'] as bool? ?? true,
      distractors: json['distractors'] as bool? ?? true,
      hints: HintThresholds.fromJson(
        json['hintThresholds'] as Map<String, dynamic>?,
      ),
    );
  }

  /// One entry per round. Length determines the round count.
  final List<int> counts;
  final List<String> speciesPool;
  final bool singleSpecies;
  final String arrangement;
  final bool shuffleSpecies;

  /// Whether to mix decor into the meadow. Off makes the round unfailable,
  /// which is the right call for a demotion floor.
  final bool distractors;

  final HintThresholds hints;

  int get roundCount => counts.length;
}

/// The default curve: five rounds instead of eight, and deliberately NOT
/// monotonic.
///
/// The old sequence ran 3,4,5,6,7,8,9,10 — 52 taps and a ramp that only ever
/// went up, which reads to a five-year-old as "this is going to keep getting
/// harder forever". Zig-zagging means each round is a fresh shape rather than
/// one more step up a staircase, and 25 taps lands the whole sub-mode inside
/// the ~2.5 minutes a child this age reliably sustains.
///
/// Escalation still happens — it just moves to the session level, driven by
/// the child's streak rather than by position in the list. See
/// [ParadeRoundPlanner.plan].
const List<int> kDefaultParadeCounts = <int>[3, 5, 4, 7, 6];

/// The lowest count a round may drop to. Below three there's nothing to count.
const int kMinParadeCount = 3;

/// The most creatures that fit the meadow layout comfortably.
const int kMaxParadeCount = 10;

/// Meadow decor mixed in among the creatures: butterflies, frogs, a watering
/// can. Tapping one is a wrong answer.
///
/// These exist so the round CAN be failed. Before them the mechanic was
/// unfailable by construction — Done only appeared once every creature was
/// tapped, and double-taps were ignored — so `success: true` was the only
/// possible outcome and the entire mastery ladder was unreachable.
///
/// They are deliberately NOT a second creature species.
/// specs/shared/k-activity-patterns.md requires single species per round at
/// Concrete so the kid attends to cardinality rather than to sorting; a
/// butterfly reads as obviously "not one of the things we're counting", which
/// makes a wrong tap possible without turning counting into classification.
/// Don't "improve" these into a rival species later.
const List<String> kParadeDistractorAssets = <String>[
  'assets/activities/shape-garden/butterfly-decor-yellow.png',
  'assets/activities/shape-garden/butterfly-decor-blue.png',
  'assets/activities/shape-garden/butterfly-decor-pink.png',
  'assets/activities/shape-garden/frog-decor-green.png',
  'assets/activities/shape-garden/frog-decor-teal.png',
  AssetPaths.shapeGardenWateringCan,
];

/// One position in the round's meadow: either a creature to count or a piece
/// of decor to leave alone. Built by the planner so the interleaving is
/// deterministic under a seed and testable.
class ParadeCell {
  const ParadeCell.creature(this.creatureIndex) : decorAsset = null;
  const ParadeCell.decor(this.decorAsset) : creatureIndex = null;

  /// Set for countable creatures; this is the index the tap handler uses.
  final int? creatureIndex;

  /// Set for decor. Tapping this is the wrong answer.
  final String? decorAsset;

  bool get isCreature => creatureIndex != null;
}

class ParadeRound {
  const ParadeRound({
    required this.index,
    required this.targetCount,
    required this.species,
    required this.arrangement,
    required this.cells,
  });

  final int index;
  final int targetCount;
  final ParadeSpecies species;
  final String arrangement;

  /// Creatures and decor, already interleaved in render order.
  final List<ParadeCell> cells;
}

class ParadeRoundPlanner {
  const ParadeRoundPlanner();

  /// Build the round list.
  ///
  /// [seed] makes the shuffle reproducible — same seed, same rounds — so tests
  /// can assert exact content. Pass the session id's hash in production so a
  /// child gets a different order each sitting.
  ///
  /// [streak] applies invisible session-level escalation, per
  /// specs/shared/adaptive-scaffolding.md: a child on a 3-streak gets slightly
  /// bigger groups, and one who has been failing gets slightly smaller ones.
  /// She never sees a "level up" message — the numbers just look a bit
  /// different, which is the whole design intent of that spec.
  List<ParadeRound> plan({
    ParadeRoundParameters params = const ParadeRoundParameters(),
    int seed = 0,
    int streak = 0,
  }) {
    final rng = math.Random(seed);
    final pool = params.speciesPool.isEmpty
        ? kAllParadeSpeciesIds
        : params.speciesPool;

    // The first entry stays put: lessons that name a species expect the round
    // they hand off to to feature it. Everything after it is fair game.
    final ordered = <String>[pool.first];
    final rest = pool.skip(1).toList();
    if (params.shuffleSpecies) rest.shuffle(rng);
    ordered.addAll(rest);

    final bump = streak >= 3 ? 2 : (streak < 0 ? -1 : 0);

    return <ParadeRound>[
      for (var i = 0; i < params.counts.length; i++)
        () {
          final count = (params.counts[i] + bump).clamp(
            kMinParadeCount,
            kMaxParadeCount,
          );
          return ParadeRound(
            index: i,
            targetCount: count,
            // Cycle rather than index directly, so a counts list longer than
            // the species pool still produces a valid round instead of
            // overflowing.
            //
            // One species per round regardless of `singleSpecies`: mixing them
            // is not implemented, and k-activity-patterns.md requires single
            // species at Concrete anyway so the kid attends to cardinality
            // rather than to sorting.
            species: paradeSpeciesById(ordered[i % ordered.length]),
            arrangement: params.arrangement,
            cells: _cells(
              count: count,
              // Round 1 is clean. A child meeting the activity for the first
              // time should get one uncomplicated success before anything can
              // go wrong; decor arrives from round 2 onward.
              decorCount: i == 0 ? 0 : (params.distractors ? 1 + (i % 2) : 0),
              rng: rng,
            ),
          );
        }(),
    ];
  }

  List<ParadeCell> _cells({
    required int count,
    required int decorCount,
    required math.Random rng,
  }) {
    final cells = <ParadeCell>[
      for (var i = 0; i < count; i++) ParadeCell.creature(i),
    ];
    final decor = <String>[...kParadeDistractorAssets]..shuffle(rng);
    for (var d = 0; d < decorCount && d < decor.length; d++) {
      // Never first: the kid's eye lands leftmost, and opening a round on a
      // wrong-answer target is a trap rather than a challenge.
      final at = 1 + rng.nextInt(cells.length);
      cells.insert(at, ParadeCell.decor(decor[d]));
    }
    return cells;
  }
}
