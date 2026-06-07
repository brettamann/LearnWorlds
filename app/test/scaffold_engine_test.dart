// ScaffoldEngine tests — verify the lesson-vs-proceed branch.

import 'package:critmath/data/activity_registry.dart';
import 'package:critmath/data/concept_registry.dart';
import 'package:critmath/engines/mastery/concept_state.dart';
import 'package:critmath/engines/scaffolding/scaffold_decision.dart';
import 'package:critmath/engines/scaffolding/scaffold_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScaffoldEngine', () {
    const engine = ScaffoldEngine();

    test('first encounter with canonical introducer → PlayLesson(K.CC.4a)',
        () async {
      final activities = await ActivityRegistry.loadKindergarten();
      final concepts = await ConceptRegistry.loadKindergarten();
      final activity = activities.byId('counting-parade');
      final concept = concepts.byId('K.CC.4a');

      final decision = engine.decide(
        activity: activity,
        concept: concept,
        state: const ConceptState(conceptId: 'K.CC.4a'),
      );

      expect(decision, isA<PlayLesson>());
      expect(
        (decision as PlayLesson).lessonId,
        'lesson-k-cc-4a-one-to-one',
      );
    });

    test('subsequent encounter (Practicing) → ProceedAtLayer', () async {
      final activities = await ActivityRegistry.loadKindergarten();
      final concepts = await ConceptRegistry.loadKindergarten();
      final activity = activities.byId('counting-parade');
      final concept = concepts.byId('K.CC.4a');

      final decision = engine.decide(
        activity: activity,
        concept: concept,
        state: const ConceptState(
          conceptId: 'K.CC.4a',
          status: MasteryStatus.practicing,
          currentLayer: CpaLayer.concrete,
        ),
      );

      expect(decision, isA<ProceedAtLayer>());
      expect((decision as ProceedAtLayer).layer, CpaLayer.concrete);
    });

    test('concept without lessonId → ProceedAtLayer even on first encounter',
        () async {
      final activities = await ActivityRegistry.loadKindergarten();
      final concepts = await ConceptRegistry.loadKindergarten();
      final activity = activities.byId('counting-parade');
      final concept = concepts.byId('K.CC.4c'); // exercises-no-introducer

      final decision = engine.decide(
        activity: activity,
        concept: concept,
        state: const ConceptState(conceptId: 'K.CC.4c'),
      );

      expect(decision, isA<ProceedAtLayer>());
    });
  });
}
