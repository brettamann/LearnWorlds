// RoundCoordinator — the seam between activity UI and the mastery/reward
// engines. The activity calls resolveRound(); the coordinator threads the
// outcome through MasteryEngine, persists the new ConceptState, and pays out
// coins for a success. Stays tiny on purpose so engine logic isn't smeared
// across widgets.

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/creature_card_catalog.dart';
import '../engines/mastery/mastery_engine.dart';
import '../engines/mastery/round_outcome.dart';
import '../providers/collection_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/session_provider.dart';
import '../providers/wallet_provider.dart';

class RoundCoordinator {
  /// [random] is a test seam — override the provider with a seeded Random to
  /// make card drops deterministic.
  RoundCoordinator(this._ref, {math.Random? random})
    : _random = random ?? math.Random();

  /// Chance that a passed round yields a creature card she doesn't have.
  ///
  /// One in four is tuned so a five-round sub-mode usually yields one card and
  /// occasionally yields none — often enough to be a reason to keep playing,
  /// rare enough that the reveal is still an event. The eight-card set then
  /// takes roughly six or seven sittings to fill, which is the span
  /// specs/shared/reward-tracks.md calls "the dry middle of the curriculum".
  static const double kCardDropChance = 0.25;

  final Ref _ref;
  final math.Random _random;
  static const _engine = MasteryEngine();

  void resolveRound({
    required String activityId,
    required String conceptId,
    required RoundResult result,
    String? instanceKey,
  }) {
    final progress = _ref.read(kidProgressProvider.notifier);
    final state = progress.getOrCreate(conceptId, instanceKey: instanceKey);
    final outcome = RoundOutcome(
      conceptId: conceptId,
      instanceKey: instanceKey,
      layer: state.currentLayer,
      result: result,
      sessionId: _ref.read(sessionIdProvider),
      at: DateTime.now(),
    );
    final next = _engine.apply(state, outcome);
    progress.put(next);
    _ref.read(walletProvider.notifier).award(coinsFor(result));
    // A failed round still pays coins but never drops a card: the coin floor
    // exists so the counter never freezes, while a card is a find, and finding
    // something for getting it wrong would make the find mean nothing.
    if (result != RoundResult.failure) _rollForCard(activityId);
  }

  /// Maybe hand out a creature card. Only ever picks from cards she doesn't
  /// already have, so a full set stops rolling entirely rather than showing
  /// her duplicates of things she owns.
  ///
  /// Challenge-sourced cards are never in the pool. Those are granted by the
  /// challenge that earns them, and a rare turning up in an ordinary round
  /// would spend the only reward that makes the challenge worth finishing.
  void _rollForCard(String activityId) {
    final collection = _ref.read(cardCollectionProvider.notifier);
    final pool = kCreatureCards
        .where(
          (c) =>
              c.activityId == activityId &&
              c.source == CardSource.roundDrop &&
              !collection.has(c.id),
        )
        .toList();
    if (pool.isEmpty) return;
    if (_random.nextDouble() >= kCardDropChance) return;

    // Rarity biases *which* card drops, not whether one does. A round that
    // promises a card and delivers nothing is worse than not promising.
    final total = pool.fold<int>(
      0,
      (sum, c) => sum + cardRarityWeight(c.rarity),
    );
    var roll = _random.nextInt(total);
    for (final card in pool) {
      roll -= cardRarityWeight(card.rarity);
      if (roll >= 0) continue;
      if (collection.grant(card.id)) {
        _ref.read(pendingCardRevealProvider.notifier).show(card.id);
      }
      return;
    }
  }
}

final roundCoordinatorProvider = Provider<RoundCoordinator>(
  RoundCoordinator.new,
);
