// ActivityScreen — hosts an ActivityRunner for the requested activity.
// Sprint 1 only knows Counting Parade; other activities fall back to the
// "coming soon" placeholder. M8 wires round resolution through the
// MasteryEngine + reward engine.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/button_labels.dart';
import '../../data/sanctuary_sequence.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/next_sub_mode.dart';
import '../../engines/scaffolding/scaffold_decision.dart';
import '../../engines/scaffolding/scaffold_engine.dart';
import '../../models/activity.dart';
import '../../models/reward_track.dart';
import '../../providers/app_providers.dart';
import '../../providers/exploration_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/reward_progress_provider.dart';
import '../../providers/save_provider.dart';
import '../../providers/sub_mode_progress_provider.dart';
import '../widgets/build_a_habitat_runner.dart';
import '../widgets/caption_overlay.dart';
import '../widgets/card_reveal_overlay.dart';
import '../widgets/care_pantry_runner.dart';
import '../widgets/caretakers_bench_runner.dart';
import '../widgets/coin_fly_layer.dart';
import '../widgets/coin_hud.dart';
import '../widgets/counting_parade_runner.dart';
import '../widgets/fluency_runner.dart';
import '../widgets/glitter_burst.dart';
import '../widgets/next_arrow_button.dart';
import '../widgets/picnic_baskets_runner.dart';
import '../widgets/scribes_tower_runner.dart';
import '../widgets/shape_garden_runner.dart';
import '../widgets/storytellers_pond_runner.dart';
import '../widgets/ten_frame_pond_runner.dart';
import '../widgets/wheres_buddy_runner.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({
    super.key,
    required this.activityId,
    this.launchExtra,
  });

  final String activityId;

  /// Optional payload from the LessonScreen handoff: subMode + round params.
  /// Null when the kid taps the activity tile directly (no lesson needed).
  final Map<String, dynamic>? launchExtra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(activityRegistryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          registry.maybeWhen(
            data: (r) => r.byId(activityId).displayName,
            orElse: () => activityId,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to the Sanctuary',
          onPressed: () => context.go('/sanctuary'),
        ),
        actions: const [
          // The wallet has been paying out since sprint 1 with nowhere to show
          // it. Mounted in the app bar rather than over the playfield so it
          // can't collide with any runner's layout.
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: CoinHud(compact: true)),
          ),
        ],
      ),
      body: Stack(
        children: [
          registry.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (data) {
              if (activityId == 'counting-parade') {
                final subMode =
                    (launchExtra?['subMode'] as String?) ?? 'count-the-parade';
                return CountingParadeRunner(
                  // The lesson screen already played the keeper intro before
                  // the iShow; don't replay it on the round.
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode: subMode,
                  // Lesson JSON has always carried a roundParameters block and
                  // LessonScreen has always routed it here; until now nothing
                  // read it, so authored content couldn't shape a round.
                  roundParameters:
                      launchExtra?['roundParameters'] as Map<String, dynamic>?,
                  onSequenceComplete: () => _onSuccess(context, ref),
                );
              }
              if (activityId == 'shape-garden') {
                // Lesson hand-off passes its `youDo.subMode` here so the
                // runner can dispatch to the right body (find-shape for
                // K.G.2 vs flat-or-solid for K.G.3). On a direct tap from
                // the Sanctuary map there's no lesson context — default
                // to the K.G.2 find-shape sub-mode.
                final subMode =
                    (launchExtra?['subMode'] as String?) ?? 'find-shape';
                return ShapeGardenRunner(
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode: subMode,
                  onSequenceComplete: () => _onSuccess(context, ref),
                );
              }
              if (activityId == 'wheres-buddy') {
                // K.G.1 has two playable sub-modes: place-mode (drag the
                // Buddy to a relative position) and find-mode (tap where
                // the Buddy is hiding). Default to the registry's
                // declared default (`find-mode`) on a direct tap.
                final subMode = (launchExtra?['subMode'] as String?) ??
                    kWheresBuddySubModeFindMode;
                return WheresBuddyRunner(
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode: subMode,
                  onSequenceComplete: () => _onSuccess(context, ref),
                );
              }
              if (activityId == 'build-a-habitat') {
                // K.G.5 (sticks + clay) runs as Phase 1 inside the
                // round; K.G.6 (compose) runs as Phase 2 of the same
                // round. The sub-mode picks how rich the build is —
                // simple-shelter (triangle + 1 piece), creature-home
                // (all three blueprints), grand-habitat (pentagon
                // challenge), or frame-only (skip Phase 2).
                final subMode = (launchExtra?['subMode'] as String?) ??
                    kBuildAHabitatSubModeSimpleShelter;
                return BuildAHabitatRunner(
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode: subMode,
                  onSequenceComplete: () => _onSuccess(context, ref),
                );
              }
              if (activityId == 'ten-frame-pond') {
                return TenFramePondRunner(
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode:
                      (launchExtra?['subMode'] as String?) ?? 'fill-to-target',
                  onSequenceComplete: () => _onSuccess(context, ref),
                );
              }
              if (activityId == 'care-pantry') {
                return CarePantryRunner(
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode:
                      (launchExtra?['subMode'] as String?) ?? 'simple-pantry',
                  onSequenceComplete: () => _onSuccess(context, ref),
                );
              }
              if (activityId == 'scribes-tower') {
                return ScribesTowerRunner(
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode:
                      (launchExtra?['subMode'] as String?) ?? 'trace-numeral',
                  onSequenceComplete: () => _onSuccess(context, ref),
                );
              }
              if (activityId == 'storytellers-pond') {
                return StorytellersPondRunner(
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode: (launchExtra?['subMode'] as String?) ?? 'add-to',
                  onSequenceComplete: () => _onSuccess(context, ref),
                );
              }
              if (activityId == 'caretakers-bench') {
                return CaretakersBenchRunner(
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode: (launchExtra?['subMode'] as String?) ??
                      'describe-attributes',
                  onSequenceComplete: () => _onSuccess(context, ref),
                );
              }
              if (activityId == 'picnic-baskets') {
                return PicnicBasketsRunner(
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode:
                      (launchExtra?['subMode'] as String?) ?? 'match-by-line',
                  onSequenceComplete: () => _onSuccess(context, ref),
                );
              }
              if (activityId == 'fluency-within-5') {
                return FluencyRunner(
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode: (launchExtra?['subMode'] as String?) ?? 'casual',
                  onSequenceComplete: () => _onSuccess(context, ref),
                );
              }
              // A developer-only landing now. The Sanctuary map draws a node
              // with no runner behind it as asleep and answers a tap out loud
              // instead of routing here (see kPlayableActivities), because a
              // sentence in English on a blank screen is, to the person this
              // game is for, indistinguishable from the app having crashed.
              // The only way in is Settings → "Launch a specific lesson".
              return Center(
                child: Text('Activity "$activityId" lands in a later sprint.'),
              );
            },
          ),
          const CaptionOverlay(),
          // Topmost, and IgnorePointer throughout. Every resolveRound call in
          // the app happens inside a runner rendered by this Stack, so this is
          // the only mount point the payout animation needs.
          const CoinFlyLayer(),
          // Above the coins: a card is the one reward beat allowed to stop
          // play, and it must not have coins sailing across it.
          const CardRevealOverlay(),
        ],
      ),
    );
  }

  /// Round-success handler. Records the just-cleared sub-mode, then —
  /// only when every non-challenge sub-mode of the activity is now done —
  /// reveals the map node, advances the egg track, and (the first time
  /// that flip happens for counting-parade) routes into the Haddock-gift
  /// presentation.
  void _onSuccess(BuildContext context, WidgetRef ref) {
    // Measured as a stage number rather than "has counting-parade been
    // completed", because the egg now also advances per cleared sub-mode.
    // The gift moment is simply the track leaving stage zero — whichever
    // source got it there.
    final eggBefore = ref.read(rewardProgressProvider)[kMysteryEggTrack.id] ??
        const RewardTrackState();
    final stageBefore = kMysteryEggTrack.computeTargetStage(
      eggBefore.completedActivities,
      eggBefore.completionEvents,
      eggBefore.lastSeenStage,
    );

    _markActivityCompleted(ref);

    final eggAfter = ref.read(rewardProgressProvider)[kMysteryEggTrack.id] ??
        const RewardTrackState();
    final stageAfter = kMysteryEggTrack.computeTargetStage(
      eggAfter.completedActivities,
      eggAfter.completionEvents,
      eggAfter.lastSeenStage,
    );
    final isFirstEggMoment = stageBefore == 0 && stageAfter >= 1;

    if (isFirstEggMoment) {
      context.go('/reward/k-mystery-egg-gift');
      return;
    }
    // Auto-advance: if more non-challenge sub-modes remain for this
    // activity, the round-complete sheet's Continue button routes the kid
    // straight into the next one instead of dumping them back on the
    // Sanctuary map. A child who ended the visit struggling goes one step
    // simpler instead of one step harder.
    final nextSubMode = _findNextSubMode(ref);
    _showRoundCompleteSheet(
      context,
      ref,
      nextSubMode: nextSubMode,
      // The stage the egg has just reached, and whether this sitting is what
      // moved it. Read here rather than in the sheet because by the time the
      // sheet builds, "before" is gone.
      eggStage: stageAfter,
      eggAdvanced: stageAfter > stageBefore,
    );
  }

  /// What "Next!" plays - see `next_sub_mode.dart`. Null when the chain is
  /// finished (a replay), and the sheet falls back to "Sanctuary".
  ///
  /// Chain, not merely non-challenge: a demotion floor below the entry point
  /// is the easiest thing in the activity, and auto-advancing into it made
  /// the last build of Build-a-Habitat the simplest one — the ramp running
  /// backwards on the culminating round. The floor is now reached only by a
  /// child who ended a visit struggling, which is who it was written for.
  SubMode? _findNextSubMode(WidgetRef ref) {
    final registry = ref.read(activityRegistryProvider).valueOrNull;
    final activity = registry?.byIdOrNull(activityId);
    if (activity == null) return null;
    final playedId = (launchExtra?['subMode'] as String?) ??
        _defaultSubModeForActivity(activityId);
    final played = activity.subModes.where((m) => m.id == playedId).firstOrNull;
    final conceptId = played != null && played.primaryConcepts.isNotEmpty
        ? played.primaryConcepts.first
        : activity.concepts.first.conceptId;
    return nextSubModeAfter(
      activity: activity,
      playedId: playedId,
      completed:
          ref.read(subModeProgressProvider.notifier).completedFor(activityId),
      state: ref.read(kidProgressProvider.notifier).getOrCreate(conceptId),
    );
  }

  /// Routes into the next sub-mode through the same ScaffoldEngine
  /// decision the Sanctuary picker uses — first-time picks land on the
  /// lesson, subsequent picks proceed straight to the activity round.
  void _routeToNextSubMode(
    BuildContext context,
    WidgetRef ref,
    SubMode subMode,
  ) {
    final registry = ref.read(activityRegistryProvider).valueOrNull;
    final concepts = ref.read(conceptRegistryProvider).valueOrNull;
    if (registry == null || concepts == null) {
      context.go('/sanctuary');
      return;
    }
    final activity = registry.byIdOrNull(activityId);
    if (activity == null) {
      context.go('/sanctuary');
      return;
    }
    // Sub-modes with their own animated intro skip ScaffoldEngine —
    // letting it fire the introducing-concept's lesson on top would
    // stack the wrong demo in front of the runner's own one. Mirrors
    // the same short-circuit in sanctuary_map_screen `_routeForSubMode`.
    if (subMode.ownsIntro) {
      context.go(
        '/activity/${activity.id}',
        extra: <String, dynamic>{'subMode': subMode.id},
      );
      return;
    }
    const engine = ScaffoldEngine();
    final entryConceptId = subMode.primaryConcepts.isNotEmpty
        ? subMode.primaryConcepts.first
        : activity.concepts.first.conceptId;
    final concept = concepts.byId(entryConceptId);
    final state =
        ref.read(kidProgressProvider.notifier).getOrCreate(concept.id);
    final decision = engine.decide(
      activity: activity,
      concept: concept,
      state: state,
    );
    switch (decision) {
      case PlayLesson(:final lessonId):
        context.go(
          '/lesson/$lessonId',
          extra: <String, dynamic>{'subMode': subMode.id},
        );
      case ProceedAtLayer():
        context.go(
          '/activity/${activity.id}',
          extra: <String, dynamic>{'subMode': subMode.id},
        );
    }
  }

  /// Records the just-cleared sub-mode and — when every non-challenge
  /// sub-mode of this activity is now complete — also reveals the map
  /// node and grants the activity-level reward track stage. The egg
  /// gift presentation in `_onSuccess` is gated on the same condition,
  /// so the kid only meets Haddock-with-egg after finishing the full
  /// counting curriculum, not just the first sub-mode.
  void _markActivityCompleted(WidgetRef ref) {
    final subMode = (launchExtra?['subMode'] as String?) ??
        _defaultSubModeForActivity(activityId);
    ref.read(subModeProgressProvider.notifier).markCompleted(
          activityId: activityId,
          subModeId: subMode,
        );
    // Unconditional, and deliberately *not* gated on the whole activity being
    // done: this is the beat the egg now advances on. Keyed by sub-mode so
    // replaying one she already cleared can't push the track forward again.
    ref.read(rewardProgressProvider.notifier).markCompletionEvent(
          trackId: kMysteryEggTrack.id,
          key: '$activityId/$subMode',
        );
    if (_allChainSubModesDone(ref)) {
      final code = kSanctuaryCodeByActivity[activityId];
      if (code != null) {
        ref.read(explorationProvider.notifier).markCompleted(code);
      }
      ref.read(rewardProgressProvider.notifier).markActivityCompleted(
            trackId: kMysteryEggTrack.id,
            activityId: activityId,
          );
    }
    ref.read(saveCoordinatorProvider).persist();
  }

  /// True when every chain sub-mode of this activity has been completed at
  /// least once. Used to gate map-node exploration + reward track
  /// advancement — both should only fire when the activity is fully
  /// cleared, not on the first sub-mode.
  ///
  /// A floor below the entry point is excluded, and on this map that is not
  /// a nicety. Node completion is what lifts the fog on the next node,
  /// Build-a-Habitat is what stands between the child and Where's Buddy, and
  /// requiring `frame-only` put the remedial drill on the critical path out
  /// of the activity for a child who never needed it.
  bool _allChainSubModesDone(WidgetRef ref) {
    final registry = ref.read(activityRegistryProvider).valueOrNull;
    if (registry == null) return false;
    final activity = registry.byIdOrNull(activityId);
    if (activity == null) return false;
    final completed =
        ref.read(subModeProgressProvider.notifier).completedFor(activityId);
    for (final subMode in activity.subModes) {
      if (!subMode.isChainStep) continue;
      if (!completed.contains(subMode.id)) return false;
    }
    return true;
  }

  /// Sensible per-activity default sub-mode when the kid arrived without
  /// a `subMode` in `launchExtra` (e.g. via a direct route in dev tools).
  static String _defaultSubModeForActivity(String activityId) {
    switch (activityId) {
      case 'counting-parade':
        return 'count-the-parade';
      case 'shape-garden':
        return 'find-shape';
      case 'wheres-buddy':
        return 'find-mode';
      case 'build-a-habitat':
        return 'simple-shelter';
      case 'ten-frame-pond':
        return 'fill-to-target';
      case 'care-pantry':
        return 'simple-pantry';
      case 'scribes-tower':
        return 'trace-numeral';
      case 'storytellers-pond':
        return 'add-to';
      case 'caretakers-bench':
        return 'describe-attributes';
      case 'picnic-baskets':
        return 'match-by-line';
      case 'fluency-within-5':
        return 'casual';
      default:
        return 'default';
    }
  }

  /// The beat at the end of a sub-mode — the one blocking celebration
  /// `activity-progress-bar.md` asks for.
  ///
  /// It used to be a Material `Icons.celebration` glyph, the words "Nicely
  /// counted!" at 32 point, and an arrow. Three things wrong with that, all
  /// of them the same thing: it said "counted" at the end of a sorting round
  /// and a hide-and-seek round; the words were the only content and they were
  /// words; and it made no sound at all, so the payoff beat of every sub-mode
  /// was a mystery box in front of a child who cannot read.
  ///
  /// It shows the egg now. That is not decoration — it is the only place the
  /// egg's motion can actually be seen. `RewardOverlay` plays the
  /// advancement fanfare, but it lives on the Sanctuary map, and this sheet
  /// usually routes straight into the next sub-mode without passing it. Since
  /// the track was retuned to advance once per cleared sub-mode, that meant
  /// the game's one long-cycle reward moved after every sitting and she was
  /// almost never there to see it.
  void _showRoundCompleteSheet(
    BuildContext context,
    WidgetRef ref, {
    required SubMode? nextSubMode,
    required int eggStage,
    required bool eggAdvanced,
  }) {
    final hasNext = nextSubMode != null;
    // Stage 0 cannot normally reach here — the first completion routes to the
    // gift screen instead — but a save that predates the track would, and a
    // null sprite in front of her is worse than a plain congratulation.
    final stage = eggStage >= 1 && eggStage <= kMysteryEggTrack.finalStage
        ? kMysteryEggTrack.stageByNumber(eggStage)
        : null;
    final line = stage?.message ?? kRoundCompleteFallbackLine;

    // The two sounds this beat was missing. `whoosh` for the sheet arriving,
    // which every sheet in the game did in silence; `eggCrack` only when this
    // sitting is what moved the egg, which is the one sound in the catalog
    // written for a specific moment and played at none.
    final feedback = ref.read(feedbackEngineProvider);
    feedback.whoosh();
    if (eggAdvanced) feedback.eggAdvance();

    // Enqueued, not spoken. The runner's own closing keeper line is very
    // likely still in flight — she taps Continue on the interstitial and this
    // sheet is what the tap opens — and `speak` would cut it off mid-word.
    ref.read(narrationPlayerProvider.notifier).enqueue(
          NarrationLine(text: line, cueId: 'round-complete:egg-$eggStage'),
          caption: false,
        );

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => RoundCompleteSheet(
        stage: stage,
        line: line,
        celebrate: eggAdvanced,
        arrowLabel: hasNext ? kLabelNextBang : kLabelSanctuary,
        idleHintText: hasNext
            ? 'Tap the arrow to keep going!'
            : 'Tap the arrow to head back to the Sanctuary!',
        onNext: () {
          Navigator.of(sheetCtx).pop();
          if (hasNext) {
            _routeToNextSubMode(context, ref, nextSubMode);
          } else {
            GoRouter.of(context).go('/sanctuary');
          }
        },
      ),
    );
  }
}

/// The body of the end-of-sub-mode sheet, pulled out so a test can mount it
/// without playing a whole sub-mode to get there.
class RoundCompleteSheet extends StatelessWidget {
  const RoundCompleteSheet({
    super.key,
    required this.stage,
    required this.line,
    required this.celebrate,
    required this.arrowLabel,
    required this.idleHintText,
    required this.onNext,
  });

  /// The reward stage to show, or null for a save with no egg yet.
  final RewardStage? stage;

  /// The words being spoken over it.
  final String line;

  /// True only when this sitting is what moved the egg.
  final bool celebrate;

  final String arrowLabel;
  final String idleHintText;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 164,
            height: 164,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (stage == null)
                  const Icon(Icons.celebration, size: 96, color: Colors.amber)
                else
                  Image.asset(stage!.spriteAsset, fit: BoxFit.contain),
                // Only when this sitting is what moved it. A burst on every
                // sub-mode would stop meaning "something happened".
                if (celebrate)
                  const Positioned.fill(
                    child: IgnorePointer(child: GlitterBurst()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // The same words that are being spoken. Kept visible for the adult
          // reading over her shoulder, and small, because it is the second
          // channel here rather than the first.
          Text(
            line,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: NextArrowButton(
              key: const ValueKey('round-complete-next'),
              idleHintEnabled: true,
              idleHintText: idleHintText,
              onPressed: onNext,
              label: arrowLabel,
            ),
          ),
        ],
      ),
    );
  }
}
