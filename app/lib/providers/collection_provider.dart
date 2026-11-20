// Card collection — which creature cards the kid has found, and which one is
// waiting to be shown to her.
//
// Two notifiers because they have different lifetimes. The collection is save
// state; the pending reveal is a one-frame handoff from RoundCoordinator (which
// can't draw anything) to CardRevealOverlay (which can). Keeping the reveal out
// of the collection means a card is never "found" twice if the overlay rebuilds.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardCollection extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  bool has(String cardId) => state.contains(cardId);

  /// Returns false if the card was already collected, so the caller can skip
  /// the reveal rather than showing a duplicate.
  bool grant(String cardId) {
    if (state.contains(cardId)) return false;
    state = <String>{...state, cardId};
    return true;
  }

  void hydrate(Set<String> cardIds) => state = cardIds;
}

final cardCollectionProvider =
    NotifierProvider<CardCollection, Set<String>>(CardCollection.new);

/// The card the kid has just earned and not yet been shown, or null.
class PendingCardReveal extends Notifier<String?> {
  @override
  String? build() => null;

  /// First one wins. Two cards can't land in the same round today, but if that
  /// ever changes, dropping the second is better than a reveal that flickers
  /// past before a five-year-old has focused on it.
  void show(String cardId) {
    if (state != null) return;
    state = cardId;
  }

  void dismiss() => state = null;
}

final pendingCardRevealProvider =
    NotifierProvider<PendingCardReveal, String?>(PendingCardReveal.new);
