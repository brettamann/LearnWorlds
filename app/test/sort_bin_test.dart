// The sorting baskets were labelled in a language the player cannot read.
//
// Sort-by-attribute is a round whose entire content is telling the bins apart.
// The bins were '3 sides', '4 sides', '5+ sides', 'small', 'big', 'round' and
// 'pointy' — fourteen-point type in an amber pill over a 28px basket icon, in
// front of a five-year-old who cannot read a word of it. So every drop was a
// guess, and getting one right taught her nothing, because nothing on the
// screen said what the basket she hit was for.
//
// The shapes that belong in each basket are drawn in it now. How much to draw
// is a decision rather than a maximum, and the two halves of that decision are
// pinned below: the four-sides basket shows a square while the round also
// contains a rectangle, because seeing that the rectangle belongs with the
// square is the generalisation K.G.4 asks for; and the size baskets show the
// same shape twice, because the attribute is the size and two different shapes
// would invite her to sort by shape instead.

import 'dart:io';

import 'package:critmath/data/narration_script.dart';
import 'package:critmath/data/sort_attribute_words.dart';
import 'package:critmath/engines/narration/narration_cue_log.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:critmath/providers/app_providers.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/ui/screens/activity_screen.dart';
import 'package:critmath/ui/widgets/next_arrow_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('every basket says what goes in it', () {
    test('without using its words', () {
      for (final id in kSortBinLabels.keys) {
        expect(
          kSortBinExemplars[id],
          isNotNull,
          reason: '$id has a label and no picture, so the only way to tell it '
              'from the basket beside it is to read it',
        );
        expect(kSortBinExemplars[id], isNotEmpty, reason: '$id draws nothing');
      }
    });

    test('and the two halves cannot drift apart', () {
      // A picture for a basket that no longer exists is dead weight; a basket
      // with no picture is the bug. Both directions, one assertion.
      expect(kSortBinExemplars.keys.toSet(), kSortBinLabels.keys.toSet());
    });

    test('out of sprites that are really on disk', () {
      for (final exemplars in kSortBinExemplars.values) {
        for (final ex in exemplars) {
          expect(
            File(ex.asset).existsSync(),
            isTrue,
            reason: '${ex.asset} is drawn on a basket and not in the repo',
          );
        }
      }
    });

    test('and no two baskets in a round look the same', () {
      // Two baskets side by side showing the same picture is the old bug with
      // extra steps: she still cannot tell them apart, and now she has been
      // told she can. Checked per round, because a triangle means "three
      // sides" in one round and "pointy" in another and that is fine.
      const rounds = <List<String>>[
        <String>['3-sides', '4-sides', '5plus-sides'],
        <String>['small', 'big'],
        <String>['round', 'pointy'],
      ];
      for (final round in rounds) {
        final looks = <String>[];
        for (final id in round) {
          looks.add(
            kSortBinExemplars[id]!
                .map((e) => '${e.asset}@${e.scale}')
                .join('+'),
          );
        }
        expect(
          looks.toSet(),
          hasLength(looks.length),
          reason: 'two baskets in $round are drawn identically',
        );
      }
    });

    test('the size baskets differ only in size', () {
      // If they differed in shape too she could sort correctly by shape and
      // never think about size, which is the whole round.
      final small = kSortBinExemplars['small']!.single;
      final big = kSortBinExemplars['big']!.single;
      expect(small.asset, big.asset);
      expect(small.scale, lessThan(big.scale));
    });

    test('the four-sides basket still asks her to generalise', () {
      // The round contains a square and a rectangle and they both belong
      // here. Drawing both would turn the round into shape-matching.
      expect(kSortBinExemplars['4-sides'], hasLength(1));
      expect(kSortBinExemplars['4-sides']!.single.kind, 'square');
      // "Five or more" is a category rather than a shape, so one pentagon
      // would read as "the pentagon basket" and leave the hexagon homeless.
      expect(kSortBinExemplars['5plus-sides'], hasLength(2));
    });
  });

  group('a tap on a basket says its name', () {
    /// The clip the app would look for, or null if nothing is rendered.
    File? clipFor(String text) {
      final dir = Directory('assets/audio/narration');
      if (!dir.existsSync()) return null;
      final key = narrationClipKey(text);
      for (final file in dir.listSync().whereType<File>()) {
        if (file.uri.pathSegments.last.startsWith('$key.')) return file;
      }
      return null;
    }

    test('and the recording for it exists', () {
      // These seven clips were rendered a long time ago — the script lists
      // them and its note has always said "read aloud when a basket is
      // tapped". Nothing listened for the tap, so they sat on disk unplayable
      // for months. This half checks they are still there; the widget test
      // below checks something now plays them.
      final script = narrationScriptTexts();
      for (final label in kSortBinLabels.values) {
        expect(script, contains(narrationTextNormalize(label)));
        expect(clipFor(label), isNotNull, reason: 'no clip for "$label"');
      }
    });

    testWidgets('and tapping one plays it', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [sessionIdProvider.overrideWithValue('sort-bin')],
      );
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
                  builder: (_, __) => const ActivityScreen(
                    activityId: 'shape-garden',
                    launchExtra: <String, dynamic>{
                      'subMode': 'sort-by-attribute',
                    },
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
      Future<void> settle() async {
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await settle();
      // Past the keeper's intro to the baskets.
      await tester.tap(find.byType(NextArrowButton).first, warnIfMissed: false);
      await settle();

      final basket = find.byKey(const ValueKey('sort-bin-4-sides'));
      expect(basket, findsOneWidget, reason: 'never reached the round');
      await tester.tap(basket, warnIfMissed: false);
      await settle();

      expect(
        container.read(narrationCueLogProvider).keys,
        contains(narrationTextNormalize(kSortBinLabels['4-sides']!)),
      );

      // Unmount before the container, or the narration timer outlives both.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();
      await tester.pump();
    });

    testWidgets('and a shape can still be dropped into it', (tester) async {
      // The tap handler wraps the whole basket card, which is the right
      // target size for a five-year-old and sits directly above the
      // DragTarget. Dropping goes through the drag system rather than the
      // gesture arena, so a tap handler above it should not intercept - but
      // "should" is how the last hard bug in this repo got shipped, and
      // nothing else in the suite drops a shape into a basket at all.
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [sessionIdProvider.overrideWithValue('sort-drop')],
      );
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
                  builder: (_, __) => const ActivityScreen(
                    activityId: 'shape-garden',
                    launchExtra: <String, dynamic>{
                      'subMode': 'sort-by-attribute',
                    },
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
      Future<void> settle() async {
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await settle();
      await tester.tap(find.byType(NextArrowButton).first, warnIfMissed: false);
      await settle();

      final item = find.byKey(const ValueKey('sort-item-tri-1'));
      final bin = find.byKey(const ValueKey('sort-bin-3-sides'));
      expect(item, findsOneWidget, reason: 'never reached the round');

      final gesture = await tester.startGesture(tester.getCenter(item));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(tester.getCenter(bin));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await settle();

      expect(
        find.byKey(const ValueKey('sort-item-tri-1')),
        findsNothing,
        reason: 'the triangle is still in the pool, so the drop never landed',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();
      await tester.pump();
    });
  });

  test('the baskets are drawn from the neutral shape art', () {
    // The `example` variants are the plain red ones the lesson uses for "a
    // triangle" rather than "this particular leaf-coloured triangle". A
    // basket labelled with a specific variant would read as "put THIS one
    // here", which is a different and much easier question.
    for (final exemplars in kSortBinExemplars.values) {
      for (final ex in exemplars) {
        expect(ex.variant, 'example');
        expect(ex.asset, contains('/shape-garden/'));
      }
    }
  });
}
