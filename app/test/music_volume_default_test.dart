// Retuning the music bed has to reach a device that has already played.
//
// Every save carries a musicVolume whether or not anyone has ever touched the
// slider — the whole settings block is persisted the first time a round
// resolves. So the hydration default only ever applies to a player who has
// never played, and lowering the shipped level would have changed nothing for
// the one child actually using this.
//
// A stored value identical to a *previous* default is therefore almost
// certainly not a choice; it is the old default, written down. Those are
// adopted forward. Anything else is treated as deliberate and left alone.

import 'dart:convert';

import 'package:critmath/data/sfx_catalog.dart';
import 'package:critmath/providers/audio_settings_provider.dart';
import 'package:critmath/providers/save_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _saveKey = 'critmath.save.v1';

Future<double> hydratedMusicVolume(Map<String, dynamic> save) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    _saveKey: jsonEncode(save),
  });
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await container.read(saveCoordinatorProvider).hydrate();
  return container.read(musicVolumeProvider);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bed is quieter than the sound effects', () {
    // The bed plays underneath narration. If it ever creeps up to the level of
    // the effects it is competing with the voice telling a child what to do.
    expect(kDefaultMusicVolume, lessThan(kDefaultSfxVolume));
    expect(kDefaultMusicVolume, greaterThan(0));
  });

  test('a save with no audio settings takes the current default', () async {
    expect(await hydratedMusicVolume(<String, dynamic>{}), kDefaultMusicVolume);
  });

  test('a stored level that was only ever the old default moves forward',
      () async {
    expect(
      await hydratedMusicVolume(<String, dynamic>{'musicVolume': 0.35}),
      kDefaultMusicVolume,
      reason: 'without this, retuning the bed reaches nobody who has played',
    );
  });

  test('a level someone actually chose is left alone', () async {
    expect(
      await hydratedMusicVolume(<String, dynamic>{'musicVolume': 0.7}),
      closeTo(0.7, 0.0001),
    );
    expect(
      await hydratedMusicVolume(<String, dynamic>{'musicVolume': 0.0}),
      0.0,
      reason: 'silence is a choice, and the loudest one to get wrong',
    );
  });
}
