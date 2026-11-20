// The Counting Parade sub-modes on SanctuaryRoundShell: the behaviour each
// one kept, and the bugs the hand-copied lifecycles had.

import 'package:critmath/data/count_forward_from_n_rounds.dart';
import 'package:critmath/data/parade_species.dart';
import 'package:critmath/engines/narration/narration_cue_log.dart';
import 'package:critmath/engines/narration/narration_player.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:critmath/ui/widgets/count_forward_from_n_runner.dart';
import 'package:critmath/ui/widgets/count_on_by_ones_runner.dart';
import 'package:critmath/ui/widgets/count_out_n_runner.dart';
import 'package:critmath/ui/widgets/counting_parade_runner.dart';
import 'package:critmath/ui/widgets/keeper_aside.dart';
import 'package:critmath/ui/widgets/keeper_intro_overlay.dart';
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
}
