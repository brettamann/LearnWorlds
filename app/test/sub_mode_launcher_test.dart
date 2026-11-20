// Where a sub-mode opens. The map and "Next!" used to decide this separately,
// and "Next!" forgot that a challenge never plays the introducing lesson.

import 'package:critmath/data/concept_registry.dart';
import 'package:critmath/engines/mastery/concept_state.dart';
import 'package:critmath/models/activity.dart';
import 'package:critmath/models/concept.dart';
import 'package:critmath/navigation/sub_mode_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

const _concept = Concept(
  id: 'K.T.1',
  standardCode: 'K.T.1',
  description: 'test concept',
  gradeLevel: 'K',
  strand: 'test',
  requiresLesson: true,
  granularity: 'concept',
  lessonId: 'k-t-1-lesson',
  introducedBy: 'test-activity',
);

const _registry = ConceptRegistry(version: 1, concepts: [_concept]);

const _step = SubMode(id: 'step', primaryConcepts: ['K.T.1'], isDefault: true);
const _challenge =
    SubMode(id: 'challenge', primaryConcepts: ['K.T.1'], isChallenge: true);
const _ownsIntro =
    SubMode(id: 'own-demo', primaryConcepts: ['K.T.1'], ownsIntro: true);

const _activity = Activity(
  id: 'test-activity',
  displayName: 'Test',
  region: 'sanctuary',
  grade: 'K',
  status: 'built',
  concepts: [ConceptRef(conceptId: 'K.T.1', role: 'introduces')],
  subModes: [_step, _challenge, _ownsIntro],
);

ConceptState _fresh(String id) => ConceptState(conceptId: id);

LaunchTarget _resolve(SubMode m, {ConceptRegistry? concepts = _registry}) =>
    resolveSubModeLaunch(
      activity: _activity,
      subMode: m,
      concepts: concepts,
      stateFor: _fresh,
    );

void main() {
  test('a first visit to an ordinary step plays its lesson first', () {
    final t = _resolve(_step);
    expect(t, isA<LessonFirst>());
    expect((t as LessonFirst).lessonId, 'k-t-1-lesson');
    expect(t.subModeId, 'step');
  });

  test('a challenge goes straight in, even on a first encounter', () {
    // The bug: auto-advance into a challenge routed through the lesson.
    final t = _resolve(_challenge);
    expect(t, isA<StraightIn>());
    expect(t.subModeId, 'challenge');
  });

  test('a sub-mode that owns its intro goes straight in', () {
    expect(_resolve(_ownsIntro), isA<StraightIn>());
  });

  test('with no concept registry loaded it plays rather than detours', () {
    expect(_resolve(_step, concepts: null), isA<StraightIn>());
  });

  test('a returning player goes straight in', () {
    final t = resolveSubModeLaunch(
      activity: _activity,
      subMode: _step,
      concepts: _registry,
      stateFor: (id) =>
          ConceptState(conceptId: id, status: MasteryStatus.practicing),
    );
    expect(t, isA<StraightIn>());
  });
}
