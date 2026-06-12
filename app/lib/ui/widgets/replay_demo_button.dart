// ReplayDemoButton — small "?" circle the kid can tap during a practice
// round to hear the round's prompt again. Live testing surfaced that
// kindergartners who get distracted mid-round lose track of what
// they're being asked to do; a one-tap replay is much friendlier than
// having them quit the round and start over.
//
// Where to use it: ONLY in the *practice* portions of a runner — the
// counting/dragging phase where the kid is actively doing the work.
// Skip it on:
//   - intro / keeper-bubble screens (the kid is still listening)
//   - I-Show / demonstration animations
//   - celebrating / interstitial / reward beats
//   - challenge-offer or chest-open moments
//
// The button is parked at the left edge of the screen, vertically
// centered, so it doesn't compete with the right-edge Continue arrow
// shelf. See specs/shared/ui-affordances.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';

class ReplayDemoButton extends ConsumerWidget {
  const ReplayDemoButton({
    super.key,
    required this.label,
    required this.cueId,
    this.size = 56,
    this.color = const Color(0xFF4FC3F7),
  });

  /// Narration the kid hears on tap. Pass the round's "what should I do"
  /// prompt verbatim — usually the same line the runner spoke at the
  /// start of the round.
  final String label;

  /// Stable id so the narration player can dedupe and the analytics can
  /// count replays per round. Convention: `<runner>:replay:r<round>`.
  final String cueId;

  /// Diameter of the circular button.
  final double size;

  /// Body / glow tint. Defaults to a soft sky-blue so the button reads
  /// as "help" rather than "do something."
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Replay the directions',
      child: Material(
        shape: const CircleBorder(),
        color: color,
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            ref.read(narrationPlayerProvider.notifier).speak(
                  NarrationLine(text: label, cueId: cueId),
                );
          },
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.question_mark_rounded,
              size: size * 0.55,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fixed-width "shelf" for the replay button, mirroring the right-edge
/// `kContinueArrowShelf`. The shelf sits on the left edge of the runner
/// so the (?) button has a consistent home regardless of how the round
/// content reflows. Pass `null` to render an empty shelf (e.g. on
/// rounds where replay is suppressed) without shifting the layout.
SizedBox kReplayDemoShelf({required Widget? child}) {
  return SizedBox(
    width: 72,
    child: Center(child: child ?? const SizedBox.shrink()),
  );
}
