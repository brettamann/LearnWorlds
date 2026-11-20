// The beat at the end of a sub-mode.
//
// It is the one blocking celebration `activity-progress-bar.md` asks for, it
// fires every two or three minutes, and it was a Material `Icons.celebration`
// glyph over the words "Nicely counted!" at 32 point, in silence. Three things
// wrong with that and they are the same thing: it said "counted" at the end of
// a sorting round and a hide-and-seek round; the words were the only content
// and they were words; and it made no sound, so the payoff of every sub-mode
// was a mystery box in front of a child who cannot read.
//
// It shows the egg now, and that is not decoration. `RewardOverlay` plays the
// advancement fanfare but it lives on the Sanctuary map, and this sheet
// usually routes straight into the next sub-mode without passing it. Since the
// track was retuned to advance once per cleared sub-mode, the game's one
// long-cycle reward had been moving after every sitting with almost nobody
// there to see it.

import 'package:critmath/data/button_labels.dart';
import 'package:critmath/data/warm_lines.dart';
import 'package:critmath/models/reward_track.dart';
import 'package:critmath/ui/screens/activity_screen.dart';
import 'package:critmath/ui/widgets/glitter_burst.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpSheet(
    WidgetTester tester, {
    required RewardStage? stage,
    required String line,
    required bool celebrate,
  }) async {
    useViewSize(tester, const Size(900, 900));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RoundCompleteSheet(
              stage: stage,
              line: line,
              celebrate: celebrate,
              arrowLabel: kLabelNextBang,
              idleHintText: 'Tap the arrow to keep going!',
              onNext: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('shows the egg at the stage it has just reached', (tester) async {
    final stage = kMysteryEggTrack.stageByNumber(3);
    await pumpSheet(tester, stage: stage, line: stage.message, celebrate: true);

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == stage.spriteAsset,
      ),
      findsOneWidget,
      reason: 'the sheet is not showing the egg she just moved',
    );
    // The words on screen are the words being spoken. They used to be
    // "Nicely counted!" whatever she had actually been doing.
    expect(find.text(stage.message), findsOneWidget);
    expect(find.text('Nicely counted!'), findsNothing);
  });

  testWidgets('bursts only when this sitting is what moved it', (tester) async {
    final stage = kMysteryEggTrack.stageByNumber(2);

    await pumpSheet(tester, stage: stage, line: stage.message, celebrate: true);
    expect(find.byType(GlitterBurst), findsOneWidget);

    // A replay of a sub-mode she has already cleared does not advance the
    // track — `markCompletionEvent` is keyed and deduped — so the egg is
    // still worth showing and the fanfare is not. A burst every time would
    // stop meaning "something happened".
    await pumpSheet(
      tester,
      stage: stage,
      line: stage.message,
      celebrate: false,
    );
    expect(find.byType(GlitterBurst), findsNothing);
  });

  testWidgets('falls back to something rather than nothing', (tester) async {
    // Unreachable from a normal save — the first cleared sub-mode is what
    // hands the egg over — but the whole content of this sheet is the egg,
    // so a save without one must not land on a blank card.
    await pumpSheet(
      tester,
      stage: null,
      line: kRoundCompleteFallbackLine,
      celebrate: false,
    );
    expect(find.text(kRoundCompleteFallbackLine), findsOneWidget);
    expect(find.byIcon(Icons.celebration), findsOneWidget);
  });

  testWidgets('and the way onward is the arrow, as everywhere else',
      (tester) async {
    var tapped = false;
    useViewSize(tester, const Size(900, 900));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RoundCompleteSheet(
              stage: kMysteryEggTrack.stageByNumber(1),
              line: kMysteryEggTrack.stageByNumber(1).message,
              celebrate: false,
              arrowLabel: kLabelSanctuary,
              idleHintText: 'Tap the arrow to head back to the Sanctuary!',
              onNext: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(
      find.byKey(const ValueKey('round-complete-next')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(tapped, isTrue);
  });
}
