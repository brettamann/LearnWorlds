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
//   - The `label` must be reachable by the recording script. A clip is
//     looked up by the words spoken, so a label typed inline in a
//     screen gets no clip and speaks in the OS synth voice instead —
//     not silence, a change of narrator mid-session. Dart labels live
//     in a Flutter-free catalog under lib/data/ (see map_labels.dart);
//     JSON-authored ones are swept by tool/dump_narration_script.dart.
//   - Do NOT wrap gameplay sprites (parade creatures, challenge
//     animals, etc.) — those need direct taps without narration.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/feedback/feedback_engine.dart';
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
    ref.narration.say(label, cueId: cueId ?? 'gate:$label', caption: false);
  }

  /// The press itself, independent of whether anything is said.
  ///
  /// Here rather than at each call site because this is the one wrapper every
  /// piece of chrome in the game already goes through. Before it, `Sfx.uiTap`
  /// was played by the character creator and by nothing else - so the big
  /// arrow that ends every round in every activity, every map node, every
  /// picker card and every basket made no sound at all when a child pressed
  /// them. The research on this age group is blunt about it: every tap wants a
  /// sound, and audio is the cheapest channel and the one most often skipped.
  void _press(WidgetRef ref) {
    ref.read(feedbackEngineProvider).uiTap();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(readAloudGateEnabledProvider);
    if (!enabled) {
      // Gate disabled: no narration and no extra gesture surface - but the
      // press still has to be audible, so the tap sound is wrapped around the
      // child rather than living in the gated branch.
      return GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTapDown: (_) => _press(ref),
        child: child,
      );
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
                _press(ref);
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
