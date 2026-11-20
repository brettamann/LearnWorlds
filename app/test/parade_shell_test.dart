// The Counting Parade sub-modes on SanctuaryRoundShell: the behaviour each
// one kept, and the bugs the hand-copied lifecycles had.

import 'package:critmath/data/count_forward_from_n_rounds.dart';
import 'package:critmath/data/creature_card_catalog.dart';
import 'package:critmath/data/parade_species.dart';
import 'package:critmath/data/tens_parade_words.dart';
import 'package:critmath/engines/narration/narration_cue_log.dart';
import 'package:critmath/engines/narration/narration_player.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:critmath/providers/collection_provider.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:critmath/ui/widgets/caption_overlay.dart';
import 'package:critmath/ui/widgets/count_forward_from_n_runner.dart';
import 'package:critmath/ui/widgets/count_on_by_ones_runner.dart';
import 'package:critmath/ui/widgets/count_out_n_runner.dart';
import 'package:critmath/ui/widgets/counting_challenge_layer.dart';
import 'package:critmath/ui/widgets/counting_parade_runner.dart';
import 'package:critmath/ui/widgets/keeper_aside.dart';
import 'package:critmath/ui/widgets/keeper_intro_overlay.dart';
import 'package:critmath/ui/widgets/tens_parade_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

Future<ProviderContainer> _pump(WidgetTester tester, Widget runner) async {
  useViewSize(tester);
  final container = ProviderContainer(
    overrides: [sessionIdProvider.overrideWithValue('parade-shell')],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: runner)),
    ),
  );
  await tester.pump();
  return container;
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('count forward from n', () {
    testWidgets('Done grades the round once, and then goes away',
        (tester) async {
      // The arrow used to stay up through the celebration, and a second tap
      // resolved the round - and paid - a second time.
      final c = await _pump(
        tester,
        CountForwardFromNRunner(skipIntro: true, onSequenceComplete: () {}),
      );
      await tester.pump(const Duration(seconds: 2));
      final round = kCountForwardRounds.first;
      for (var i = 0; i < round.arrivalsCount; i++) {
        await _tapKey(tester, 'count-forward-r0-arrival-$i');
      }
      await _tapKey(tester, 'count-forward-done-arrow');
      expect(c.read(walletProvider), 5);
      expect(
        find.byKey(const ValueKey('count-forward-done-arrow')),
        findsNothing,
      );
      await unmountAndDrain(tester);
    });
  });

  group('count on by ones', () {
    testWidgets('the animated demo is the opening, and Start begins round one',
        (tester) async {
      await _pump(
        tester,
        CountOnByOnesRunner(onSequenceComplete: () {}),
      );
      expect(
        find.byType(KeeperIntroOverlay),
        findsNothing,
        reason: 'the demo stands in for the keeper intro',
      );
      // Ten counts, the fold, nine decades, the kick-off.
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await _tapKey(tester, 'count-on-ones-demo-start');
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.byKey(const ValueKey('count-on-ones-r0-arrival-0')),
        findsOneWidget,
      );
      await unmountAndDrain(tester);
    });
  });

  group('count out n', () {
    testWidgets('the drag demo plays once, after the intro', (tester) async {
      await _pump(tester, CountOutNRunner(onSequenceComplete: () {}));
      await _tapKey(tester, 'counting-parade-start-button');
      expect(
        find.byKey(const ValueKey('count-out-r0-pool-0')),
        findsNothing,
        reason: 'the demo is on the board before she can drag anything',
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byKey(const ValueKey('count-out-r0-pool-0')), findsOneWidget);
      await unmountAndDrain(tester);
    });

    testWidgets('a lesson hand-off goes straight to the board', (tester) async {
      await _pump(
        tester,
        CountOutNRunner(skipIntro: true, onSequenceComplete: () {}),
      );
      expect(find.byKey(const ValueKey('count-out-r0-pool-0')), findsOneWidget);
      await unmountAndDrain(tester);
    });
  });

  group('count the parade', () {
    Future<ProviderContainer> countRound(
      WidgetTester tester,
      List<int> counts,
    ) async {
      final c = await _pump(
        tester,
        CountingParadeRunner(
          skipIntro: true,
          onSequenceComplete: () {},
          roundParameters: <String, dynamic>{
            'counts': counts,
            'species': 'fawn',
          },
        ),
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('parade-species-card'))),
      );
      await tester.pump();
      for (var i = 0; i < counts.first; i++) {
        await _tapKey(tester, 'fawn-$i');
      }
      await _tapKey(tester, 'parade-done-arrow');
      return c;
    }

    testWidgets('the keeper waits for the last count instead of cutting it off',
        (tester) async {
      final c = await countRound(tester, const <int>[3, 5]);
      // No hold between rounds: the aside is up a frame later...
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump();
      expect(find.byType(KeeperAside), findsOneWidget);
      // ...and her line is queued behind "Three.", not spoken over it.
      expect(c.read(narrationPlayerProvider.notifier).queuedCount, 1);
      await unmountAndDrain(tester);
    });

    testWidgets('the last beat holds two seconds, then says "some coins"',
        (tester) async {
      // It used to announce rounds x 5 coins, whatever was actually paid.
      final c = await countRound(tester, const <int>[3]);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(
        find.byKey(const ValueKey('counting-parade-finale-next')),
        findsNothing,
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.byKey(const ValueKey('counting-parade-finale-next')),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));
      final said = c.read(narrationCueLogProvider).keys;
      expect(said, contains(narrationTextNormalize(kParadeRewardLine)));
      expect(said.where(RegExp(r'Here are \d+ coins').hasMatch), isEmpty);
      await unmountAndDrain(tester);
    });
  });

  group('tens parade', () {
    /// Taps every creature on screen until the challenge has its hundred.
    Future<void> pumpUntilSaid(
      WidgetTester tester,
      ProviderContainer c,
      String line,
    ) async {
      final key = narrationTextNormalize(line);
      for (var i = 0; i < 60; i++) {
        if (c.read(narrationCueLogProvider).keys.contains(key)) return;
        await tester.pump(const Duration(milliseconds: 250));
      }
      fail('never said: "$line"');
    }

    Future<void> countToAHundred(WidgetTester tester) async {
      for (var i = 0; i < 600; i++) {
        if (find
            .byKey(const ValueKey('tens-parade-repeat'))
            .evaluate()
            .isNotEmpty) {
          return;
        }
        final creatures = find.byWidgetPredicate((w) {
          final k = w.key;
          return k is ValueKey<String> &&
              k.value.startsWith('challenge-creature-');
        });
        for (final e in creatures.evaluate().toList()) {
          final box = e.renderObject;
          if (box is! RenderBox || !box.attached || !box.hasSize) continue;
          final at = box.localToGlobal(box.size.center(Offset.zero));
          if (at.dx < 0 || at.dx > kTabletSize.width) continue;
          await tester.tapAt(at);
        }
        await tester.pump(const Duration(milliseconds: 400));
      }
      fail('the challenge never reached its finale');
    }

    testWidgets('pays its bonus and card once per visit, not again on Again',
        (tester) async {
      final c = await _pump(
        tester,
        TensParadeRunner(skipIntro: true, onSequenceComplete: () {}),
      );
      await countToAHundred(tester);
      expect(c.read(walletProvider), kTensParadeRewardCoins);
      expect(
        c.read(cardCollectionProvider),
        contains(kTensParadeChallengeCardId),
      );
      // The reward line is queued behind "One hundred.", so wait for it to
      // be said rather than a fixed time: how long the line ahead takes
      // varies, and a fixed wait made this fail one run in three.
      await pumpUntilSaid(
        tester,
        c,
        tensParadeRewardLine(earnedCard: true),
      );

      await _tapKey(tester, 'tens-parade-repeat');
      await countToAHundred(tester);
      // ...and so promises nothing.
      await pumpUntilSaid(tester, c, kTensParadeRepeatLine);
      expect(
        c.read(walletProvider),
        kTensParadeRewardCoins,
        reason: 'a second run in the same visit pays nothing more',
      );
      await unmountAndDrain(tester);
    });

    testWidgets('the challenge stays clear of the caption band',
        (tester) async {
      // It used to hand-roll its frame and fill to the bottom of the window,
      // so creatures drifted through the strip under the subtitles.
      await _pump(
        tester,
        Stack(
          children: [
            Positioned.fill(
              child: TensParadeRunner(
                skipIntro: true,
                onSequenceComplete: () {},
              ),
            ),
            const CaptionOverlay(),
          ],
        ),
      );
      final layer = tester.getRect(find.byType(CountingChallengeLayer));
      expect(
        layer.bottom,
        lessThanOrEqualTo(kTabletSize.height - kCaptionBandClearance),
      );
      await unmountAndDrain(tester);
    });

    testWidgets('the demo creature drifts every frame', (tester) async {
      // Its position used to be read outside the AnimatedBuilder, so it sat
      // off-stage until something else rebuilt the layout.
      await _pump(
        tester,
        TensParadeRunner(onSequenceComplete: () {}),
      );
      final sprite = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == kParadeFawn.spriteAsset,
      );
      await tester.pump(const Duration(milliseconds: 500));
      final early = tester.getTopLeft(sprite);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.getTopLeft(sprite).dx, greaterThan(early.dx));
      await unmountAndDrain(tester);
    });
  });
}
