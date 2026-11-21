// BuddyMood — the Buddy's emotional register.
//
// Note what is deliberately absent: there is no `sad`, `disappointed`, or
// `wrong` mood. specs/shared/art-direction.md and specs/shared/
// k-activity-patterns.md both rule out reactions that read as disappointment,
// and for good reason — the Buddy exists to take pressure *off* the child, so
// it must never become one more thing that looks let down when she misses.
//
// A wrong answer gets `curious`: a head-tilt that says "hm, not that one",
// which carries the information without carrying the judgement.

/// Kept in its own file rather than beside BuddyWidget so the feedback engine
/// and providers can depend on the vocabulary without dragging in the widget
/// layer (and the import cycle that would create).
enum BuddyMood {
  /// Resting. Breathing and blinking, nothing else.
  idle,

  /// Something went right — a counted object, a passed round.
  happy,

  /// Working on it. Used while a child is mid-round and doing fine.
  thinking,

  /// Leaning in and pointing at the target. This is the hint ladder's
  /// second rung: help that arrives from a friend who noticed, rather than
  /// from the game announcing a failure.
  encouraging,

  /// "Hm — not that one." The wrong-answer reaction.
  curious,
}

/// Which way the Buddy faces. Implemented as a horizontal flip, so it costs
/// no extra art.
enum BuddyFacing { left, right }
