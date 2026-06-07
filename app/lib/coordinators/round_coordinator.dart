// RoundCoordinator — the seam between activity UI and the mastery/reward
// engines. The activity calls resolveRound(); the coordinator threads the
// outcome through MasteryEngine, persists the new ConceptState, and pays out
// coins for a success. Stays tiny on purpose so engine logic isn't smeared
// across widgets.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engines/mastery/mastery_engine.dart';
import '../engines/mastery/round_outcome.dart';
import '../providers/progress_provider.dart';
import '../providers/save_provider.dart';
import '../providers/session_provider.dart';
import '../providers/wallet_provider.dart';

class RoundCoordinator {
  RoundCoordinator(this._ref);

  final Ref _ref;
  static const _engine = MasteryEngine();

  /// Sprint 1: 5 coins per successful round (per project-bootstrap §rewards).
  static const _coinsPerRoundPass = 5;

  void resolveRound({
    required String activityId,
    required String conceptId,
    required bool success,
    String? instanceKey,
  }) {
    final progress = _ref.read(kidProgressProvider.notifier);
    final state = progress.getOrCreate(conceptId, instanceKey: instanceKey);
    final outcome = RoundOutcome(
      conceptId: conceptId,
      instanceKey: instanceKey,
      layer: state.currentLayer,
      result: success ? RoundResult.success : RoundResult.failure,
      sessionId: _ref.read(sessionIdProvider),
      at: DateTime.now(),
    );
    final next = _engine.apply(state, outcome);
    progress.put(next);
    if (success) {
      _ref.read(walletProvider.notifier).award(_coinsPerRoundPass);
    }
    // Fire-and-forget; the coordinator doesn't wait on disk before returning
    // because the in-memory state is already the source of truth.
    _ref.read(saveCoordinatorProvider).persist();
  }
}

final roundCoordinatorProvider =
    Provider<RoundCoordinator>(RoundCoordinator.new);
