// What "Next!" on the end-of-visit sheet plays.
//
// Normally the first step of the activity's chain she has not finished, so
// the sub-modes read as a path: count the parade, then count on from a number,
// then count out. The exception is a child who ended the visit struggling at
// the simplest layer there is - see [isStrugglingAtFloor] - who goes one step
// simpler instead ([Activity.simplerThan]). That is step two of the staggered
// demotion in specs/shared/adaptive-scaffolding.md, and until it existed the
// two sub-modes written for exactly that child (Build-a-Habitat's frame-only
// and Care Pantry's categorize-only) could not be reached by any route.

import '../../models/activity.dart';
import '../mastery/concept_state.dart';

/// Her last two rounds of the concept failed, at the concrete layer.
///
/// Above concrete the mastery engine handles it by itself - two failures drop
/// a layer and reset the count - so a run of failures that is still standing
/// here is one there was no gentler representation for.
bool isStrugglingAtFloor(ConceptState state) =>
    state.currentLayer == CpaLayer.concrete && state.consecutiveFailures >= 2;

/// The sub-mode to offer after [playedId], or null to go back to the map.
///
/// [state] is the concept the played sub-mode teaches, read after its last
/// round was graded. [completed] already includes [playedId]: a sub-mode she
/// struggled with still counts as done, because the map must never close on a
/// five-year-old, so the easier one is a detour and "Next!" after it carries
/// on down the chain.
SubMode? nextSubModeAfter({
  required Activity activity,
  required String playedId,
  required Set<String> completed,
  required ConceptState state,
}) {
  if (isStrugglingAtFloor(state)) {
    final easier = activity.simplerThan(playedId);
    if (easier != null) return easier;
  }
  for (final m in activity.subModes) {
    if (m.isChainStep && !completed.contains(m.id)) return m;
  }
  return null;
}
