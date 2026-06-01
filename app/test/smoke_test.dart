// Smoke test — the skeleton renders without crashing.
// Real test coverage starts in sprint 0 per
// specs/shared/project-bootstrap.md "Build sequencing".

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:critmath/app.dart';

void main() {
  testWidgets('skeleton app renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CritMathApp()));
    expect(find.text('CritMath skeleton — routing not yet wired'), findsOneWidget);
  });
}
