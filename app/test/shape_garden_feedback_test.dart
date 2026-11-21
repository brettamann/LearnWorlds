// Shape Garden — the wrong-tap path.
//
// This runner had the starkest version of the app-wide gap: the wrong branch
// of `_onTap` spoke a line and returned, with no setState at all. Nothing on
// screen changed, no sound played, and the round still resolved as a clean
// success no matter how many wrong shapes were tapped.
//
// These tests pin the two halves of the fix: a wrong tap is visible, and it
// reaches the mastery engine.

import 'package:critmath/activities/shape_garden/shape_garden_runner.dart';
import 'package:critmath/engines/mastery/concept_state.dart';
import 'package:critmath/providers/progress_provider.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:critmath/ui/common/answer_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Let the Buddy's container-scoped auto-settle timer fire before the test
  /// ends. pumpAndSettle can't be used — the breathing loop never settles.
  Future<void> drainTimers(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
  }

  Future<ProviderContainer> pumpGarden(WidgetTester tester) async {
    useViewSize(tester);

    final container = ProviderContainer(
      overrides: [sessionIdProvider.overrideWithValue('test-session')],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ShapeGardenRunner(
              skipIntro: true,
              onSequenceComplete: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('every shape on the board is wrapped in AnswerFeedback',
      (tester) async {
    await pumpGarden(tester);
    // Round 1 is 3 circles + 4 distractors. The exact count doesn't matter;
    // what matters is that the wrong-answer reaction is attached at all,
    // because for most of this app's life it was attached to nothing.
    expect(find.byType(AnswerFeedback), findsWidgets);
    await drainTimers(tester);
  });

  testWidgets('a wrong tap is registered and does not resolve the round',
      (tester) async {
    final container = await pumpGarden(tester);

    // Round 1 hunts circles. Its wrong answers are all decor — the
    // distractor pool is "kinds met earlier in this sequence", which is
    // empty on the first round, so the board is circles plus butterflies.
    final wrong = find.byWidgetPredicate(
      (w) =>
          w is GestureDetector &&
          w.key is ValueKey<String> &&
          !(w.key! as ValueKey<String>).value.contains('target'),
    );
    expect(wrong, findsWidgets, reason: 'round 1 seeds four non-targets');

    await tester.tap(wrong.first, warnIfMissed: false);
    await tester.pump();

    // The round must not have resolved. Before the fix the wrong branch
    // returned without touching state, so this was trivially true — but the
    // round *also* resolved as a clean success later regardless, which is
    // what the next test covers.
    expect(container.read(walletProvider), 0);
    expect(container.read(kidProgressProvider)['K.G.2'], isNull);
    await drainTimers(tester);
  });

  testWidgets('wrong taps downgrade the round from clean to soft',
      (tester) async {
    final container = await pumpGarden(tester);

    Finder byIdFragment(String fragment) => find.byWidgetPredicate(
          (w) =>
              w is GestureDetector &&
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.contains(fragment),
        );

    // One wrong tap, then clear every circle.
    final wrong = find.byWidgetPredicate(
      (w) =>
          w is GestureDetector &&
          w.key is ValueKey<String> &&
          !(w.key! as ValueKey<String>).value.contains('target'),
    );
    await tester.tap(wrong.first, warnIfMissed: false);
    await tester.pump();

    final targets = byIdFragment('target-circle');
    final count = targets.evaluate().length;
    expect(count, greaterThan(0));
    for (var i = 0; i < count; i++) {
      await tester.tap(
        byIdFragment('target-circle').at(i),
        warnIfMissed: false,
      );
      await tester.pump();
    }

    final state = container.read(kidProgressProvider)['K.G.2'];
    expect(state, isNotNull, reason: 'the round should have resolved');
    // Soft success: coins still pay (never zero — a frozen counter reads as
    // punishment) but the promotion streak does not advance.
    expect(container.read(walletProvider), greaterThan(0));
    expect(state!.currentStreak, 0);
    expect(state.currentLayer, CpaLayer.concrete);
    expect(state.consecutiveFailures, 0);
    await drainTimers(tester);
  });
}
