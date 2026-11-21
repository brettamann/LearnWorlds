// Decorating the sanctuary — the one surface in the game with no right answer.
//
// The properties worth pinning are the ones that would quietly ruin it: a
// placement that does not survive a restart (the whole point is that the map
// stays decorated between sittings), a purchase that charges twice, and the
// caps that stop a stuck finger on a touchscreen writing a save with ten
// thousand rows in it.
//
// There is deliberately no test asserting anything about *where* she puts
// things. There is no correct answer here, and a test that implied there was
// would be the first step to breaking the feature.

import 'dart:convert';

import 'package:critmath/data/sanctuary_decor_catalog.dart';
import 'package:critmath/models/decor_placement.dart';
import 'package:critmath/providers/sanctuary_decor_provider.dart';
import 'package:critmath/providers/save_provider.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('catalog', () {
    test('every item has a price and a distinct spoken name', () {
      for (final item in kSanctuaryDecor) {
        expect(kDecorPrices[item.tier], isNotNull);
      }
      final names = kSanctuaryDecor.map(decorNameLine).toSet();
      expect(
        names,
        hasLength(kSanctuaryDecor.length),
        reason: 'two items sharing a name would share a narration clip key',
      );
    });

    test('the starter set is free and everything else is not', () {
      for (final item in kSanctuaryDecor) {
        final free = kDecorFreeItems.contains(item.id);
        expect(decorPrice(item.id), free ? 0 : greaterThan(0));
      }
      expect(
        kDecorFreeItems,
        isNotEmpty,
        reason: 'an empty tray on first open is a storefront, not a toybox',
      );
      for (final id in kDecorFreeItems) {
        expect(decorItemById(id), isNotNull, reason: '$id is not in the set');
      }
    });

    test('every item is small enough to place beside a lesson node', () {
      // A node is 0.07 of the shortest side. Decor may be bigger, but an item
      // wide enough to blanket the map would make the map unusable.
      for (final item in kSanctuaryDecor) {
        expect(item.widthFraction, greaterThan(0.0));
        expect(item.widthFraction, lessThan(0.25), reason: item.id);
      }
    });
  });

  group('ownership', () {
    test('the starter set is owned without ever being granted', () {
      final c = container();
      final owner = c.read(decorOwnershipProvider.notifier);
      for (final id in kDecorFreeItems) {
        expect(owner.owns(id), isTrue);
      }
      expect(
        c.read(decorOwnershipProvider),
        isEmpty,
        reason:
            'free items are checked, never stored — so the free set can '
            'change later without leaving stale grants in old saves',
      );
    });

    test('granting twice is idempotent', () {
      final c = container();
      final owner = c.read(decorOwnershipProvider.notifier)
        ..grant('star-fountain')
        ..grant('star-fountain');
      expect(c.read(decorOwnershipProvider), hasLength(1));
      expect(owner.owns('star-fountain'), isTrue);
    });

    test('hydrate drops free items rather than storing them', () {
      final c = container();
      c.read(decorOwnershipProvider.notifier).hydrate({
        'toadstool-cluster',
        'lily-pond',
      });
      expect(c.read(decorOwnershipProvider), {'lily-pond'});
    });
  });

  group('placement', () {
    test('the same item can be placed in several spots', () {
      // The first design that keys placements on the item id quietly makes
      // three mushrooms in three places impossible, which is an obviously
      // reasonable thing for a five-year-old to want.
      final c = container();
      final decor = c.read(sanctuaryDecorProvider.notifier)
        ..place('toadstool-cluster', 0.1, 0.1)
        ..place('toadstool-cluster', 0.5, 0.5)
        ..place('toadstool-cluster', 0.9, 0.2);
      expect(c.read(sanctuaryDecorProvider), hasLength(3));
      expect(decor.countOf('toadstool-cluster'), 3);
      final ids = c
          .read(sanctuaryDecorProvider)
          .map((p) => p.instanceId)
          .toSet();
      expect(ids, hasLength(3), reason: 'instance ids must be distinct');
    });

    test('moving lifts a placement to the top of the draw order', () {
      final c = container();
      final decor = c.read(sanctuaryDecorProvider.notifier);
      final first = decor.place('flower-patch', 0.2, 0.2)!;
      decor.place('lily-pond', 0.4, 0.4);
      decor.move(first.instanceId, 0.8, 0.8);

      final placements = c.read(sanctuaryDecorProvider);
      expect(placements.last.instanceId, first.instanceId);
      expect(placements.last.x, closeTo(0.8, 1e-9));
      expect(placements, hasLength(2), reason: 'a move is not a copy');
    });

    test('positions are clamped to the map rather than rejected', () {
      final c = container();
      final decor = c.read(sanctuaryDecorProvider.notifier);
      final p = decor.place('flower-patch', 1.4, -0.3)!;
      expect(p.x, 1.0);
      expect(p.y, 0.0);
    });

    test('removing one leaves the others alone', () {
      final c = container();
      final decor = c.read(sanctuaryDecorProvider.notifier);
      final a = decor.place('flower-patch', 0.1, 0.1)!;
      final b = decor.place('lily-pond', 0.2, 0.2)!;
      decor.remove(a.instanceId);
      expect(c.read(sanctuaryDecorProvider).map((p) => p.instanceId), [
        b.instanceId,
      ]);
    });

    test('an instance id is never reused after a delete', () {
      // Reuse would let a stale drag land on whatever took the old id's place.
      final c = container();
      final decor = c.read(sanctuaryDecorProvider.notifier);
      final a = decor.place('flower-patch', 0.1, 0.1)!;
      decor.remove(a.instanceId);
      final b = decor.place('flower-patch', 0.1, 0.1)!;
      expect(b.instanceId, isNot(a.instanceId));
    });

    test('the caps hold, and hitting one is not an error', () {
      final c = container();
      final decor = c.read(sanctuaryDecorProvider.notifier);
      for (var i = 0; i < SanctuaryDecor.kMaxPerItem + 5; i++) {
        decor.place('flower-patch', 0.5, 0.5);
      }
      expect(decor.countOf('flower-patch'), SanctuaryDecor.kMaxPerItem);
      // Over the per-item cap, place() returns null instead of throwing.
      expect(decor.place('flower-patch', 0.5, 0.5), isNull);
      // ...and a different item is still placeable, so one full item never
      // locks the whole tray.
      expect(decor.place('lily-pond', 0.5, 0.5), isNotNull);
    });
  });

  group('hydrate', () {
    test(
      'a row naming an item that no longer exists is dropped, not fatal',
      () {
        final c = container();
        c.read(sanctuaryDecorProvider.notifier).hydrate([
          const DecorPlacement(
            instanceId: 1,
            decorId: 'a-decoration-we-removed',
            x: 0.5,
            y: 0.5,
          ),
          const DecorPlacement(
            instanceId: 2,
            decorId: 'lily-pond',
            x: 0.5,
            y: 0.5,
          ),
        ]);
        expect(c.read(sanctuaryDecorProvider).map((p) => p.decorId), [
          'lily-pond',
        ]);
      },
    );

    test('ids continue past the highest one restored', () {
      final c = container();
      final decor = c.read(sanctuaryDecorProvider.notifier)
        ..hydrate([
          const DecorPlacement(
            instanceId: 41,
            decorId: 'lily-pond',
            x: 0.1,
            y: 0.1,
          ),
        ]);
      expect(decor.place('flower-patch', 0.2, 0.2)!.instanceId, 42);
    });
  });

  group('persistence', () {
    // The single property the whole feature rests on: she comes back the next
    // day and her sanctuary is still decorated. Everything else here is a
    // detail; this is the feature.
    test('a decorated map survives a save and a reload', () async {
      SharedPreferences.setMockInitialValues({});

      final first = container();
      first.read(decorOwnershipProvider.notifier).grant('star-fountain');
      final placed = first
          .read(sanctuaryDecorProvider.notifier)
          .place('star-fountain', 0.31, 0.62)!;
      first.read(sanctuaryDecorProvider.notifier).place('lily-pond', 0.8, 0.1);
      await first.read(saveCoordinatorProvider).persist();

      // A genuinely fresh container: nothing carries over but the prefs blob.
      final second = container();
      expect(second.read(sanctuaryDecorProvider), isEmpty);
      await second.read(saveCoordinatorProvider).hydrate();

      expect(second.read(decorOwnershipProvider), contains('star-fountain'));
      final restored = second.read(sanctuaryDecorProvider);
      expect(restored, hasLength(2));
      expect(restored.first.decorId, 'star-fountain');
      expect(restored.first.instanceId, placed.instanceId);
      expect(restored.first.x, closeTo(0.31, 1e-6));
      expect(restored.first.y, closeTo(0.62, 1e-6));
    });

    test('a save written before decorating existed still loads', () async {
      // The blob has no decor keys at all. Empty is the honest migration:
      // nothing was bought and nothing was placed.
      SharedPreferences.setMockInitialValues({
        'critmath.save.v1': jsonEncode(<String, dynamic>{'coins': 40}),
      });
      final c = container();
      await c.read(saveCoordinatorProvider).hydrate();
      expect(c.read(sanctuaryDecorProvider), isEmpty);
      expect(c.read(decorOwnershipProvider), isEmpty);
      expect(
        c.read(walletProvider),
        40,
        reason: 'the rest of the save must still load',
      );
    });
  });

  group('DecorPlacement json', () {
    test('survives a round trip', () {
      const p = DecorPlacement(
        instanceId: 7,
        decorId: 'star-fountain',
        x: 0.25,
        y: 0.75,
      );
      final back = DecorPlacement.fromJson(p.toJson())!;
      expect(back.instanceId, 7);
      expect(back.decorId, 'star-fountain');
      expect(back.x, closeTo(0.25, 1e-9));
      expect(back.y, closeTo(0.75, 1e-9));
    });

    test('a malformed row returns null rather than throwing', () {
      // A save is the one file that must never fail to load: losing the whole
      // sanctuary over one bad row is far worse than losing one mushroom.
      expect(DecorPlacement.fromJson(null), isNull);
      expect(DecorPlacement.fromJson('nonsense'), isNull);
      expect(DecorPlacement.fromJson(<String, dynamic>{}), isNull);
      expect(
        DecorPlacement.fromJson(<String, dynamic>{
          'instanceId': 'not an int',
          'decorId': 'lily-pond',
          'x': 0.5,
          'y': 0.5,
        }),
        isNull,
      );
    });

    test('an out-of-range saved position is clamped back onto the map', () {
      final p = DecorPlacement.fromJson(<String, dynamic>{
        'instanceId': 1,
        'decorId': 'lily-pond',
        'x': 9.0,
        'y': -9.0,
      })!;
      expect(p.x, 1.0);
      expect(p.y, 0.0);
    });
  });
}
