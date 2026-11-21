// ParadeSpecies — the Counting Parade cast, as a catalog keyed by id.
//
// This used to be a private `_ParadeCreature` const list inside the runner,
// with the eight rounds, their counts, and their keeper transition lines all
// baked in. That made every playthrough byte-identical — same species, same
// order, same numbers, forever — which is a large part of why the activity
// felt repetitive on the second visit.
//
// Pulling the cast out here lets lesson JSON name species by id
// (`speciesPool`) and lets ParadeRoundPlanner shuffle them, while the
// AssetPaths indirection specs/shared/counting-sequence.md asks for stays put.
//
// Kitten and puppy sprites ship in the folder but are deliberately absent:
// the Sanctuary's fiction is mythical creatures, and mundane pets break it.

import 'asset_paths.dart';
import 'number_words.dart';

class ParadeSpecies {
  const ParadeSpecies({
    required this.id,
    required this.spriteAsset,
    required this.singular,
    required this.plural,
  });

  /// Stable id. This is what lesson JSON references in `speciesPool`, so
  /// renaming one is a content-breaking change.
  final String id;

  final String spriteAsset;

  /// Lowercase, used in the counting prompt ("Touch each fawn").
  final String singular;

  /// Lowercase, used in cardinality and transition lines ("three fawns").
  final String plural;
}

// One const per member, so a fixed round list (Count Forward From N, Long
// Parade...) can name its creature rather than restate its sprite and words.
const ParadeSpecies kParadeFawn = ParadeSpecies(
  id: 'fawn',
  spriteAsset: AssetPaths.countingParadeFawn,
  singular: 'fawn',
  plural: 'fawns',
);

const ParadeSpecies kParadeGryphon = ParadeSpecies(
  id: 'gryphon',
  spriteAsset: AssetPaths.countingParadeBabyGryphon,
  singular: 'gryphon',
  plural: 'gryphons',
);

const ParadeSpecies kParadeDragon = ParadeSpecies(
  id: 'dragon',
  spriteAsset: AssetPaths.countingParadeBabyDragon,
  singular: 'dragon',
  plural: 'dragons',
);

const ParadeSpecies kParadeUnicorn = ParadeSpecies(
  id: 'unicorn',
  spriteAsset: AssetPaths.countingParadeBabyUnicorn,
  singular: 'unicorn',
  plural: 'unicorns',
);

const ParadeSpecies kParadePhoenix = ParadeSpecies(
  id: 'phoenix',
  spriteAsset: AssetPaths.countingParadeBabyPhoenix,
  singular: 'phoenix',
  plural: 'phoenixes',
);

const ParadeSpecies kParadeCentaur = ParadeSpecies(
  id: 'centaur',
  spriteAsset: AssetPaths.countingParadeBabyCentaur,
  singular: 'centaur',
  plural: 'centaurs',
);

const ParadeSpecies kParadeToucan = ParadeSpecies(
  id: 'toucan',
  spriteAsset: AssetPaths.countingParadeBabyToucan,
  singular: 'toucan',
  plural: 'toucans',
);

const ParadeSpecies kParadeGoldenEgg = ParadeSpecies(
  id: 'golden-egg',
  spriteAsset: AssetPaths.countingParadeGoldenEgg,
  singular: 'golden egg',
  plural: 'golden eggs',
);

const List<ParadeSpecies> kParadeSpecies = <ParadeSpecies>[
  kParadeFawn,
  kParadeGryphon,
  kParadeDragon,
  kParadeUnicorn,
  kParadePhoenix,
  kParadeCentaur,
  kParadeToucan,
  kParadeGoldenEgg,
];

const List<String> kAllParadeSpeciesIds = <String>[
  'fawn',
  'gryphon',
  'dragon',
  'unicorn',
  'phoenix',
  'centaur',
  'toucan',
  'golden-egg',
];

/// Falls back to the first entry rather than throwing: a typo in authored
/// lesson JSON should degrade to a playable round, not a crash in a child's
/// hands.
ParadeSpecies paradeSpeciesById(String id) => kParadeSpecies.firstWhere(
  (s) => s.id == id,
  orElse: () => kParadeSpecies.first,
);

/// The keeper's between-round line: celebratory and species-specific, per
/// specs/shared/counting-sequence.md.
///
/// Generated rather than authored per-round because the rounds are shuffled -
/// a hardcoded "Now the gryphon babies" cannot survive a species order that
/// changes each session. [rotation] varies the phrasing so five rounds do not
/// land in the same rhythm; k-activity-patterns.md asks for 2-4 alternatives
/// on any line a kid hears repeatedly.
///
/// It deliberately does NOT name the species coming next. Naming it made the
/// line depend on three things at once - the count, the species finished and
/// the species next - which is 1,792 sentences, of which a session speaks
/// four. That put the line permanently out of reach of a recorded voice, so it
/// was the one beat in a round that switched back to the browser synth. Not
/// naming the next species costs nothing: the next creatures are on screen a
/// second later, and she can see them.
///
/// Note this line carries the cardinality itself. It is the ONLY thing spoken
/// at the round boundary - SystemTts cancels whatever is in flight when a new
/// utterance starts, so a separate "three!" line here would cut this one off.
String paradeTransitionLine({
  required int count,
  required ParadeSpecies done,
  required int rotation,
}) {
  final n = spellNumber(count);
  final cap = spellNumberCapitalized(count);
  switch (rotation.abs() % 4) {
    case 0:
      return '$cap ${done.plural}! Beautifully counted.';
    case 1:
      return "That's $n ${done.plural}. Every one of them.";
    case 2:
      return '$cap ${done.plural}, all here.';
    default:
      return 'Good counting — $n ${done.plural}.';
  }
}

/// The wrap-up after the final round. Names the total so the last thing a kid
/// hears is the cardinality, which is the point of K.CC.4b.
String paradeFinalLine({required int count, required ParadeSpecies done}) =>
    'All ${spellNumber(count)} ${done.plural} counted. Beautifully done.';

/// Keeper's opening ask, framed as helping Buddy rather than answering the
/// keeper — specs/shared/k-activity-patterns.md keeps every word in the
/// narrator's voice while moving the *job* to the two of them together.
///
/// Lifted out of CountingParadeRunner so `narration_script.dart` can enumerate
/// it for recording. The generator must call the same code the game calls, or
/// the script drifts from what a child actually hears and the clips silently
/// stop matching.
String paradeIntroDialog({
  required int count,
  required ParadeSpecies species,
}) =>
    // The keeper's failing, not the creatures' behaviour. An earlier wording
    // had them "wander off every time I blink", which broke on the one species
    // in kAllParadeSpeciesIds that cannot walk: it generated "The golden eggs
    // wander off every time I blink" about one visit in eight. Losing track is
    // true of anything in a meadow, and it motivates the task better besides:
    // if things wander you fetch them, but if you lose track you count.
    "Oh, thank goodness you're here. I lose track of the ${species.plural} "
    'every time I blink. Buddy is still learning to count — can you show '
    'Buddy how, and make sure all ${spellNumber(count)} are still in the '
    'meadow?';

/// The instruction spoken as the counting phase opens.
String paradeCountingPrompt(ParadeSpecies species) =>
    'Touch each ${species.singular} — and count out loud with me!';

/// The keeper's last line of a visit, as she hands over the coins.
///
/// It used to name a total - rounds x the clean-round rate - which overstated
/// the payout whenever a round needed help, and could only be recorded for the
/// six round counts someone remembered to enumerate. Every other activity says
/// "some coins"; so does this one.
const String kParadeRewardLine =
    'Thank you, friend! Here are some coins from the Sanctuary.';

/// What the Done arrow says when she has counted everything and left it
/// waiting.
const String kParadeDoneHint =
    'You counted them all! Tap the arrow to keep going.';

/// "a" or "an" for [word].
///
/// Every species in the cast today takes "a", so this changes nothing yet.
/// It is here because the first one that does not - an owl, an elk - would
/// otherwise ship as "a owl" in a *recorded* clip, which is a worse bug than
/// it sounds: the wording is the clip key, so the fix would also orphan the
/// recording and silently drop the line back to the browser voice.
String paradeArticle(String word) =>
    'aeiou'.contains(word.isEmpty ? 'x' : word[0].toLowerCase()) ? 'an' : 'a';

/// Spoken over the card that introduces the round's creature, before any
/// counting starts.
///
/// The card exists because a pre-reader has no way to learn what she is
/// looking at. She counts fawns for a round and never finds out they are
/// fawns; the sprite is a picture of an animal and nothing names it. Naming it
/// first also gives the count something to be *about*, which is the difference
/// between counting shapes on a screen and counting the fawns in the meadow.
String paradeSpeciesIntroLine(ParadeSpecies species) =>
    'This is ${paradeArticle(species.singular)} ${species.singular}! '
    "Let's count them next!";

/// The card's title, which is the species name with a capital letter. Derived
/// rather than authored so it cannot disagree with the spoken line.
String paradeSpeciesTitle(ParadeSpecies species) =>
    species.singular[0].toUpperCase() + species.singular.substring(1);
