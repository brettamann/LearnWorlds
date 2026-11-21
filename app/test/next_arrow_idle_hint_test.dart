// The Continue arrow's idle nudge, and when it should stop.
//
// The nudge exists because a K-grader may not recognise a wiggling arrow as
// "the way forward". It fired every ten seconds forever, which is fine for the
// thirty seconds it was designed for and wrong after that: a child who has
// wandered off leaves a voice calling out to an empty room, on a loop, for as
// long as the tab is open. Five is where it gives up.
//
// The arrow keeps wiggling and glowing either way — whenever she does come
// back there is still something moving to aim at, it just isn't shouting.

import 'package:critmath/engines/narration/narration_line.dart';
import 'package:critmath/engines/narration/narration_player.dart';
import 'package:critmath/ui/common/next_arrow_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hint = 'Tap the arrow to continue!';

  Widget arrow(String text) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: NextArrowButton(
          idleHintEnabled: true,
          idleHintText: text,
          onPressed: () {},
          label: 'Continue',
        ),
      ),
    ),
  );

  /// Counts how many times [text] is actually spoken.
  ///
  /// The cue log dedupes by words, so it can only say whether a line was ever
  /// heard. Listening to the player catches every firing, because each nudge
  /// pushes a fresh line into state.
  ({ProviderContainer container, int Function() count}) watch(String text) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var fires = 0;
    container.listen<NarrationLine?>(narrationPlayerProvider, (_, next) {
      if (next?.text == text) fires++;
    });
    return (container: container, count: () => fires);
  }

  testWidgets('nudges a child who has gone quiet', (tester) async {
    final w = watch(hint);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: w.container, child: arrow(hint)),
    );
    await tester.pump();
    expect(w.count(), 0);
    await tester.pump(const Duration(seconds: 11));
    expect(w.count(), 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('gives up after five rather than calling out forever', (
    tester,
  ) async {
    final w = watch(hint);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: w.container, child: arrow(hint)),
    );
    await tester.pump();
    // Three minutes of standing still: eighteen nudges at the old cadence.
    await tester.pump(const Duration(seconds: 180));
    expect(w.count(), kMaxIdleHints);
    // And no timer is left running — which the framework's own pending-timer
    // check enforces the moment this test ends.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('starts over when the beat changes', (tester) async {
    // A button that survives from one beat to the next would otherwise inherit
    // a spent counter and never speak again.
    const second = 'You counted them all! Tap the arrow to keep going.';
    final w = watch(second);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: w.container, child: arrow(hint)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 180));
    expect(w.count(), 0);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: w.container, child: arrow(second)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    expect(
      w.count(),
      1,
      reason: 'a new line means she got here by doing something',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the arrow is ringed so it does not dissolve into the meadow', (
    tester,
  ) async {
    final w = watch(hint);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: w.container, child: arrow(hint)),
    );
    await tester.pump();
    final ringed = tester
        .widgetList<Material>(find.byType(Material))
        .where(
          (m) =>
              m.shape is CircleBorder &&
              (m.shape! as CircleBorder).side.width >= 3 &&
              (m.shape! as CircleBorder).side.color.a > 0.9,
        );
    expect(
      ringed,
      isNotEmpty,
      reason: 'amber on a bright yellow-green meadow needs a dark edge',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
