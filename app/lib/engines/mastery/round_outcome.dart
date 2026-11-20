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
