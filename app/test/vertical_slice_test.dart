// End-to-end vertical slice — Home map → Sanctuary map → lesson tile →
// MicroLesson → Counting Parade round → mastery promotion + coin payout.
// Proves the navigation chain plus mastery + reward bookkeeping all work
// together.

import 'package:critmath/app.dart';
import 'package:critmath/data/map_anchor_scanner.dart';
import 'package:critmath/engines/mastery/concept_state.dart';
import 'package:critmath/providers/exploration_provider.dart';
import 'package:critmath/providers/map_anchors_provider.dart';
import 'package:critmath/providers/progress_provider.dart';
import 'package:critmath/providers/read_aloud_settings_provider.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:critmath/ui/widgets/keeper_aside.dart';
import 'package:critmath/ui/widgets/progress_bar_to_reward.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'full vertical slice: home → sanctuary → lesson → round → mastery + coins',
      (tester) async {
    // iPad-ish surface so the keeper + speech bubble + "Let's count!" button
    // all lay out on-screen and remain hit-testable.
    tester.view.physicalSize = const Size(1180, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Avoid the heavy PNG decode + 4M-pixel scan in the test sandbox by
    // overriding the anchor provider with fixed positions, and seed F0 as
    // already explored so the F1 (Counting Parade) node is visible without
    // walking through the cutscene.
    final container = ProviderContainer(
      overrides: [
        // Pin the RNG seed. ParadeRoundPlanner shuffles the species order off
        // the session id so a replay isn't identical; the test needs it stable.
        sessionIdProvider.overrideWithValue('test-session'),
        sanctuaryAnchorsProvider.overrideWith((ref) async {
          return const MapAnchors(
            anchors: {
              0xF0: Offset(0.20, 0.85),
              0xF1: Offset(0.40, 0.70),
              0xF2: Offset(0.55, 0.55),
              0xF3: Offset(0.50, 0.30),
              0xF4: Offset(0.30, 0.40),
              0xF5: Offset(0.15, 0.55),
              0xF6: Offset(0.20, 0.20),
              0xF7: Offset(0.45, 0.10),
              0xF8: Offset(0.65, 0.20),
              0xF9: Offset(0.80, 0.35),
              0xFA: Offset(0.85, 0.55),
              0xFB: Offset(0.80, 0.75),
            },
            imageWidth: 2048,
            imageHeight: 2048,
          );
        }),
      ],
    );
    addTearDown(container.dispose);
    container.read(explorationProvider.notifier).markCompleted(0xF0);
    // Test the wired action paths, not the read-aloud gate. (The gate has
    // its own dedicated tests / manual QA; the slice walks first-tap-acts.)
    container.read(readAloudGateEnabledProvider.notifier).set(false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CritMathApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Home map is rendered. Tap the Mystic Sanctuary region.
    expect(find.text('Mystical Island'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Mystic Sanctuary'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (tester.any(find.byKey(const ValueKey('node-counting-parade')))) break;
    }

    expect(find.text('Mystic Sanctuary'), findsOneWidget);
    expect(find.byKey(const ValueKey('node-counting-parade')), findsOneWidget);
    // Tap the banner text — both the yellow node and the parchment banner
    // share the same onTap. Targeting the text is robust because the
    // outer widget's geometry spans both pieces with empty space between.
    await tester.tap(find.text('Counting Parade'));
    // Don't pumpAndSettle: lesson timers will block forever. Pump until the
    // LessonScreen's keeper-intro button shows up.
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(
        find.byKey(const ValueKey('lesson-keeper-start-button')),
      )) {
        break;
      }
    }

    // The lesson screen opens on the keeper intro. Tap "Let's count!" to
    // advance into the iShow demonstration.
    final lessonStart =
        find.byKey(const ValueKey('lesson-keeper-start-button'));
    expect(lessonStart, findsOneWidget);
    await tester.tap(lessonStart);
    await tester.pump();

    // Walk the iShow timeline: 22s total, skip available after 15s,
    // Continue button enables at 22s.
    await tester.pump(const Duration(seconds: 22));

    final continueArrow = find.byKey(const ValueKey('lesson-continue-arrow'));
    expect(continueArrow, findsOneWidget);
    await tester.tap(continueArrow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // We-Try: the demonstration is over and it is her turn. The lesson asks
    // her to touch two fawns, answers each touch, finishes the count itself
    // and hands off. This used to go straight from the Continue arrow to the
    // round, because nothing ran the phase.
    //
    // Walked here rather than skipped, because a slice test that steps over
    // the middle third of the lesson is not a slice of the thing a child
    // plays.
    final weTry = find.byKey(const ValueKey('we-try-layer'));
    expect(
      weTry,
      findsOneWidget,
      reason: 'the lesson handed straight to the round with no practice beat',
    );
    // Walk the whole phase rather than a fixed number of touches. This used
    // to tap exactly twice, which was not a choice - it was how many the
    // lesson let her have before finishing the count for her. Every countable
    // is hers now, so the loop is "keep answering until nothing is asked",
    // bounded only against a gate that never closes.
    for (var touch = 0; touch < 8; touch++) {
      var opened = false;
      for (var i = 0; i < 60; i++) {
        if (find
            .byKey(const ValueKey('we-try-gate-open'))
            .evaluate()
            .isNotEmpty) {
          opened = true;
          break;
        }
        // Stop the moment the phase is over rather than waiting out the poll.
        // The round opens on a species card that dismisses itself after a few
        // seconds, so fifteen spare seconds here are enough to miss it - which
        // reads as the round never starting.
        if (weTry.evaluate().isEmpty) break;
        await tester.pump(const Duration(milliseconds: 250));
      }
      if (!opened) break;
      await tester.tapAt(tester.getCenter(weTry));
      await tester.pump(const Duration(milliseconds: 300));
    }
    // Run the closing lines out; the phase ends itself and navigates.
    // pumpAndSettle would hang on the arrow's infinite wiggle/glow
    // controllers, so pump in chunks.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find
          .byKey(const ValueKey('parade-species-card'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 500));

    // Every round opens with a card naming its creature. Tap it away — the
    // card advances itself after a few seconds, but waiting on that would make
    // this a test about a timer.
    final firstCard = find.byKey(const ValueKey('parade-species-card'));
    expect(firstCard, findsOneWidget);
    await tester.tapAt(tester.getCenter(firstCard));
    await tester.pump();

    // The round skips the keeper intro on lesson hand-off and starts at the
    // first sequence entry — 3 fawns. Progress bar is mounted at 0/8.
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.byType(ProgressBarToReward), findsOneWidget);
    expect(
      tester
          .widget<ProgressBarToReward>(find.byType(ProgressBarToReward))
          .progress,
      0.0,
    );
    // The next-arrow Done button only appears once every creature is tapped.
    expect(find.byKey(const ValueKey('parade-done-arrow')), findsNothing);

    // Tap each of the three fawns.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(ValueKey('fawn-$i')));
      await tester.pump();
    }
    expect(find.text('3 / 3'), findsOneWidget);

    // Tap the wiggling Done arrow → the keeper's aside slides in over the
    // still-visible meadow. It used to be a full-screen modal needing another
    // tap; it is now non-blocking and retires itself.
    final doneArrow = find.byKey(const ValueKey('parade-done-arrow'));
    expect(doneArrow, findsOneWidget);
    await tester.tap(doneArrow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The transition line is showing in the aside bubble. Asserted on the
    // cardinality half only: the species that comes NEXT is shuffled per
    // session by design, so naming it here would make the test depend on the
    // shuffle rather than on the behaviour under test.
    expect(find.textContaining('Three fawns!'), findsWidgets);
    // ...and it did NOT take over the screen: the meadow is still rendered
    // underneath, which is the whole point of the change.
    expect(find.byType(KeeperAside), findsOneWidget);

    // First round's mastery + coin payout already fired.
    final progressAfterRound1 = container.read(kidProgressProvider);
    expect(progressAfterRound1['K.CC.4a'], isNotNull);
    expect(
      progressAfterRound1['K.CC.4a']!.status,
      MasteryStatus.practicing,
    );
    expect(progressAfterRound1['K.CC.4a']!.currentStreak, 1);
    expect(container.read(walletProvider), 5);

    // Progress bar has advanced one notch — 1 of 5 rounds done. (Was 8; the
    // sub-mode was shortened to ~2.5 minutes of play. See kDefaultParadeCounts.)
    final barAfterRound1 =
        tester.widget<ProgressBarToReward>(find.byType(ProgressBarToReward));
    expect(barAfterRound1.progress, closeTo(1 / 5, 1e-9));
    expect(barAfterRound1.celebrate, isFalse);

    // No tap needed any more: the aside holds for its reading time, slides
    // out, and advances to round 2 (4 gryphons) on its own. Explicit pumps
    // rather than pumpAndSettle — the Buddy's breathing loop never settles.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    // Round 2 wants 5, per the authored counts curve [3, 5, 4, 7, 6] — which
    // deliberately zig-zags rather than climbing, so difficulty never reads as
    // a staircase to a five-year-old. The count badge is legible behind the
    // dimmed species card, which is the point of showing the meadow through
    // it rather than replacing the screen.
    expect(find.text('0 / 5'), findsOneWidget);

    // Round 2 opens with its own card, naming whichever creature the shuffle
    // put here. Tapped away rather than waited out, so the runner is left with
    // no pending timer when the tree comes down.
    final card = find.byKey(const ValueKey('parade-species-card'));
    expect(card, findsOneWidget, reason: 'every round names its creature');
    await tester.tapAt(tester.getCenter(card));
    await tester.pump();

    // Tear the screen down inside the test. The parade legitimately keeps
    // several timers running while it is on screen — the hint ladder, the
    // counted-creature exits — and the framework fails any test whose tree is
    // disposed with one outstanding. Unmounting here runs the runner's own
    // dispose, which is what cancels them; the pump first lets the Buddy's
    // container-scoped reaction settle, since that one outlives the widget.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
