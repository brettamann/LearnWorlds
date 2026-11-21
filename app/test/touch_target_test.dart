// Is everything she has to hit big enough to hit?
//
// This player is five, on a touchscreen, with the fine motor control of a
// five-year-old. `kMinTouchTarget` is 60 logical pixels - about 12.6mm on the
// iPad Air this is meant for - and the reasoning for the number is in
// `touch_target.dart`. The short version: Apple's 44 points and Material's 48
// are written for adults.
//
// Four things were under it, and none of them was visible in the code or in a
// screenshot:
//
//   * The habitat's sticks. She taps an edge of the shelter frame to place a
//     stick, and the tap box was the drawn bar - 28 pixels thick, about 6mm,
//     lying at an angle. Hitting one is a precision task.
//   * The "?" replay button, at 56. That is the control a stuck child reaches
//     for, so it is the last one that should be hard to hit.
//   * The Sanctuary map's nodes and their parchment banners, at 53 and 45.
//     The map is the first screen of every session and the nodes are how she
//     gets anywhere.
//   * The app-bar back arrow on six screens, at 40 - under Apple's adult
//     minimum, never mind this one - including the activity screen, which is
//     the way out of a round.
//
// The fix in every case was to grow the *hit area* and leave the drawing
// alone, because in three of the four the drawn size is load-bearing: the
// stick's thickness is the proportion `HabitatFrameLayout` gives the round,
// the lesson and the picker card, and the node's diameter is what makes it
// sit on the path in the painting.
//
// So this measures hit areas, and `habitat_frame_layout_test.dart` and the
// map goldens keep the drawings honest from the other side.

import 'package:critmath/app.dart';
import 'package:critmath/data/map_anchor_scanner.dart';
import 'package:critmath/data/sanctuary_sequence.dart';
import 'package:critmath/platform/sfx_engine.dart';
import 'package:critmath/providers/exploration_provider.dart';
import 'package:critmath/providers/map_anchors_provider.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/ui/common/caption_overlay.dart';
import 'package:critmath/ui/common/touch_target.dart';
import 'package:critmath/ui/screens/home_map_screen.dart';
import 'package:critmath/ui/screens/sanctuary_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'playfield_caption_band_test.dart' show playfields;
import 'support/harness.dart';

/// The reference window, as `README.md` and the rest of the suite use.
const Size _size = Size(1180, 820);

/// Everything on screen that takes a touch and is small enough to be an
/// actor rather than a backdrop.
///
/// Full-bleed gesture surfaces are excluded: several runners wrap the whole
/// playfield in one - Where's Buddy's miss reaction is the clearing itself -
/// and their size says nothing about how hard anything is to hit.
List<String> undersizedTargets(WidgetTester tester) {
  final screenArea = _size.width * _size.height;
  final out = <String>{};
  for (final type in <Type>[
    GestureDetector,
    Draggable<Object>,
    DragTarget<Object>,
    InkWell,
  ]) {
    for (final element in find.byType(type).evaluate()) {
      final box = element.renderObject;
      if (box is! RenderBox || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.width * rect.height > screenArea * 0.35) continue;
      // A hair under, to forgive the float error in a fraction-derived size
      // that lands on 59.9999.
      if (rect.shortestSide >= kMinTouchTarget - 0.5) continue;
      out.add(
        '$type ${rect.width.toStringAsFixed(0)}x'
        '${rect.height.toStringAsFixed(0)} at '
        '(${rect.left.toStringAsFixed(0)}, ${rect.top.toStringAsFixed(0)})',
      );
    }
  }
  return out.toList()..sort();
}

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

class _QuietEngine extends SfxEngine {
  @override
  Future<void> startMusicBed(String variantKey) async {}
  @override
  void releaseMusicBed({Duration grace = kMusicBedReleaseGrace}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  void sizeTheWindow(WidgetTester tester) {
    useViewSize(tester, _size);
  }

  group('playfields', () {
    for (final key in playfields().keys) {
      testWidgets('$key asks her to hit nothing tiny', (tester) async {
        sizeTheWindow(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sessionIdProvider.overrideWithValue('band-guard')],
            child: MaterialApp(
              theme: critMathTheme,
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(child: playfields()[key]!),
                    const CaptionOverlay(),
                  ],
                ),
              ),
            ),
          ),
        );
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          undersizedTargets(tester),
          isEmpty,
          reason: '$key has a target under ${kMinTouchTarget.toInt()}px',
        );
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
      });
    }
  });

  group('maps', () {
    /// Mounted under `critMathTheme`, not a bare MaterialApp: the app-bar
    /// button sizing lives in the theme, so a guard without it would be
    /// measuring a different app from the one she gets.
    Future<void> pumpMap(WidgetTester tester, Widget screen) async {
      sizeTheWindow(tester);
      final container = ProviderContainer(
        overrides: [
          sfxEngineProvider.overrideWithValue(_QuietEngine()),
          mapAnchorsProvider.overrideWith((ref, _) async => _fakeAnchors()),
        ],
      );
      addTearDown(container.dispose);
      container.read(explorationProvider.notifier).replaceAll({0, 1, 2, 3});
      // Real asset I/O; see the note in `sanctuary_asleep_node_test.dart`.
      await preloadRegistries(tester, container);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => screen),
          for (final path in const [
            '/activity/:id',
            '/lesson/:id',
            '/sanctuary',
            '/settings',
            '/collection',
            '/shop',
            '/creator',
          ])
            GoRoute(path: path, builder: (_, __) => const SizedBox()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(theme: critMathTheme, routerConfig: router),
        ),
      );
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('the Sanctuary nodes and their banners are reachable', (
      tester,
    ) async {
      await pumpMap(tester, const SanctuaryMapScreen());
      expect(undersizedTargets(tester), isEmpty);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });

    testWidgets('and so is everything on the island', (tester) async {
      await pumpMap(tester, const HomeMapScreen());
      expect(undersizedTargets(tester), isEmpty);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });
  });
}
