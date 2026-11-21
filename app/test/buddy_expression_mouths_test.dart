// Mood-driven mouths: the art exists, resolves, and is not for sale.
//
// Both halves of this failed silently before the art landed.
// `buddyMouthIdForMood` has asked for v2/v3/v4 since the Buddy rewrite, and
// `buddyMouthAsset` falls back to the default for an unknown id — so the mood
// swap was wired, drawing nothing, with no error anywhere. The opposite
// mistake is just as quiet: dropping the three into `kBuddyMouths` would have
// made them resolve *and* put "flat line" in the shop for 20 coins.

import 'dart:io';

import 'package:critmath/data/buddy_parts_catalog.dart';
import 'package:critmath/data/buddy_shop_catalog.dart';
import 'package:critmath/models/buddy_mood.dart';
import 'package:critmath/ui/characters/buddy_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaultAsset = 'assets/buddy/mouths/v1.png';

  group('expression mouths', () {
    test('every mood resolves to art that is not the default fallback', () {
      // idle and encouraging deliberately keep whatever the child chose.
      const expressive = <BuddyMood>[
        BuddyMood.happy,
        BuddyMood.curious,
        BuddyMood.thinking,
      ];
      for (final mood in expressive) {
        final id = buddyMouthIdForMood(mood, 'v1');
        expect(id, isNot('v1'), reason: '$mood should swap the mouth');
        expect(
          buddyMouthAsset(id),
          isNot(defaultAsset),
          reason:
              'mood $mood wants "$id" and got the fallback — the art is '
              'missing from kBuddyExpressionMouths, so the mood renders as v1',
        );
      }
    });

    test('idle and encouraging keep the chosen mouth', () {
      for (final mood in <BuddyMood>[BuddyMood.idle, BuddyMood.encouraging]) {
        expect(buddyMouthIdForMood(mood, 'v1'), 'v1');
      }
    });

    test('the art files actually exist', () {
      // pubspec declares assets/buddy/mouths/ as a directory, so a missing file
      // is not a build error — it is a runtime exception in front of a child.
      for (final option in kBuddyExpressionMouths) {
        expect(
          File(option.assetPath).existsSync(),
          isTrue,
          reason: '${option.id} declares ${option.assetPath}, which is absent',
        );
      }
    });

    test('are not offered by the shop or the creator', () {
      // kBuddyMouths is the cosmetic list; buddy_shop_catalog prices every
      // entry in it. An expression mouth appearing here is a child able to buy
      // a pensive flat line and wear it permanently.
      final cosmeticIds = kBuddyMouths.map((o) => o.id).toSet();
      for (final option in kBuddyExpressionMouths) {
        expect(
          cosmeticIds,
          isNot(contains(option.id)),
          reason: '${option.id} is a mood sprite, not a cosmetic',
        );
      }
    });

    test('no id collides between the two lists', () {
      final all = <String>[
        ...kBuddyMouths.map((o) => o.id),
        ...kBuddyExpressionMouths.map((o) => o.id),
      ];
      expect(all.toSet().length, all.length);
    });

    test('shop mouth items stay limited to the cosmetic list', () {
      final shopMouthIds = buddyPartsOfKind(
        BuddyPartKind.mouth,
      ).map((({String assetPath, String id}) o) => o.id).toSet();
      for (final option in kBuddyExpressionMouths) {
        expect(shopMouthIds, isNot(contains(option.id)));
      }
    });
  });
}
