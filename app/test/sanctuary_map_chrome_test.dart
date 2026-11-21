// The Sanctuary map's controls, and its music.
//
// Two failures found the same way — by watching a five-year-old on the map for
// a couple of minutes.
//
//   1. The four things she can do there (decorate, cards, shop, settings) were
//      24px Material icons in the top-right of the app bar. That is the least
//      reachable corner of the screen and the last place a child looks, and it
//      made a quarter of the game effectively undiscoverable.
//   2. The map played in total silence. Every claim on the music bed lived in
//      an activity runner, so the one screen she spends the most time on — the
//      hub she returns to after every sub-mode — was the one screen with no
//      music at all.

import 'package:critmath/data/sfx_catalog.dart';
import 'package:critmath/platform/sfx_engine.dart';
import 'package:critmath/ui/map/map_side_rail.dart';
import 'package:critmath/ui/scopes/music_bed_scope.dart';
import 'package:critmath/ui/screens/sanctuary_map_screen.dart';
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

  Future<_RecordingEngine> pumpMap(WidgetTester tester) async {
    useViewSize(tester);

    final engine = _RecordingEngine();
    final container = ProviderContainer(
      overrides: [sfxEngineProvider.overrideWithValue(engine)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const SanctuaryMapScreen(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    return engine;
  }

  testWidgets('the map claims the music bed, and releases it on the way out', (
    tester,
  ) async {
    final engine = await pumpMap(tester);

    expect(
      engine.claimed,
      contains(kDefaultMusicBed),
      reason: 'the hub she returns to after every sub-mode played silent',
    );
    expect(engine.releases, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(
      engine.releases,
      1,
      reason:
          'released rather than stopped, so the next screen can claim the '
          'same bed inside the grace window and she hears no seam',
    );
  });

  testWidgets('every control is on the rail, at kid size', (tester) async {
    await pumpMap(tester);

    expect(find.byType(MapSideRail), findsOneWidget);
    final buttons = find.byType(MapRailButton);
    expect(
      buttons,
      findsNWidgets(4),
      reason: 'decorate, cards, shop, settings',
    );

    for (final element in buttons.evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(
        size.width,
        greaterThanOrEqualTo(kMapRailButtonSize),
        reason: 'a control a five-year-old has to find cannot be a 24px icon',
      );
    }

    // And none of them left behind in the corner they came from.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      ),
      findsOneWidget,
      reason: 'only the back arrow stays in the app bar',
    );
  });

  testWidgets('the rail cannot overflow the space it is given', (tester) async {
    // A Row does not scroll sideways, so anything wider than the rail is a
    // layout exception rather than a scrollbar. The coin HUD is the risk: its
    // numerals are 42pt and it grows with the balance.
    await pumpMap(tester);
    expect(tester.takeException(), isNull);

    final rail = tester.getSize(find.byType(MapSideRail));
    expect(rail.width, kMapRailWidth);
  });

  testWidgets('MusicBedScope wraps the screen rather than the map alone', (
    tester,
  ) async {
    // Wrapping inside the AspectRatio would release the bed every time the
    // decorate tray rebuilt the tree beneath it.
    await pumpMap(tester);
    expect(find.byType(MusicBedScope), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(Scaffold),
        matching: find.byType(MusicBedScope),
      ),
      findsOneWidget,
    );
  });
}
