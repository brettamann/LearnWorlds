// CaptionOverlay — bottom-pinned caption surface. Watches the NarrationPlayer
// and renders the current line. Hidden when no line is active.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/narration/narration_player.dart';

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
