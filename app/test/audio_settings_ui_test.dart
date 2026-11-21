// The volume controls, which until now existed everywhere except the screen.
//
// SfxEngine, the providers, the save blob and AudioUnlockScope's listeners were
// all wired for music and effect levels from the start — the only missing piece
// was any way to move them. So "turn the music down" was a code change and a
// rebuild, and the one number chosen that way (33%) was chosen in one room, on
// one pair of speakers.
//
// What these pin is the split that makes a slider usable: the level has to move
// while you are dragging it, and the save must not.

import 'package:critmath/data/sfx_catalog.dart';
import 'package:critmath/providers/audio_settings_provider.dart';
import 'package:critmath/providers/save_provider.dart';
import 'package:critmath/ui/scopes/music_bed_scope.dart';
import 'package:critmath/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pumpSettings(WidgetTester tester) async {
    useViewSize(tester, const Size(1180, 900));

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pump();
    return container;
  }

  /// The slider under [key], addressed by its ValueKey rather than by position
  /// so that adding a setting above it cannot silently re-target the test.
  Finder sliderIn(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(Slider),
      );

  testWidgets('both levels are reachable, and start at the shipped defaults',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Sound effects'), findsOneWidget);

    expect(
      tester.widget<Slider>(sliderIn('music-volume')).value,
      closeTo(kDefaultMusicVolume, 0.001),
    );
    expect(
      tester.widget<Slider>(sliderIn('sfx-volume')).value,
      closeTo(kDefaultSfxVolume, 0.001),
    );
  });

  testWidgets('dragging is heard immediately and saved once it settles',
      (tester) async {
    final container = await pumpSettings(tester);
    container.read(saveCoordinatorProvider).startAutosave();
    final slider = tester.widget<Slider>(sliderIn('music-volume'));

    // Mid-drag. onChanged fires per frame and must reach the provider, because
    // that is what pushes the level into the playing bed — a slider you cannot
    // hear while moving it is a slider you cannot set.
    for (final level in [0.6, 0.7, 0.8]) {
      slider.onChanged!(level);
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(container.read(musicVolumeProvider), closeTo(0.8, 0.001));
    expect(
      (await SharedPreferences.getInstance()).getKeys(),
      isEmpty,
      reason: 'a per-frame save rewrites the whole save blob sixty times a '
          'second',
    );

    // Let it settle: one write, of the level she chose.
    await tester.pump(kAutosaveDelay * 2);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    final raw = (await SharedPreferences.getInstance()).getString(
      'critmath.save.v1',
    );
    expect(raw, isNotNull, reason: 'settling is what commits it');
    expect(raw, contains('"musicVolume":0.8'));
  });

  testWidgets('turning a channel off takes its slider away', (tester) async {
    // ui-affordances.md: missing controls, not disabled ones. A level for a
    // channel that is off does nothing, and a dead slider is worse than none.
    final container = await pumpSettings(tester);
    expect(sliderIn('music-volume'), findsOneWidget);

    container.read(musicEnabledProvider.notifier).set(false);
    await tester.pump();

    expect(sliderIn('music-volume'), findsNothing);
    expect(
      sliderIn('sfx-volume'),
      findsOneWidget,
      reason: 'the two channels are independent',
    );
  });

  testWidgets('the screen keeps the music playing while you set its level',
      (tester) async {
    // The reason this screen claims the bed at all. Without it the release from
    // the previous screen expires a few seconds after arriving here, and the
    // music slider is being tuned against silence.
    await pumpSettings(tester);
    expect(find.byType(MusicBedScope), findsOneWidget);
  });
}
