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
import 'package:critmath/providers/wallet_provider.dart';
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
    // pumpAndSettle would hang on the arrow's infinite wiggle/glow controllers;
    // pump in chunks long enough for navigation + the post-frame intro
    // callback + go_router's transition animation (~300ms).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // The round skips the keeper intro on lesson hand-off and starts at the
    // first sequence entry — 3 fawns. Progress bar is mounted at 0/8.
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.byType(ProgressBarToReward), findsOneWidget);
    expect(
      tester.widget<ProgressBarToReward>(find.byType(ProgressBarToReward))
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

    // Tap the wiggling Done arrow → keeper interstitial appears.
    final doneArrow = find.byKey(const ValueKey('parade-done-arrow'));
    expect(doneArrow, findsOneWidget);
    await tester.tap(doneArrow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Interstitial keeper appears with the gryphon transition line. The
    // line shows in both the speech bubble and the caption overlay, so allow
    // for at least one match.
    expect(
      find.text('Great! All three fawns. Now the gryphon babies.'),
      findsWidgets,
    );

    // First round's mastery + coin payout already fired.
    final progressAfterRound1 = container.read(kidProgressProvider);
    expect(progressAfterRound1['K.CC.4a'], isNotNull);
    expect(
      progressAfterRound1['K.CC.4a']!.status,
      MasteryStatus.practicing,
    );
    expect(progressAfterRound1['K.CC.4a']!.currentStreak, 1);
    expect(container.read(walletProvider), 5);

    // Progress bar has advanced one notch — 1 of 8 rounds done.
    final barAfterRound1 = tester
        .widget<ProgressBarToReward>(find.byType(ProgressBarToReward));
    expect(barAfterRound1.progress, closeTo(1 / 8, 1e-9));
    expect(barAfterRound1.celebrate, isFalse);

    // Tap the interstitial Continue → next round (4 gryphons).
    await tester.tap(find.byKey(const ValueKey('parade-interstitial-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('0 / 4'), findsOneWidget);
  });
}
