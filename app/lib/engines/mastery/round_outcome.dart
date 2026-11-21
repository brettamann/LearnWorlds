// RoundOutcome — the payload an activity hands the MasteryEngine after a
// round (or a lesson You-Do) resolves. Pure data; the engine consumes it.

import 'concept_state.dart';

/// How a round went.
///
/// [softSuccess] is the "got there, but with help" case that
/// specs/shared/adaptive-scaffolding.md calls for: the kid finished, so
/// nothing punitive happens and coins still pay out, but it does not count
/// toward the promotion streak. A round that needed a hint, or that took a
/// couple of wrong taps, resolves here.
enum RoundResult { success, softSuccess, failure }

/// Misses in one round that make it a failure, unless an activity says
/// otherwise. Three is the number the activity specs settled on: one or two
/// wrong taps is a slip, three is not having the idea yet.
const int kMissesToFail = 3;

/// The one grading rule every round uses.
///
/// [misses] or more than [failAt] is a [RoundResult.failure]; a round with no
/// misses that the game did not have to help with is a
/// [RoundResult.success]; anything else got there with help and is a
/// [RoundResult.softSuccess]. Pass `failAt: null` for a round that cannot be
/// failed (every tap counts toward the answer, so only help can mark it).
RoundResult gradeRound({
  int misses = 0,
  bool helped = false,
  int? failAt = kMissesToFail,
}) {
  if (failAt != null && misses >= failAt) return RoundResult.failure;
  if (misses == 0 && !helped) return RoundResult.success;
  return RoundResult.softSuccess;
}

/// Coins a round pays, by result (per project-bootstrap §rewards).
///
/// Note that even a failure pays. A five-year-old must never watch the coin
/// counter fail to move - specs/shared/adaptive-scaffolding.md is emphatic
/// that this system is "never punitive", and a zero payout is a punishment
/// whatever we call it. The gap between 5 and 1 is enough to make clean
/// rounds feel better without making a hard one feel like a loss.
int coinsFor(RoundResult result) => switch (result) {
  RoundResult.success => kCoinsForCleanRound,
  RoundResult.softSuccess => 3,
  RoundResult.failure => 1,
};

/// What a clean round pays - the most a round can earn.
const int kCoinsForCleanRound = 5;

class RoundOutcome {
  const RoundOutcome({
    required this.conceptId,
    required this.layer,
    required this.result,
    required this.sessionId,
    required this.at,
    this.instanceKey,
  });

  final String conceptId;
  final String? instanceKey;
  final CpaLayer layer;
  final RoundResult result;
  final String sessionId;
  final DateTime at;
}
