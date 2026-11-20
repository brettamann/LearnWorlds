// The Buddy shop — the first thing in the game that spends a coin.
//
// The wallet has paid out five coins a round since the first sprint into a
// balance with nothing to buy. These tests pin the three properties that make
// the shop safe to hand a five-year-old: it can't overdraw, it can't take a
// part away from a save that predates it, and the create-mode wardrobe never
// shows her a tile that won't work.

import 'package:critmath/data/buddy_shop_catalog.dart';
import 'package:critmath/models/buddy_appearance.dart';
import 'package:critmath/providers/buddy_appearance_provider.dart';
import 'package:critmath/providers/buddy_wardrobe_provider.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:critmath/ui/screens/character_creator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Wallet.spend', () {
    late ProviderContainer container;
    late Wallet wallet;

    setUp(() {
      container = ProviderContainer();
      wallet = container.read(walletProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('refuses a purchase the balance cannot cover', () {
      wallet.award(19);
      expect(wallet.spend(20), isFalse);
      expect(container.read(walletProvider), 19, reason: 'balance untouched');
    });

    test('spends exactly, down to zero', () {
      wallet.award(20);
      expect(wallet.spend(20), isTrue);
      expect(container.read(walletProvider), 0);
    });

    test('cannot be driven negative by a negative price', () {
      wallet.award(10);
      expect(wallet.spend(-5), isFalse);
      expect(container.read(walletProvider), 10);
    });
  });

  group('BuddyWardrobe', () {
    late ProviderContainer container;
    late BuddyWardrobe wardrobe;

    setUp(() {
      container = ProviderContainer();
      wardrobe = container.read(buddyWardrobeProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('the starter wardrobe is owned without being granted', () {
      expect(wardrobe.owns('body:gold'), isTrue);
      expect(wardrobe.owns('body:purple'), isFalse);
      expect(container.read(buddyWardrobeProvider), isEmpty);
    });

    test('grant is idempotent', () {
      wardrobe
        ..grant('body:purple')
        ..grant('body:purple');
      expect(container.read(buddyWardrobeProvider), {'body:purple'});
    });

    test('hydrate grandfathers a part the saved Buddy is already wearing', () {
      // The case that matters: a save written before the shop existed, whose
      // Buddy is wearing a colour the shop now charges for. Taking it back
      // would be the most punishing thing this feature could do.
      wardrobe.hydrate(
        const <String>{},
        appearance: BuddyAppearance.defaults().copyWith(
          bodyId: 'purple',
          hatId: 'crown',
        ),
      );
      expect(wardrobe.owns('body:purple'), isTrue);
      expect(wardrobe.owns('hat:crown'), isTrue);
    });

    test('hydrate does not store free parts', () {
      wardrobe.hydrate(
        const <String>{'body:purple'},
        appearance: BuddyAppearance.defaults(),
      );
      // gold / v1 / arm-1 / leg-1 are all free; only the purchase persists.
      expect(container.read(buddyWardrobeProvider), {'body:purple'});
    });
  });

  group('shop screen', () {
    /// Let the Buddy's reaction hold expire before the tree is torn down.
    /// pumpAndSettle can't be used — BuddyWidget's breathing loop never
    /// settles. The longest hold in play here is the purchase cheer at 2.4s.
    Future<void> drain(WidgetTester tester) =>
        tester.pump(const Duration(seconds: 3));

    Future<ProviderContainer> pump(
      WidgetTester tester,
      BuddyScreenMode mode,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: CharacterCreatorScreen(mode: mode)),
        ),
      );
      await tester.pump();
      return container;
    }

    testWidgets('an unaffordable tap changes nothing', (tester) async {
      final container = await pump(tester, BuddyScreenMode.shop);

      expect(buddyPartPrice(BuddyPartKind.body, 'purple'), 20);
      await tester.tap(find.byKey(const ValueKey('body-purple')));
      await tester.pump();

      expect(container.read(walletProvider), 0);
      expect(container.read(buddyWardrobeProvider), isEmpty);
      expect(container.read(buddyAppearanceProvider).bodyId, 'gold');

      await drain(tester);
    });

    testWidgets('an affordable tap buys and equips in one go', (tester) async {
      final container = await pump(tester, BuddyScreenMode.shop);
      container.read(walletProvider.notifier).award(50);
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('body-purple')));
      await tester.pump();

      expect(container.read(walletProvider), 30, reason: '50 - 20');
      expect(container.read(buddyWardrobeProvider), contains('body:purple'));
      // Auto-equipped: making her tap twice reads as the purchase not working.
      expect(container.read(buddyAppearanceProvider).bodyId, 'purple');
      await drain(tester);
    });

    testWidgets('a second tap on an owned part does not charge again',
        (tester) async {
      final container = await pump(tester, BuddyScreenMode.shop);
      container.read(walletProvider.notifier).award(50);
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('body-purple')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('body-teal')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('body-purple')));
      await tester.pump();

      expect(container.read(walletProvider), 10, reason: 'two buys, not three');
      expect(container.read(buddyAppearanceProvider).bodyId, 'purple');
      await drain(tester);
    });

    testWidgets('create mode hides locked parts and offers a way to the shop',
        (tester) async {
      await pump(tester, BuddyScreenMode.create);

      // Free bodies are pickable...
      expect(find.byKey(const ValueKey('body-gold')), findsOneWidget);
      expect(find.byKey(const ValueKey('body-pink')), findsOneWidget);
      // ...and nothing she can't wear is on screen, so every tile works.
      expect(find.byKey(const ValueKey('body-purple')), findsNothing);
      // The one affordance that leads out of the wardrobe.
      expect(find.byKey(const ValueKey('swatch-shop')), findsOneWidget);

      await drain(tester);
    });
  });
}
