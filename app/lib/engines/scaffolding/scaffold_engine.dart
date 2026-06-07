// ScaffoldEngine — answers "what should happen at the top of this round?"
//
// Sprint 1 implements only the branch the vertical slice exercises:
//   - First encounter with a `requiresLesson` concept where the activity is
//     the canonical introducer → PlayLesson(lessonId).
//   - Otherwise → ProceedAtLayer(grade-default-for-K = Concrete).
//
// Demotion, sub-mode floor selection, and exercises-only concepts arrive
// in later sprints.

import '../../models/activity.dart';
import '../../models/concept.dart';
import '../mastery/concept_state.dart';
import 'scaffold_decision.dart';

class ScaffoldEngine {
  const ScaffoldEngine();

  ScaffoldDecision decide({
    required Activity activity,
    required Concept concept,
    required ConceptState state,
  }) {
    final isCanonicalIntroducer = concept.introducedBy == activity.id;
    if (state.isFirstEncounter &&
        concept.requiresLesson &&
        concept.lessonId != null &&
        isCanonicalIntroducer) {
      return PlayLesson(
        lessonId: concept.lessonId!,
        conceptId: concept.id,
      );
    }
    return ProceedAtLayer(
      conceptId: concept.id,
      layer: state.currentLayer,
    );
  }
}
