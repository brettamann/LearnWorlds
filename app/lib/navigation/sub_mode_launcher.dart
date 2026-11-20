// Where tapping a sub-mode takes her: its lesson first, or straight in.
//
// This decision was written out twice - once on the Sanctuary map for a
// picked sub-mode, once on the activity screen for "Next!" - and the copies
// had drifted. The map sent a challenge sub-mode straight to the activity;
// the activity screen forgot the challenge case, so auto-advancing into a
// challenge could open a lesson in front of it. Now both call this.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activities/activity_launch.dart';
import '../data/concept_registry.dart';
import '../engines/mastery/concept_state.dart';
import '../engines/scaffolding/scaffold_decision.dart';
import '../engines/scaffolding/scaffold_engine.dart';
import '../models/activity.dart';
import '../providers/app_providers.dart';
import '../providers/progress_provider.dart';
import 'routes.dart';

/// Where a sub-mode launch goes.
sealed class LaunchTarget {
  const LaunchTarget(this.subModeId);
  final String subModeId;
}

/// Play [lessonId] first, then hand off into the sub-mode.
class LessonFirst extends LaunchTarget {
  const LessonFirst(this.lessonId, super.subModeId);
  final String lessonId;
}

/// Go straight into the activity.
class StraightIn extends LaunchTarget {
  const StraightIn(super.subModeId);
}

/// Decides where [subMode] of [activity] should open. Pure, so it is tested
/// directly.
///
/// Two kinds never play the introducing lesson: a challenge (an optional
/// final check after every step is done; the runner has its own brief demo)
/// and a sub-mode that owns its intro (its runner plays its own animated
/// lesson, and the concept's lesson on top would stack two demos). With no
/// concept registry loaded yet, playing beats a detour to the map.
LaunchTarget resolveSubModeLaunch({
  required Activity activity,
  required SubMode subMode,
  required ConceptRegistry? concepts,
  required ConceptState Function(String conceptId) stateFor,
}) {
  if (subMode.isChallenge || subMode.ownsIntro || concepts == null) {
    return StraightIn(subMode.id);
  }
  final concept = concepts.byId(activity.entryConceptIdFor(subMode));
  final decision = const ScaffoldEngine().decide(
    activity: activity,
    concept: concept,
    state: stateFor(concept.id),
  );
  return switch (decision) {
    PlayLesson(:final lessonId) => LessonFirst(lessonId, subMode.id),
    ProceedAtLayer() => StraightIn(subMode.id),
  };
}

/// Opens [subMode] of [activity] wherever [resolveSubModeLaunch] says.
void launchSubMode(
  BuildContext context,
  WidgetRef ref, {
  required Activity activity,
  required SubMode subMode,
}) {
  final target = resolveSubModeLaunch(
    activity: activity,
    subMode: subMode,
    concepts: ref.read(conceptRegistryProvider).valueOrNull,
    stateFor: ref.read(kidProgressProvider.notifier).getOrCreate,
  );
  switch (target) {
    case LessonFirst(:final lessonId):
      // The picked sub-mode rides along so the lesson hands off into it
      // rather than its own youDo.subMode - one lesson can introduce several
      // sub-modes of a chain.
      context.goLesson(lessonId, subModeId: target.subModeId);
    case StraightIn():
      context.goActivity(
        activity.id,
        ActivityLaunch(subModeId: target.subModeId),
      );
  }
}
