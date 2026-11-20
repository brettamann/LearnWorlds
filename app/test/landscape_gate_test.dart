// The game is landscape, and portrait has to say so.
//
// There is no way to enforce this on the platform it ships on.
// `SystemChrome.setPreferredOrientations` is a real lock on iOS and Android
// native and a no-op on web; the web app manifest's `orientation` field is
// honoured by Chrome on Android and ignored by iOS Safari, including for a
// page added to the home screen. On the iPad she will actually hold, asking is
// the only lock there is.

import 'package:critmath/ui/widgets/landscape_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/harness.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    useViewSize(tester, size);
    await tester.pumpWidget(
      const MaterialApp(
        home: LandscapeGate(
          child: Scaffold(body: Center(child: Text('the meadow'))),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('landscape gets the game', (tester) async {
    // iPad Air, the reference size the rest of the tests use.
    await pumpAt(tester, const Size(1180, 820));
    expect(find.text('the meadow'), findsOneWidget);
    expect(find.text('Turn me sideways to play'), findsNothing);
  });

  testWidgets('portrait gets the ask', (tester) async {
    await pumpAt(tester, const Size(820, 1180));
    expect(find.text('the meadow'), findsNothing);
    expect(find.byIcon(Icons.tablet_mac), findsOneWidget);
  });

  testWidgets('a square window counts as landscape', (tester) async {
    // Nothing is gained by blocking a window that is exactly square, and a
    // strict `>` would flicker the prompt while someone drags a resize handle
    // through it.
    await pumpAt(tester, const Size(900, 900));
    expect(find.text('the meadow'), findsOneWidget);
  });

  testWidgets('rotating back brings the game straight up', (tester) async {
    await pumpAt(tester, const Size(820, 1180));
    expect(find.text('the meadow'), findsNothing);
    tester.view.physicalSize = const Size(1180, 820);
    await tester.pump();
    expect(find.text('the meadow'), findsOneWidget);
  });
}
