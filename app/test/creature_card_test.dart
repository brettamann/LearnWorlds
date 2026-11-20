// Creature card drops — the first thing in the game whose reward is an object
// rather than a number.
//
// The properties worth pinning are the ones a five-year-old would notice going
// wrong: never a duplicate, never a card for a round she failed, and the rolls
// stop entirely once the set is complete rather than quietly failing forever.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:critmath/coordinators/round_coordinator.dart';
import 'package:critmath/data/creature_card_catalog.dart';
import 'package:critmath/data/playable_activities.dart';
import 'package:critmath/engines/mastery/round_outcome.dart';
import 'package:critmath/providers/collection_provider.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A Random that always lands on [value] for nextDouble, so the drop roll can
/// be forced either way. nextInt still varies so *which* card drops is a real
/// weighted pick rather than always the first.
class _FixedChance implements math.Random {
  _FixedChance(this.value, [int seed = 7]) : _inner = math.Random(seed);

  final double value;
  final math.Random _inner;

  @override
  bool nextBool() => _inner.nextBool();

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => _inner.nextInt(max);
}

/// The cards an ordinary passed round can actually yield.
final List<CreatureCard> _roundDropCards =
    kCreatureCards.where((c) => c.source == CardSource.roundDrop).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer containerWith(math.Random random) {
    final container = ProviderContainer(
      overrides: [
        sessionIdProvider.overrideWithValue('test-session'),
        roundCoordinatorProvider.overrideWith(
          (ref) => RoundCoordinator(ref, random: random),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  void playRound(
    ProviderContainer container, {
    RoundResult result = RoundResult.success,
    String activityId = 'counting-parade',
  }) {
    container.read(roundCoordinatorProvider).resolveRound(
          activityId: activityId,
          conceptId: 'K.CC.4a',
          result: result,
        );
  }

  group('catalog', () {
    test('every card pictures a species that still exists', () {
      // A species renamed in parade_species.dart without updating the card
      // would produce a card showing the wrong creature.
      expect(debugCardSpeciesAreValid(), isTrue);
    });

    test('every place in the Sanctuary has creatures to find', () {
      // All twenty-four used to belong to Counting Parade, so a passed round
      // anywhere else could never turn up a card - three of the four built
      // places had no collectible at all. A new activity with no card of its
      // own is the same hole reopening.
      final homes = _roundDropCards.map((c) => c.activityId).toSet();
      for (final id in kPlayableActivities) {
        expect(homes, contains(id), reason: '$id has no card to find');
      }
    });

    test('card ids are unique', () {
      final ids = kCreatureCards.map((c) => c.id).toSet();
      expect(ids.length, kCreatureCards.length);
    });

    test('the challenge card is present, and is the only challenge card', () {
      final card = creatureCardById(kTensParadeChallengeCardId);
      expect(card, isNotNull);
      expect(card!.displayName, 'Cloud Unicorn');
      expect(card.source, CardSource.challenge);
      expect(
        card.speciesId,
        isNull,
        reason: 'it carries its own art; no parade species pictures it',
      );
      // This used to also assert it was the only card with a null species,
      // which held while the Cloud Unicorn was the one piece of card-only art.
      // Fifteen more were drawn to finish the set, so a null species is now
      // ordinary. What still has to be exactly one is the *challenge* grant:
      // a rare that a hundred taps might fail to produce would be a worse
      // reward than no card at all, so exactly one card is handed over rather
      // than rolled for.
      expect(
        kCreatureCards.where((c) => c.source == CardSource.challenge),
        hasLength(1),
      );
    });

    test('a card with no species carries art of its own', () {
      // speciesId is the hook that propagates a sprite swap in
      // parade_species.dart. A card without one owns its asset outright, so
      // nothing upstream will ever notice if that file goes missing.
      for (final card in kCreatureCards.where((c) => c.speciesId == null)) {
        expect(
          File(card.spriteAsset).existsSync(),
          isTrue,
          reason: '${card.id} points at ${card.spriteAsset}, which is not '
              'on disk — run `node tools/artgen/artgen.mjs install`',
        );
      }
    });

    test('every runtime card is authored in the reward catalog', () {
      // The catalog JSON is the authority and this list is its runtime view.
      // A card added here but not there would drop something the reward
      // system has never heard of.
      final json = jsonDecode(
        File('assets/data/reward-catalog/kindergarten.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final authored = <String>{
        for (final item in json['items'] as List<dynamic>)
          (item as Map<String, dynamic>)['id'] as String,
      };
      for (final card in kCreatureCards) {
        expect(
          authored,
          contains(card.id),
          reason: '${card.id} is not in data/reward-catalog/kindergarten.json',
        );
      }
    });
  });

  group('drops', () {
    test('a guaranteed roll fills the droppable set and then stops', () {
      final container = containerWith(_FixedChance(0));
      // Cards live in different places now, so filling the album means
      // playing everywhere.
      final homes = _roundDropCards.map((c) => c.activityId).toSet();
      for (var i = 0; i < kCreatureCards.length; i++) {
        for (final home in homes) {
          playRound(container, activityId: home);
        }
      }
      expect(
        container.read(cardCollectionProvider).length,
        _roundDropCards.length,
        reason: 'no duplicates: each drop picks only from un-owned cards',
      );

      // Set complete. Further rounds must be inert, not throw on an empty
      // weighted pick.
      playRound(container);
      expect(
        container.read(cardCollectionProvider).length,
        _roundDropCards.length,
      );
    });

    test('a challenge card never falls out of an ordinary round', () {
      // The Cloud Unicorn is the entire reward for counting to a hundred. If
      // it could turn up in round three of a regular sub-mode, the challenge
      // would have nothing left to give.
      final container = containerWith(_FixedChance(0));
      final homes = _roundDropCards.map((c) => c.activityId).toSet();
      for (var i = 0; i < 50; i++) {
        for (final home in homes) {
          playRound(container, activityId: home);
        }
      }
      expect(
        container.read(cardCollectionProvider),
        isNot(contains(kTensParadeChallengeCardId)),
      );
      expect(
        container.read(cardCollectionProvider).length,
        _roundDropCards.length,
        reason: 'fifty guaranteed rolls still cannot reach a challenge card',
      );
    });

    test('a failed round never drops a card', () {
      final container = containerWith(_FixedChance(0));
      playRound(container, result: RoundResult.failure);
      expect(container.read(cardCollectionProvider), isEmpty);
      // ...but it still pays coins, which is the separate rule that a
      // five-year-old must never watch the counter freeze.
      expect(container.read(pendingCardRevealProvider), isNull);
    });

    test('a roll above the drop chance yields nothing', () {
      final container = containerWith(_FixedChance(0.99));
      for (var i = 0; i < 20; i++) {
        playRound(container);
      }
      expect(container.read(cardCollectionProvider), isEmpty);
    });

    test('cards only drop from the activity that owns them', () {
      final container = containerWith(_FixedChance(0));
      for (var i = 0; i < 20; i++) {
        playRound(container, activityId: 'shape-garden');
      }
      final found = container.read(cardCollectionProvider);
      expect(found, isNotEmpty);
      for (final id in found) {
        final card = kCreatureCards.firstWhere((c) => c.id == id);
        expect(card.activityId, 'shape-garden');
      }
      // And a place with no cards of its own finds none.
      final elsewhere = containerWith(_FixedChance(0));
      playRound(elsewhere, activityId: 'no-such-place');
      expect(elsewhere.read(cardCollectionProvider), isEmpty);
    });

    test('the reveal is queued for exactly the card that was granted', () {
      final container = containerWith(_FixedChance(0));
      playRound(container);
      final pending = container.read(pendingCardRevealProvider);
      expect(pending, isNotNull);
      expect(container.read(cardCollectionProvider), contains(pending));
      expect(creatureCardById(pending!), isNotNull);
    });
  });

  group('PendingCardReveal', () {
    test('a second card cannot overwrite one still on screen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final reveal = container.read(pendingCardRevealProvider.notifier);
      reveal
        ..show('creature-card-fawn')
        ..show('creature-card-golden-egg');
      expect(container.read(pendingCardRevealProvider), 'creature-card-fawn');
      reveal.dismiss();
      expect(container.read(pendingCardRevealProvider), isNull);
    });
  });
}
