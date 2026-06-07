// MasteryEngine unit tests — verify the promotion + status transitions
// against the spec rules in specs/shared/adaptive-scaffolding.md.

import 'package:critmath/engines/mastery/concept_state.dart';
import 'package:critmath/engines/mastery/mastery_engine.dart';
import 'package:critmath/engines/mastery/round_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = MasteryEngine();
  const conceptId = 'K.CC.4a';

  RoundOutcome success({
    CpaLayer layer = CpaLayer.concrete,
    String session = 's1',
    DateTime? at,
  }) =>
      RoundOutcome(
        conceptId: conceptId,
        layer: layer,
        result: RoundResult.success,
        sessionId: session,
        at: at ?? DateTime(2026, 6, 1),
      );

  RoundOutcome failure({
    CpaLayer layer = CpaLayer.concrete,
    String session = 's1',
    DateTime? at,
  }) =>
      RoundOutcome(
        conceptId: conceptId,
        layer: layer,
        result: RoundResult.failure,
        sessionId: session,
        at: at ?? DateTime(2026, 6, 1),
      );

  group('MasteryEngine', () {
    test('first success promotes NotStarted to Practicing', () {
      final state = engine.apply(
        const ConceptState(conceptId: conceptId),
        success(),
      );
      expect(state.status, MasteryStatus.practicing);
      expect(state.currentStreak, 1);
      expect(state.currentLayer, CpaLayer.concrete);
    });

    test('three successes promote Concrete → Pictorial; streak resets', () {
      var state = const ConceptState(conceptId: conceptId);
      for (var i = 0; i < 3; i++) {
        state = engine.apply(state, success());
      }
      expect(state.currentLayer, CpaLayer.pictorial);
      expect(state.currentStreak, 0);
    });

    test('failure resets streak but keeps layer', () {
      var state = const ConceptState(conceptId: conceptId);
      state = engine.apply(state, success());
      state = engine.apply(state, success());
      state = engine.apply(state, failure());
      expect(state.currentStreak, 0);
      expect(state.currentLayer, CpaLayer.concrete);
    });

    test('mastery needs 5 Abstract successes across 3 sessions and 3 days',
        () {
      var state = const ConceptState(conceptId: conceptId);
      // Climb to Abstract.
      for (var i = 0; i < 3; i++) {
        state = engine.apply(state, success(layer: CpaLayer.concrete));
      }
      for (var i = 0; i < 3; i++) {
        state = engine.apply(state, success(layer: CpaLayer.pictorial));
      }
      expect(state.currentLayer, CpaLayer.abstract);

      // 5 Abstract successes spread across 3 sessions on 3 days.
      final dates = [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 2),
        DateTime(2026, 6, 2),
        DateTime(2026, 6, 3),
        DateTime(2026, 6, 3),
      ];
      final sessions = ['s1', 's2', 's2', 's3', 's3'];
      for (var i = 0; i < 5; i++) {
        state = engine.apply(
          state,
          success(
            layer: CpaLayer.abstract,
            session: sessions[i],
            at: dates[i],
          ),
        );
      }
      expect(state.status, MasteryStatus.mastered);
      expect(state.abstractSuccessCount, 5);
    });

    test('mastery does NOT fire when sessions/days are insufficient', () {
      var state = const ConceptState(
        conceptId: conceptId,
        currentLayer: CpaLayer.abstract,
      );
      for (var i = 0; i < 5; i++) {
        state = engine.apply(state, success(layer: CpaLayer.abstract));
      }
      expect(state.abstractSuccessCount, 5);
      expect(state.status, isNot(MasteryStatus.mastered));
    });
  });
}
