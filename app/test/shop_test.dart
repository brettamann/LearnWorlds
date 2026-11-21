// Shop: one purchase rule for both shops.

import 'package:critmath/coordinators/shop.dart';
import 'package:critmath/data/sanctuary_decor_catalog.dart';
import 'package:critmath/providers/buddy_wardrobe_provider.dart';
import 'package:critmath/providers/sanctuary_decor_provider.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('buying charges the price and grants the item', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(walletProvider.notifier).set(100);
    expect(
      c.read(shopProvider).buyBuddyPart('hat:crown', 30),
      PurchaseOutcome.bought,
    );
    expect(c.read(walletProvider), 70);
    expect(c.read(buddyWardrobeProvider.notifier).owns('hat:crown'), isTrue);
  });

  test('buying what she owns charges nothing', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(walletProvider.notifier).set(100);
    c.read(shopProvider).buyBuddyPart('hat:crown', 30);
    expect(
      c.read(shopProvider).buyBuddyPart('hat:crown', 30),
      PurchaseOutcome.alreadyOwned,
    );
    expect(c.read(walletProvider), 70);
  });

  test('an item she cannot afford is refused whole', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final priced = kSanctuaryDecor
        .map((d) => d.id)
        .firstWhere((id) => decorPrice(id) > 0);
    c.read(walletProvider.notifier).set(decorPrice(priced) - 1);
    expect(c.read(shopProvider).buyDecor(priced), PurchaseOutcome.cannotAfford);
    expect(c.read(walletProvider), decorPrice(priced) - 1);
    expect(c.read(decorOwnershipProvider.notifier).owns(priced), isFalse);
  });
}
