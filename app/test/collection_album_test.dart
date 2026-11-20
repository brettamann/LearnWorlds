// The album's spoken names.
//
// The screen is built for a pre-reader and so carries almost no text: a found
// card is a sprite, an unfound one is a black silhouette, and the name under a
// found card is the one thing on screen she cannot read. Tapping is the only
// way she can get at it, which makes this wiring the whole point of the screen
// rather than a nicety.
//
// The silhouette case is tested for the same reason wrong answers are: a tap
// that produces nothing is indistinguishable from a frozen app.

import 'package:critmath/data/creature_card_catalog.dart';
import 'package:critmath/engines/narration/narration_line.dart';
import 'package:critmath/engines/narration/narration_player.dart';
import 'package:critmath/providers/collection_provider.dart';
import 'package:critmath/ui/screens/collection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpAlbum(
    WidgetTester tester, {
    Set<String> found = const <String>{},
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(cardCollectionProvider.notifier).hydrate(found);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CollectionScreen()),
      ),
    );
    return container;
  }

  testWidgets('tapping a found card says its name', (tester) async {
    final container = await pumpAlbum(tester, found: {'creature-card-fawn'});

    await tester.tap(find.byKey(const ValueKey('card-creature-card-fawn')));
    await tester.pump();

    final spoken = container.read(narrationPlayerProvider);
    expect(spoken, isA<NarrationLine>());
    expect(spoken!.text, 'Fawn.');
  });

  testWidgets('tapping a silhouette answers rather than doing nothing',
      (tester) async {
    final container = await pumpAlbum(tester);

    await tester.tap(find.byKey(const ValueKey('card-creature-card-fawn')));
    await tester.pump();

    expect(container.read(narrationPlayerProvider)?.text, kCardNotFoundLine);
  });

  testWidgets('the Cloud Unicorn has a slot even before it is earned',
      (tester) async {
    // The gap is the content: a rare she has never seen still has to be on
    // screen as a silhouette, or there is nothing to want.
    await pumpAlbum(tester);
    expect(
      find.byKey(const ValueKey('card-$kTensParadeChallengeCardId')),
      findsOneWidget,
    );
  });

  test('every card has a distinct spoken name', () {
    // Two cards sharing a name would share a clip key, so one of them would
    // silently borrow the other's recording.
    final lines = kCreatureCards.map(cardFoundLine).toSet();
    expect(lines, hasLength(kCreatureCards.length));
  });
}
