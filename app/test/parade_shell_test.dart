// The Counting Parade sub-modes on SanctuaryRoundShell: the behaviour each
// one kept, and the bugs the hand-copied lifecycles had.

import 'package:critmath/data/count_forward_from_n_rounds.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:critmath/ui/widgets/count_forward_from_n_runner.dart';
import 'package:critmath/ui/widgets/count_on_by_ones_runner.dart';
import 'package:critmath/ui/widgets/count_out_n_runner.dart';
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
}
