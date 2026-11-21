// Shared widget-test harness. One place for the setup every screen and runner
// test needs, so a change to how the app boots (a new registry, a new route)
// is made here once instead of in every file that copied it.
//
// See app/README.md "Five traps in widget tests" for why these exist:
// pumpAndSettle never returns on screens with a breathing Buddy, and the
// registries must be loaded inside runAsync.

import 'package:critmath/providers/app_providers.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The landscape iPad-ish surface most tests run on.
const Size kTabletSize = Size(1180, 820);

/// Sets the test view to [size] at 1x and restores it when the test ends.
void useViewSize(WidgetTester tester, [Size size = kTabletSize]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// A container with the session id pinned, so runners that seed their round
/// order off it are reproducible.
ProviderContainer testContainer({
  String sessionId = 'test',
  List<Override> overrides = const [],
}) => ProviderContainer(
  overrides: [sessionIdProvider.overrideWithValue(sessionId), ...overrides],
);

/// Loads the activity and concept registries for real. They read JSON out of
/// the asset bundle, whose cache the test binding clears between tests, so
/// from the second test in a file this is file I/O that fake-async pumping
/// can never finish.
Future<void> preloadRegistries(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.runAsync(() async {
    await container.read(activityRegistryProvider.future);
    await container.read(conceptRegistryProvider.future);
  });
}

/// Pumps [home] at `/` inside a GoRouter, with a stub `/sanctuary` route so
/// anything that navigates home lands somewhere findable (`find.text('map')`).
/// [routes] adds or replaces extra paths.
Future<void> pumpRouted(
  WidgetTester tester,
  ProviderContainer container,
  Widget home, {
  Map<String, WidgetBuilder> routes = const {},
}) async {
  final all = <String, WidgetBuilder>{
    '/sanctuary': (_) => const Scaffold(body: Text('map')),
    ...routes,
  };
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => home),
            for (final e in all.entries)
              GoRoute(path: e.key, builder: (context, _) => e.value(context)),
          ],
        ),
      ),
    ),
  );
}

/// Pumps [count] frames of [step] each. Use instead of pumpAndSettle on any
/// screen with a repeating animation.
Future<void> pumpFrames(
  WidgetTester tester, {
  int count = 20,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(step);
  }
}

/// Replaces the tree with nothing and runs the clock forward so every pending
/// timer (narration, celebration holds, idle help) fires against an unmounted
/// tree and the test ends with none outstanding.
Future<void> unmountAndDrain(
  WidgetTester tester, {
  Duration total = const Duration(seconds: 30),
  Duration step = const Duration(seconds: 1),
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}
