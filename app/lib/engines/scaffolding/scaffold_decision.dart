// ScaffoldDecision — output of the ScaffoldEngine. Tells the ActivityRunner
// what to do at the start of a round: play a MicroLesson, or proceed straight
// into a normal round at the given CPA layer.

import '../mastery/concept_state.dart';

sealed class ScaffoldDecision {
  const ScaffoldDecision();
}

class PlayLesson extends ScaffoldDecision {
  const PlayLesson({
    required this.lessonId,
    required this.conceptId,
  });

  final String lessonId;
  final String conceptId;
}

class ProceedAtLayer extends ScaffoldDecision {
  const ProceedAtLayer({
    required this.conceptId,
    required this.layer,
  });

  final String conceptId;
  final CpaLayer layer;
}
