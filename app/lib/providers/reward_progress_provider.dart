// RewardProgress — per-track state for the grade-spanning reward system.
// Keyed by track id (`k-mystery-egg`, `wundle-spark`, etc.) so multiple
// tracks can run in parallel as we add grades.
//
// Each track records:
//   - which advancing activities have been completed
//   - the highest stage the kid has *seen* on the map (drives the
//     "should we play the fanfare?" check on next map mount)
//   - whether the track has graduated (final stage shown + map remounted)
//
// Persistence rides in the SaveCoordinator save blob.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardTrackState {
  const RewardTrackState({
    this.completedActivities = const <String>{},
    this.lastSeenStage = 0,
    this.graduated = false,
  });

  /// Set of activity ids (from the registry, e.g. `counting-parade`) that
  /// have been completed at least once for this track's grant table.
  final Set<String> completedActivities;

  /// Highest stage number (1..N) the kid has watched on the map. Drives the
  /// advancement-animation trigger: if `targetStage > lastSeenStage` on a
  /// map mount, the overlay plays the transition and bumps this up.
  final int lastSeenStage;

  /// True once the track has reached its final stage and the kid has come
  /// back to the map (so they saw stage 8, left, and returned). Drives the
  /// "show the complete sprite" branch.
  final bool graduated;

  RewardTrackState copyWith({
    Set<String>? completedActivities,
    int? lastSeenStage,
    bool? graduated,
  }) {
    return RewardTrackState(
      completedActivities: completedActivities ?? this.completedActivities,
      lastSeenStage: lastSeenStage ?? this.lastSeenStage,
      graduated: graduated ?? this.graduated,
    );
  }
}

class RewardProgress extends Notifier<Map<String, RewardTrackState>> {
  @override
  Map<String, RewardTrackState> build() => const <String, RewardTrackState>{};

  RewardTrackState stateFor(String trackId) {
    return state[trackId] ?? const RewardTrackState();
  }

  void markActivityCompleted({
    required String trackId,
    required String activityId,
  }) {
    final current = stateFor(trackId);
    if (current.completedActivities.contains(activityId)) return;
    final next = current.copyWith(
      completedActivities: {...current.completedActivities, activityId},
    );
    state = {...state, trackId: next};
  }

  void markStageSeen({required String trackId, required int stage}) {
    final current = stateFor(trackId);
    if (current.lastSeenStage >= stage) return;
    state = {
      ...state,
      trackId: current.copyWith(lastSeenStage: stage),
    };
  }

  void markGraduated({required String trackId}) {
    final current = stateFor(trackId);
    if (current.graduated) return;
    state = {
      ...state,
      trackId: current.copyWith(graduated: true),
    };
  }

  void replaceAll(Map<String, RewardTrackState> snapshot) {
    state = Map<String, RewardTrackState>.from(snapshot);
  }
}

final rewardProgressProvider =
    NotifierProvider<RewardProgress, Map<String, RewardTrackState>>(
  RewardProgress.new,
);
