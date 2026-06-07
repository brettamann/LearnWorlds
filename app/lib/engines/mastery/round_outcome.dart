// RoundOutcome — the payload an activity hands the MasteryEngine after a
// round (or a lesson You-Do) resolves. Pure data; the engine consumes it.

import 'concept_state.dart';

enum RoundResult { success, failure }

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
