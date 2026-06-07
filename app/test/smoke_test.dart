// Smoke test — verifies the home map renders and the Sanctuary region is
// reachable from it.

import 'package:critmath/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home map renders and Sanctuary region is tappable',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CritMathApp()));
    await tester.pumpAndSettle();
    expect(find.text('Mystical Island'), findsOneWidget);
    expect(find.bySemanticsLabel('Mystic Sanctuary'), findsOneWidget);
  });
}
