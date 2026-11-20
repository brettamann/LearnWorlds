// A place on the map that isn't built yet.
//
// Seven of the Sanctuary's eleven nodes open nothing: four aren't in the
// activity registry at all, three are registered with no runner. They stay on
// the map on purpose (specs/shared/map-screens.md), but a tap on one used to do
// one of two things and both were bad — nothing at all, which to a child who
// cannot read is the app having frozen, or a route to a blank screen carrying
// the sentence `Activity "ten-frame-pond" lands in a later sprint.`
//
// sanctuary_path_test.dart covers the sequencing rule underneath this. These
// cover what she actually sees and hears.

import 'package:critmath/data/map_anchor_scanner.dart';
import 'package:critmath/data/map_labels.dart';
import 'package:critmath/data/playable_activities.dart';
import 'package:critmath/data/sanctuary_sequence.dart';
import 'package:critmath/engines/narration/narration_player.dart';
import 'package:critmath/platform/sfx_engine.dart';
import 'package:critmath/providers/app_providers.dart';
import 'package:critmath/providers/exploration_provider.dart';
import 'package:critmath/providers/map_anchors_provider.dart';
import 'package:critmath/ui/screens/sanctuary_map_screen.dart';
import 'package:critmath/ui/widgets/map_node_with_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The twelve anchors, on a widely spaced grid.
///
/// Fabricated rather than scanned: MapAnchorScanner decodes the map PNG, and
/// that never completes under `flutter test` — the provider sits in
/// AsyncLoading forever and the map draws no nodes at all. Where the anchors
/// really are is the artist's business; these tests are about which nodes
/// appear and what they do when touched.
///
/// A grid rather than the obvious diagonal, and spaced far wider than the real
/// map needs: each node's parchment banner stretches to fit its name and sits
/// beside it, so nodes placed close together produce banners that overlap, and
/// then a tap aimed at one lands on whichever was painted last. That failed as
/// "the node went nowhere", which is indistinguishable from the bug these
/// tests exist to catch.
MapAnchors _fakeAnchors() => MapAnchors(
      anchors: <int, Offset>{
        for (var i = 0; i < kSanctuarySequence.length; i++)
          kSanctuarySequence[i]: Offset(
            0.13 + 0.33 * (i % 3),
            0.11 + 0.22 * (i ~/ 3),
          ),
      },
      imageWidth: 1024,
      imageHeight: 1024,
    );

/// A silent engine — these tests are about pictures and words, not audio.
class _QuietEngine extends SfxEngine {
  @override
  Future<void> startMusicBed(String variantKey) async {}

  @override
  void releaseMusicBed({Duration grace = kMusicBedReleaseGrace}) {}
}

void main() {
  // Every node is built now; these hold the asleep machinery against the
  // map as it was, for the next region that has unbuilt places in it.
  setUp(() => debugPlayableOverride = kFourActivitySanctuary);
  tearDown(() => debugPlayableOverride = null);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Pumps the map with [explored] already finished, and returns the router so
  /// a test can ask where a tap took her.
  Future<(GoRouter, ProviderContainer)> pumpMap(
    WidgetTester tester,
    Set<int> explored,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        sfxEngineProvider.overrideWithValue(_QuietEngine()),
        mapAnchorsProvider.overrideWith((ref, _) async => _fakeAnchors()),
      ],
    );
    addTearDown(container.dispose);
    container.read(explorationProvider.notifier).replaceAll(explored);

    // Load the two registries for real, before anything is pumped.
    //
    // They read JSON out of the asset bundle, and the test binding clears that
    // bundle's cache after every test — so from the second test onward this is
    // genuine file I/O, which a fake-async `pump()` can never let complete no
    // matter how many frames it runs. Left to pumping, the map came up with
    // both registries still loading, drew Build-a-Habitat as a sleeping node
    // called "Build A Habitat", and a tap on it did nothing: a perfect
    // imitation of the bug these tests exist to catch.
    await tester.runAsync(() async {
      await container.read(activityRegistryProvider.future);
      await container.read(conceptRegistryProvider.future);
    });

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SanctuaryMapScreen()),
        GoRoute(
          path: '/activity/:id',
          builder: (_, __) => const Scaffold(body: Text('an activity')),
        ),
        GoRoute(
          path: '/lesson/:id',
          builder: (_, __) => const Scaffold(body: Text('a lesson')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // The anchors resolve on a microtask (they are overridden above), but the
    // map still needs a frame or two to place anything against them.
    //
    // Pumped explicitly rather than settled: MapFogLayer drifts its clouds on
    // a repeating controller, so pumpAndSettle never returns on this screen.
    var ready = false;
    for (var i = 0; i < 20 && !ready; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      ready = container.read(sanctuaryAnchorsProvider).hasValue;
    }
    expect(ready, isTrue, reason: 'the map never placed its anchors');
    await tester.pump();
    return (router, container);
  }

  /// The banner half of a node — the canonical `node-<id>` key.
  Finder node(String activityId) => find.byKey(ValueKey('node-$activityId'));

  /// The parchment itself. The widget under the key is a Stack holding one
  /// absolutely-positioned child, so its own centre is the middle of the map
  /// and a tap there lands on the artwork.
  Finder banner(String activityId) => find
      .descendant(
        of: node(activityId),
        matching: find.byType(GestureDetector),
      )
      .first;

  testWidgets('a sleeping node is drawn, and drawn differently',
      (tester) async {
    await pumpMap(tester, {kSanctuaryCutsceneCode, 0xF1, 0xF2});

    final asleep = tester.widget<MapNodeWithBanner>(node('ten-frame-pond'));
    expect(asleep.asleep, isTrue);
    expect(
      asleep.numberInside,
      isNull,
      reason: 'a lesson number is a promise that there is something to do',
    );

    final awake = tester.widget<MapNodeWithBanner>(node('build-a-habitat'));
    expect(awake.asleep, isFalse);
    expect(awake.numberInside, isNotNull);
  });

  testWidgets('the activities behind an unbuilt one are reachable',
      (tester) async {
    // The regression that matters. Ten-Frame Pond is node three and has no
    // runner, so under the old one-step reveal the map stopped there and
    // Build-a-Habitat and Where's Buddy — both finished — were unreachable.
    await pumpMap(tester, {kSanctuaryCutsceneCode, 0xF1, 0xF2});
    expect(node('build-a-habitat'), findsOneWidget);

    await pumpMap(tester, {kSanctuaryCutsceneCode, 0xF1, 0xF2, 0xF4});
    expect(
      node('wheres-buddy'),
      findsOneWidget,
      reason: 'three sleeping nodes in a row must not hide the one after them',
    );
  });

  testWidgets('tapping a sleeping node says why, and goes nowhere',
      (tester) async {
    final (router, container) =
        await pumpMap(tester, {kSanctuaryCutsceneCode, 0xF1, 0xF2});

    await tester.tap(banner('ten-frame-pond'));
    await tester.pump();

    expect(
      container.read(narrationPlayerProvider)?.text,
      kAsleepPlaceLine,
      reason: 'silence is indistinguishable from a frozen app',
    );
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/',
      reason: 'it must not route to the "lands in a later sprint" screen',
    );
  });

  testWidgets('the nodes this unblocked actually open something',
      (tester) async {
    // Opening the path is only worth anything if what is behind it works. Both
    // of these route through ScaffoldEngine on a first tap, which needs a
    // lesson to exist for their entry concept (K.G.5 and K.G.1) — so this is
    // as much a check on the content as on the map.
    for (final (explored, id) in <(Set<int>, String)>[
      ({kSanctuaryCutsceneCode, 0xF1, 0xF2}, 'build-a-habitat'),
      ({kSanctuaryCutsceneCode, 0xF1, 0xF2, 0xF4}, 'wheres-buddy'),
    ]) {
      final (router, _) = await pumpMap(tester, explored);
      await tester.tap(banner(id));

      // The tap runs through ScaffoldEngine, which reads two registries and
      // may open the sub-mode picker first. Waited on rather than pumped a
      // fixed number of times: a count that happens to be enough today is a
      // test that goes red for the next person for no reason.
      var opened = false;
      for (var i = 0; i < 40 && !opened; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final path = router.routerDelegate.currentConfiguration.uri.path;
        opened = path.startsWith('/lesson/') ||
            path.startsWith('/activity/') ||
            // More than one playable sub-mode opens the picker instead of
            // routing, which is just as much "it opened something".
            find.text('What do you want to play?').evaluate().isNotEmpty;
      }
      expect(
        opened,
        isTrue,
        reason: '$id went nowhere — it is on the map but not playable',
      );
    }
  });

  testWidgets('a node the registry never heard of still reads as a place',
      (tester) async {
    // care-pantry has a spec and a map position but no registry entry, so the
    // map had nothing for the parchment and printed the id.
    await pumpMap(tester, {kSanctuaryCutsceneCode, 0xF1, 0xF2, 0xF4});
    final banner = tester.widget<MapNodeWithBanner>(node('care-pantry'));
    expect(banner.label, 'Care Pantry');
    expect(banner.asleep, isTrue);
  });
}
