// Does the middle third of the lesson happen?
//
// Every lesson is authored as I-Show / We-Try / You-Do: watch it, do it with
// help, do it graded. All 22 have a full `weTry` block - a scene, a
// choreography, its own narration - and for the whole life of the project the
// screen went straight from I-Show to You-Do. The phase existed on disk and
// nowhere else.
//
// It was easy to miss for a specific reason worth writing down: `WeTryPhase`
// *did* parse the narration lines, so anything looking for missing content
// found none. What it skipped was `choreography`, the key that says when to
// speak them and where she has to touch. Parsed words and an unparsed script
// look identical from every direction except running it.
//
// The phase cannot be failed - every lesson's own `passCondition` says so
// ("any tap passes", "even one drag is enough; system completes the rest") -
// so these tests are almost all about one thing: is she asked, and does
// something happen when she answers. A We-Try that silently plays itself is a
// second I-Show, and a We-Try that waits for a touch it never acknowledges is
// worse than not having one.

import 'dart:convert';
import 'dart:io';

import 'package:critmath/models/lesson_runtime.dart';
import 'package:critmath/models/we_try_script.dart';
import 'package:critmath/ui/common/touch_here_halo.dart';
import 'package:critmath/ui/screens/lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

/// Lessons a child can currently reach - the ones introducing the four
/// activities that have a runner. Same list `lesson_scene_test.dart` uses.
const Set<String> _playableActivities = <String>{
  'counting-parade',
  'shape-garden',
  'wheres-buddy',
  'build-a-habitat',
};

/// Lessons whose body already contains guided practice of its own, and which
/// therefore hand off straight to You-Do.
///
/// Read from the lessons themselves - a lesson whose `presentation.stage`
/// owns its practice (`LessonStage.ownsPractice`) - which is exactly what
/// LessonScreen consults. The second test below keeps it honest: a concept may
/// only be here if its lesson body is genuinely interactive, because the
/// alternative reading - "this lesson does not need a We-Try" - is how the
/// phase goes missing again, one lesson at a time.
final Set<String> _bespokePractice = <String>{
  for (final lesson in _allLessons())
    if (LessonRuntime.fromJson(lesson).presentation.stage.ownsPractice)
      lesson['conceptId'] as String,
};

Map<String, dynamic> _read(File f) =>
    jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _allLessons() => [
      for (final e in Directory('assets/data/lesson-runtime').listSync())
        if (e is File && e.path.endsWith('.json')) _read(e),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final lessons = _allLessons();
  final reachable = lessons
      .where((l) => _playableActivities.contains(l['introducingActivity']))
      .toList();

  group('the phase is authored and complete', () {
    test('every lesson has a We-Try with something for her to do', () {
      final silent = <String>[];
      for (final lesson in lessons) {
        final runtime = LessonRuntime.fromJson(lesson);
        if (!runtime.weTry.script.hasGate) silent.add(runtime.conceptId);
      }
      expect(
        silent,
        isEmpty,
        reason: 'a We-Try with no kid-action step is a second I-Show',
      );
    });

    test('every cue the choreography names has words behind it', () {
      // The thing I got wrong. Searching `content/strings` for these ids finds
      // nothing and it looks like 49 lines are unwritten; they are all in the
      // lesson JSON, in the phase's own narrationScript, keyed by cueId in the
      // `at` field where a timestamp normally goes.
      final orphans = <String>[];
      for (final lesson in lessons) {
        final weTry = lesson['phases']['weTry'] as Map<String, dynamic>;
        final authored = <String>{
          for (final line in weTry['narrationScript'] as List)
            line['at'] as String,
        };
        for (final step in weTry['choreography'] as List? ?? const []) {
          final params = step['params'];
          if (params is! Map) continue;
          for (final key in const ['cueId', 'passCue', 'failCue']) {
            final cue = params[key];
            if (cue is String && !authored.contains(cue)) {
              orphans.add('${lesson['conceptId']}/$cue');
            }
          }
        }
      }
      expect(orphans, isEmpty, reason: 'a cue with no text is a silent beat');
    });

    test('and every line it will speak is a line, not a slug', () {
      for (final lesson in lessons) {
        final runtime = LessonRuntime.fromJson(lesson);
        for (final beat in runtime.weTry.script.beats) {
          if (beat is WeTrySay) {
            expect(beat.text, isNot(startsWith('we-try-')));
            expect(beat.text.trim(), isNotEmpty);
          }
        }
      }
    });
  });

  group('the exclusion list is honest', () {
    test('every reachable lesson either runs it or has its own', () {
      // Both directions. A concept dropping off the reachable list must not
      // silently lose its We-Try, and a concept added to the bespoke list must
      // actually have a bespoke one.
      final missing = <String>[];
      for (final lesson in reachable) {
        final conceptId = lesson['conceptId'] as String;
        if (_bespokePractice.contains(conceptId)) continue;
        final runtime = LessonRuntime.fromJson(lesson);
        if (!runtime.weTry.script.hasGate) missing.add(conceptId);
      }
      expect(missing, isEmpty);
    });

    test('and the three exclusions are the three with an interactive body', () {
      // Named files, so removing one of these layers without removing its
      // concept from the exclusion list fails here rather than shipping a
      // lesson with no practice at all.
      const bodies = <String, String>{
        'K.G.2': 'lib/ui/lesson/shape_find_round.dart',
        'K.G.3': 'lib/ui/lesson/kg3_flat_or_solid_lesson_layer.dart',
        'K.G.4': 'lib/ui/lesson/kg4_sort_by_attribute_lesson_layer.dart',
      };
      expect(bodies.keys.toSet(), _bespokePractice);
      for (final entry in bodies.entries) {
        expect(
          File(entry.value).existsSync(),
          isTrue,
          reason: '${entry.key} is excused the generic We-Try because '
              '${entry.value} gives it one of its own',
        );
      }
    });
  });

  group('the scene her turn opens on is its own', () {
    test('the habitat sites disagree, and each one is read', () {
      // K.G.5 fills an empty frame; K.G.6 adds to a finished one. Inheriting
      // whatever the I-Show left standing asks K.G.5 for a corner on a
      // completed triangle.
      final kg5 = LessonRuntime.fromJson(
        _read(File('assets/data/lesson-runtime/k-g-5-sticks-and-clay.json')),
      );
      final kg6 = LessonRuntime.fromJson(
        _read(File('assets/data/lesson-runtime/k-g-6-compose-3d.json')),
      );
      expect(kg5.weTry.framePrebuilt, isFalse);
      expect(kg6.weTry.framePrebuilt, isTrue);
      expect(kg5.weTry.showsRoof, isFalse);
      expect(kg6.weTry.showsRoof, isTrue);
    });

    test('and her turn counts one more than the demonstration did', () {
      // Authored deliberately: three fawns are shown, four are hers. A stage
      // that keeps its own count draws three while the narrator says "Four."
      for (final file in const ['k-cc-4a-one-to-one', 'k-cc-4b-cardinality']) {
        final runtime = LessonRuntime.fromJson(
          _read(File('assets/data/lesson-runtime/$file.json')),
        );
        expect(
          runtime.weTry.creatureCount,
          greaterThan(runtime.iShow.creatureCount),
          reason: '$file is authored 3 then 4',
        );
      }
    });
  });

  group('she is told where to touch', () {
    /// Scene-target ids the stages actually draw something for, as regular
    /// expressions. A target outside this list still *works* - the registry
    /// treats an unplaceable target as unmissable, so her touch is praised
    /// rather than corrected - but she gets no ring, and "touch this first
    /// fawn" with nothing lit is a guess.
    ///
    /// Two of these were missing when the phase was first wired and neither
    /// was visible from anywhere: K.CC.2 names the fawns that walk in
    /// `new-fawn-N` while the stage had registered only the pre-counted ones,
    /// and K.G.6 asks for `phase2-ghost-cube`, which nothing had a key on. The
    /// lesson still ran, still spoke, still advanced. It just never said
    /// where.
    const drawn = <String>[
      r'^fawn-\d+$',
      r'^new-fawn-\d+$',
      r'^cluster-\d+$',
      r'^vertex-\d+$',
      r'^edge-\d+$',
      r'^phase2-ghost-cube$',
      // Where's Buddy landmarks and the `<position>-<landmark>` zones.
      r'^(fountain|hollow-tree|mushroom|rock-cluster|cottage|pond)$',
      r'^(above|below|next-to|behind|in-front-of|beside)-',
    ];

    test('every target a reachable lesson names is one a stage draws', () {
      final unlit = <String>[];
      for (final lesson in reachable) {
        final conceptId = lesson['conceptId'] as String;
        if (_bespokePractice.contains(conceptId)) continue;
        final weTry = lesson['phases']['weTry'] as Map<String, dynamic>;
        final scene = weTry['scene'] as Map<String, dynamic>? ?? const {};
        final ids = <String>{
          if (scene['initialGlowTarget'] is String)
            scene['initialGlowTarget'] as String,
          for (final step in weTry['choreography'] as List? ?? const [])
            if (step['params'] is Map) ...<String>{
              for (final key in const [
                'target',
                'expectedTarget',
                'expectedZone',
              ])
                if ((step['params'] as Map)[key] is String)
                  (step['params'] as Map)[key] as String,
              for (final t
                  in (step['params'] as Map)['targets'] as List? ?? const [])
                if (t is String) t,
            },
        };
        for (final id in ids) {
          if (!drawn.any((p) => RegExp(p).hasMatch(id))) {
            unlit.add('$conceptId/$id');
          }
        }
      }
      expect(
        unlit,
        isEmpty,
        reason: 'these are asked for and never lit, so she has to guess',
      );
    });
  });

  group('running it', () {
    /// Mounts a lesson and runs it to the point where her turn has begun.
    Future<void> openWeTry(WidgetTester tester, String lessonId) async {
      useViewSize(tester, const Size(1200, 820));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => LessonScreen(lessonId: lessonId),
                ),
                GoRoute(
                  path: '/sanctuary',
                  builder: (_, __) => const SizedBox(),
                ),
                GoRoute(
                  path: '/activity/:id',
                  builder: (_, __) => const Text('YOU-DO'),
                ),
              ],
            ),
          ),
        ),
      );
      // Real asset I/O; poll rather than guess a delay. See the note in
      // `lesson_scene_test.dart` and README trap 4.
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
      for (var i = 0; i < 35; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      final arrow = find.byKey(const ValueKey('lesson-continue-arrow'));
      if (arrow.evaluate().isNotEmpty) {
        await tester.tap(arrow, warnIfMissed: false);
      }
      await tester.pump(const Duration(milliseconds: 300));
    }

    /// Pumps until she is actually being waited for.
    Future<void> pumpToGate(WidgetTester tester) async {
      for (var i = 0; i < 60; i++) {
        if (find
            .byKey(const ValueKey('we-try-gate-open'))
            .evaluate()
            .isNotEmpty) {
          return;
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      fail('the We-Try never opened a gate');
    }

    testWidgets('the demonstration hands over to her instead of to the game',
        (tester) async {
      await openWeTry(tester, 'lesson-k-cc-4a-one-to-one');
      expect(
        find.byKey(const ValueKey('we-try-layer')),
        findsOneWidget,
        reason: 'the Continue arrow used to go straight to the activity',
      );
      expect(find.text('YOU-DO'), findsNothing);
      // Drain.
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });

    testWidgets('it waits for her, and her touch is what moves it on',
        (tester) async {
      await openWeTry(tester, 'lesson-k-cc-4b-cardinality');
      await pumpToGate(tester);
      expect(
        find.byType(TouchHereHalo),
        findsWidgets,
        reason: 'she is asked without being told where to look',
      );

      // A gate holds. Pumping less than the hesitation threshold must not
      // carry the phase forward on its own - if it does, the phase plays
      // itself and she is a spectator again.
      final before = find.byType(TouchHereHalo).evaluate().length;
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byType(TouchHereHalo).evaluate().length, before);

      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('we-try-layer'))),
      );
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });

    testWidgets('and it never strands a child who touches nothing at all',
        (tester) async {
      // The one failure this phase must not have. `highlight-target` says
      // re-light and keep waiting, which has no floor; a kid who decides not
      // to play this beat is still owed the rest of her lesson.
      await openWeTry(tester, 'lesson-k-g-1-positional-language');
      for (var i = 0; i < 90; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(
        find.text('YOU-DO'),
        findsOneWidget,
        reason: 'the We-Try ran out with no input and never handed off',
      );
    });

    testWidgets('a touch that misses still gets an answer', (tester) async {
      // "Correct steers; incorrect corrects" - both are warm, both advance,
      // and neither is the miss sound the graded round uses. What must never
      // happen is silence: she touched the screen and nothing came back.
      await openWeTry(tester, 'lesson-k-g-1b-more-position-words');
      await pumpToGate(tester);
      final layer = find.byKey(const ValueKey('we-try-layer'));
      expect(layer, findsOneWidget);
      // Top-left corner: as far from any authored target as the stage goes.
      await tester.tapAt(tester.getTopLeft(layer) + const Offset(40, 120));
      await tester.pump(const Duration(milliseconds: 300));

      final runtime = LessonRuntime.fromJson(
        _read(
          File('assets/data/lesson-runtime/k-g-1b-more-position-words.json'),
        ),
      );
      final corrective = runtime.weTry.line('we-try-corrective-1');
      final correct = runtime.weTry.line('we-try-correct-1');
      expect(
        find.text(corrective!).evaluate().isNotEmpty ||
            find.text(correct!).evaluate().isNotEmpty,
        isTrue,
        reason: 'her touch was answered with nothing',
      );
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });
  });
}
