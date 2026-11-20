// Creature cards — the Sanctuary Creature Cards set, v1.
//
// `data/reward-catalog/kindergarten.json` has declared this set since the
// first sprint and nothing implemented it, so a child could play for an hour
// and the only thing that changed in her world was map fog. Appendix A of the
// engagement plan is blunt about why that matters: sticker counts stop
// motivating fast, and what sustains a kid is a reward that changes the world
// she inhabits — a new friend, a new room — rather than a number going up.
//
// v1 is deliberately the cheapest thing that is genuinely a collection: the
// eight Counting Parade sprites she already meets, as eight cards, with the
// ones she hasn't found shown as silhouettes. The silhouette is the mechanic.
// A gallery of what you have is a receipt; a gallery of what you *don't* have
// is a reason to play another round.
//
// Ids match `data/reward-catalog/kindergarten.json` exactly — that file is the
// authority and this is the runtime view of it. All 24 authored cards are here
// now: eight reuse the Counting Parade cast, the Cloud Unicorn is the Tens
// Parade grant, and fifteen were drawn for the album (tools/artgen).
//
// Not yet honoured from the catalog: per-item `dropRate`. Drops here are one
// roll per passed round weighted by rarity (see kCardDropChance in
// round_coordinator.dart), which is close enough in shape and needs no
// runtime catalog loader.

import '../activities/activity_ids.dart';
import 'asset_paths.dart';
import 'parade_species.dart';

enum CardRarity { common, uncommon, rare }

/// How a card can be obtained, mirroring the `sources` array on the reward
/// catalog item.
///
/// This exists because the catalog authors two genuinely different things
/// under one category. Most cards are `{ type: activity-drop }` and fall out
/// of ordinary rounds; the Cloud Unicorn is `{ type: challenge }` and must not.
/// Without the distinction the rare reward for counting to a hundred would
/// turn up in round three of an ordinary sub-mode, which is the whole of what
/// makes it worth counting to a hundred.
enum CardSource {
  /// Rolled for on any passed round of [CreatureCard.activityId].
  roundDrop,

  /// Granted outright by that activity's challenge sub-mode. Never rolled.
  challenge,
}

class CreatureCard {
  const CreatureCard({
    required this.id,
    required this.displayName,
    required this.speciesId,
    required this.spriteAsset,
    required this.rarity,
    required this.activityId,
    this.source = CardSource.roundDrop,
  });

  /// Matches the reward-catalog item id.
  final String id;

  /// What the reveal overlay and the gallery call it.
  final String displayName;

  /// The parade species this card pictures, or null for cards with their own
  /// art. Kept so a sprite swap in parade_species propagates here.
  final String? speciesId;

  final String spriteAsset;
  final CardRarity rarity;

  /// Which activity can drop this card. v1 is Counting Parade only.
  final String activityId;

  /// See [CardSource]. Defaults to `roundDrop` so adding an ordinary card
  /// stays a four-line change.
  final CardSource source;
}

/// The card the Tens Parade challenge grants. Named here rather than written
/// as a literal in the runner so that a typo is a compile error rather than a
/// card that silently never arrives.
const String kTensParadeChallengeCardId =
    'creature-card-rare-tens-parade-unicorn';

const List<CreatureCard> kCreatureCards = <CreatureCard>[
  CreatureCard(
    id: 'creature-card-fawn',
    displayName: 'Fawn',
    speciesId: 'fawn',
    spriteAsset: AssetPaths.countingParadeFawn,
    rarity: CardRarity.common,
    activityId: ActivityIds.countingParade,
  ),
  CreatureCard(
    id: 'creature-card-baby-gryphon',
    displayName: 'Baby Gryphon',
    speciesId: 'gryphon',
    spriteAsset: AssetPaths.countingParadeBabyGryphon,
    rarity: CardRarity.uncommon,
    activityId: ActivityIds.countingParade,
  ),
  CreatureCard(
    id: 'creature-card-baby-dragon',
    displayName: 'Baby Dragon',
    speciesId: 'dragon',
    spriteAsset: AssetPaths.countingParadeBabyDragon,
    rarity: CardRarity.uncommon,
    activityId: ActivityIds.countingParade,
  ),
  CreatureCard(
    id: 'creature-card-baby-unicorn',
    displayName: 'Baby Unicorn',
    speciesId: 'unicorn',
    spriteAsset: AssetPaths.countingParadeBabyUnicorn,
    rarity: CardRarity.uncommon,
    activityId: ActivityIds.countingParade,
  ),
  CreatureCard(
    id: 'creature-card-baby-phoenix',
    displayName: 'Baby Phoenix',
    speciesId: 'phoenix',
    spriteAsset: AssetPaths.countingParadeBabyPhoenix,
    rarity: CardRarity.rare,
    activityId: ActivityIds.countingParade,
  ),
  CreatureCard(
    id: 'creature-card-baby-centaur',
    displayName: 'Baby Centaur',
    speciesId: 'centaur',
    spriteAsset: AssetPaths.countingParadeBabyCentaur,
    rarity: CardRarity.uncommon,
    activityId: ActivityIds.countingParade,
  ),
  CreatureCard(
    id: 'creature-card-baby-toucan',
    displayName: 'Baby Toucan',
    speciesId: 'toucan',
    spriteAsset: AssetPaths.countingParadeBabyToucan,
    rarity: CardRarity.common,
    activityId: ActivityIds.countingParade,
  ),
  CreatureCard(
    id: 'creature-card-golden-egg',
    displayName: 'Golden Egg',
    speciesId: 'golden-egg',
    spriteAsset: AssetPaths.countingParadeGoldenEgg,
    rarity: CardRarity.rare,
    activityId: ActivityIds.countingParade,
  ),
  // ---- The rest of the set -------------------------------------------
  // `sanctuary-creature-cards-set` is authored as 24 cards and ran as nine for
  // as long as the album existed, so two thirds of it was a silhouette a child
  // could never turn over. These fifteen close it.
  //
  // All carry `speciesId: null`, like the Cloud Unicorn: they are card art
  // rather than parade cast, so there is no sprite in parade_species.dart for a
  // swap to propagate from. That is also why they are safe to add without
  // touching a single runner - the drop machinery rolls over this list filtered
  // by activityId, and Counting Parade is complete.
  //
  // Each lives somewhere. Until 2026-09-24 all fifteen carried Counting
  // Parade's activityId, which meant a passed round in Shape Garden, Where's
  // Buddy or Build-a-Habitat could never find a card at all - the album only
  // ever grew in one of the Sanctuary's places. Now every place has creatures
  // of its own, and the ones that fit it: the frog at the frog pond, the
  // squirrel in the pantry, the Star Turtle at the storyteller's pond, the
  // firefly in the tower where fireflies show the way. `creature_card_test`
  // holds every playable activity to having at least one.
  //
  // Rarity spread is the pacing lever, not decoration. cardRarityWeight makes a
  // common four times likelier than a rare, so ending at 10 common / 9 uncommon
  // / 5 rare means the album fills quickly at first and keeps two or three
  // genuinely hard-to-get faces in it for a long time.
  CreatureCard(
    id: 'creature-card-moss-bunny',
    displayName: 'Moss Bunny',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeMossBunny,
    rarity: CardRarity.common,
    activityId: ActivityIds.shapeGarden,
  ),
  CreatureCard(
    id: 'creature-card-acorn-squirrel',
    displayName: 'Acorn Squirrel',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeAcornSquirrel,
    rarity: CardRarity.common,
    activityId: ActivityIds.carePantry,
  ),
  CreatureCard(
    id: 'creature-card-berry-hedgehog',
    displayName: 'Berry Hedgehog',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeBerryHedgehog,
    rarity: CardRarity.common,
    activityId: ActivityIds.picnicBaskets,
  ),
  CreatureCard(
    id: 'creature-card-meadow-frog',
    displayName: 'Meadow Frog',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeMeadowFrog,
    rarity: CardRarity.common,
    activityId: ActivityIds.tenFramePond,
  ),
  CreatureCard(
    id: 'creature-card-star-turtle',
    displayName: 'Star Turtle',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeStarTurtle,
    rarity: CardRarity.common,
    activityId: ActivityIds.storytellersPond,
  ),
  CreatureCard(
    id: 'creature-card-honey-cub',
    displayName: 'Honey Cub',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeHoneyCub,
    rarity: CardRarity.common,
    activityId: ActivityIds.picnicBaskets,
  ),
  CreatureCard(
    id: 'creature-card-pebble-mouse',
    displayName: 'Pebble Mouse',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadePebbleMouse,
    rarity: CardRarity.common,
    activityId: ActivityIds.caretakersBench,
  ),
  CreatureCard(
    id: 'creature-card-firefly-sprite',
    displayName: 'Firefly Sprite',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeFireflySprite,
    rarity: CardRarity.common,
    activityId: ActivityIds.scribesTower,
  ),
  CreatureCard(
    id: 'creature-card-baby-pegasus',
    displayName: 'Baby Pegasus',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeBabyPegasus,
    rarity: CardRarity.uncommon,
    activityId: ActivityIds.buildAHabitat,
  ),
  CreatureCard(
    id: 'creature-card-crystal-deer',
    displayName: 'Crystal Deer',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeCrystalDeer,
    rarity: CardRarity.uncommon,
    activityId: ActivityIds.buildAHabitat,
  ),
  CreatureCard(
    id: 'creature-card-lantern-moth',
    displayName: 'Lantern Moth',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeLanternMoth,
    rarity: CardRarity.uncommon,
    activityId: ActivityIds.scribesTower,
  ),
  CreatureCard(
    id: 'creature-card-snow-fox',
    displayName: 'Snow Fox',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeSnowFox,
    rarity: CardRarity.uncommon,
    activityId: ActivityIds.wheresBuddy,
  ),
  CreatureCard(
    id: 'creature-card-rainbow-chameleon',
    displayName: 'Rainbow Chameleon',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeRainbowChameleon,
    rarity: CardRarity.uncommon,
    activityId: ActivityIds.wheresBuddy,
  ),
  CreatureCard(
    id: 'creature-card-moonlight-owl',
    displayName: 'Moonlight Owl',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeMoonlightOwl,
    rarity: CardRarity.rare,
    activityId: ActivityIds.fluencyWithin5,
  ),
  CreatureCard(
    id: 'creature-card-sunbeam-stag',
    displayName: 'Sunbeam Stag',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeSunbeamStag,
    rarity: CardRarity.rare,
    activityId: ActivityIds.shapeGarden,
  ),
  // The ninth member of `sanctuary-creature-cards-set`, and the only one the
  // parade cast does not supply - hence the null speciesId the field's own
  // doc has always promised. The catalog gives it exactly one source,
  // `{ type: challenge, challengeActivityId: counting-parade }`, and the
  // `challenge-counting-parade-chest` guarantees one card from a pool that
  // contains only this one. So it is not rolled for: finishing the Tens
  // Parade grants it. A rare that a hundred taps might still fail to produce
  // would be a worse reward than no card at all.
  CreatureCard(
    id: kTensParadeChallengeCardId,
    displayName: 'Cloud Unicorn',
    speciesId: null,
    spriteAsset: AssetPaths.countingParadeCloudUnicorn,
    rarity: CardRarity.rare,
    activityId: ActivityIds.countingParade,
    source: CardSource.challenge,
  ),
];

/// Relative weight when picking which un-owned card drops. Rare cards are
/// rarer by being picked less often, not by making the drop itself fail — a
/// round that promises a card and delivers nothing is worse than no promise.
int cardRarityWeight(CardRarity r) => switch (r) {
      CardRarity.common => 4,
      CardRarity.uncommon => 2,
      CardRarity.rare => 1,
    };

/// Spoken when she taps a card she has already found, in the album.
///
/// The album deliberately carries no text a pre-reader has to decode, which
/// leaves the name of the creature she met unreadable — the one thing a
/// collection is actually for. Naming it on a tap is the only channel she has.
///
/// The reveal overlay says [cardRevealLine] instead - a warmer framing for the
/// moment she earns one, against the bare name she gets when browsing.
String cardFoundLine(CreatureCard card) => '${card.displayName}.';

/// Spoken when she taps a silhouette.
///
/// Never a refusal, and never silence. A tap that produces nothing at all is
/// indistinguishable from a frozen app to a five-year-old, which is the single
/// failure this engagement pass exists to fix.
const String kCardNotFoundLine = "You haven't found this one yet.";

CreatureCard? creatureCardById(String id) {
  for (final c in kCreatureCards) {
    if (c.id == id) return c;
  }
  return null;
}

/// Every card the parade cast can yield. Asserts the two catalogs agree — a
/// species renamed in `parade_species.dart` without updating the card here
/// would silently produce a card picturing the wrong creature.
///
/// Cards with a null speciesId carry their own art and have no species to
/// check, so they are skipped rather than failing this.
bool debugCardSpeciesAreValid() => kCreatureCards.every(
      (c) => c.speciesId == null || kAllParadeSpeciesIds.contains(c.speciesId),
    );

/// Spoken over the reveal card, the moment a card is earned.
///
/// Enqueued rather than spoken: this beat arrives while the keeper is still
/// finishing the round, and NarrationPlayer's queue is what lets the second
/// line wait instead of cutting off the first. The card waits for a tap, so it
/// is still on screen when its turn comes.
String cardRevealLine(CreatureCard card) =>
    'A new friend! ${card.displayName}.';

/// The nudge for a child who has not tapped the card away.
///
/// The card says "Tap anywhere" in text she cannot read, so after a few
/// seconds the words arrive in the only channel she has. Spoken once, not on a
/// loop - a repeating instruction reads as being told off.
const String kCardTapToContinueLine = 'Tap anywhere to keep going.';
