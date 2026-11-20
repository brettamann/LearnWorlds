// Does a lesson show the thing it is teaching?
//
// `lesson_screen` picks its iShow scene from `conceptId`, and the last case is
// a fall-through to `_FawnStage`: three fawns standing in a meadow. That is
// exactly right for the counting lessons it was written for, and it is what
// every unrecognised lesson got. K.G.1 - positional language, the lesson that
// introduces Where's Buddy, whose entire subject is where the Buddy is - drew
// three deer and no Buddy at all. So did K.G.1b, and so do the two
// Build-a-Habitat lessons today.
//
// The scenes were authored the whole time. K.G.1 declares five landmarks, a
// Buddy centre stage, and steps that move him above the fountain, behind the
// tree and next to the mushroom. Nothing read any of it.
//
// This is the hardest kind of bug to see and the reason this file exists:
//
//   - The default renders *something plausible*. Nothing throws, nothing is
//     blank, nothing looks broken. It is a lesson about position words
//     illustrated with deer.
//   - The lesson is the phase an adult taps through to get to the game, so
//     it is the least-watched screen in the app by the person who could
//     notice - and the most-watched by the person who cannot say so.
//
// It was found by rendering the lesson to a PNG and looking at it.

import 'dart:convert';
import 'dart:io';

import 'package:critmath/data/wheres_buddy_landmarks.dart';
import 'package:critmath/data/wheres_buddy_words.dart';
import 'package:critmath/ui/screens/lesson_screen.dart';
import 'package:critmath/ui/widgets/animated_fawn.dart';
import 'package:critmath/ui/widgets/clearing_lesson_stage.dart';
import 'package:critmath/ui/widgets/habitat_lesson_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lessons a child can currently reach — the ones introducing the four
/// activities that have a runner.
const Set<String> _playableActivities = <String>{
  'counting-parade',
  'shape-garden',
  'wheres-buddy',
  'build-a-habitat',
};

/// Lessons still drawing the fawn meadow for a scene that is not fawns.
///
/// A ledger, not a permission, and it is empty: K.G.5 and K.G.6 were the last
/// two on it, and `HabitatLessonStage` draws them now.
///
/// THIS SET MUST ONLY GET SMALLER. Adding to it means shipping another lesson
/// that illustrates the wrong activity, and the second test below refuses to
/// let an entry rot here after it has been fixed.
const Set<String> _stillOnTheFallback = <String>{};

Map<String, dynamic> _lesson(String file) =>
    jsonDecode(File('../data/lesson-runtime/$file').readAsStringSync())
        as Map<String, dynamic>;

/// Every reachable lesson, as (conceptId, lessonId, scene).
List<(String, String, Map<String, dynamic>)> _reachableLessons() {
  final out = <(String, String, Map<String, dynamic>)>[];
  for (final entity in Directory('../data/lesson-runtime').listSync()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final json = _lesson(entity.uri.pathSegments.last);
    if (!_playableActivities.contains(json['introducingActivity'])) continue;
    final phases = json['phases'] as Map<String, dynamic>;
    final iShow = phases['iShow'] as Map<String, dynamic>;
    final conceptId = json['conceptId'] as String;
    final lessonId = json['id'] as String;
    final scene = iShow['scene'] as Map<String, dynamic>;
    out.add((conceptId, lessonId, scene));
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Mounts a lesson and taps past the keeper intro into the iShow scene.
  Future<void> openLesson(WidgetTester tester, String lessonId) async {
    tester.view.physicalSize = const Size(1200, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => LessonScreen(lessonId: lessonId),
              ),
              GoRoute(path: '/sanctuary', builder: (_, __) => const SizedBox()),
              GoRoute(
                path: '/activity/:id',
                builder: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
    // The lesson JSON comes off the asset bundle: real file I/O, which a
    // fake-async pump can never let finish however many frames it runs. A
    // fixed delay is a guess, and the wrong one - the test binding clears the
    // bundle cache between tests, so from the second test in a file onward
    // the load is slower than whatever you picked. Poll for the thing you are
    // waiting for instead. (This was found the honest way: the second preview
    // in a file failed on a missing keeper button while the first passed.)
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (find
          .byKey(const ValueKey('lesson-keeper-start-button'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    await tester.tap(
      find.byKey(const ValueKey('lesson-keeper-start-button')),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// The lesson schedules ~25s of timers; a test torn down with one pending
  /// fails, so run the phase out.
  Future<void> drainLesson(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  group('a lesson shows the activity it introduces', () {
    testWidgets('the position lesson stands Buddy in the real clearing',
        (tester) async {
      await openLesson(tester, 'lesson-k-g-1-positional-language');

      expect(
        find.byType(ClearingLessonStage),
        findsOneWidget,
        reason: 'K.G.1 is about where the Buddy is and it drew three fawns',
      );
      expect(
        find.byType(AnimatedFawn),
        findsNothing,
        reason: 'there are no fawns in Where\'s Buddy',
      );
      await drainLesson(tester);
    });

    testWidgets('and so does the second one', (tester) async {
      await openLesson(tester, 'lesson-k-g-1b-more-position-words');
      expect(find.byType(ClearingLessonStage), findsOneWidget);
      expect(find.byType(AnimatedFawn), findsNothing);
      await drainLesson(tester);
    });

    testWidgets('the habitat lesson builds the shelter it is about',
        (tester) async {
      // K.G.5 authors a ghost triangle, a pool of clay and sticks, and a fawn
      // waiting at the edge of the clearing for somewhere to live. It drew
      // three fawns standing in a meadow.
      await openLesson(tester, 'lesson-k-g-5-sticks-and-clay');
      expect(find.byType(HabitatLessonStage), findsOneWidget);
      await drainLesson(tester);
    });

    testWidgets('and the second phase raises it on the frame already laid',
        (tester) async {
      await openLesson(tester, 'lesson-k-g-6-compose-3d');
      expect(find.byType(HabitatLessonStage), findsOneWidget);
      await drainLesson(tester);
    });

    testWidgets('the counting lesson still shows fawns, which is right',
        (tester) async {
      // The fall-through is not wrong; it is only wrong as a *default*. This
      // is the lesson it was built for.
      await openLesson(tester, 'lesson-k-cc-4a-one-to-one');
      expect(find.byType(AnimatedFawn), findsWidgets);
      expect(find.byType(ClearingLessonStage), findsNothing);
      await drainLesson(tester);
    });
  });

  group('and no lesson is quietly illustrated with the wrong one', () {
    test('every reachable scene is either handled or on the ledger', () {
      // Scene-shape, not concept id: `creatures` means the fawn meadow is
      // honest, and anything else means it is a stand-in.
      final wrong = <String>[];
      for (final (conceptId, lessonId, scene) in _reachableLessons()) {
        final hasCreatures = scene.containsKey('creatures');
        final handled = hasCreatures ||
            scene.containsKey('shapes') ||
            scene.containsKey('landmarks') ||
            scene.containsKey('bins') ||
            scene.containsKey('buildSite');
        if (!handled && !_stillOnTheFallback.contains(conceptId)) {
          wrong.add('$conceptId ($lessonId)');
        }
      }
      expect(
        wrong,
        isEmpty,
        reason: 'these lessons draw a scene that is not theirs: $wrong',
      );
    });

    test('and the ledger only names lessons that are really still broken', () {
      // The other direction, and the one that makes the ledger shrink rather
      // than rot: a concept listed here that has since been given a scene is
      // a line nobody removed, and the next reader believes it.
      for (final conceptId in _stillOnTheFallback) {
        final match = _reachableLessons().where((l) => l.$1 == conceptId);
        expect(
          match,
          isNotEmpty,
          reason: '$conceptId is on the fallback ledger and is not a '
              'reachable lesson at all',
        );
        expect(
          match.first.$3.containsKey('creatures'),
          isFalse,
          reason: '$conceptId now has a creature scene, so it is not on the '
              'fallback any more - take it off the ledger',
        );
      }
    });
  });

  group('the position lesson speaks the round\'s vocabulary', () {
    // A lesson exists to introduce the round it hands off to. This one used to
    // name five places - "the well", "the tree", "the mushroom", "the rocks" -
    // of which four are named differently by the activity and one does not
    // exist in the game at all. Thirty seconds after being taught "the well",
    // she was asked to find "the star fountain".
    const files = <String>[
      'k-g-1-positional-language.json',
      'k-g-1b-more-position-words.json',
    ];

    test('its landmarks are the round\'s landmarks', () {
      final known = kWheresBuddyLandmarks.map((l) => l.id).toSet();
      for (final file in files) {
        final scene = ((_lesson(file)['phases']
            as Map<String, dynamic>)['iShow'] as Map<String, dynamic>)['scene'];
        final ids = ((scene as Map<String, dynamic>)['landmarks'] as List)
            .cast<String>();
        expect(ids, isNotEmpty);
        for (final id in ids) {
          expect(
            known,
            contains(id),
            reason: '$file stands the kid in front of "$id", which the round '
                'has never heard of',
          );
        }
      }
    });

    test('and every place it moves Buddy to is one she can be moved to', () {
      final landmarks = kWheresBuddyLandmarks.map((l) => l.id).toSet();
      final positions = kWheresBuddyPositions.map((p) => p.id).toSet();
      for (final file in files) {
        final iShow = (_lesson(file)['phases'] as Map<String, dynamic>)['iShow']
            as Map<String, dynamic>;
        var moves = 0;
        for (final step in iShow['animationSteps'] as List) {
          final map = step as Map<String, dynamic>;
          if (map['action'] != 'pointer-move-buddy') continue;
          moves++;
          final params = map['params'] as Map<String, dynamic>;
          expect(landmarks, contains(params['landmark']), reason: file);
          expect(positions, contains(params['position']), reason: file);
        }
        expect(moves, greaterThan(0), reason: '$file demonstrates nothing');
      }
    });

    test('and it says the names the round says', () {
      // The narration is the half a pre-reader actually receives. A picture of
      // a fountain under the word "well" teaches her the wrong word for the
      // right thing, which is worse than teaching her nothing.
      final names = kWheresBuddyLandmarkNames.values.toSet();
      for (final file in files) {
        final iShow = (_lesson(file)['phases'] as Map<String, dynamic>)['iShow']
            as Map<String, dynamic>;
        final spoken = <String>[
          for (final cue in iShow['narrationScript'] as List)
            (cue as Map<String, dynamic>)['text'] as String,
        ].join(' ');
        // Only landmarks the scene actually stands up need naming.
        final ids =
            (((iShow['scene'] as Map<String, dynamic>)['landmarks']) as List)
                .cast<String>();
        for (final id in ids) {
          final name = kWheresBuddyLandmarkNames[id]!;
          if (!spoken.contains(name.split(' ').last)) continue;
          expect(
            spoken,
            contains(name),
            reason: '$file mentions the ${name.split(' ').last} but not by '
                'the name the round uses ("$name")',
          );
        }
        expect(
          spoken.toLowerCase(),
          isNot(contains('the well')),
          reason: 'there is no well anywhere in this game',
        );
        for (final name in names) {
          if (!spoken.contains(name)) continue;
          expect(kWheresBuddyLandmarkNames.values, contains(name));
        }
      }
    });
  });
}
