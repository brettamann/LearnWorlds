// Telling a pre-reader when it is her turn.
//
// Two of the Counting Parade sub-modes open on a board that is already fully
// drawn, with some creatures counted and some waiting to be tapped. Both used
// to say so in one long sentence, spoken once, over the top of the finished
// picture — and the only thing distinguishing the two groups was a line of
// text printed between them ("new arrivals", "count by ones"). To a child who
// cannot read, that is nine identical fawns and no instruction.
//
// So both stage the opening. The counted row stands alone and bright while the
// narrator names it, then the newcomers walk on from the right under the go
// signal and the row behind them dims. The handover is carried by the picture
// and the voice at the same moment, and input opens exactly when they land.
//
// This runs the same four assertions against both runners, because the failure
// they were written for is one failure and it would come back the same way in
// either.

import 'package:critmath/activities/counting_parade/count_forward_from_n_runner.dart';
import 'package:critmath/activities/counting_parade/count_on_by_ones_runner.dart';
import 'package:critmath/data/count_forward_from_n_rounds.dart';
import 'package:critmath/data/count_on_by_ones_rounds.dart';
import 'package:critmath/data/number_words.dart';
import 'package:critmath/engines/narration/narration_cue_log.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

/// One sub-mode's staged opening, described in the terms the assertions need.
class _Opening {
  const _Opening({
    required this.name,
    required this.runner,
    required this.arrivalKeyPrefix,
    required this.rowLabel,
    required this.countedMarker,
    required this.dimmedTo,
    required this.badgeAtRest,
    required this.badgeAfterOneTap,
    required this.spokenBeats,
  });

  final String name;
  final Widget runner;

  /// Key on the tappable newcomer, minus its index.
  final String arrivalKeyPrefix;

  /// The printed label over the row of newcomers — the thing that used to be
  /// the only cue, and is now decoration.
  final String rowLabel;

  /// Text that only appears on the already-counted side of the board.
  final String countedMarker;

  /// What the counted side fades to once the newcomers land.
  final double dimmedTo;

  final String badgeAtRest;
  final String badgeAfterOneTap;

  /// The two lines of the opening, in order.
  final List<String> spokenBeats;
}

final _cases = <_Opening>[
  () {
    final round = kCountForwardRounds.first;
    return _Opening(
      name: 'count forward from n',
      runner: CountForwardFromNRunner(
        skipIntro: true,
        onSequenceComplete: () {},
      ),
      arrivalKeyPrefix: 'count-forward-r0-arrival-',
      rowLabel: '— new arrivals —',
      // The faint numeral over the first already-counted creature.
      countedMarker: '1',
      dimmedTo: 0.45,
      badgeAtRest: '${round.startN} / ${round.finalCount}',
      badgeAfterOneTap: '${round.startN + 1} / ${round.finalCount}',
      spokenBeats: <String>[
        countForwardAlreadyCountedLine(round),
        countForwardPrompt(round),
      ],
    );
  }(),
  () {
    final round = kCountOnByOnesRounds.first;
    return _Opening(
      name: 'count on by ones',
      runner: CountOnByOnesRunner(skipIntro: true, onSequenceComplete: () {}),
      arrivalKeyPrefix: 'count-on-ones-r0-arrival-',
      rowLabel: '— count by ones —',
      // The label on the filled cluster-of-ten card. Not the badge, which
      // reads "10 / 20".
      countedMarker: '${round.startN}',
      dimmedTo: 0.6,
      badgeAtRest: '${round.startN} / ${round.finalCount}',
      badgeAfterOneTap: '${round.startN + 1} / ${round.finalCount}',
      spokenBeats: <String>[
        countOnByOnesAlreadyCountedLine(round),
        countOnByOnesPrompt(round),
      ],
    );
  }(),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Long enough for both runners' pause-then-walk-on. Nothing else moves
  /// after it, so overshooting is harmless.
  const opening = Duration(milliseconds: 2000);

  Future<ProviderContainer> pump(WidgetTester tester, _Opening c) async {
    useViewSize(tester);

    final container = ProviderContainer(
      overrides: [sessionIdProvider.overrideWithValue('test-session')],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: c.runner)),
      ),
    );
    await tester.pump();
    return container;
  }

  /// Unmount first — the runner's own dispose is what cancels the arrival and
  /// hint timers — then pump for the container-scoped Buddy reaction settle.
  Future<void> tearDownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  }

  /// The tap handler on one newcomer. Null while input is locked, which is a
  /// steadier read than hit-testing a sprite that is currently off-stage.
  VoidCallback? arrivalTap(WidgetTester tester, _Opening c, int index) {
    return tester
        .widget<GestureDetector>(
          find
              .descendant(
                of: find.byKey(ValueKey('${c.arrivalKeyPrefix}$index')),
                matching: find.byType(GestureDetector),
              )
              .first,
        )
        .onTap;
  }

  double opacityAbove(WidgetTester tester, Finder child) {
    return tester
        .widget<AnimatedOpacity>(
          find
              .ancestor(of: child, matching: find.byType(AnimatedOpacity))
              .first,
        )
        .opacity;
  }

  for (final c in _cases) {
    group(c.name, () {
      testWidgets(
        'the newcomers are off-stage while the counted row is named',
        (tester) async {
          await pump(tester, c);

          expect(find.text(c.badgeAtRest), findsOneWidget);
          // Full strength: this is what is being talked about right now.
          expect(opacityAbove(tester, find.text(c.countedMarker)), 1.0);
          expect(
            opacityAbove(tester, find.text(c.rowLabel)),
            0.0,
            reason: 'the label belongs to a row that has not walked on yet',
          );
          expect(
            arrivalTap(tester, c, 0),
            isNull,
            reason:
                'tapping before the go signal would teach her that the game '
                'ignores her',
          );

          await tester.pump(opening);
          // One more frame for the rebuild. Not pumpAndSettle: the Buddy
          // breathes on a repeating controller, so nothing here ever settles.
          await tester.pump();

          expect(opacityAbove(tester, find.text(c.countedMarker)), c.dimmedTo);
          expect(opacityAbove(tester, find.text(c.rowLabel)), 1.0);
          expect(arrivalTap(tester, c, 0), isNotNull);

          await tearDownTree(tester);
        },
      );

      testWidgets('both halves of the opening are spoken, in order', (
        tester,
      ) async {
        final container = await pump(tester, c);
        // Past the opening and past the first line finishing. The narration
        // queue drains on its own clock, not the arrival timers: input opens
        // when the creatures land, and the go signal lands over the top of
        // that rather than holding her still until the sentence is over.
        await tester.pump(opening);
        await tester.pump(const Duration(seconds: 4));

        final spoken = container
            .read(narrationCueLogProvider)
            .values
            .map((cue) => cue.text)
            .toList();

        expect(
          spoken,
          containsAllInOrder(c.spokenBeats.map(narrationTextNormalize)),
          reason:
              'the second line is enqueued behind the first rather than '
              'cutting it off — see NarrationPlayer.enqueue',
        );

        await tearDownTree(tester);
      });

      testWidgets('a tap once they land counts on from N', (tester) async {
        await pump(tester, c);
        await tester.pump(opening);
        await tester.pump();

        arrivalTap(tester, c, 0)!();
        await tester.pump();

        // Counting on: the first newcomer is startN + 1, never one.
        expect(find.text(c.badgeAfterOneTap), findsOneWidget);

        await tearDownTree(tester);
      });
    });
  }

  test('count-forward does not name the number she has to say', () {
    // K.CC.2 is the skill of trusting a count you were told instead of
    // starting over at one. A prompt that says "start at four" does that for
    // her, so the go signal stops at "keep counting" and lets the ladder tone
    // and the spoken number on her first tap confirm it.
    for (final r in kCountForwardRounds) {
      expect(
        countForwardPrompt(r).toLowerCase(),
        isNot(contains(kSpelledCounts[r.startN + 1].toLowerCase())),
        reason: countForwardPrompt(r),
      );
    }
  });

  test('count-on-by-ones does name the decade it is heading for', () {
    // The opposite call, deliberately. Here the destination is the frame
    // rather than the answer: the skill is walking the ten steps between, and
    // hearing where they land is the point of K.CC.1.
    for (final r in kCountOnByOnesRounds) {
      expect(
        countOnByOnesPrompt(r).toLowerCase(),
        contains(kSpelledTens[r.finalCount ~/ 10].toLowerCase()),
        reason: countOnByOnesPrompt(r),
      );
    }
  });
}
