// The island map — the first screen of every session, and the crossroads of
// every other one.
//
// It had both of the faults the Sanctuary map was reported for, for the same
// reasons: its only control was a 24px gear in the top-right corner of the app
// bar, and it played in silence because every claim on the music bed lived
// inside an activity runner. Silence here is the worse of the two — this is
// where the app opens, so the game's first impression was no sound at all
// until the child had navigated two screens deep.

import 'package:critmath/data/map_labels.dart';
import 'package:critmath/data/sfx_catalog.dart';
import 'package:critmath/engines/narration/narration_cue_log.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:critmath/platform/sfx_engine.dart';
import 'package:critmath/ui/map/map_side_rail.dart';
import 'package:critmath/ui/scopes/music_bed_scope.dart';
import 'package:critmath/ui/screens/home_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

/// Records what a screen asked the music bed to do, without needing audio.
class _RecordingEngine extends SfxEngine {
  final List<String> claimed = <String>[];
  int releases = 0;

  @override
  Future<void> startMusicBed(String variantKey) async =>
      claimed.add(variantKey);

  @override
  void releaseMusicBed({Duration grace = kMusicBedReleaseGrace}) => releases++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  late ProviderContainer container;

  /// Everything the narration player has been asked to say, normalised.
  Set<String> spoken() => container.read(narrationCueLogProvider).keys.toSet();

  Future<_RecordingEngine> pumpMap(WidgetTester tester) async {
    useViewSize(tester);

    final engine = _RecordingEngine();
    container = ProviderContainer(
      overrides: [sfxEngineProvider.overrideWithValue(engine)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const HomeMapScreen()),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    return engine;
  }

  testWidgets('the island has music from the moment the app opens', (
    tester,
  ) async {
    final engine = await pumpMap(tester);
    expect(
      engine.claimed,
      contains(kDefaultMusicBed),
      reason: 'the first screen of every session was the silent one',
    );
    expect(find.byType(MusicBedScope), findsOneWidget);
  });

  testWidgets('the controls are on the rail, not in the corner', (
    tester,
  ) async {
    await pumpMap(tester);

    expect(find.byType(MapSideRail), findsOneWidget);
    final settings = find.byType(MapRailButton);
    expect(settings, findsOneWidget);
    expect(
      tester.getSize(settings).width,
      greaterThanOrEqualTo(kMapRailButtonSize),
    );

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      ),
      findsNothing,
      reason: 'nothing is left in the app bar to hunt for',
    );
  });

  group('nothing on this screen is silently dead', () {
    /// Where a region's tap target is, in screen pixels.
    Rect regionRect(WidgetTester tester, String id) =>
        tester.getRect(find.byKey(ValueKey('map-region-$id')));

    testWidgets('a place that is not built yet says so, out loud', (
      tester,
    ) async {
      // It said nothing at all. `enabled: false` gave the region `onTap: null`
      // under an *opaque* hit test, so the touch was swallowed and returned
      // no sound, no voice and no movement - on two of the four places a
      // child can press, on the first screen of every session. To her that is
      // not "locked", it is the app having stopped working, which is the one
      // failure this whole project set out to make impossible.
      await pumpMap(tester);
      final before = spoken();
      await tester.tapAt(regionRect(tester, 'foundry').center);
      await tester.pump();

      expect(
        spoken().difference(before),
        contains(narrationTextNormalize(kAsleepPlaceLine)),
        reason: 'tapping the Foundry returned nothing whatsoever',
      );
    });

    testWidgets('and it does not say its own name', (tester) async {
      // Deliberate, and the same call the Sanctuary made for its sleeping
      // nodes: one clip covers every dark place on both maps. She already
      // knows which one she touched; what she does not know is that nothing
      // is broken and where to go instead.
      await pumpMap(tester);
      await tester.tapAt(regionRect(tester, 'foundry').center);
      await tester.pump();
      expect(
        spoken(),
        isNot(contains(narrationTextNormalize(kFoundryRegionLabel))),
      );
    });

    testWidgets('a place that is built says its name', (tester) async {
      await pumpMap(tester);
      await tester.tapAt(regionRect(tester, 'mystic-sanctuary').center);
      await tester.pump();
      expect(
        spoken(),
        contains(narrationTextNormalize(kMysticSanctuaryRegionLabel)),
      );
    });

    testWidgets('and the rail button speaks the caption under it', (
      tester,
    ) async {
      // All five rail buttons across both maps were a bare InkWell: no tap
      // sound, because Sfx.uiTap lives inside ReadAloudGate, and no voice,
      // under a caption she cannot read. Two of the five are the entire
      // reward economy and a third is the only open-ended play in the game.
      await pumpMap(tester);
      final before = spoken();
      await tester.tap(find.byType(MapRailButton), warnIfMissed: false);
      await tester.pump();
      expect(
        spoken().difference(before),
        contains(narrationTextNormalize(kRailSettingsLabel)),
      );
    });
  });

  testWidgets('the rail sits beside the map rather than over it', (
    tester,
  ) async {
    // Region rectangles are normalised against the image, so anything that
    // changes the box the map is drawn in drags every hit box off the artwork
    // it was authored against. The rail has to take its width from the empty
    // column, and the map has to stay square-on to its own aspect ratio.
    await pumpMap(tester);
    expect(tester.takeException(), isNull);

    final rail = tester.getRect(find.byType(MapSideRail));
    final map = tester.getRect(find.byType(AspectRatio).first);
    expect(rail.width, kMapRailWidth);
    expect(
      map.right,
      lessThanOrEqualTo(rail.left + 0.5),
      reason: 'the rail is overlapping the map it is meant to sit beside',
    );
    expect(
      map.width / map.height,
      closeTo(860 / 699, 0.01),
      reason: 'the map was stretched to make room',
    );
  });
}
