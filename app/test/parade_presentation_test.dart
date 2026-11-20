// Counting Parade — the four things a pre-reader was not getting.
//
// All four came out of watching a five-year-old play, and all four are the
// same underlying problem: the game was showing her things it never told her,
// and putting its one friendly character where she wasn't looking.
//
//   1. Buddy sat at 150px in the bottom-left corner and read as part of the
//      frame rather than a character in the meadow.
//   2. When Buddy "helped find" a creature it stood in that corner and
//      gestured. Nothing connected the help to the creature.
//   3. Nothing ever named what she was counting. She would count fawns for a
//      round and never learn they were fawns.
//   4. The earned-card overlay showed a name in text and took itself away
//      after five seconds, so the whole content of the reward was a picture
//      with no name.

import 'package:critmath/data/creature_card_catalog.dart';
import 'package:critmath/data/parade_species.dart';
import 'package:critmath/engines/narration/narration_cue_log.dart';
import 'package:critmath/providers/collection_provider.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/ui/widgets/buddy_companion.dart';
import 'package:critmath/ui/widgets/caption_overlay.dart';
import 'package:critmath/ui/widgets/card_reveal_overlay.dart';
import 'package:critmath/ui/widgets/counting_parade_runner.dart';
import 'package:critmath/ui/widgets/reveal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Finder card() => find.byKey(const ValueKey('parade-species-card'));

  Future<ProviderContainer> pumpParade(WidgetTester tester) async {
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
              roundParameters: const <String, dynamic>{
                'counts': <int>[3, 5],
                'species': 'fawn',
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  /// Ends the test cleanly.
  ///
  /// Unmount first: the runner keeps real timers while it is on screen (the
  /// hint ladder, the counted-creature exits, the species card) and its own
  /// dispose is what cancels them. Then pump, because the Buddy's reaction
  /// settle is container-scoped and outlives the widget that triggered it.
  Future<void> tearDownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  }

  group('the card that names the creature', () {
    testWidgets('opens the round, naming what she is about to count',
        (tester) async {
      await pumpParade(tester);
      expect(card(), findsOneWidget);
      expect(find.text('Fawn'), findsOneWidget);
      expect(find.text("Look who's next!"), findsOneWidget);
      await tearDownTree(tester);
    });

    testWidgets('the meadow stays visible behind it', (tester) async {
      // Deliberate: the card names something she can already see, rather than
      // naming something and then producing it.
      await pumpParade(tester);
      expect(find.text('0 / 3'), findsOneWidget);
      expect(find.byKey(const ValueKey('fawn-0')), findsOneWidget);
      await tearDownTree(tester);
    });

    testWidgets('counting cannot start until it is gone', (tester) async {
      await pumpParade(tester);
      await tester
          .tapAt(tester.getCenter(find.byKey(const ValueKey('fawn-0'))));
      await tester.pump();
      expect(
        find.text('0 / 3'),
        findsOneWidget,
        reason: 'a tap through the card would count a creature she has not '
            'been introduced to yet',
      );
      await tearDownTree(tester);
    });

    testWidgets('a tap anywhere dismisses it', (tester) async {
      await pumpParade(tester);
      await tester.tapAt(tester.getCenter(card()));
      await tester.pump();
      expect(card(), findsNothing);
      await tearDownTree(tester);
    });

    testWidgets('it advances on its own if she does nothing', (tester) async {
      // A card she has to dismiss five times a sitting would put back a chunk
      // of the stop-start rhythm the KeeperAside work removed.
      await pumpParade(tester);
      expect(card(), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(card(), findsNothing);
      await tearDownTree(tester);
    });
  });

  group('Buddy', () {
    testWidgets('stands in the meadow at a size worth noticing',
        (tester) async {
      await pumpParade(tester);
      final buddy = tester.widget<BuddyCompanion>(find.byType(BuddyCompanion));
      expect(
        buddy.size,
        greaterThan(150),
        reason: 'at 150 in a corner it read as part of the frame',
      );
      await tearDownTree(tester);
    });

    testWidgets('walks to the creature it is pointing at', (tester) async {
      await pumpParade(tester);
      await tester.tapAt(tester.getCenter(card()));
      await tester.pump();

      final home = tester.getTopLeft(find.byType(BuddyCompanion));

      // Stand still. The ladder highlights at 5s and sends Buddy at 10s.
      await tester.pump(const Duration(seconds: 11));
      // Let the walk animate.
      await tester.pump(const Duration(milliseconds: 900));

      final visiting = tester.getTopLeft(find.byType(BuddyCompanion));
      expect(
        visiting,
        isNot(home),
        reason: 'the hint is Buddy going to the creature. A child who cannot '
            'read the spoken nudge can still see where her friend went.',
      );

      final creature = tester.getCenter(find.byKey(const ValueKey('fawn-0')));
      final buddyBox = tester.getRect(find.byType(BuddyCompanion));
      expect(
        buddyBox.inflate(24).contains(creature),
        isTrue,
        reason: 'Buddy pointing at empty grass is worse than no hint at all',
      );

      await tearDownTree(tester);
    });

    testWidgets('goes home once she taps something', (tester) async {
      await pumpParade(tester);
      await tester.tapAt(tester.getCenter(card()));
      await tester.pump();
      final home = tester.getTopLeft(find.byType(BuddyCompanion));

      await tester.pump(const Duration(seconds: 11));
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.getTopLeft(find.byType(BuddyCompanion)), isNot(home));

      // Help parked over a creature after she has moved on is in the way.
      await tester
          .tapAt(tester.getCenter(find.byKey(const ValueKey('fawn-0'))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.getTopLeft(find.byType(BuddyCompanion)), home);

      await tearDownTree(tester);
    });
  });

  group('the words on the cards', () {
    test('every species gets a line naming it', () {
      for (final species in kParadeSpecies) {
        final line = paradeSpeciesIntroLine(species);
        expect(line, contains(species.singular));
        expect(line, endsWith('!'));
      }
    });

    test('the article agrees with the name', () {
      // Nothing in the cast starts with a vowel today. The check is here
      // because the first one that does would otherwise ship as "a owl" in a
      // *recorded* clip — and the wording is the clip key, so fixing it later
      // would orphan the recording and drop the line back to the synth voice.
      expect(paradeArticle('owl'), 'an');
      expect(paradeArticle('fawn'), 'a');
      expect(paradeArticle(''), 'a');
    });

    test('the title on the card is the name in the spoken line', () {
      for (final species in kParadeSpecies) {
        expect(
          paradeSpeciesIntroLine(species).toLowerCase(),
          contains(paradeSpeciesTitle(species).toLowerCase()),
        );
      }
    });
  });

  group('RevealCardFace', () {
    testWidgets('shows the prompt when one is given, and not otherwise',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RevealCardFace(
              eyebrow: 'A new friend!',
              spriteAsset: 'assets/buddy/mouths/v1.png',
              title: 'Cloud Unicorn',
              accent: Color(0xFFE0A53C),
              footer: TapAnywherePrompt(accent: Color(0xFFE0A53C)),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Cloud Unicorn'), findsOneWidget);
      expect(find.text('Tap anywhere'), findsOneWidget);
      expect(find.byIcon(Icons.touch_app), findsOneWidget);
    });
  });

  group('the new-friend card', () {
    // It used to show a name in text a pre-reader cannot read and then take
    // itself away after five seconds, so the entire content of the reward was
    // a picture she got no name for and might not have finished looking at.

    Future<ProviderContainer> pumpReveal(WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Stack(children: [CardRevealOverlay()])),
          ),
        ),
      );
      container
          .read(pendingCardRevealProvider.notifier)
          .show(kCreatureCards.first.id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      return container;
    }

    testWidgets('says the name out loud', (tester) async {
      final container = await pumpReveal(tester);
      expect(
        container.read(narrationCueLogProvider).keys,
        contains(cardRevealLine(kCreatureCards.first)),
        reason: 'the name in text is the one thing she cannot get at',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 40));
    });

    testWidgets('shows the tap prompt and waits to be dismissed',
        (tester) async {
      await pumpReveal(tester);
      expect(find.text(kCreatureCards.first.displayName), findsOneWidget);
      expect(find.text('Tap anywhere'), findsOneWidget);

      // The old five-second auto-dismiss is gone; she decides when she is
      // done looking.
      await tester.pump(const Duration(seconds: 8));
      expect(find.text('Tap anywhere'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 40));
    });

    testWidgets('nudges her in the only channel she has', (tester) async {
      final container = await pumpReveal(tester);
      expect(
        container.read(narrationCueLogProvider).keys,
        isNot(contains(kCardTapToContinueLine)),
        reason: 'a child who taps straight away never hears it',
      );
      await tester.pump(const Duration(seconds: 8));
      expect(
        container.read(narrationCueLogProvider).keys,
        contains(kCardTapToContinueLine),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 40));
    });

    testWidgets('a tap anywhere puts it away', (tester) async {
      final container = await pumpReveal(tester);
      await tester.tapAt(const Offset(30, 30));
      await tester.pump();
      expect(container.read(pendingCardRevealProvider), isNull);
      expect(find.text('Tap anywhere'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 40));
    });

    testWidgets('gives up waiting rather than stranding her', (tester) async {
      // A five-year-old who wanders off mid-reveal must not come back to a
      // game that is stuck. That hazard did not go away when the card got
      // more patient.
      final container = await pumpReveal(tester);
      await tester.pump(const Duration(seconds: 31));
      expect(container.read(pendingCardRevealProvider), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 40));
    });
  });

  group('Buddy after a demonstration', () {
    testWidgets('walks back rather than standing over what it counted',
        (tester) async {
      // The demonstration is the one hint the child does not answer, so
      // nothing else was sending Buddy home and it stood over the creature it
      // had just counted for the rest of the round.
      await pumpParade(tester);
      await tester.tapAt(tester.getCenter(card()));
      await tester.pump();
      final home = tester.getTopLeft(find.byType(BuddyCompanion));

      // point at 10s, demonstrate at 15s.
      await tester.pump(const Duration(seconds: 16));
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        tester.getTopLeft(find.byType(BuddyCompanion)),
        isNot(home),
        reason: 'it should be over the creature it just tapped',
      );
      expect(find.text('1 / 3'), findsOneWidget);

      // It lingers a beat so she sees the touch, then leaves.
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.getTopLeft(find.byType(BuddyCompanion)), home);

      await tearDownTree(tester);
    });

    testWidgets('rests clear of the caption bar', (tester) async {
      // It used to sit at the very bottom of the meadow with the
      // semi-transparent black band lying across it, so the one character in
      // the scene spent every round behind a subtitle.
      await pumpParade(tester);
      await tester.tapAt(tester.getCenter(card()));
      await tester.pump();

      final field = tester.getRect(find.byType(CountingParadeRunner));
      final buddy = tester.getRect(find.byType(BuddyCompanion));
      expect(
        buddy.bottom,
        lessThanOrEqualTo(field.bottom - kCaptionBandClearance + 1),
        reason: 'Buddy overlaps the caption band',
      );
      await tearDownTree(tester);
    });
  });
}
