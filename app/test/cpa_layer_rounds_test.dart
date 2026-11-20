// The concrete-pictorial-abstract ladder has to change what she sees.
//
// The mastery engine has promoted and demoted children between layers since
// the first sprint, and until 2026-09-25 no round read the result: a child
// three clean rounds into "abstract" answered with the same acorns over the
// same numerals and the same dots on the same cards as on her first puzzle.
// Mastery - "five successes at the abstract layer" - was therefore measured
// on rounds that were never abstract.
//
// These pin the fade in both directions: the supports go as the layer rises,
// and a miss puts one layer back for that puzzle, because a child who is
// stuck at abstract is exactly the child the acorns are for.

import 'package:critmath/activities/sub_mode_ids.dart';
import 'package:critmath/data/fluency_words.dart';
import 'package:critmath/data/round_pick.dart';
import 'package:critmath/data/storytellers_pond_words.dart';
import 'package:critmath/engines/mastery/concept_state.dart';
import 'package:critmath/engines/mastery/round_outcome.dart';
import 'package:critmath/providers/progress_provider.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/ui/widgets/fluency_runner.dart';
import 'package:critmath/ui/widgets/number_choice.dart';
import 'package:critmath/ui/widgets/sanctuary_round_shell.dart';
import 'package:critmath/ui/widgets/storytellers_pond_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

const String _session = 'cpa-layers';

Future<ProviderContainer> _mount(
  WidgetTester tester,
  Widget runner, {
  required String concept,
  required CpaLayer layer,
}) async {
  useViewSize(tester);
  final container = ProviderContainer(
    overrides: [sessionIdProvider.overrideWithValue(_session)],
  );
  addTearDown(container.dispose);
  container
      .read(kidProgressProvider.notifier)
      .put(ConceptState(conceptId: concept, currentLayer: layer));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: runner)),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

Finder get _acorns => find.byKey(const ValueKey('fluency-acorns'));
Finder get _dots => find.descendant(
      of: find.byType(NumberCard),
      matching: find.byType(DotFrame),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('supportLayer', () {
    test('is her layer until she misses', () {
      for (final l in CpaLayer.values) {
        expect(supportLayer(l), l);
      }
    });
    test('a miss is one layer more concrete, never two', () {
      expect(supportLayer(CpaLayer.abstract, misses: 3), CpaLayer.pictorial);
      expect(supportLayer(CpaLayer.pictorial, misses: 1), CpaLayer.concrete);
      expect(supportLayer(CpaLayer.concrete, misses: 2), CpaLayer.concrete);
    });
  });

  group('Fluency Within 5', () {
    final first = fluencyRoundsFor(
      FluencyWithin5Modes.casual,
      seed: _session.hashCode,
    ).first.first;

    Widget runner() => FluencyRunner(
          skipIntro: true,
          onSequenceComplete: () {},
        );

    int wrongChoice(WidgetTester tester) {
      for (final e in find.byType(NumberCard).evaluate()) {
        final v = (e.widget as NumberCard).value;
        if (v != first.answer) return v;
      }
      throw StateError('no wrong card on the board');
    }

    testWidgets('concrete: acorns over the numbers, dots on the cards',
        (tester) async {
      await _mount(
        tester,
        runner(),
        concept: 'K.OA.5',
        layer: CpaLayer.concrete,
      );
      expect(_acorns, findsWidgets);
      expect(_dots, findsWidgets);
      await _unmount(tester);
    });

    testWidgets('pictorial: acorns stay, the dots go until she misses',
        (tester) async {
      await _mount(
        tester,
        runner(),
        concept: 'K.OA.5',
        layer: CpaLayer.pictorial,
      );
      expect(_acorns, findsWidgets);
      expect(_dots, findsNothing);
      await tester.tap(
        find.byKey(ValueKey('number-card-${wrongChoice(tester)}')),
      );
      await _settle(tester);
      expect(_dots, findsWidgets, reason: 'a miss brings the dots back');
      await _unmount(tester);
    });

    testWidgets('abstract: just the numbers, and a miss brings the acorns',
        (tester) async {
      await _mount(
        tester,
        runner(),
        concept: 'K.OA.5',
        layer: CpaLayer.abstract,
      );
      expect(_acorns, findsNothing);
      expect(_dots, findsNothing);
      await tester.tap(
        find.byKey(ValueKey('number-card-${wrongChoice(tester)}')),
      );
      await _settle(tester);
      expect(
        _acorns,
        findsWidgets,
        reason: 'stuck at abstract is who they '
            'are for',
      );
      expect(_dots, findsNothing, reason: 'one layer down, not two');
      await _unmount(tester);
    });

    testWidgets('abstract: the hint ladder helps the same way', (tester) async {
      await _mount(
        tester,
        runner(),
        concept: 'K.OA.5',
        layer: CpaLayer.abstract,
      );
      expect(_acorns, findsNothing);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(_acorns, findsWidgets);
      await _unmount(tester);
    });
  });

  group("Storyteller's Pond", () {
    final story = storiesFor(
      StorytellersPondModes.addTo,
      seed: roundSeed(_session, StorytellersPondModes.addTo),
    ).first;

    Widget runner() => StorytellersPondRunner(
          skipIntro: true,
          onSequenceComplete: () {},
        );

    /// Calls every waiting duckling over, which brings up the question.
    Future<void> actItOut(WidgetTester tester) async {
      for (var i = story.a; i < story.a + story.b; i++) {
        await tester.tap(find.byKey(ValueKey('story-critter-$i')));
        await _settle(tester);
      }
      expect(find.byType(NumberCard), findsWidgets);
    }

    testWidgets('pictorial: bare numerals until she misses', (tester) async {
      await _mount(
        tester,
        runner(),
        concept: 'K.OA.2',
        layer: CpaLayer.pictorial,
      );
      await actItOut(tester);
      expect(_dots, findsNothing);
      final wrong = find
          .byType(NumberCard)
          .evaluate()
          .map((e) => (e.widget as NumberCard).value)
          .firstWhere((v) => v != story.answer);
      await tester.tap(find.byKey(ValueKey('number-card-$wrong')));
      await _settle(tester);
      expect(_dots, findsWidgets);
      expect(find.byKey(const ValueKey('story-sentence')), findsNothing);
      await _unmount(tester);
    });

    testWidgets('abstract: the solved story is written as a number sentence',
        (tester) async {
      await _mount(
        tester,
        runner(),
        concept: 'K.OA.2',
        layer: CpaLayer.abstract,
      );
      await actItOut(tester);
      expect(find.byKey(const ValueKey('story-sentence')), findsNothing);
      await tester.tap(find.byKey(ValueKey('number-card-${story.answer}')));
      await _settle(tester);
      expect(
        find.text('${story.a} + ${story.b} = ${story.answer}'),
        findsOneWidget,
      );
      await _unmount(tester);
    });

    testWidgets('concrete: dots, and no sentence', (tester) async {
      await _mount(
        tester,
        runner(),
        concept: 'K.OA.2',
        layer: CpaLayer.concrete,
      );
      await actItOut(tester);
      expect(_dots, findsWidgets);
      await tester.tap(find.byKey(ValueKey('number-card-${story.answer}')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('story-sentence')), findsNothing);
      await _unmount(tester);
    });
  });

  testWidgets('the layer is read per round, after the last one was graded',
      (tester) async {
    // Three clean rounds promote. The round after the promotion has to be
    // drawn at the new layer - and the round being celebrated must not be
    // redrawn under her.
    final seen = <int, CpaLayer>{};
    final container = await _mount(
      tester,
      SanctuaryRoundShell(
        activityId: 'test',
        roundCount: 5,
        conceptIdFor: (_) => 'K.OA.5',
        introLine: 'Hello.',
        keeperLineFor: (_) => 'Good.',
        finalLine: 'Bye.',
        skipIntro: true,
        showBuddy: false,
        background: const SizedBox(),
        onSequenceComplete: () {},
        roundBuilder: (context, c) {
          seen[c.index] ??= c.layer;
          expect(
            c.layer,
            seen[c.index],
            reason: 'round ${c.index} changed '
                'layer while on screen',
          );
          return TextButton(
            key: ValueKey('finish-${c.index}'),
            onPressed: () => c.finish(RoundResult.success),
            child: const Text('go'),
          );
        },
      ),
      concept: 'K.OA.5',
      layer: CpaLayer.concrete,
    );
    for (var r = 0; r < 4; r++) {
      await tester.tap(find.byKey(ValueKey('finish-$r')));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    expect(seen[0], CpaLayer.concrete);
    expect(seen[2], CpaLayer.concrete);
    expect(seen[3], CpaLayer.pictorial);
    expect(
      container.read(kidProgressProvider)['K.OA.5']!.currentLayer,
      CpaLayer.pictorial,
    );
    await _unmount(tester);
  });
}
