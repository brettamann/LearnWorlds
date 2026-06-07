// KidProgress — in-memory map of ConceptState.key → ConceptState for the
// active kid. Sprint 1 boots empty; M9 will hydrate from disk via the
// SaveCoordinator. The state is scoped at app-level for the slice because
// we only have one implicit kid; multi-kid scoping comes later.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engines/mastery/concept_state.dart';

class KidProgress extends Notifier<Map<String, ConceptState>> {
  @override
  Map<String, ConceptState> build() => const {};

  ConceptState getOrCreate(String conceptId, {String? instanceKey}) {
    final key = instanceKey == null ? conceptId : '$conceptId/$instanceKey';
    final existing = state[key];
    if (existing != null) return existing;
    return ConceptState(conceptId: conceptId, instanceKey: instanceKey);
  }

  void put(ConceptState updated) {
    state = {...state, updated.key: updated};
  }

  /// Replaces the whole map. Used at boot by SaveCoordinator after disk hydrate.
  void replaceAll(Map<String, ConceptState> snapshot) {
    state = snapshot;
  }
}

final kidProgressProvider =
    NotifierProvider<KidProgress, Map<String, ConceptState>>(KidProgress.new);
