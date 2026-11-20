// RewardTrack — a grade-spanning collectible whose state evolves as the kid
// completes specific lessons. Lives in the corner of the region map; taps
// show a flavour message; advancement triggers a fanfare animation.
//
// Each grade owns ≥1 track. K has the mystery egg (Haddock hands you an egg
// at the end of the first lesson; it shakes, cracks, and hatches over the
// course of the curriculum, becoming a baby dragon you can find at home).
// Future tracks (1st-grade wand spark, 2nd-grade hero badge, etc.) plug in
// via the same shape.
//
// See specs/shared/reward-tracks.md.

import '../data/asset_paths.dart';

/// How "alive" the sprite feels in its corner. Drives the idle wiggle.
enum RewardAmbient { still, gentle, moderate, energetic, gentleHatched }

class RewardStage {
  const RewardStage({
    required this.spriteAsset,
    required this.message,
    required this.ambient,
  });

  /// Sprite drawn in the corner.
  final String spriteAsset;

  /// Flavour line shown when the kid taps the corner sprite.
  final String message;

  /// How animated the sprite should be in its idle state.
  final RewardAmbient ambient;
}

class RewardTrack {
  const RewardTrack({
    required this.id,
    required this.name,
    required this.stages,
    required this.stageGrants,
    required this.completeStage,
    this.eventsPerStage = 0,
  });

  /// Stable id used by save persistence + analytics.
  final String id;

  /// Human-readable name (parent dashboard, save metadata).
  final String name;

  /// Ordered list of stages 1..N. `stages[0]` is stage 1.
  final List<RewardStage> stages;

  /// Activity-id → stage-number map. When the kid completes an activity in
  /// this map, the track's target stage becomes `max(currentTarget, value)`.
  /// Activities not in the map don't advance the track (but may still be
  /// part of the curriculum).
  ///
  /// This is now a *floor* rather than the only driver — see [eventsPerStage].
  /// Keeping it means existing saves and the counting-parade gift moment
  /// behave exactly as before.
  final Map<String, int> stageGrants;

  /// Completion events needed per stage, or 0 to advance on [stageGrants]
  /// alone.
  ///
  /// Grants alone advanced the egg once per *whole activity* — every
  /// non-challenge sub-mode of Counting Parade, which is about thirty-one
  /// rounds before Haddock ever hands the egg over. specs/shared/reward-tracks.md
  /// says this track is what "carries the kid through the dry middle of the
  /// curriculum", and at that cadence it was very nearly a static picture.
  ///
  /// Counting sub-modes instead puts the first stage at roughly round five and
  /// gives the map something visibly different to come back to after most
  /// sittings, which is the whole retention mechanic.
  final int eventsPerStage;

  /// Shown after the kid has seen the final stage and returned to the map.
  /// This is the "graduated" state — the egg's hatched, the wand's lit, etc.
  final RewardStage completeStage;

  int get finalStage => stages.length;

  /// Compute the target stage from completed activities and completion
  /// events. Returns 0 if neither has advanced the track yet.
  ///
  /// The two sources are combined with `max`, never summed: whichever has
  /// carried the kid further wins. That keeps [stageGrants] working as a
  /// floor, so a save written before [eventsPerStage] existed lands on the
  /// same stage it always did.
  ///
  /// [seen] is the highest stage she has already been shown, and the result
  /// never drops below it. The pace of the track is a dial that gets turned -
  /// it was slowed from one sitting a stage to two when the Sanctuary's other
  /// seven places were built - and without the floor, turning it would make
  /// an egg she had watched crack open visibly un-crack.
  int computeTargetStage(
    Set<String> completedActivities, [
    Set<String> completionEvents = const <String>{},
    int seen = 0,
  ]) {
    var max = seen;
    for (final id in completedActivities) {
      final stage = stageGrants[id];
      if (stage != null && stage > max) max = stage;
    }
    if (eventsPerStage > 0) {
      // The first event is worth a stage on its own, whatever the pace: it is
      // the moment Haddock hands her the egg, at the end of her very first
      // sitting, and that hook is not something to slow down. The pace
      // applies from the second stage on.
      final n = completionEvents.length;
      final fromEvents = n == 0 ? 0 : 1 + (n - 1) ~/ eventsPerStage;
      if (fromEvents > max) max = fromEvents;
    }
    return max > finalStage ? finalStage : max;
  }

  RewardStage stageByNumber(int n) {
    if (n < 1 || n > stages.length) {
      throw ArgumentError('Stage $n out of range for track $id');
    }
    return stages[n - 1];
  }
}

/// The K-region mystery egg. Stage grants follow the map-sequence rule
/// requested by the design: lesson 1 grants stage 1 (egg given), lessons
/// 2–4 stay at stage 1, lessons 5–11 each advance the egg by one. Lesson
/// 11 (Fluency Within 5) is the final advancement to stage 8; the next
/// visit to the Sanctuary map graduates the track to the hatched state.
final RewardTrack kMysteryEggTrack = RewardTrack(
  id: 'k-mystery-egg',
  name: 'Haddocks Mystery Egg',
  stages: List<RewardStage>.unmodifiable([
    RewardStage(
      spriteAsset: AssetPaths.kMysteryEggStage(1),
      message: 'Haddock gave you this mysterious egg to look after. '
          'Keep counting and see what hatches!',
      ambient: RewardAmbient.still,
    ),
    RewardStage(
      spriteAsset: AssetPaths.kMysteryEggStage(2),
      message: 'The egg gave a little jump just now. Strange... '
          'keep at your studies!',
      ambient: RewardAmbient.gentle,
    ),
    RewardStage(
      spriteAsset: AssetPaths.kMysteryEggStage(3),
      message: "A small crack has appeared on the egg's shell. Whatever's "
          "inside is getting restless — don't stop now!",
      ambient: RewardAmbient.gentle,
    ),
    RewardStage(
      spriteAsset: AssetPaths.kMysteryEggStage(4),
      message: "The crack is bigger and the egg shakes when you're "
          'not looking. Keep going!',
      ambient: RewardAmbient.moderate,
    ),
    RewardStage(
      spriteAsset: AssetPaths.kMysteryEggStage(5),
      message: 'Something inside is tapping! What could it be? '
          'Keep your studies up.',
      ambient: RewardAmbient.moderate,
    ),
    RewardStage(
      spriteAsset: AssetPaths.kMysteryEggStage(6),
      message: 'The egg trembles and you hear faint chirps. '
          'Almost there...',
      ambient: RewardAmbient.energetic,
    ),
    RewardStage(
      spriteAsset: AssetPaths.kMysteryEggStage(7),
      message: 'The egg is rocking and a tiny snout has poked through! '
          'Just a little more learning to do.',
      ambient: RewardAmbient.energetic,
    ),
    RewardStage(
      spriteAsset: AssetPaths.kMysteryEggStage(8),
      message: "It's about to hatch any second! Finish your last lesson "
          "to find out what's inside!",
      ambient: RewardAmbient.energetic,
    ),
  ]),
  // Lesson 1 (Counting Parade) → stage 1. Then non-advancing lessons 2–4.
  // Then one advance per lesson from F5 through FB.
  // One cleared sub-mode per stage.
  //
  // This was two, tuned against the K curriculum as *authored* — eleven
  // activities, far more sub-modes than the egg has stages, so a stage per
  // sub-mode "would hatch in the first week and leave the rest of the grade
  // with no track running". Sound reasoning about content that does not exist.
  // Four of those eleven activities are built, and their non-optional
  // sub-modes come to thirteen against the sixteen events two-per-stage needs.
  // A child could clear every last thing in the game, never hatch the egg, and
  // never even reach stage eight — whose line is "It's about to hatch any
  // second! Finish your last lesson to find out what's inside!"
  //
  // At one, the egg moves every time she finishes a sitting, which is the
  // right cadence for a five-year-old anyway, and hatches at eight of the
  // thirteen. The tail is real: five sub-modes and four challenges play out
  // after the payoff with this track finished. That is the cost, and it is a
  // much smaller cost than a carrot that can never be reached.
  //
  // It also moves the gift. `isFirstEggMoment` fires when the track first
  // reaches stage 1, so Haddock now hands the egg over at the end of her very
  // first sitting rather than her second. Taken deliberately rather than
  // swallowed: a first session that ends with someone giving her a mystery to
  // look after is the hook, and it is the same reason Teach Your Monster hands
  // you a monster inside the first minute.
  //
  // `egg_can_hatch_test.dart` checks this against the sub-modes that actually
  // exist rather than against a plan, and it is also the signal for turning
  // the dial back up: when the remaining seven activities land it will still
  // pass at two, and that is the moment to slow it down again.
  //
  // 2026-09-24: they landed, and it is two. With every Sanctuary place built
  // there are about thirty chain sub-modes, and at one a stage the egg
  // hatched a quarter of the way along the path and left three quarters of
  // the Sanctuary with no long-cycle reward at all. At two it hatches around
  // the middle. An egg already further along than the new pace puts it is
  // held where it was - see `seen` in computeTargetStage.
  //
  // 2026-09-25: four. Walking the path in order, two a stage put stage eight
  // - "finish your last lesson to find out what's inside!" - in Care Pantry,
  // the fifth place of eleven, and the hatch straight after it. Four puts a
  // stage at roughly every place she finishes (Counting Parade's five
  // sub-modes carry it to two, Shape Garden to three, and so on), stage
  // eight in Picnic Baskets and the hatch on the way to the last place, which
  // is the arc reward-tracks.md drew. The short-cycle rewards moved in to fill
  // the gaps since this was last set: a card a round at one in four from the
  // place she is in, coins she can spend on Buddy, and the egg on the
  // end-of-sub-mode sheet every time whether it moved or not.
  // `egg_can_hatch_test.dart` pins both ends.
  eventsPerStage: 4,
  stageGrants: const {
    'counting-parade': 1,
    'care-pantry': 2,
    'scribes-tower': 3,
    'storytellers-pond': 4,
    'wheres-buddy': 5,
    'caretakers-bench': 6,
    'picnic-baskets': 7,
    'fluency-within-5': 8,
  },
  completeStage: const RewardStage(
    spriteAsset: AssetPaths.kMysteryEggComplete,
    message: 'Your baby dragon is exploring the Sanctuary. '
        'Visit your home to find them!',
    ambient: RewardAmbient.gentleHatched,
  ),
);
