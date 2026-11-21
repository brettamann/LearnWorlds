// Build-a-Habitat on the round shell: each phase graded exactly once, and the
// words the runner speaks are the words the recording script lists.

import 'package:critmath/activities/build_a_habitat/build_a_habitat_runner.dart';
import 'package:critmath/activities/sub_mode_ids.dart';
import 'package:critmath/data/build_a_habitat_blueprints.dart';
import 'package:critmath/data/habitat_words.dart';
import 'package:critmath/data/narration_script.dart';
import 'package:critmath/engines/mastery/round_outcome.dart';
import 'package:critmath/engines/narration/narration_line.dart';
import 'package:critmath/engines/narration/narration_player.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:critmath/ui/round/keeper_intro_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the words', () {
    test('the round table names every blueprint, in catalog order', () {
      expect(
        kHabitatBlueprints.map((b) => b.id).toList(),
        kHabitatBlueprintIds,
      );
      for (final id in kHabitatBlueprintIds) {
        expect(kHabitatKeeperLines[id], isNotNull, reason: id);
        expect(kHabitatDisplayNames[id], isNotNull, reason: id);
      }
    });

    test('every roof kind a blueprint uses has a scripted line', () {
      // The roof line interpolates the kind, so a new kind on a blueprint
      // would be a sentence nothing recorded.
      for (final bp in kHabitatBlueprints) {
        for (final piece in bp.roof) {
          expect(kHabitatRoofKinds, contains(piece.kind), reason: bp.id);
        }
      }
    });
  });

  group('a round', () {
    late ProviderContainer container;
    late List<String> heard;

    Future<void> pumpHabitat(WidgetTester tester, String subMode) async {
      useViewSize(tester);
      container = testContainer();
      addTearDown(container.dispose);
      heard = <String>[];
      container.listen<NarrationLine?>(narrationPlayerProvider, (_, l) {
        if (l != null) heard.add(l.text);
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: BuildAHabitatRunner(
                subMode: subMode,
                skipIntro: true,
                onSequenceComplete: () {},
              ),
            ),
          ),
        ),
      );
      await pumpFrames(tester, count: 5);
    }

    Future<void> tapKey(WidgetTester tester, String key) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await pumpFrames(tester, count: 2);
    }

    Future<void> buildFrame(WidgetTester tester) async {
      final bp = kHabitatBlueprints.first;
      for (var i = 0; i < bp.corners.length; i++) {
        await tapKey(tester, 'habitat-corner-$i');
      }
      for (var i = 0; i < bp.edges.length; i++) {
        await tapKey(tester, 'habitat-edge-$i');
      }
    }

    testWidgets('frame and roof are each graded once', (tester) async {
      await pumpHabitat(tester, BuildAHabitatModes.simpleShelter);
      await buildFrame(tester);
      // The roof prompt waits for "Stick." instead of cutting it off.
      expect(container.read(narrationPlayerProvider)?.text, kHabitatStickLine);
      // The frame (K.G.5) pays as it ends, before the roof is touched.
      expect(container.read(walletProvider), coinsFor(RoundResult.success));
      expect(find.byKey(const ValueKey('habitat-roof-0')), findsOneWidget);
      // Long enough for "Stick." and then the roof prompt to be said.
      await pumpFrames(tester, count: 80);

      await tapKey(tester, 'habitat-roof-0');
      expect(container.read(walletProvider), 2 * coinsFor(RoundResult.success));
      // Past the celebration and into the finale: nothing more is paid.
      await pumpFrames(tester, count: 60);
      expect(find.byType(KeeperIntroOverlay), findsOneWidget);
      expect(container.read(walletProvider), 2 * coinsFor(RoundResult.success));

      // ...and is then said.
      final stick = heard.lastIndexOf(kHabitatStickLine);
      expect(stick, greaterThanOrEqualTo(0));
      expect(heard.indexOf(kHabitatRaisePrompt), greaterThan(stick));

      final scripted = <String>{
        for (final line in narrationScriptTexts()) narrationClipKey(line),
      };
      expect(
        heard.where((l) => !scripted.contains(narrationClipKey(l))),
        isEmpty,
      );
      await unmountAndDrain(tester);
    });

    testWidgets('frame-only ends with the frame, graded once', (tester) async {
      await pumpHabitat(tester, BuildAHabitatModes.frameOnly);
      await buildFrame(tester);
      expect(container.read(walletProvider), coinsFor(RoundResult.success));
      expect(find.byKey(const ValueKey('habitat-roof-0')), findsNothing);
      await pumpFrames(tester, count: 60);
      expect(find.byType(KeeperIntroOverlay), findsOneWidget);
      expect(container.read(walletProvider), coinsFor(RoundResult.success));
      await unmountAndDrain(tester);
    });

    testWidgets('three sticks before their corners fail the frame', (
      tester,
    ) async {
      await pumpHabitat(tester, BuildAHabitatModes.frameOnly);
      for (var i = 0; i < 3; i++) {
        await tapKey(tester, 'habitat-edge-0');
      }
      await buildFrame(tester);
      expect(container.read(walletProvider), coinsFor(RoundResult.failure));
      expect(heard, contains(habitatStickBlockedLine(1)));
      expect(heard, contains(habitatStickBlockedLine(2)));
      await unmountAndDrain(tester);
    });
  });
}
