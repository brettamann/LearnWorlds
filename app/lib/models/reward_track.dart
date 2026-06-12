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
  final Map<String, int> stageGrants;

  /// Shown after the kid has seen the final stage and returned to the map.
  /// This is the "graduated" state — the egg's hatched, the wand's lit, etc.
  final RewardStage completeStage;

  int get finalStage => stages.length;

  /// Compute the target stage given a set of completed activity ids.
  /// Returns 0 if no advancing activity has been completed yet.
  int computeTargetStage(Set<String> completedActivities) {
    var max = 0;
    for (final id in completedActivities) {
      final stage = stageGrants[id];
      if (stage != null && stage > max) max = stage;
    }
    return max;
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
