// BuddyReaction — a tiny app-wide bus for "the Buddy should react now".
//
// Why a provider instead of a widget parameter: the Buddy is meant to be
// present and responsive in *every* activity, but the things it reacts to
// (a counted object, a wrong tap, a hint firing) happen deep inside runner
// state. Threading a mood down through each runner's widget tree would mean
// editing all ten of them and keeping the plumbing in sync forever.
//
// Instead FeedbackEngine publishes here and BuddyCompanion subscribes, so a
// runner gets a reactive Buddy for free — it never mentions the Buddy at all.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/buddy_mood.dart';

class BuddyReaction {
  const BuddyReaction({this.mood = BuddyMood.idle, this.token = 0});

  final BuddyMood mood;

  /// Bumped on every `react()` call. Lets the widget replay a one-shot even
  /// when the mood hasn't changed — two correct taps in a row should give two
  /// hops, not one.
  final int token;

  BuddyReaction copyWith({BuddyMood? mood, int? token}) => BuddyReaction(
        mood: mood ?? this.mood,
        token: token ?? this.token,
      );
}

class BuddyReactionController extends Notifier<BuddyReaction> {
  Timer? _settle;

  @override
  BuddyReaction build() {
    ref.onDispose(() => _settle?.cancel());
    return const BuddyReaction();
  }

  /// Show [mood], then drift back to idle after [hold].
  ///
  /// Auto-settling matters: without it the Buddy would be frozen mid-cheer
  /// from whenever the last correct answer happened, which reads as a stuck
  /// sprite rather than a live companion.
  void react(
    BuddyMood mood, {
    Duration hold = const Duration(milliseconds: 1600),
  }) {
    _settle?.cancel();
    state = BuddyReaction(mood: mood, token: state.token + 1);
    if (mood != BuddyMood.idle) {
      _settle = Timer(hold, settle);
    }
  }

  /// Drop straight back to idle. Called on round transitions so a reaction
  /// from the previous round doesn't bleed into the next one.
  void settle() {
    _settle?.cancel();
    _settle = null;
    if (state.mood != BuddyMood.idle) {
      state = state.copyWith(mood: BuddyMood.idle);
    }
  }
}

final buddyReactionProvider =
    NotifierProvider<BuddyReactionController, BuddyReaction>(
  BuddyReactionController.new,
);
