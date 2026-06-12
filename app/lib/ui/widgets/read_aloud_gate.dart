// ReadAloudGate — wraps a tappable element so that, when the read-aloud
// setting is on, a tap narrates the element's label *and* fires its
// action on the same gesture. Originally a two-step "tap to hear, tap
// again to act" gate; live testing with kindergartners showed the
// double-tap was confusing — they'd tap once, hear the label, and then
// either expect the action to fire or lose track of which thing they
// were touching. The current model speaks-and-acts in one beat.
//
// USAGE (always wrap, not at the call site — the wrapping should be
// invisible to callers):
//
//   1. NextArrowButton, MapNodeWithBanner, MapScreen regions, etc. wrap
//      themselves internally. Callers pass `onPressed` and `label` as
//      they always did.
//   2. New interactive widgets should follow the same convention. See
//      specs/shared/read-aloud-gate.md for the authoring checklist.
//
// AUTHORING RULES:
//   - The `label` is spoken via TTS only (speakWithoutCaption). The
//     text is either already visible on screen (button label pill,
//     banner) or the audio is the affordance — never duplicate it in
//     the caption overlay.
//   - Do NOT wrap gameplay sprites (parade creatures, challenge
//     animals, etc.) — those need direct taps without narration.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../providers/read_aloud_settings_provider.dart';

class ReadAloudGate extends ConsumerWidget {
  const ReadAloudGate({
    super.key,
    required this.child,
    required this.label,
    required this.onTap,
    this.cueId,
  });

  /// The visual element being gated. Its own gesture handlers should
  /// match `onTap` so behavior is consistent whether the gate is on or
  /// off — when off, taps go straight to the child; when on, the gate
  /// intercepts, narrates, and forwards the same gesture.
  final Widget child;

  /// What to speak aloud on tap.
  final String label;

  /// The "actual action" — fires on every tap (alongside the narration
  /// when the gate is enabled).
  final VoidCallback onTap;

  /// Optional stable id for the spoken cue, used for analytics + cache
  /// keying once pre-rendered audio replaces system TTS.
  final String? cueId;

  void _speakLabel(WidgetRef ref) {
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          NarrationLine(
            text: label,
            cueId: cueId ?? 'gate:$label',
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(readAloudGateEnabledProvider);
    if (!enabled) {
      // Gate disabled: child handles taps normally — no narration, no
      // extra gesture surface.
      return child;
    }
    // Gate enabled: intercept taps so we can narrate *and* run the
    // action in one beat. We wrap with a transparent GestureDetector
    // and IgnorePointer the child so its own onTap doesn't double-fire.
    return MouseRegion(
      // Desktop / mouse-driven: hovering narrates the label without
      // firing the action. The next click still acts (and narrates).
      onEnter: (_) => _speakLabel(ref),
      child: Stack(
        children: [
          IgnorePointer(child: child),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _speakLabel(ref);
                onTap();
              },
            ),
          ),
        ],
      ),
    );
  }
}
