// KeeperIntroOverlay — story-context preamble used by the Sanctuary activities.
// The keeper appears with a speech bubble explaining *why* the kid is being
// asked to do the math. Used by:
//   - LessonScreen (Counting Parade lesson) before the iShow demonstration.
//   - CountingParadeRunner before a normal round (when not entering from a
//     lesson, in which case the lesson already played the intro).
//
// On `onStart`, the caller flips state to its next phase (lesson iShow or
// round). The dialog text is also spoken by the NarrationPlayer.

import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';
import 'next_arrow_button.dart';

class KeeperIntroOverlay extends StatelessWidget {
  const KeeperIntroOverlay({
    super.key,
    required this.dialog,
    required this.startLabel,
    required this.onStart,
    this.startButtonKey = const ValueKey('keeper-intro-start-button'),
  });

  final String dialog;
  final String startLabel;
  final VoidCallback onStart;
  final Key startButtonKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Image.asset(
                  AssetPaths.sanctuaryKeeperMystic,
                  height: 360,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SpeechBubble(text: dialog),
                  const SizedBox(height: 24),
                  // Standard advance affordance — same wiggling amber arrow
                  // as every other "you're done, go next" moment in the game.
                  // Pinned to the right of the speech-bubble column so the
                  // arrow stays on the right edge of the screen across all
                  // surfaces (matches the practice rounds + lesson Continue).
                  // See specs/shared/ui-affordances.md.
                  Align(
                    alignment: Alignment.centerRight,
                    child: NextArrowButton(
                      key: startButtonKey,
                      onPressed: onStart,
                      label: startLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          height: 1.35,
          color: Colors.black87,
        ),
      ),
    );
  }
}
