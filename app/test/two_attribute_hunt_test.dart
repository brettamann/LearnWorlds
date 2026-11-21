// The colour a round asks for has to be a colour something on the board is.
//
// The two-attribute hunt is the hardest thing the Shape Garden asks: two
// attributes at once, and it is the activity's challenge mode. Round one said
// "find every shape that is blue and has four sides", and the two shapes it
// counted as the answer were a near-black square and a grey brick wall. There
// is no blue four-sided sprite in the game - the whole 2D set contains exactly
// one blue thing, and it is a triangle.
//
// Nothing failed, and that is the interesting part. Each shape carried a
// hand-written `color` field beside its sprite variant, and **nothing ever
// read it**: the answer set is authored by hand too, and it was authored to
// agree with the label rather than with the paint. So the field was fiction
// that no code path could contradict, in the one round where a child who
// understands the concept perfectly cannot get it right.
//
// Found by rendering the board and looking at it. These checks are what make
// looking unnecessary next time: the colour is now derived from the sprite
// (`shape_colors.dart`), and a round that speaks a colour word has to have
// that colour on the board and in its answer.

import 'dart:io';

import 'package:critmath/activities/shape_garden/two_attribute_hunt_runner.dart';
import 'package:critmath/data/asset_paths.dart';
import 'package:critmath/data/shape_colors.dart';
import 'package:critmath/data/two_attribute_hunt_rounds.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

/// Colour words that could appear in a prompt, longest first so that a
/// hypothetical "light green" is not read as "green".
final List<String> _colorWords = kShapeVariantColor.values.toSet().toList()
  ..sort((a, b) => b.length.compareTo(a.length));

/// The colour word [round] asks for, or null if it is not a colour round.
String? _colorAsked(HuntRound round) {
  final prompt = round.prompt.toLowerCase();
  for (final word in _colorWords) {
    if (prompt.contains(word)) return word;
  }
  return null;
}

/// Taps every match on each board in turn, letting the celebration and the
/// keeper aside run between them, until the finale's buttons are up.
Future<void> _playAllRounds(WidgetTester tester) async {
  for (final round in kTwoAttributeHuntRounds) {
    final first = find.byKey(ValueKey('2attr-shape-${round.matches.first}'));
    for (var i = 0; i < 30 && first.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    for (final id in round.matches) {
      await tester.tap(
        find.byKey(ValueKey('2attr-shape-$id')),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  final finale = find.byKey(const ValueKey('2attr-repeat'));
  for (var i = 0; i < 30 && finale.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  expect(finale, findsOneWidget, reason: 'never reached the finale');
}

void main() {
  group('every round', () {
    for (final round in kTwoAttributeHuntRounds) {
      test('${round.title}: its answer is on its board', () {
        final ids = round.shapes.map((s) => s.id).toSet();
        expect(round.matches, isNotEmpty);
        expect(
          round.matches.difference(ids),
          isEmpty,
          reason: 'an answer that is not on the board can never be tapped, so '
              'the round would never resolve',
        );
        expect(
          ids.length,
          round.shapes.length,
          reason: 'two shapes sharing an id share a tap',
        );
      });

      test('${round.title}: every sprite it names exists', () {
        for (final shape in round.shapes) {
          final path =
              AssetPaths.shapeGarden2dSprite(shape.kind, shape.variant);
          expect(
            File(path).existsSync(),
            isTrue,
            reason: '${shape.id} draws $path, which is not in the bundle',
          );
        }
      });

      test('${round.title}: every variant declares its colour', () {
        for (final shape in round.shapes) {
          expect(
            kShapeVariantColor,
            contains(shape.variant),
            reason: '${shape.variant} has no row in shape_colors.dart, so no '
                'round can ask for its colour and be checked',
          );
        }
      });

      final asked = _colorAsked(round);
      if (asked == null) continue;

      test('${round.title}: asks for $asked, and $asked is painted there', () {
        final onBoard = round.shapes.where((s) => s.color == asked);
        expect(
          onBoard,
          isNotEmpty,
          reason: 'the round asks for $asked and nothing on the board is '
              '$asked. She cannot answer it by looking.',
        );
      });

      test('${round.title}: every answer really is $asked', () {
        for (final id in round.matches) {
          final shape = round.shapes.firstWhere((s) => s.id == id);
          expect(
            shape.color,
            asked,
            reason: '$id is drawn as ${shape.variant} - '
                '${shape.color} - in the round that asks for $asked',
          );
        }
      });

      test('${round.title}: no unlisted shape is $asked and shaped right', () {
        // The second attribute varies by round, so this checks the half that
        // does not: a shape that matches on colour and is not in the answer
        // has to differ on the other attribute. Which it does is the round
        // author's business; that there is *some* difference is not.
        for (final shape in round.shapes) {
          if (round.matches.contains(shape.id)) continue;
          if (shape.color != asked) continue;
          final answers = round.matches
              .map((id) => round.shapes.firstWhere((s) => s.id == id));
          expect(
            answers.every(
              (a) => a.kind != shape.kind || a.isLarge != shape.isLarge,
            ),
            isTrue,
            reason: '${shape.id} is $asked and is a ${shape.kind}, the same '
                'as an answer. A child tapping it is right and is told she '
                'is wrong.',
          );
        }
      });
    }
  });

  testWidgets('the bonus is paid once per visit, however often she plays again',
      (tester) async {
    // "Again!" used to go through the same Continue that paid the bonus, so
    // every replay of the challenge paid another 50 coins.
    SharedPreferences.setMockInitialValues({});
    useViewSize(tester);
    final container = testContainer(sessionId: 'two-attr-bonus');
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: TwoAttributeHuntRunner(
              onSequenceComplete: () {},
              skipIntro: true,
            ),
          ),
        ),
      ),
    );

    await _playAllRounds(tester);
    expect(container.read(walletProvider), kTwoAttributeHuntBonus);

    for (var replay = 0; replay < 2; replay++) {
      await tester.tap(find.byKey(const ValueKey('2attr-repeat')));
      await tester.pump();
      await _playAllRounds(tester);
      expect(
        container.read(walletProvider),
        kTwoAttributeHuntBonus,
        reason: 'replay ${replay + 1} paid the bonus again',
      );
      // And the replay's finale does not promise coins it is not paying.
      expect(find.text(kTwoAttributeHuntReward), findsNothing);
    }

    await unmountAndDrain(tester);
  });
}
