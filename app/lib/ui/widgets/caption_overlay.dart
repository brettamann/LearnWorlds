// CaptionOverlay — bottom-pinned caption surface. Watches the NarrationPlayer
// and renders the current line. Hidden when no line is active.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/narration/narration_player.dart';

/// Vertical space the caption bar claims at the bottom of a scene.
///
/// Anything a child is meant to look at has to sit above this. The Buddy in
/// the Counting Parade did not: it stood at the very bottom of the meadow with
/// the semi-transparent black caption band lying across it, so the one
/// character in the scene spent the whole round behind a subtitle.
///
/// It then happened again, in Where's Buddy, where the Buddy is not a
/// companion but the thing she has to pick up: he waited at the bottom of the
/// clearing with the band across him, and "below the mushroom" - an answer -
/// landed there too. That one is fixed by `ClearingGeometry`, which lays the
/// whole clearing out inside the space this constant leaves. Two activities
/// have now put their most important sprite here, so treat a screen that
/// places anything by a fraction of its own height as suspect until it has
/// been rendered and looked at.
///
/// A single number rather than a measurement, because the bar only exists
/// while something is being said and a companion that hopped up and down with
/// every line would be worse than one that is slightly too high.
const double kCaptionBandClearance = 96;

class CaptionOverlay extends ConsumerWidget {
  const CaptionOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = ref.watch(narrationPlayerProvider);
    if (line == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Positioned(
      left: 24,
      right: 24,
      bottom: 24,
      // Captions are read-only — never intercept taps meant for the buttons
      // and sprites beneath them.
      child: IgnorePointer(
        child: SafeArea(
          child: Material(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
