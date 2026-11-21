// The sub-mode picker — the screen a pre-reader could not read.
//
// From her second visit to an activity onwards, this sheet stands between
// every tap on a Sanctuary node and the game behind it, which makes it the
// most-seen surface in the app after the two maps. It was made entirely of
// text — a question, an activity name, and a caption under each sprite — and
// it made no sound at all. The sprites are stop-gaps that mostly do not
// depict their sub-mode (the three Where's Buddy options are a toucan, a
// phoenix and a unicorn), so there was nothing on it a five-year-old could
// decode. Her only strategy was to tap one and find out.
//
// The other half of this file is about `isDemotionFloor`, a registry flag
// that was parsed into the model and then read by nothing. `frame-only` is
// Build-a-Habitat's remedial floor — where the scaffolding is meant to put a
// kid who is struggling — and because the flag was inert it sat in the chain
// as an ordinary step, with three consequences:
//
//   1. It has no picker artwork, so the sheet drew it as a grey question mark
//      captioned `frame-only`.
//   2. It comes last in registry order, so the easiest build in the activity
//      was the one she played last — the ramp running backwards.
//   3. The activity could not be marked complete without it, and on this map
//      completing Build-a-Habitat is what lifts the fog on Where's Buddy.
//
// The flag does NOT mean "outside the chain", which is the reading that would
// have broken far more than it fixed — see `the entry point is a step even
// when it is also the floor` below.

import 'dart:io';

import 'package:critmath/data/asset_paths.dart';
import 'package:critmath/data/build_a_habitat_blueprints.dart';
import 'package:critmath/data/narration_script.dart';
import 'package:critmath/data/playable_activities.dart';
import 'package:critmath/data/sub_mode_picker_data.dart';
import 'package:critmath/engines/narration/narration_cue_log.dart';
import 'package:critmath/models/activity.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:critmath/providers/read_aloud_settings_provider.dart';
import 'package:critmath/providers/setting_notifiers.dart';
import 'package:critmath/ui/map/sub_mode_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

/// Activities a child can actually reach, parsed the way the app parses them.
List<Activity> _playableActivities() {
  final json = activityRegistryJson();
  return <Activity>[
    for (final raw in json['activities'] as List<dynamic>)
      if (isActivityPlayable((raw as Map<String, dynamic>)['id'] as String))
        Activity.fromJson(raw),
  ];
}

/// Runs the sheet's read-through to the end.
///
/// It is a self-rescheduling chain, so one long pump only fires the first
/// link - each pump advances to the next. A test that ends with one of these
/// outstanding fails in teardown, which is the right amount of annoying: a
/// picker still naming its options after it has gone is a real bug.
Future<void> drainReadThrough(WidgetTester tester, int options) async {
  for (var i = 0; i <= options; i++) {
    await tester.pump(const Duration(seconds: 4));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('every option the picker can show is decodable', () {
    test('has a sprite and a label of its own', () {
      // The failure this forbids: a sub-mode reaches the sheet with no
      // catalog entry, and the card falls back to a grey question mark over
      // the raw id. That is not a placeholder a pre-reader can work with —
      // it is indistinguishable from a broken tile, and the spoken fallback
      // has no recorded clip so it arrives in the browser's synth voice.
      final missing = <String>[];
      for (final activity in _playableActivities()) {
        for (final subMode in activity.subModes) {
          // Exactly the set the sheet can render: the chain she works
          // through, plus the challenges appended once it is done.
          if (!subMode.isChainStep && !subMode.isChallenge) continue;
          final option = pickerOptionFor(
            activityId: activity.id,
            subModeId: subMode.id,
          );
          if (option == null) missing.add('${activity.id}/${subMode.id}');
        }
      }
      expect(missing, isEmpty, reason: 'no picker artwork for: $missing');
    });

    test('no two options anywhere share a label', () {
      // Clips are keyed by their words. Two sub-modes agreeing on a label
      // would be one recording doing both jobs, which is fine, and one card
      // that says the name of a different game, which is not.
      final labels = <String>[
        for (final activity in kSubModePickerData.values)
          for (final option in activity.values) option.label,
      ];
      expect(labels.toSet(), hasLength(labels.length));
    });

    test('no two options anywhere draw the same picture', () {
      // They did, and nothing anywhere said so. The baby phoenix was "Count
      // by ones" on the Counting Parade node and "Put Buddy there" on the
      // Where's Buddy node; the baby unicorn was "Big parade" and "In the
      // middle". Both files were internally consistent, both cards rendered,
      // and a child learning which picture opens which game was being taught
      // a contradiction between two screens she never sees at the same time.
      final seen = <String, String>{};
      final clashes = <String>[];
      for (final activity in kSubModePickerData.entries) {
        for (final option in activity.value.entries) {
          final id = option.value.symbol.identity;
          final where = '${activity.key}/${option.key}';
          final prior = seen[id];
          if (prior != null) clashes.add('$prior and $where both draw $id');
          seen[id] = where;
        }
      }
      expect(clashes, isEmpty, reason: clashes.join('; '));
    });

    test('and every sprite it draws is really in the repo', () {
      // The cards are the only thing on this sheet a pre-reader can use. A
      // path that no longer resolves is a grey broken-image box where the
      // game she is choosing ought to be.
      final missing = <String>[
        for (final asset in pickerSpriteAssets())
          if (!File(asset).existsSync()) asset,
        for (final blueprint in kHabitatBlueprints)
          for (final piece in blueprint.roof)
            if (!File(piece.placedAsset).existsSync()) piece.placedAsset,
        for (final asset in <String>[
          AssetPaths.buildAHabitatStick,
          AssetPaths.buildAHabitatClayBall,
        ])
          if (!File(asset).existsSync()) asset,
      ];
      expect(
        missing,
        isEmpty,
        reason: 'picker art missing from disk: $missing',
      );
    });

    test('the catalog carries nothing the picker will not offer', () {
      // Artwork for a sub-mode the sheet cannot show would mean somebody put
      // it back in the chain, which is the bug this file is about.
      for (final activity in _playableActivities()) {
        for (final subMode in activity.subModes) {
          if (subMode.isChainStep || subMode.isChallenge) continue;
          expect(
            pickerOptionFor(activityId: activity.id, subModeId: subMode.id),
            isNull,
            reason:
                '${activity.id}/${subMode.id} is a floor below the entry '
                'point and is never chosen, so drawing it is a picker entry '
                'with no way to be reached',
          );
        }
      }
    });
  });

  group('the picker speaks', () {
    test('every spoken string is in the recording script', () {
      final script = narrationScriptTexts();
      for (final line in spokenSubModeLabels()) {
        expect(
          script,
          contains(narrationTextNormalize(line)),
          reason:
              '"$line" is read aloud but the renderer will never see it, '
              'so it will speak in the browser voice',
        );
      }
    });

    test('every spoken string has a rendered clip', () {
      for (final line in spokenSubModeLabels()) {
        expect(
          narrationClipFor(line),
          isNotNull,
          reason:
              'no clip for "$line". Re-render:\n'
              '  cd app && dart run tool/dump_narration_script.dart '
              '> ../tools/tts/kokoro/script.json\n'
              '  node tools/tts/kokoro/render.mjs render',
        );
      }
    });

    test('the sheet has no label typed inline', () {
      // Exactly the failure map_labels_test.dart exists for, one screen over.
      // A label written here rather than in the catalog is unreachable by the
      // enumeration, so it renders fine, speaks fine, and speaks in the wrong
      // voice — the only symptom is a change of narrator mid-sentence.
      final source = File(
        'lib/ui/map/sub_mode_picker_sheet.dart',
      ).readAsStringSync();
      expect(
        RegExp(r'''label:\s*['"]''').hasMatch(source),
        isFalse,
        reason:
            'picker labels are spoken, so they belong in '
            'data/sub_mode_picker_data.dart',
      );
    });
  });

  group('the sheet', () {
    late ProviderContainer container;

    /// Opens the real picker over a stub screen and settles it.
    Future<void> open(
      WidgetTester tester,
      List<SubModePickerEntry> entries, {
      List<Override> overrides = const <Override>[],
    }) async {
      useViewSize(tester, const Size(1400, 900));

      container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showSubModePicker(
                    context,
                    activityId: 'shape-garden',
                    activityDisplayName: 'Shape Garden',
                    entries: entries,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    /// Everything the narration player has actually said, normalised.
    Set<String> spoken() =>
        container.read(narrationCueLogProvider).keys.toSet();

    const findShape = SubModePickerEntry(
      subMode: SubMode(id: 'find-shape', primaryConcepts: ['K.G.2']),
      isCompleted: true,
      isNext: false,
    );
    const flatOrSolid = SubModePickerEntry(
      subMode: SubMode(id: 'flat-or-solid', primaryConcepts: ['K.G.3']),
      isCompleted: false,
      isNext: true,
    );

    testWidgets('asks the question out loud when it opens', (tester) async {
      await open(tester, const [findShape, flatOrSolid]);
      expect(
        spoken(),
        contains(narrationTextNormalize(kSubModePickerQuestion)),
        reason:
            'the one screen in the game that asks her something and then '
            'waits, and she cannot read it',
      );
      await drainReadThrough(tester, 2);
    });

    testWidgets('names an option on the tap that opens it', (tester) async {
      await open(tester, const [findShape, flatOrSolid]);
      // warnIfMissed: the card's own InkWell sits under ReadAloudGate's
      // IgnorePointer by design, so the tap lands on the gate above it. That
      // is the arrangement under test, not a miss.
      await tester.tap(
        find.byKey(const ValueKey('sub-mode-pick-flat-or-solid')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      final label = pickerOptionFor(
        activityId: 'shape-garden',
        subModeId: 'flat-or-solid',
      )!.label;
      expect(spoken(), contains(narrationTextNormalize(label)));
    });

    testWidgets('and that tap still picks it', (tester) async {
      // ReadAloudGate covers its child with its own gesture surface, so a
      // wrapper that narrated and swallowed the tap would leave a sheet that
      // reads its options aloud and opens none of them.
      String? picked;
      useViewSize(tester, const Size(1400, 900));
      container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    picked = await showSubModePicker(
                      context,
                      activityId: 'shape-garden',
                      activityDisplayName: 'Shape Garden',
                      entries: const [findShape, flatOrSolid],
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('sub-mode-pick-find-shape')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(picked, 'find-shape');
    });

    // ---- the read-through ------------------------------------------------
    //
    // Everywhere else in the game, ReadAloudGate speaks a control's name on
    // the tap that acts, and that is right when the control does what it
    // says. This is the one screen that asks her to *choose*, and there
    // speak-on-tap tells her what she picked after she has picked it. The
    // gate's other affordance - hover to hear without acting - needs a mouse,
    // and she plays on a touchscreen.

    const sortThemOut = SubModePickerEntry(
      subMode: SubMode(id: 'sort-by-attribute', primaryConcepts: ['K.G.4']),
      isCompleted: false,
      isNext: false,
    );

    String said(String subModeId) => narrationTextNormalize(
      pickerOptionFor(activityId: 'shape-garden', subModeId: subModeId)!.label,
    );

    testWidgets('names each option in turn, after the question', (
      tester,
    ) async {
      await open(tester, const [findShape, flatOrSolid, sortThemOut]);
      // The question, and nothing named yet - she is being asked before she
      // is being given the answers.
      expect(
        spoken(),
        contains(narrationTextNormalize(kSubModePickerQuestion)),
      );
      expect(spoken(), isNot(contains(said('find-shape'))));

      // One pump per link: each is scheduled relative to the one before, and
      // three seconds is longer than the longest label plus its gap.
      await tester.pump(const Duration(seconds: 3));
      expect(spoken(), contains(said('find-shape')));
      expect(
        spoken(),
        isNot(contains(said('flat-or-solid'))),
        reason:
            'two names at once is worse than none - she cannot tell which '
            'card either belongs to',
      );

      await tester.pump(const Duration(seconds: 3));
      expect(spoken(), contains(said('flat-or-solid')));
      expect(spoken(), isNot(contains(said('sort-by-attribute'))));

      await tester.pump(const Duration(seconds: 3));
      expect(spoken(), contains(said('sort-by-attribute')));

      // And then it stops rather than looping.
      await drainReadThrough(tester, 3);
    });

    testWidgets('and stops the moment she touches anything', (tester) async {
      await open(tester, const [findShape, flatOrSolid, sortThemOut]);
      await tester.pump(const Duration(seconds: 3));
      expect(spoken(), contains(said('find-shape')));

      // Not on a card - on the strip of padding above the heading. Deciding
      // is the signal that she is done listening, and it does not have to be
      // a good tap. (This is why the Listener is translucent rather than
      // deferToChild: deferToChild never sees a touch that lands on empty
      // padding.)
      //
      // Top *centre*, not the top-left corner: a Material 3 bottom sheet has
      // a 28-pixel corner radius and clips it, so a point six pixels in from
      // the corner is outside the sheet entirely and lands on the modal
      // barrier behind it. That is not a subtlety worth rediscovering.
      final rect = tester.getRect(find.byType(SubModePickerSheet));
      await tester.tapAt(Offset(rect.center.dx, rect.top + 6));
      await tester.pump();

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      expect(
        spoken(),
        isNot(contains(said('flat-or-solid'))),
        reason:
            'the sheet went on reading its menu out after she had already '
            'started choosing',
      );
    });

    testWidgets('fits a small screen without a card going out of reach', (
      tester,
    ) async {
      // The cards got bigger when the symbols stopped being borrowed sprites
      // - 96 was not enough box for a scene to read in - and Counting Parade
      // offers six of them. On a short or narrow viewport that is three rows,
      // and the sheet used to size itself to its content with nothing bounding
      // it: the overflow would be a striped bar and a card she can see and
      // cannot touch. Indistinguishable, from where she is sitting, from the
      // app being broken - which this project treats as worse than getting
      // the answer wrong.
      useViewSize(tester, const Size(560, 520));

      container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showSubModePicker(
                    context,
                    activityId: 'counting-parade',
                    activityDisplayName: 'Counting Parade',
                    entries: <SubModePickerEntry>[
                      for (final id
                          in kSubModePickerData['counting-parade']!.keys)
                        SubModePickerEntry(
                          subMode: SubMode(
                            id: id,
                            primaryConcepts: const ['K.CC.1'],
                          ),
                          isCompleted: false,
                          isNext: false,
                        ),
                    ],
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // A RenderFlex overflow is reported as an exception, not a failure, so
      // it has to be asked for by name or the test passes over the top of it.
      expect(tester.takeException(), isNull);

      // And every card is reachable: the last one is only off-screen until
      // she scrolls, which is the difference between bounded and overflowing.
      await tester.dragUntilVisible(
        find.byKey(const ValueKey('sub-mode-pick-tens-parade')),
        find.byType(SingleChildScrollView),
        const Offset(0, -60),
      );
      expect(
        find.byKey(const ValueKey('sub-mode-pick-tens-parade')),
        findsOneWidget,
      );

      await drainReadThrough(tester, 6);
    });

    testWidgets('and says nothing at all when read-aloud is off', (
      tester,
    ) async {
      // A travelling highlight with no voice under it is not a quieter
      // version of this feature - it is a light moving across the screen for
      // no stated reason. Nothing is scheduled, so nothing needs draining
      // either, and that is what this really pins.
      //
      // The pump below has to be long enough for the first name to have been
      // due. The first version of this test pumped fifty milliseconds and
      // passed with the setting check deleted, because the first name is not
      // due for two and a half seconds either way - a guard satisfied by the
      // fact that nothing had happened yet.
      await open(
        tester,
        const [findShape, flatOrSolid, sortThemOut],
        overrides: [readAloudGateEnabledProvider.overrideWith(_GateOff.new)],
      );
      await tester.pump(const Duration(seconds: 3));
      expect(spoken(), isNot(contains(said('find-shape'))));
      expect(
        spoken(),
        isNot(contains(narrationTextNormalize(kSubModePickerQuestion))),
        reason:
            'read-aloud off means the game does not narrate, and the '
            'question is narration',
      );
    });
  });

  group('the habitat cards are the habitat', () {
    // These three used to be `shapeGarden3dOutline('cube' / 'cylinder' /
    // 'sphere')` — three grey hollow solids that differ from each other about
    // as much as three grey hollow solids can, and none of which appears in
    // the sub-mode it stood for. The card draws the finished build now,
    // straight out of the blueprint data the round assembles, so it cannot
    // drift from the activity: it *is* the activity's data.

    test('draw the blueprint their sub-mode runs', () {
      // Mirrors `_rounds` in build_a_habitat_runner: simple-shelter runs the
      // triangle, creature-home runs all three (the square is the one it
      // adds), grand-habitat runs the pentagon.
      const expected = <String, int>{
        'simple-shelter': 0,
        'creature-home': 1,
        'grand-habitat': 2,
      };
      for (final entry in expected.entries) {
        final symbol =
            kSubModePickerData['build-a-habitat']![entry.key]!.symbol;
        expect(symbol, isA<PickerHabitat>(), reason: entry.key);
        expect((symbol as PickerHabitat).blueprintIndex, entry.value);
      }
    });

    test('and the three are still a triangle, a square and a pentagon', () {
      // Corner count is the entire difference between the three cards. Put
      // the blueprints in a different order and all three quietly start
      // showing the wrong build, which is exactly the failure the old
      // borrowed sprites had.
      expect(kHabitatBlueprints.map((b) => b.corners.length).toList(), <int>[
        3,
        4,
        5,
      ]);
    });

    test('and a roof piece names one sprite, not two', () {
      // The kind -> creature mapping used to be private to the runner. The
      // card needed it too, and a second copy would have meant a card showing
      // a turtle where the round puts a gnome — drift a five-year-old
      // learning "which picture is which game" cannot afford.
      for (final blueprint in kHabitatBlueprints) {
        for (final piece in blueprint.roof) {
          expect(piece.placedAsset, contains(piece.kind));
          expect(piece.outlineAsset, contains(piece.kind));
          expect(piece.placedAsset, isNot(piece.outlineAsset));
        }
      }
    });
  });

  group('demotion floors are not steps in the chain', () {
    test('the flag is actually read', () {
      final habitat = _playableActivities().firstWhere(
        (a) => a.id == 'build-a-habitat',
      );
      final floor = habitat.subModes.firstWhere((m) => m.id == 'frame-only');
      expect(floor.isDemotionFloor, isTrue, reason: 'registry changed');
      expect(floor.isChainStep, isFalse);
    });

    test('the entry point is a step even when it is also the floor', () {
      // The reading that nearly shipped. "A demotion floor is not a chain
      // step" is true of Build-a-Habitat and false of everything else: five
      // of the seven K activities mark their FIRST sub-mode both `isDefault`
      // and `isDemotionFloor`, because the simplest thing an activity
      // teaches is also where a new kid starts. Filtering on the flag alone
      // would have deleted find-shape from Shape Garden and find-mode from
      // Where's Buddy — each activity's default, and in Where's Buddy's case
      // half of the two things it contains.
      var checked = 0;
      for (final activity in _playableActivities()) {
        for (final subMode in activity.subModes) {
          if (!subMode.isDefault) continue;
          checked++;
          expect(
            subMode.isChainStep,
            isTrue,
            reason:
                '${activity.id} would open a picker without its own '
                'default sub-mode in it',
          );
        }
      }
      expect(checked, greaterThanOrEqualTo(4), reason: 'read no defaults');
    });

    test('a floor below the entry point is not a step', () {
      for (final activity in _playableActivities()) {
        for (final subMode in activity.subModes) {
          if (!subMode.isDemotionFloor || subMode.isDefault) continue;
          expect(
            subMode.isChainStep,
            isFalse,
            reason:
                '${activity.id}/${subMode.id} would make a struggling '
                'kid clear the remedial drill to finish the activity',
          );
        }
      }
    });

    test('every activity still has a chain to work through', () {
      // The other direction. `isChainStep` filters two flags out; an activity
      // whose sub-modes are all challenges and floors would show an empty
      // picker and complete on nothing, which reads as a node that opens
      // and closes.
      for (final activity in _playableActivities()) {
        expect(
          activity.subModes.where((m) => m.isChainStep),
          isNotEmpty,
          reason: '${activity.id} has no ordinary sub-mode',
        );
      }
    });
  });
}

/// Read-aloud turned off, the way the Settings screen turns it off.
class _GateOff extends BoolSetting {
  @override
  bool build() => false;
}
