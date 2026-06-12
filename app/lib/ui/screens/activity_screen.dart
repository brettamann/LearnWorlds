// ActivityScreen — hosts an ActivityRunner for the requested activity.
// Sprint 1 only knows Counting Parade; other activities fall back to the
// "coming soon" placeholder. M8 wires round resolution through the
// MasteryEngine + reward engine.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/sanctuary_sequence.dart';
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
import '../widgets/caption_overlay.dart';
import '../widgets/counting_parade_runner.dart';
import '../widgets/next_arrow_button.dart';
import '../widgets/shape_garden_runner.dart';

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
      ),
      body: Stack(
        children: [
          registry.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (data) {
              if (activityId == 'counting-parade') {
                final subMode = (launchExtra?['subMode'] as String?) ??
                    'count-the-parade';
                return CountingParadeRunner(
                  // The lesson screen already played the keeper intro before
                  // the iShow; don't replay it on the round.
                  skipIntro: launchExtra?['fromLesson'] != null,
                  subMode: subMode,
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
              return Center(
                child: Text('Activity "$activityId" lands in a later sprint.'),
              );
            },
          ),
          const CaptionOverlay(),
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
    final eggBefore = ref.read(rewardProgressProvider)[kMysteryEggTrack.id] ??
        const RewardTrackState();
    final hadEggBefore =
        eggBefore.completedActivities.contains('counting-parade');

    _markActivityCompleted(ref);

    final eggAfter = ref.read(rewardProgressProvider)[kMysteryEggTrack.id] ??
        const RewardTrackState();
    final hasEggNow =
        eggAfter.completedActivities.contains('counting-parade');
    final isFirstEggMoment =
        activityId == 'counting-parade' && !hadEggBefore && hasEggNow;

    if (isFirstEggMoment) {
      context.go('/reward/k-mystery-egg-gift');
      return;
    }
    // Auto-advance: if more non-challenge sub-modes remain for this
    // activity, the round-complete sheet's Continue button routes the kid
    // straight into the next one instead of dumping them back on the
    // Sanctuary map.
    final nextSubMode = _findNextSubMode(ref);
    _showRoundCompleteSheet(context, ref, success: true, nextSubMode: nextSubMode);
  }

  /// First non-challenge sub-mode of this activity that hasn't been
  /// completed yet. Returns null when the kid has cleared everything
  /// (replay flow) — the sheet falls back to "Sanctuary" in that case.
  SubMode? _findNextSubMode(WidgetRef ref) {
    final registry = ref.read(activityRegistryProvider).valueOrNull;
    if (registry == null) return null;
    final activity = registry.byIdOrNull(activityId);
    if (activity == null) return null;
    final completed =
        ref.read(subModeProgressProvider.notifier).completedFor(activityId);
    for (final subMode in activity.subModes) {
      if (subMode.isChallenge) continue;
      if (!completed.contains(subMode.id)) return subMode;
    }
    return null;
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
    if (_allNonChallengeSubModesDone(ref)) {
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

  /// True when every non-challenge sub-mode of this activity has been
  /// completed at least once. Used to gate map-node exploration + reward
  /// track advancement — both should only fire when the activity is
  /// fully cleared, not on the first sub-mode.
  bool _allNonChallengeSubModesDone(WidgetRef ref) {
    final registry = ref.read(activityRegistryProvider).valueOrNull;
    if (registry == null) return false;
    final activity = registry.byIdOrNull(activityId);
    if (activity == null) return false;
    final completed =
        ref.read(subModeProgressProvider.notifier).completedFor(activityId);
    for (final subMode in activity.subModes) {
      if (subMode.isChallenge) continue;
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
      default:
        return 'default';
    }
  }

  void _showRoundCompleteSheet(
    BuildContext context,
    WidgetRef ref, {
    required bool success,
    SubMode? nextSubMode,
  }) {
    final hasNext = nextSubMode != null;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.celebration : Icons.refresh,
                size: 72,
                color: success ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                success ? 'Nicely counted!' : 'Try again.',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerRight,
                child: NextArrowButton(
                  key: const ValueKey('round-complete-next'),
                  idleHintEnabled: true,
                  idleHintText: hasNext
                      ? 'Tap the arrow to keep going!'
                      : 'Tap the arrow to head back to the Sanctuary!',
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    if (hasNext) {
                      _routeToNextSubMode(context, ref, nextSubMode);
                    } else {
                      GoRouter.of(context).go('/sanctuary');
                    }
                  },
                  label: hasNext ? 'Next!' : 'Sanctuary',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

