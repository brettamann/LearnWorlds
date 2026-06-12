// SubModeProgress — tracks which sub-modes of each activity the kid has
// completed at least once. Drives the Sanctuary node picker: the first
// time the kid taps an activity node, they go straight to the default
// sub-mode's lesson. After a sub-mode finishes (`onSequenceComplete`
// fires in the runner), it's recorded here so the next tap surfaces a
// picker — replay any completed sub-mode, or move on to the next
// un-completed one.
//
// Persisted by SaveCoordinator. Replaces nothing in `RewardProgress`;
// reward tracks remain activity-level (one stage per activity completion)
// while this provider is the finer-grained sub-mode dimension the new
// node picker needs.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubModeProgress extends Notifier<Map<String, Set<String>>> {
  @override
  Map<String, Set<String>> build() => const <String, Set<String>>{};

  /// Record that `subModeId` has been completed for `activityId`. Idempotent.
  void markCompleted({
    required String activityId,
    required String subModeId,
  }) {
    final current = state[activityId] ?? const <String>{};
    if (current.contains(subModeId)) return;
    state = {
      ...state,
      activityId: {...current, subModeId},
    };
  }

  /// Sub-modes the kid has cleared for `activityId`. Returns empty when
  /// nothing has been completed yet.
  Set<String> completedFor(String activityId) =>
      state[activityId] ?? const <String>{};

  bool hasCompleted({
    required String activityId,
    required String subModeId,
  }) =>
      completedFor(activityId).contains(subModeId);

  /// Boot-time hydration from disk via SaveCoordinator.
  void replaceAll(Map<String, Set<String>> snapshot) {
    state = {
      for (final entry in snapshot.entries) entry.key: Set<String>.from(entry.value),
    };
  }
}

final subModeProgressProvider =
    NotifierProvider<SubModeProgress, Map<String, Set<String>>>(
  SubModeProgress.new,
);
