// ExplorationProgress — which Sanctuary map nodes the kid has discovered.
// Each anchor code (e.g. 0xF0 for the cutscene, 0xF1..0xFB for the 11
// lessons) lives in this set once the kid has completed that node. The map
// uses this to draw clouds, banners, and the dotted path with reveal state.
//
// Persisted by SaveCoordinator so progress survives reload.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExplorationProgress extends Notifier<Set<int>> {
  @override
  Set<int> build() => const <int>{};

  void markCompleted(int code) {
    if (state.contains(code)) return;
    state = {...state, code};
  }

  void replaceAll(Set<int> snapshot) {
    state = Set<int>.from(snapshot);
  }

  bool isCompleted(int code) => state.contains(code);
}

final explorationProvider =
    NotifierProvider<ExplorationProgress, Set<int>>(ExplorationProgress.new);
