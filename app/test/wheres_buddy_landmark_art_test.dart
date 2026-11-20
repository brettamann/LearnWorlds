// Where's Buddy had no landmarks.
//
// The activity teaches K.G.1 — position words, *relative to a place*. "Find
// Buddy, he is behind the hollow tree." "Put Buddy above the giant mushroom."
// Six places are named, each at a fixed position on the clearing, and the
// runner drew the name: six identical white pills of text over the Shape
// Garden courtyard illustration, which contains no fountain, no tree, no
// mushroom and no cottage. The code comment claimed a pre-reader would
// recognise "the cottage" by the placeholder shape underneath the chip. There
// was no shape underneath. There was grass.
//
// So the whole activity, for the child it is written for, was six labels she
// could not read on an empty plaza — every round a guess with a one-in-six
// floor, and no way to learn anything from being right. It shipped, it was
// narrated, it had a challenge mode built for it, and it could not be played.
//
// Three of the six sprites came from `sanctuary/decor`, which already sells a
// lily pond, a toadstool cluster and a star fountain in exactly this style;
// three were generated (tools/artgen: hollow tree, cottage, rock cluster).

import 'dart:io';

import 'package:critmath/data/asset_paths.dart';
import 'package:critmath/data/wheres_buddy_landmarks.dart';
import 'package:critmath/data/wheres_buddy_words.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/ui/widgets/caption_overlay.dart';
import 'package:critmath/ui/widgets/wheres_buddy_landmark_sprite.dart';
import 'package:critmath/ui/widgets/wheres_buddy_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('every named place has a picture', () {
    test('and the file is really on disk', () {
      for (final lm in kWheresBuddyLandmarks) {
        final path = AssetPaths.wheresBuddyLandmarks[lm.id];
        expect(
          path,
          isNotNull,
          reason: '${lm.id} is a place the narrator names with nothing drawn '
              'for it, which is the bug this file exists for',
        );
        expect(
          File(path!).existsSync(),
          isTrue,
          reason: '$path is referenced but not in the repo',
        );
      }
    });

    test('the folder holding them is declared in pubspec', () {
      // Flutter fails the build on a *missing* asset directory but says
      // nothing about a present one that was never declared: the file is
      // simply absent from the bundle and `Image.asset` throws at paint time,
      // on the clearing, in front of her.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final path in AssetPaths.wheresBuddyLandmarks.values) {
        final dir = '${path.substring(0, path.lastIndexOf('/'))}/';
        expect(
          pubspec,
          contains(dir),
          reason: '$dir is not in pubspec.yaml assets',
        );
      }
    });

    test('no two places share a sprite', () {
      // Two landmarks drawn identically are one landmark as far as she is
      // concerned, and the round that names the other one is unanswerable.
      final paths = AssetPaths.wheresBuddyLandmarks.values.toList();
      expect(paths.toSet(), hasLength(paths.length));
    });

    test('and every sprite belongs to a place that exists', () {
      final ids = kWheresBuddyLandmarks.map((l) => l.id).toSet();
      expect(AssetPaths.wheresBuddyLandmarks.keys.toSet(), ids);
    });
  });

  test('the places do not sit on top of each other', () {
    // Positions were authored when a landmark was a 112px chip. A sprite is
    // bigger than that, and two overlapping ones make "between the pond and
    // the rock cluster" a target inside a landmark rather than a gap.
    //
    // Swept across the landscape shapes the game actually runs in — it is
    // orientation-gated, see landscape_gate_test.dart — because the sprites
    // are sized off the *shorter* side while the positions spread across the
    // longer one, so the squarest allowed window is the worst case and the
    // only one worth checking carefully.
    for (final aspect in <double>[1.2, 1.5, 1.78, 2.0, 2.4]) {
      const windowH = 800.0;
      final windowW = windowH * aspect;
      // Measured in the clearing rather than in the window. They are not the
      // same box: the clearing stops above the caption band, so both the
      // vertical gaps and the sprite sizes are smaller than the window would
      // suggest, and checking the window checks a composition nobody sees.
      final clearing = ClearingGeometry(width: windowW, height: windowH);
      for (var i = 0; i < kWheresBuddyLandmarks.length; i++) {
        for (var j = i + 1; j < kWheresBuddyLandmarks.length; j++) {
          final a = kWheresBuddyLandmarks[i];
          final b = kWheresBuddyLandmarks[j];
          final sa = clearing.sizeOf(a.sizeFraction);
          final sb = clearing.sizeOf(b.sizeFraction);
          final pa = clearing.place(a.position);
          final pb = clearing.place(b.position);
          final dx = (pa.dx - pb.dx).abs();
          final dy = (pa.dy - pb.dy).abs();
          final clearance = (sa + sb) / 2;
          expect(
            dx >= clearance || dy >= clearance,
            isTrue,
            reason: '${a.id} and ${b.id} overlap at $aspect:1 — '
                'dx ${dx.toStringAsFixed(0)}, dy ${dy.toStringAsFixed(0)}, '
                'need ${clearance.toStringAsFixed(0)} in one of them',
          );
        }
      }
    }
  });

  group('on the clearing', () {
    late ProviderContainer container;

    Future<void> pumpRound(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      container = ProviderContainer(
        overrides: [sessionIdProvider.overrideWithValue('landmark-art')],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: WheresBuddyRunner(
                subMode: kWheresBuddySubModeFindMode,
                skipIntro: true,
                onSequenceComplete: () {},
              ),
            ),
          ),
        ),
      );
      // Explicit frames: BuddyWidget breathes on a repeating controller, so
      // pumpAndSettle never returns on a playfield.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('all six are drawn', (tester) async {
      await pumpRound(tester);
      expect(tester.takeException(), isNull);
      for (final lm in kWheresBuddyLandmarks) {
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName == lm.spriteAsset,
          ),
          findsOneWidget,
          reason: '${lm.id} is on the clearing but not on the screen',
        );
      }
    });

    testWidgets('only the place under discussion carries its name',
        (tester) async {
      // Six permanent captions were the old design and they were the whole of
      // the landmark. Now the picture is, and six pieces of text a pre-reader
      // cannot use would only crowd a clearing she has to judge distances
      // across. The name appears on the one being talked about, which is the
      // moment it ties a spoken "the hollow tree" to a tree.
      await pumpRound(tester);
      var named = 0;
      for (final lm in kWheresBuddyLandmarks) {
        if (find.text(lm.displayName).evaluate().isNotEmpty) named++;
      }
      expect(
        named,
        1,
        reason: 'find-mode names exactly one landmark per round',
      );
    });
  });

  group('and the Buddy has somewhere to stand', () {
    // The clearing was mapped onto the whole window, caption band included,
    // and the band is opaque. So the bottom tenth of the authored space was
    // somewhere things could be put and not seen - and the Buddy's resting
    // spot was in it. He waited every round with the band lying across his
    // body, which matters more than it sounds: he is the one thing on the
    // screen she has to pick up, and he was mostly behind a subtitle she
    // cannot read.
    //
    // It survived because it does not look broken. His head clears the band,
    // so the screen shows a Buddy, just a short one. It was found by
    // rendering the playfield and looking at it - the same way the landmarks
    // above were found to be missing altogether.
    //
    // Swept across window shapes for the reason the overlap test is: sprites
    // size off the shorter side while positions spread across the longer one.

    /// Every landscape shape the orientation gate allows.
    const aspects = <double>[1.2, 1.5, 1.78, 2.0, 2.4];

    test('he is never behind the caption band', () {
      for (final aspect in aspects) {
        const windowH = 800.0;
        final windowW = windowH * aspect;
        final clearing = ClearingGeometry(width: windowW, height: windowH);
        final at = clearing.place(kClearingBuddyHome);
        final bottom = at.dy + clearing.buddySize / 2;
        expect(
          bottom,
          lessThanOrEqualTo(windowH - kCaptionBandClearance + 1),
          reason: 'at $aspect:1 the Buddy waits under the caption band',
        );
      }
    });

    test('nor is any place he can be asked to stand', () {
      // "Below the mushroom" is an answer, and it was landing in the band too.
      for (final aspect in aspects) {
        const windowH = 800.0;
        final windowW = windowH * aspect;
        final clearing = ClearingGeometry(width: windowW, height: windowH);
        for (final landmark in kWheresBuddyLandmarks) {
          for (final position in kWheresBuddyPositions) {
            final spot = clearingSpotFor(
              landmarkId: landmark.id,
              positionId: position.id,
            );
            final bottom = clearing.place(spot).dy + clearing.buddySize / 2;
            expect(
              bottom,
              lessThanOrEqualTo(windowH - kCaptionBandClearance + 1),
              reason: '${position.id} ${landmark.id} at $aspect:1 puts him '
                  'under the caption band',
            );
          }
        }
      }
    });

    test('and he does not wait standing on a landmark', () {
      // The first fix for the band moved him straight onto the rock cluster,
      // which in *this* activity is not cosmetic: the question is which thing
      // he is next to, and he would have started every round already next to
      // one of them.
      for (final aspect in aspects) {
        const windowH = 800.0;
        final windowW = windowH * aspect;
        final clearing = ClearingGeometry(width: windowW, height: windowH);
        final at = clearing.place(kClearingBuddyHome);
        for (final landmark in kWheresBuddyLandmarks) {
          final lm = clearing.place(landmark.position);
          final size = clearing.sizeOf(landmark.sizeFraction);
          final clearance = (size + clearing.buddySize) / 2;
          final dx = (at.dx - lm.dx).abs();
          final dy = (at.dy - lm.dy).abs();
          expect(
            dx >= clearance || dy >= clearance,
            isTrue,
            reason: 'he waits on top of ${landmark.id} at $aspect:1',
          );
        }
      }
    });
  });

  test('the fountain is called what it looks like', () {
    // It was "the unicorn fountain" for as long as no fountain was drawn. The
    // sprite is the decor set's star fountain and has no unicorn on it, and a
    // name that argues with the picture is worse than no picture: the picture
    // and the spoken word are the only two things she has.
    expect(kWheresBuddyLandmarkNames['fountain'], 'the star fountain');
    for (final name in kWheresBuddyLandmarkNames.values) {
      expect(name, isNot(contains('unicorn')));
    }
  });
}
