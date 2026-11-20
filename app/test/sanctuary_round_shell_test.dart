// The shell's extension points: how long the celebration holds, an extra
// concept graded mid-round, ungraded visits, and custom intro / finale.

import 'package:critmath/engines/mastery/round_outcome.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:critmath/ui/widgets/keeper_aside.dart';
import 'package:critmath/ui/widgets/sanctuary_round_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

Widget _shell({
  int rounds = 2,
  Duration hold = const Duration(milliseconds: 1400),
  bool gradeRounds = true,
  Widget Function(BuildContext, VoidCallback)? intro,
  Widget Function(BuildContext, VoidCallback)? finale,
  VoidCallback? onFinale,
  VoidCallback? onDone,
}) =>
    SanctuaryRoundShell(
      activityId: 'test',
      roundCount: rounds,
      conceptIdFor: (_) => 'K.T.1',
      introLine: 'Hello.',
      keeperLineFor: (_) => 'Next one.',
      finalLine: 'All done.',
      background: const ColoredBox(color: Colors.green),
      skipIntro: intro == null,
      celebrationHold: hold,
      gradeRounds: gradeRounds,
      introBuilder: intro,
      finaleBuilder: finale,
      onFinale: onFinale,
      onSequenceComplete: onDone ?? () {},
      showBuddy: false,
      roundBuilder: (context, c) => Column(
        children: [
          TextButton(
            key: ValueKey('finish-${c.index}'),
            onPressed: () => c.finish(RoundResult.success),
            child: const Text('finish'),
          ),
          TextButton(
            key: ValueKey('extra-${c.index}'),
            onPressed: () => c.grade('K.T.2', RoundResult.success),
            child: const Text('extra'),
          ),
        ],
      ),
    );

Future<ProviderContainer> _pump(WidgetTester tester, Widget shell) async {
  useViewSize(tester);
  final container = testContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: shell)),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the keeper speaks only after the celebration hold',
      (tester) async {
    await _pump(tester, _shell(hold: const Duration(milliseconds: 1000)));
    await tester.tap(find.byKey(const ValueKey('finish-0')));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(KeeperAside), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(KeeperAside), findsOneWidget);
    await unmountAndDrain(tester);
  });

  testWidgets('a graded round pays, an ungraded visit does not',
      (tester) async {
    var c = await _pump(tester, _shell());
    await tester.tap(find.byKey(const ValueKey('finish-0')));
    await tester.pump();
    expect(c.read(walletProvider), coinsFor(RoundResult.success));
    await unmountAndDrain(tester);

    c = await _pump(tester, _shell(gradeRounds: false));
    await tester.tap(find.byKey(const ValueKey('finish-0')));
    await tester.pump();
    expect(c.read(walletProvider), 0);
    await unmountAndDrain(tester);
  });

  testWidgets('grade() grades a second concept in the same round',
      (tester) async {
    final c = await _pump(tester, _shell());
    await tester.tap(find.byKey(const ValueKey('extra-0')));
    await tester.tap(find.byKey(const ValueKey('finish-0')));
    await tester.pump();
    expect(c.read(walletProvider), 2 * coinsFor(RoundResult.success));
    await unmountAndDrain(tester);
  });

  testWidgets('a custom intro starts the visit when it says so',
      (tester) async {
    await _pump(
      tester,
      _shell(
        intro: (context, start) => TextButton(
          key: const ValueKey('demo-done'),
          onPressed: start,
          child: const Text('demo'),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('finish-0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('demo-done')));
    await tester.pump();
    expect(find.byKey(const ValueKey('finish-0')), findsOneWidget);
    await unmountAndDrain(tester);
  });

  testWidgets('a custom finale replaces the overlay and fires onFinale once',
      (tester) async {
    var finales = 0;
    var done = false;
    await _pump(
      tester,
      _shell(
        rounds: 1,
        onFinale: () => finales += 1,
        onDone: () => done = true,
        finale: (context, finish) => TextButton(
          key: const ValueKey('custom-finale'),
          onPressed: finish,
          child: const Text('bye'),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('finish-0')));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byKey(const ValueKey('custom-finale')), findsOneWidget);
    expect(finales, 1);
    await tester.tap(find.byKey(const ValueKey('custom-finale')));
    expect(done, isTrue);
    await unmountAndDrain(tester);
  });
}
