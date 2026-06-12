// KeeperChoiceOverlay — same staging as KeeperIntroOverlay (keeper on the
// left, speech bubble on the right) but with **two** advance buttons so the
// kid can pick between two paths. Used for the challenge-offer and
// challenge-repeat beats in Counting Parade; reusable for any future
// "yes / no thanks" keeper moment.
//
// Both buttons use NextArrowButton per specs/shared/ui-affordances.md —
// the label below each arrow tells the kid which one is which.

import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';
import 'next_arrow_button.dart';

class KeeperChoiceOverlay extends StatelessWidget {
  const KeeperChoiceOverlay({
    super.key,
    required this.dialog,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    this.primaryButtonKey,
    this.secondaryButtonKey,
  });

  final String dialog;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final Key? primaryButtonKey;
  final Key? secondaryButtonKey;

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
                  Row(
                    // Right-aligned so the arrow shelf stays in the same
                    // place across every surface; the secondary option
                    // sits to the left of the primary one inside the
                    // shelf area.
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      NextArrowButton(
                        key: secondaryButtonKey,
                        onPressed: onSecondary,
                        label: secondaryLabel,
                      ),
                      const SizedBox(width: 32),
                      NextArrowButton(
                        key: primaryButtonKey,
                        onPressed: onPrimary,
                        label: primaryLabel,
                      ),
                    ],
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
          fontSize: 22,
          height: 1.35,
          color: Colors.black87,
        ),
      ),
    );
  }
}
