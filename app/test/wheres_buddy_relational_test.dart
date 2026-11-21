// The Where's Buddy challenge — "put Buddy between these two things".
//
// It was offered and not implemented. `relational-mode` is the sub-mode the
// picker unlocks with a "Challenge!" chip once find-mode and place-mode are
// done, and the dispatcher quietly handed back place-mode: the same four
// rounds she had just played, paying a challenge chest for them. Harmless
// while the Sanctuary path dead-ended two nodes earlier and nobody could get
// to this activity at all — not harmless once the path opened.
//
// What is worth pinning is the part that makes it a different exercise rather
// than a re-skin: the target is the midpoint of two named landmarks, and both
// of them are pointed out.

import 'package:critmath/activities/sub_mode_ids.dart';
import 'package:critmath/activities/wheres_buddy/wheres_buddy_landmark_sprite.dart';
import 'package:critmath/activities/wheres_buddy/wheres_buddy_runner.dart';
import 'package:critmath/data/wheres_buddy_landmarks.dart';
import 'package:critmath/data/wheres_buddy_words.dart';
import 'package:critmath/engines/narration/narration_player.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/ui/characters/buddy_widget.dart';
import 'package:critmath/ui/common/answer_feedback.dart';
import 'package:critmath/ui/round/keeper_aside.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the pairs', () {
    test('name real landmarks, and never the same one twice', () {
      for (final (a, b) in kWheresBuddyRelationalPairs) {
        expect(a, isNot(b), reason: 'between one thing means nothing');
        for (final id in [a, b]) {
          expect(
            kWheresBuddyLandmarks.map((l) => l.id),
            contains(id),
            reason: '$id is not on the clearing',
          );
          expect(kWheresBuddyLandmarkNames[id], isNotNull);
        }
      }
    });

    test('are far enough apart that the middle is a real place', () {
      // Two landmarks nearly on top of each other give a target that is
      // indistinguishable from "on the landmark", and the drop tolerance
      // would accept either end — so the round would pass without her having
      // understood anything about between-ness.
      for (final (a, b) in kWheresBuddyRelationalPairs) {
        final pa = wheresBuddyLandmark(a).position;
        final pb = wheresBuddyLandmark(b).position;
        final gap = (pa - pb).distance;
        expect(
          gap,
          greaterThan(0.4),
          reason:
              '$a and $b are ${gap.toStringAsFixed(2)} apart — the '
              'midpoint is inside the tolerance of both ends',
        );
      }
    });

    test('the middle does not land on a third landmark', () {
      // If the answer sits on the mushroom, the round teaches "drag Buddy to
      // the mushroom", which is the wrong lesson and a confusing one: she
      // would be right for a reason that has nothing to do with the word.
      for (final (a, b) in kWheresBuddyRelationalPairs) {
        final pa = wheresBuddyLandmark(a).position;
        final pb = wheresBuddyLandmark(b).position;
        final middle = Offset((pa.dx + pb.dx) / 2, (pa.dy + pb.dy) / 2);
        for (final other in kWheresBuddyLandmarks) {
          if (other.id == a || other.id == b) continue;
          expect(
            (other.position - middle).distance,
            greaterThan(0.14),
            reason: 'the middle of $a and $b sits on ${other.id}',
          );
        }
      }
    });
  });

  group('the words', () {
    test('the prompt names both landmarks and the word being taught', () {
      final line = wheresBuddyRelationalPrompt('hollow-tree', 'mushroom');
      expect(line, contains(kWheresBuddyBetween));
      // Read from the catalog rather than retyped. A landmark gets renamed
      // whenever its name stops agreeing with its picture - the fountain
      // once, the toadstools since - and a test that restates the words
      // fails on the rename rather than on anything being wrong.
      expect(line, contains(kWheresBuddyLandmarkNames['hollow-tree']!));
      expect(line, contains(kWheresBuddyLandmarkNames['mushroom']!));
    });

    test('"between" stays out of the single-landmark vocabulary', () {
      // Putting it in kWheresBuddyPrepositions would look tidy and would make
      // the narration script render thirty-six clips for sentences the game
      // can never say — "Find Buddy, they are between the pond." Worse, the
      // ordinary modes would start dealing it as a round with a vector that
      // does not exist.
      expect(kWheresBuddyPrepositions.values, isNot(contains('between')));
      expect(
        kWheresBuddyPositions.map((p) => p.id),
        isNot(contains('between')),
      );
    });

    test('every spoken relational line is distinct', () {
      // Clips are keyed by their words, so two rounds sharing a sentence
      // would share a clip and the second would sound like a repeat.
      final lines = <String>[
        for (final (a, b) in kWheresBuddyRelationalPairs)
          wheresBuddyRelationalPrompt(a, b),
        for (final (a, b) in kWheresBuddyRelationalPairs)
          wheresBuddyRelationalRestate(a, b),
      ];
      expect(lines.toSet(), hasLength(lines.length));
    });
  });

  group('the round', () {
    late ProviderContainer container;

    Future<void> pumpChallenge(WidgetTester tester) async {
      useViewSize(tester, const Size(1400, 900));

      container = ProviderContainer(
        overrides: [sessionIdProvider.overrideWithValue('relational-test')],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: WheresBuddyRunner(
                subMode: WheresBuddyModes.relationalMode,
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

    testWidgets('opens on the between prompt, not a place-mode one', (
      tester,
    ) async {
      await pumpChallenge(tester);
      expect(tester.takeException(), isNull);

      final (a, b) = kWheresBuddyRelationalPairs.first;
      // Asserted on what was spoken rather than what is drawn: the prompt has
      // no on-screen home of its own — the caption bar belongs to
      // ActivityScreen, and a pre-reader could not use it anyway. The sentence
      // *is* the task here, so the voice is the thing to check.
      expect(
        container.read(narrationPlayerProvider)?.text,
        wheresBuddyRelationalPrompt(a, b),
        reason: 'the challenge is still handing back a place-mode round',
      );
    });

    testWidgets('names both landmarks on the clearing', (tester) async {
      // The highlight used to be inferred as "the landmark nearest the
      // target", which is right only while every target is an offset from
      // exactly one of them. A midpoint is nearest to neither in any useful
      // sense, so one of the two chips would have stayed dark.
      await pumpChallenge(tester);
      final (a, b) = kWheresBuddyRelationalPairs.first;
      for (final id in [a, b]) {
        expect(
          find.text(kWheresBuddyLandmarkNames[id]!),
          findsOneWidget,
          reason: '$id is named in the prompt but not marked on the clearing',
        );
      }
    });

    /// The clearing box, which every normalized coordinate is relative to.
    Rect clearing(WidgetTester tester) =>
        tester.getRect(find.byType(AnswerFeedback));

    /// Drags Buddy to [target] in normalized clearing coordinates, lets go,
    /// and waits out the celebration beat.
    Future<void> dragBuddyTo(WidgetTester tester, Offset target) async {
      final box = clearing(tester);
      final buddy = find.byType(BuddyWidget).first;
      final geometry = ClearingGeometry(width: box.width, height: box.height);
      final at = geometry.place(target);
      await tester.drag(
        buddy,
        Offset(box.left + at.dx, box.top + at.dy) - tester.getCenter(buddy),
      );
      // Past the one-second pause before the keeper speaks. Explicit frames,
      // because the Buddy never stops breathing.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    /// Unmounts the runner and tears the container down with it.
    ///
    /// A passed round leaves a timer running in NarrationPlayer, which waits
    /// out its estimate of the spoken line before starting the next one. That
    /// timer belongs to the provider container rather than to any widget, so
    /// unmounting alone does not cancel it and the binding fails the test for
    /// a pending timer — which says nothing about the thing being tested. The
    /// registered teardown runs too late to help; it has to happen here.
    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();
      await tester.pump();
    }

    /// Where Buddy is now, in normalized clearing coordinates.
    ///
    /// Normalized against `ClearingGeometry`, not against the raw box. The
    /// clearing stops above the caption band - anything placed in the strip
    /// underneath is drawn where it cannot be seen - so the box and the
    /// coordinate space the round works in are two different heights.
    Offset buddyAt(WidgetTester tester) {
      final box = clearing(tester);
      final geometry = ClearingGeometry(width: box.width, height: box.height);
      final centre = tester.getCenter(find.byType(BuddyWidget).first);
      return Offset(
        (centre.dx - box.left) / geometry.width,
        (centre.dy - box.top) / geometry.height,
      );
    }

    testWidgets('Buddy can be dragged, and the middle is the answer', (
      tester,
    ) async {
      // Both halves of this shipped broken in the first cut. The runner asked
      // "is this place-mode?" in four separate places to mean "can she move
      // Buddy?", so the challenge put an instruction over a Buddy nailed to
      // the grass: told to place him between two things, and unable to move
      // him at all.
      await pumpChallenge(tester);
      final (a, b) = kWheresBuddyRelationalPairs.first;
      final pa = wheresBuddyLandmark(a).position;
      final pb = wheresBuddyLandmark(b).position;
      final middle = Offset((pa.dx + pb.dx) / 2, (pa.dy + pb.dy) / 2);

      await dragBuddyTo(tester, middle);

      expect(
        find.byType(KeeperAside),
        findsOneWidget,
        reason: 'dropping on the midpoint did not pass the round',
      );
      expect(buddyAt(tester).dx, closeTo(middle.dx, 0.02));
      expect(buddyAt(tester).dy, closeTo(middle.dy, 0.02));
      await close(tester);
    });

    testWidgets('dropping on one of the two named things is not the answer', (
      tester,
    ) async {
      // The failure that would make this a re-skin: if either end counted,
      // "between" would be satisfied by "at", and she could pass every round
      // without the word meaning anything.
      await pumpChallenge(tester);
      final (a, _) = kWheresBuddyRelationalPairs.first;

      await dragBuddyTo(tester, wheresBuddyLandmark(a).position);

      expect(
        find.byType(KeeperAside),
        findsNothing,
        reason: 'landing on one end passed the round',
      );
      // And she is not left holding a wrong answer: Buddy goes back to where
      // he started so the next try begins from the same place.
      expect(buddyAt(tester).dy, greaterThan(0.8));
      await close(tester);
    });
  });
}
