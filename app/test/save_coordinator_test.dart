// SaveCoordinator: what it saves, that a change made mid-write still reaches
// the disk, that autosave saves without being asked, and that one bad field
// in an old save costs only that field.

import 'dart:async';
import 'dart:convert';

import 'package:critmath/providers/audio_settings_provider.dart';
import 'package:critmath/providers/collection_provider.dart';
import 'package:critmath/providers/save_provider.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'critmath.save.v1';

Future<Map<String, dynamic>> _onDisk() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_key);
  return raw == null
      ? <String, dynamic>{}
      : jsonDecode(raw) as Map<String, dynamic>;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('slot keys are unique, and every one is written', () async {
    final keys = [for (final s in kSaveSlots) s.key];
    expect(keys.toSet().length, keys.length);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(saveCoordinatorProvider).persist();
    expect((await _onDisk()).keys.toSet(), keys.toSet());
  });

  test('what is saved is what comes back', () async {
    final first = ProviderContainer();
    first.read(walletProvider.notifier).set(42);
    first.read(cardCollectionProvider.notifier).hydrate({'creature-card-fawn'});
    first.read(sfxVolumeProvider.notifier).set(0.4);
    await first.read(saveCoordinatorProvider).persist();
    first.dispose();

    final second = ProviderContainer();
    addTearDown(second.dispose);
    await second.read(saveCoordinatorProvider).hydrate();
    expect(second.read(walletProvider), 42);
    expect(second.read(cardCollectionProvider), {'creature-card-fawn'});
    expect(second.read(sfxVolumeProvider), 0.4);
  });

  test(
    'a change made while a write is in flight still reaches the disk',
    () async {
      // The bug: a persist() during a write was handed that write's future, and
      // that write had already taken its snapshot - so the change was not on
      // disk until some unrelated later save. Here a slot changes the coins and
      // asks for a save in the middle of being written, after the coins slot
      // has been read: exactly the window the old code dropped.
      late final SaveCoordinator save;
      var interrupted = false;
      final c = ProviderContainer(
        overrides: [
          saveCoordinatorProvider.overrideWith(
            (ref) => SaveCoordinator(
              ref,
              slots: [
                kSaveSlots.firstWhere((s) => s.key == 'coins'),
                SaveSlot(
                  key: 'interrupt',
                  watch: walletProvider,
                  write: (ref) {
                    if (!interrupted) {
                      interrupted = true;
                      ref.read(walletProvider.notifier).set(8);
                      unawaited(save.persist());
                    }
                    return null;
                  },
                  read: (_, __) {},
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      save = c.read(saveCoordinatorProvider);
      c.read(walletProvider.notifier).set(5);
      await save.persist();
      expect((await _onDisk())['coins'], 8);
    },
  );

  test('autosave writes a change nobody asked it to save', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(saveCoordinatorProvider).startAutosave();
    c.read(walletProvider.notifier).set(13);
    expect((await _onDisk())['coins'], isNull, reason: 'it waits a beat');
    await Future<void>.delayed(kAutosaveDelay * 2);
    expect((await _onDisk())['coins'], 13);
  });

  test('one unreadable field costs that field, not the whole save', () async {
    SharedPreferences.setMockInitialValues({
      _key: jsonEncode(<String, dynamic>{
        'coins': 21,
        'progress': 'this should have been a map',
        'cards': ['creature-card-fawn'],
      }),
    });
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(saveCoordinatorProvider).hydrate();
    expect(c.read(walletProvider), 21);
    expect(c.read(cardCollectionProvider), {'creature-card-fawn'});
  });

  test('a save that is not JSON at all starts fresh', () async {
    SharedPreferences.setMockInitialValues({_key: '{not json'});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(saveCoordinatorProvider).hydrate();
    expect(c.read(walletProvider), 0);
  });
}
