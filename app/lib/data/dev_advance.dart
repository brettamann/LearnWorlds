// DevAdvance — testing utility that fast-forwards the kid's save state to
// "as if every Sanctuary lesson up to (but not including) the chosen one
// has been completed." Lets a dev jump straight to a later lesson to test
// it without playing through the whole curriculum.
//
// What gets advanced:
//   - exploration: every magenta anchor up to (target - 1) is marked
//     completed, so the map shows the dotted-path reveal + node banners
//     the same way it would after honest play.
//   - reward progress: each preceding activity is added to the mystery-egg
//     track's `completedActivities` set, so `computeTargetStage` lands on
//     the right egg stage and the corner sprite shows the right art.
//   - wallet: a flat `coinsPerRound` per preceding activity, matching the
//     production grant in RoundCoordinator.
//
// What does NOT get advanced:
//   - concept mastery (KidProgress): left alone so the lesson tutorial
//     still plays the first time at the target node — that's usually what
//     the dev is trying to test. If the dev also wants to skip the
//     tutorial they can flip the introduce → practicing state by hand,
//     but the common case is "I want to see this lesson run cold."
//
// Use from SettingsScreen. Lives outside the screen because it touches a
// half-dozen providers + persistence, and that orchestration is worth
// having a unit-testable home for.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reward_track.dart';
import '../providers/app_providers.dart';
import '../providers/exploration_provider.dart';
import '../providers/reward_progress_provider.dart';
import '../providers/save_provider.dart';
import '../providers/sub_mode_progress_provider.dart';
import '../providers/wallet_provider.dart';
import 'sanctuary_sequence.dart';

/// Production coin grant per round pass. Mirrors
/// `RoundCoordinator._coinsPerRoundPass`. Kept here as a constant so the
/// dev tool grants the same amount honest play would.
const int kDevAdvanceCoinsPerActivity = 5;

class DevAdvanceOption {
  const DevAdvanceOption({
    required this.code,
    required this.activityId,
    required this.displayName,
    required this.sequenceIndex,
  });

  /// Magenta anchor code (`0xF1`..`0xFB`). The cutscene at `0xF0` is never
  /// offered as a target because there's no "lesson" to land on — but it's
  /// still advanced past when you pick anything after it.
  final int code;

  /// Activity id (e.g. `shape-garden`). Used as the navigation target
  /// after advancement.
  final String activityId;

  /// Label shown in the picker.
  final String displayName;

  /// Position in `kSanctuarySequence`. Used to know what to mark as
  /// completed before this target.
  final int sequenceIndex;
}

/// Builds the picker list — every non-cutscene Sanctuary entry in order.
/// Display names use a tiny hardcoded map so the picker doesn't need to
/// wait on the activity registry future at open time.
List<DevAdvanceOption> devAdvanceOptions() {
  const displayNames = <String, String>{
    'counting-parade': 'Counting Parade',
    'shape-garden': 'Shape Garden',
    'ten-frame-pond': 'Ten-Frame Pond',
    'build-a-habitat': 'Build-a-Habitat',
    'care-pantry': 'Care Pantry',
    'scribes-tower': "Scribe's Tower",
    'storytellers-pond': "Storyteller's Pond",
    'wheres-buddy': "Where's Buddy?",
    'caretakers-bench': "Caretaker's Bench",
    'picnic-baskets': 'Picnic Baskets',
    'fluency-within-5': 'Fluency Within 5',
  };
  final out = <DevAdvanceOption>[];
  for (var i = 0; i < kSanctuarySequence.length; i++) {
    final code = kSanctuarySequence[i];
    final activityId = kSanctuaryActivityByCode[code];
    if (activityId == null) continue; // cutscene
    out.add(
      DevAdvanceOption(
        code: code,
        activityId: activityId,
        displayName: displayNames[activityId] ?? activityId,
        sequenceIndex: i,
      ),
    );
  }
  return out;
}

class DevAdvanceResult {
  const DevAdvanceResult({
    required this.precedingActivitiesCompleted,
    required this.coinsGranted,
    required this.targetActivityId,
  });

  final int precedingActivitiesCompleted;
  final int coinsGranted;
  final String targetActivityId;
}

/// Fast-forwards save state to the moment just before `target` would
/// normally be played. Persists via the save coordinator before returning
/// so a hot-reload or app restart preserves the jump.
Future<DevAdvanceResult> applyDevAdvance(
  WidgetRef ref,
  DevAdvanceOption target,
) async {
  // Every code up to (but not including) the target's sequence index is
  // marked explored. That includes the cutscene at index 0.
  final explorationNotifier = ref.read(explorationProvider.notifier);
  for (var i = 0; i < target.sequenceIndex; i++) {
    explorationNotifier.markCompleted(kSanctuarySequence[i]);
  }

  // Reward track: mark every preceding activity completed. The mystery
  // egg's stage grants are static — adding to `completedActivities`
  // produces the correct target stage on next map mount.
  //
  // Sub-mode progress: mark every non-challenge sub-mode of each
  // preceding activity completed too, so the Sanctuary picker treats
  // those nodes as "fully cleared" (no `next` chip, replays only). The
  // target activity itself is left untouched so the picker shows it cold.
  final rewardNotifier = ref.read(rewardProgressProvider.notifier);
  final subModeNotifier = ref.read(subModeProgressProvider.notifier);
  final registry = ref.read(activityRegistryProvider).valueOrNull;
  var precedingActivities = 0;
  for (var i = 0; i < target.sequenceIndex; i++) {
    final code = kSanctuarySequence[i];
    final activityId = kSanctuaryActivityByCode[code];
    if (activityId == null) continue; // cutscene has no activity
    rewardNotifier.markActivityCompleted(
      trackId: kMysteryEggTrack.id,
      activityId: activityId,
    );
    final activity = registry?.byIdOrNull(activityId);
    if (activity != null) {
      for (final subMode in activity.subModes) {
        if (subMode.isChallenge) continue;
        subModeNotifier.markCompleted(
          activityId: activityId,
          subModeId: subMode.id,
        );
      }
    }
    precedingActivities += 1;
  }

  // Wallet: production-equivalent grant per preceding activity.
  final coins = precedingActivities * kDevAdvanceCoinsPerActivity;
  if (coins > 0) {
    ref.read(walletProvider.notifier).award(coins);
  }

  await ref.read(saveCoordinatorProvider).persist();

  return DevAdvanceResult(
    precedingActivitiesCompleted: precedingActivities,
    coinsGranted: coins,
    targetActivityId: target.activityId,
  );
}

/// Wipes every advanced state back to a fresh-boot kid: exploration empty,
/// reward track empty, wallet zero. The target lesson is the first
/// Sanctuary node. Use this to undo a previous dev jump.
Future<void> resetDevAdvance(WidgetRef ref) async {
  ref.read(explorationProvider.notifier).replaceAll(const <int>{});
  ref.read(rewardProgressProvider.notifier).replaceAll(
        const <String, RewardTrackState>{},
      );
  ref.read(subModeProgressProvider.notifier).replaceAll(
        const <String, Set<String>>{},
      );
  ref.read(walletProvider.notifier).set(0);
  await ref.read(saveCoordinatorProvider).persist();
}
