// MasteryEngine — pure-function state machine.
//
// Inputs:  current ConceptState + RoundOutcome.
// Output:  new ConceptState (immutable; original is unchanged).
//
// Rules implemented (per specs/shared/adaptive-scaffolding.md):
//   - First success after lesson → Practicing.
//   - Concrete streak ≥ 3 → promote to Pictorial; reset streak.
//   - Pictorial streak ≥ 3 → promote to Abstract; reset streak.
//   - Abstract success → increment abstractSuccessCount.
//   - Mastered when ≥ 5 Abstract successes AND ≥ 3 distinct sessions
//     AND ≥ 3 distinct calendar days AND last Abstract attempt was success.
//   - Failure: streak resets; demote logic lands in a later sprint
//     (Sprint 1's vertical slice never demotes).
//
// "No failures in last 3 Abstract attempts" and the demote_struggle path are
// deferred — the slice doesn't exercise them and the spec calls for them in
// the polish pass.

import 'concept_state.dart';
import 'round_outcome.dart';

class MasteryEngine {
  const MasteryEngine();

  static const int _promoteStreak = 3;
  static const int _masteryAbstractSuccesses = 5;
  static const int _masterySessions = 3;
  static const int _masteryDays = 3;

  ConceptState apply(ConceptState state, RoundOutcome outcome) {
    assert(
      state.conceptId == outcome.conceptId &&
          state.instanceKey == outcome.instanceKey,
      'RoundOutcome conceptId/instanceKey must match ConceptState',
    );

    final sessions = {...state.sessionIds, outcome.sessionId};
    final days = {...state.daysTouched, _dayKey(outcome.at)};
    final firstTouched = state.firstTouchedAt ?? outcome.at;

    if (outcome.result == RoundResult.failure) {
      return state.copyWith(
        currentStreak: 0,
        sessionIds: sessions,
        daysTouched: days,
        firstTouchedAt: firstTouched,
        lastTouchedAt: outcome.at,
        status: state.status == MasteryStatus.notStarted
            ? MasteryStatus.introduced
            : state.status,
      );
    }

    // Success path.
    final newStreak = state.currentStreak + 1;
    var newLayer = state.currentLayer;
    var streakForState = newStreak;
    var newStatus = state.status == MasteryStatus.notStarted
        ? MasteryStatus.practicing
        : (state.status == MasteryStatus.introduced
            ? MasteryStatus.practicing
            : state.status);

    if (newStreak >= _promoteStreak && newLayer != CpaLayer.abstract) {
      newLayer = _promote(newLayer);
      streakForState = 0;
    }

    final newAbstractSuccesses = outcome.layer == CpaLayer.abstract
        ? state.abstractSuccessCount + 1
        : state.abstractSuccessCount;

    if (_masteryReached(
      abstractSuccesses: newAbstractSuccesses,
      sessions: sessions,
      days: days,
      lastResult: outcome.result,
    )) {
      newStatus = MasteryStatus.mastered;
    }

    return state.copyWith(
      status: newStatus,
      currentLayer: newLayer,
      currentStreak: streakForState,
      abstractSuccessCount: newAbstractSuccesses,
      sessionIds: sessions,
      daysTouched: days,
      firstTouchedAt: firstTouched,
      lastTouchedAt: outcome.at,
    );
  }

  CpaLayer _promote(CpaLayer layer) {
    switch (layer) {
      case CpaLayer.concrete:
        return CpaLayer.pictorial;
      case CpaLayer.pictorial:
        return CpaLayer.abstract;
      case CpaLayer.abstract:
        return CpaLayer.abstract;
    }
  }

  bool _masteryReached({
    required int abstractSuccesses,
    required Set<String> sessions,
    required Set<String> days,
    required RoundResult lastResult,
  }) {
    if (lastResult != RoundResult.success) return false;
    return abstractSuccesses >= _masteryAbstractSuccesses &&
        sessions.length >= _masterySessions &&
        days.length >= _masteryDays;
  }

  String _dayKey(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-'
      '${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';
}
