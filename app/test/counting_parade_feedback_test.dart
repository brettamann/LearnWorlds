// Counting Parade — wrong-tap feedback and the round-result grading.
//
// The behaviour under test here previously did not exist in any form. A wrong
// tap produced no setState, no visual change, and no sound; to a pre-reading
// child that is indistinguishable from the app having frozen. And because the
// mechanic couldn't be failed at all, every round resolved `success: true` and
// the entire mastery ladder was unreachable.

import 'package:critmath/engines/mastery/concept_state.dart';
import 'package:critmath/providers/progress_provider.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:critmath/ui/widgets/answer_feedback.dart';
import 'package:critmath/ui/widgets/counting_parade_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Let the Buddy's auto-settle timer fire before the test ends.
  ///
  /// BuddyReactionController holds the reaction for ~2s and then drifts back
  /// to idle. That timer is container-scoped rather than widget-scoped, so it
  /// outlives the widget tree and trips the framework's pending-timer check.
  /// pumpAndSettle can't be used here — the Buddy's breathing loop repeats
  /// forever and would never settle.
  Future<void> drainTimers(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
  }

  /// Tap away the card that names the round's creature.
  ///
  /// Every round now opens with one: a pre-reader had no way to learn what she
  /// was looking at. It advances itself after a few seconds, but a test that
  /// waited for that would be a test about the timer.
  Future<void> skipSpeciesCard(WidgetTester tester) async {
    final card = find.byKey(const ValueKey('parade-species-card'));
    if (card.evaluate().isEmpty) return;
    // tapAt rather than tap(finder): the stage is a Positioned.fill, and
    // tap() warns that the offset it derives does not hit-test the widget it
    // matched. Any point inside the card layer dismisses it — "tap anywhere"
    // is the affordance.
    await tester.tapAt(tester.getCenter(card));
    await tester.pump();
  }

  /// Mounts the parade with a pinned seed and a round-1 count of 3, skipping
  /// the keeper intro so the test starts on the playfield.
  Future<ProviderContainer> pumpParade(
    WidgetTester tester, {
    List<int> counts = const <int>[3, 5],
  }) async {
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
            body: CountingParadeRunner(
              skipIntro: true,
              onSequenceComplete: () {},
              roundParameters: <String, dynamic>{
                'counts': counts,
                'species': 'fawn',
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await skipSpeciesCard(tester);
    return container;
  }

  testWidgets('round 1 is clean — no decor to tap wrongly', (tester) async {
    await pumpParade(tester);
    expect(find.text('0 / 3'), findsOneWidget);
    // A kid meeting the activity should get one uncomplicated success first.
    expect(find.byKey(const ValueKey('decor-0')), findsNothing);
    await drainTimers(tester);
  });

  testWidgets('a clean round resolves as a full success', (tester) async {
    final container = await pumpParade(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(ValueKey('fawn-$i')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('parade-done-arrow')));
    await tester.pump();

    final state = container.read(kidProgressProvider)['K.CC.4a'];
    expect(state, isNotNull);
    expect(state!.currentStreak, 1, reason: 'clean round advances the streak');
    expect(state.consecutiveFailures, 0);
    expect(container.read(walletProvider), 5);
    await drainTimers(tester);
  });

  testWidgets('tapping decor shakes it and does not advance the count',
      (tester) async {
    // Round 2 is where decor first appears.
    final container = await pumpParade(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(ValueKey('fawn-$i')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('parade-done-arrow')));
    await tester.pump();
    // Let the non-blocking keeper aside run its course and advance the round.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    await skipSpeciesCard(tester);

    expect(find.text('0 / 5'), findsOneWidget);
    final decor = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('decor-'),
    );
    expect(decor, findsWidgets, reason: 'round 2 seeds meadow decor');

    final before = container.read(walletProvider);
    await tester.tap(decor.first);
    await tester.pump();

    // The count is untouched — decor is not countable.
    expect(find.text('0 / 5'), findsOneWidget);
    // ...but something visibly happened, which is the whole point.
    expect(find.byType(AnswerFeedback), findsWidgets);
    // A wrong tap costs nothing on its own.
    expect(container.read(walletProvider), before);
    await drainTimers(tester);
  });

  testWidgets(
      'a round with wrong taps still pays out and never demotes below '
      'Concrete', (tester) async {
    final container = await pumpParade(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(ValueKey('fawn-$i')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('parade-done-arrow')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    await skipSpeciesCard(tester);

    final decor = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('decor-'),
    );
    // Three wrong taps grade the round as a failure.
    for (var i = 0; i < 3; i++) {
      await tester.tap(decor.first);
      await tester.pump();
    }
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(ValueKey('fawn-$i')));
      await tester.pump();
    }
    final coinsBefore = container.read(walletProvider);
    await tester.tap(find.byKey(const ValueKey('parade-done-arrow')));
    await tester.pump();

    final state = container.read(kidProgressProvider)['K.CC.4a']!;
    // Never punitive: the coin counter must still move. A five-year-old
    // watching it freeze reads that as a punishment whatever we call it.
    expect(container.read(walletProvider), greaterThan(coinsBefore));
    expect(state.currentLayer, CpaLayer.concrete);
    expect(state.consecutiveFailures, 1);
    await drainTimers(tester);
  });
}
