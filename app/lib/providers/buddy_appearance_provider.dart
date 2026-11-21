// BuddyAppearance state — the kid's Buddy configuration as picked in
// the character creator. Persisted by SaveCoordinator alongside the
// rest of the save state. Defaults to `BuddyAppearance.defaults()` on
// a brand new save so the Hub already has a Buddy to render.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/buddy_appearance.dart';

class BuddyAppearanceNotifier extends Notifier<BuddyAppearance> {
  @override
  BuddyAppearance build() => BuddyAppearance.defaults();

  /// Replace the current Buddy with `next`. Use this from the creator
  /// when the kid confirms a selection. Idempotent — a no-op replace
  /// won't churn listeners.
  void replace(BuddyAppearance next) {
    if (state == next) return;
    state = next;
  }

  /// Targeted setters for incremental edits from the creator's swatch
  /// rows. Each one rebuilds with `copyWith` so the rest of the
  /// appearance is preserved.
  void setBody(String bodyId) => state = state.copyWith(bodyId: bodyId);
  void setEyes(String eyesId) => state = state.copyWith(eyesId: eyesId);
  void setMouth(String mouthId) => state = state.copyWith(mouthId: mouthId);
  void setArms(String armsId) => state = state.copyWith(armsId: armsId);
  void setLegs(String legsId) => state = state.copyWith(legsId: legsId);

  /// Equip a hat. Pass null to clear the current hat.
  void setHat(String? hatId) {
    state = hatId == null
        ? state.copyWith(clearHat: true)
        : state.copyWith(hatId: hatId);
  }

  /// Hydration entry point used by SaveCoordinator at boot.
  void hydrate(BuddyAppearance saved) {
    state = saved;
  }
}

final buddyAppearanceProvider =
    NotifierProvider<BuddyAppearanceNotifier, BuddyAppearance>(
      BuddyAppearanceNotifier.new,
    );
