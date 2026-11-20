// Every sub-mode a child can pick has to open something she can play.
//
// This net should have existed a long time ago. Of the seventeen sub-modes
// across the four built activities, five had no test touching them at all and
// two whole activities — Build-a-Habitat and Where's Buddy — had none. That was
// survivable only because the Sanctuary path dead-ended before either of them
// (see sanctuary_path_test.dart), so nobody could reach the untested half. Now
// that they are reachable, "nobody has ever opened this" is not a state to
// leave them in.
//
// Deliberately shallow: it mounts each sub-mode through the real ActivityScreen
// dispatch, taps past the keeper's intro, and checks that something playable
// came up. It does not play the round — each mechanic is different enough that
// driving them all would be a different, much larger test. What it catches is
// the whole class of failure where a sub-mode is offered in the picker and
// opens a blank screen, an exception, or the developer placeholder.
//
// It did not always tap past the intro, and that gap was the entire value of
// the net. Every sub-mode opens on a full-screen keeper overlay with one
// arrow on it, so stopping at the first frame meant eighteen tests that
// rendered the same widget eighteen times and never once drew a playfield.
// Shape Garden's sorting round had been throwing `RenderFlex children have
// non-zero flex but incoming height constraints are unbounded` on every frame
// it was on screen since it was written, and this file was green throughout.

import 'dart:convert';
import 'dart:io';

import 'package:critmath/data/playable_activities.dart';
import 'package:critmath/providers/app_providers.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/ui/screens/activity_screen.dart';
import 'package:critmath/ui/widgets/next_arrow_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// (activityId, subModeId) for everything a child can be handed, read from the
/// registry rather than listed here — a sub-mode added to the JSON and never
/// wired up is exactly what this is looking for.
List<(String, String)> _everySubMode() {
  final json = jsonDecode(
    File('assets/data/activity-registry/kindergarten.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return <(String, String)>[
    for (final activity in json['activities'] as List<dynamic>)
      if (isActivityPlayable(
        (activity as Map<String, dynamic>)['id'] as String,
      ))
        for (final subMode in activity['subModes'] as List<dynamic>)
          (
            activity['id'] as String,
            (subMode as Map<String, dynamic>)['id'] as String,
          ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> openSubMode(
    WidgetTester tester,
    String activityId,
    String subModeId,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        // Several runners seed their round order off the session id. Pinned so
        // a failure here is reproducible rather than a one-in-N shuffle.
        sessionIdProvider.overrideWithValue('sub-mode-smoke'),
      ],
    );

    // Loaded for real before pumping: the registries read JSON out of the asset
    // bundle, whose cache the test binding clears between tests, so from the
    // second case onward this is file I/O that fake-async pumping can never
    // finish. See the note in app/README.md.
    await tester.runAsync(() async {
      await container.read(activityRegistryProvider.future);
      await container.read(conceptRegistryProvider.future);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => ActivityScreen(
                  activityId: activityId,
                  launchExtra: <String, dynamic>{'subMode': subModeId},
                ),
              ),
              GoRoute(
                path: '/sanctuary',
                builder: (_, __) => const Scaffold(body: Text('map')),
              ),
            ],
          ),
        ),
      ),
    );
    // Explicit frames rather than pumpAndSettle: every playfield carries a
    // BuddyCompanion, which breathes on a repeating controller and never lets
    // the tree settle.
    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await settle();
    // Through the keeper's intro to the thing behind it. Bounded rather than
    // "until the arrow is gone" because some runners keep an arrow on the
    // playfield, and a loop that chased it would play the whole sub-mode.
    for (var t = 0; t < 2; t++) {
      final arrow = find.byType(NextArrowButton);
      if (arrow.evaluate().isEmpty) break;
      // The arrow wraps itself in ReadAloudGate, whose gesture surface sits
      // over an IgnorePointer'd child, so the tap lands above the button it
      // is aimed at. That is the arrangement, not a miss.
      await tester.tap(arrow.first, warnIfMissed: false);
      await settle();
    }
    return container;
  }

  /// Unmount before the container goes, so a narration timer armed by the
  /// intro line does not outlive the test as a pending-timer failure.
  Future<void> close(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
    await tester.pump();
  }

  for (final (activityId, subModeId) in _everySubMode()) {
    testWidgets('$activityId / $subModeId opens', (tester) async {
      final container = await openSubMode(tester, activityId, subModeId);

      expect(
        tester.takeException(),
        isNull,
        reason: 'threw while opening, or laid out illegally once the intro '
            'was out of the way',
      );
      expect(
        find.textContaining('lands in a later sprint'),
        findsNothing,
        reason: 'the picker offers this and the dispatcher does not know it — '
            'a pre-reader gets a sentence in English on a blank screen',
      );
      // Something to touch. Every runner opens either on the keeper's intro
      // (one big arrow) or straight into a playfield; either way a sub-mode
      // that renders nothing tappable is a dead end whatever it looks like.
      expect(
        find.byType(GestureDetector),
        findsWidgets,
        reason: 'nothing on screen responds to a touch',
      );
      await close(tester, container);
    });
  }

  testWidgets('the list being walked is not empty', (tester) async {
    // A path typo would turn every test above into a silent pass.
    expect(_everySubMode().length, greaterThanOrEqualTo(17));
  });
}
