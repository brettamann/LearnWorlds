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
//   - Failure: streak resets, consecutiveFailures increments, and 2 in a row
//     demote one CPA layer. Asymmetric on purpose — 3 up, 2 down — because the
//     spec asks us to be "generous on the way down, conservative on the way
//     up". Concrete is the floor; there is nowhere gentler to go.
//   - Soft success (finished, but with a hint or a couple of wrong taps):
//     clears the failure count, but does NOT advance the promotion streak and
//     does NOT count toward Abstract mastery.
//
// Note this whole failure path was dead code until recently: every runner
// hardcoded `success: true`, so nothing ever demoted and the CPA ladder only
// went one way.
//
// Still deferred: the "no failures in last 3 Abstract attempts" tail check.
// Step 2 of staggered demotion (dropping to a simpler sub-mode) needs activity
// context the engine doesn't have, so it lives with the routing instead - see
// engines/scaffolding/next_sub_mode.dart. The layer this engine moves is read
// by the rounds themselves through `RoundContext.layer`.

import 'concept_state.dart';
import 'round_outcome.dart';

class MasteryEngine {
  const MasteryEngine();

  static const int _promoteStreak = 3;

  /// Failures in a row before dropping a CPA layer. Two, against three to
  /// promote — see the header note on asymmetry.
  static const int demoteAfterFailures = 2;

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
      final failures = state.consecutiveFailures + 1;
      // Concrete is the floor — there is no simpler representation to fall
      // back to, so a struggling kid stays there, the failures keep counting,
      // and `isStrugglingAtFloor` sends her one sub-mode simpler next.
      final shouldDemote =
          failures >= demoteAfterFailures &&
          state.currentLayer != CpaLayer.concrete;
      return state.copyWith(
        currentStreak: 0,
        // Reset on demote so the kid gets a full two attempts at the easier
        // layer before anything moves again.
        consecutiveFailures: shouldDemote ? 0 : failures,
        currentLayer: shouldDemote
            ? _demote(state.currentLayer)
            : state.currentLayer,
        sessionIds: sessions,
        daysTouched: days,
        firstTouchedAt: firstTouched,
        lastTouchedAt: outcome.at,
        status: state.status == MasteryStatus.notStarted
            ? MasteryStatus.introduced
            : state.status,
      );
    }

    if (outcome.result == RoundResult.softSuccess) {
      // She finished, so nothing punitive happens and the struggle counter
      // clears — but help was involved, so this doesn't buy progress toward
      // the next layer.
      return state.copyWith(
        consecutiveFailures: 0,
        sessionIds: sessions,
        daysTouched: days,
        firstTouchedAt: firstTouched,
        lastTouchedAt: outcome.at,
        status: state.status == MasteryStatus.notStarted
            ? MasteryStatus.practicing
            : (state.status == MasteryStatus.introduced
                  ? MasteryStatus.practicing
                  : state.status),
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
      // A success breaks the failure run. Demotion is meant to catch a kid
      // who is consistently struggling, not one who missed twice across a
      // whole session with a clean round in between.
      consecutiveFailures: 0,
      abstractSuccessCount: newAbstractSuccesses,
      sessionIds: sessions,
      daysTouched: days,
      firstTouchedAt: firstTouched,
      lastTouchedAt: outcome.at,
    );
  }

  /// One step back down the CPA ladder. Concrete is the floor.
  ///
  /// The kid is never told this happened — adaptive-scaffolding.md is explicit
  /// that there is no "you've been moved down a level" message. The problems
  /// just start looking a little more concrete again.
  CpaLayer _demote(CpaLayer layer) {
    switch (layer) {
      case CpaLayer.abstract:
        return CpaLayer.pictorial;
      case CpaLayer.pictorial:
        return CpaLayer.concrete;
      case CpaLayer.concrete:
        return CpaLayer.concrete;
    }
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
