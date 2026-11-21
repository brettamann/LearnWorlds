// WarmLines — rotated phrasings for the lines a child hears most often.
//
// specs/shared/k-activity-patterns.md requires 2–4 alternative phrasings for
// celebratory and corrective lines. The runners shipped with exactly one each,
// so a child who missed four times heard the identical sentence four times —
// which is how a helpful line turns into noise she learns to tune out.
//
// Tone rules, from k-activity-patterns.md and art-direction.md:
//   - Never "Wrong!", never "Try harder!", never "Oops!"
//   - Warmth, then demonstration. A miss is information, not a verdict.
//   - Brisk, never patronising. No "you'll love this!", no "little champion".
//   - Real math language — these are read aloud to a pre-reader, so they carry
//     the entire instruction.
//
// Rotation is by index rather than random so a given session is reproducible
// in tests and a child never hears the same line twice running.

const List<String> _missLines = <String>[
  'Not that one. Look again.',
  'That one is different. Keep looking.',
  'Hmm, not quite. Try another.',
  'Close! Have another look.',
];

const List<String> _hintLines = <String>[
  'Take your time. Look for the next one.',
  'Buddy is looking too. Which one comes next?',
  "Here — let's find one together.",
];

/// A warm "not that one" line. [n] is the miss count within the round; callers
/// typically pass a counter they already keep.
String warmMissLine(int n) => _missLines[n.abs() % _missLines.length];

/// A round-pass line that names the cardinality, because saying the total is
/// the pedagogical point of K.CC.4b — the last number word tells you how many.
///
/// [count] is the total counted, [pluralNoun] the creature name ("fawns").
/// [n] rotates the framing so eight rounds don't sound identical.
String warmPassLine(int n, {required int count, required String pluralNoun}) {
  switch (n.abs() % 4) {
    case 0:
      return '$count! That is $count $pluralNoun.';
    case 1:
      return 'You counted $count $pluralNoun.';
    case 2:
      return '$count $pluralNoun altogether.';
    default:
      return 'That makes $count.';
  }
}

/// Escalating hint text. [level] is the hint-ladder rung (1-based).
String warmHintLine(int level) =>
    _hintLines[(level - 1).clamp(0, _hintLines.length - 1)];

/// What the end-of-sub-mode sheet says when there is no egg to talk about.
///
/// Only reachable from a save that predates the reward track, since the first
/// cleared sub-mode is what hands the egg over. It exists because the sheet's
/// whole content is the egg, and a beat that falls back to nothing is the
/// silent screen this replaced.
const String kRoundCompleteFallbackLine =
    'You finished the whole thing. '
    'Nicely done!';
