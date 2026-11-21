// KeeperAside — the keeper says something without stopping the game.
//
// Why this exists
// ---------------
// The keeper's between-round lines are good writing, but they were delivered
// through KeeperIntroOverlay: a full-screen modal that replaced the playfield
// and required an arrow tap to dismiss. The default Counting Parade sub-mode
// ran eight rounds, which meant roughly sixteen screen-blocking dialogs in a
// single sitting. Play never flowed for more than five taps at a time, and
// that stop-start rhythm is a large part of why the activity felt repetitive.
//
// This slides a portrait and a bubble in over the live scene, holds long
// enough to be heard, and slides out on its own. The child never has to
// acknowledge it, and the meadow stays visible underneath the whole time.
//
// What is NOT changed: the end-of-sub-mode reward beat stays blocking. That
// one is the payoff specs/shared/activity-progress-bar.md mandates, and it is
// supposed to interrupt.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../engines/feedback/feedback_engine.dart';

class KeeperAside extends ConsumerStatefulWidget {
  const KeeperAside({
    super.key,
    required this.text,
    required this.token,
    this.holdFor,
    this.portraitAsset = AssetPaths.sanctuaryKeeperMystic,
    this.portraitHeight = 190,
    this.onDismissed,
  });

  /// The line to show. Null hides the aside entirely.
  final String? text;

  /// Bump to (re)show. Lets the same widget instance present a new line each
  /// round without the caller juggling keys.
  final int token;

  /// How long to stay up. Defaults to a reading-time estimate derived from
  /// the line's length, matching the rule in
  /// specs/shared/text-and-tts-deferral.md.
  final Duration? holdFor;

  final String portraitAsset;
  final double portraitHeight;

  /// Fires after the exit animation finishes. Runners use this to advance
  /// rounds, so the transition is paced by the aside rather than by a tap.
  final VoidCallback? onDismissed;

  @override
  ConsumerState<KeeperAside> createState() => _KeeperAsideState();
}

class _KeeperAsideState extends ConsumerState<KeeperAside>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide;
  Timer? _holdTimer;
  String? _shownText;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      duration: const Duration(milliseconds: 340),
      reverseDuration: const Duration(milliseconds: 260),
      vsync: this,
    );
    if (widget.text != null) _present();
  }

  @override
  void didUpdateWidget(KeeperAside oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token && widget.text != null) _present();
  }

  Duration get _hold {
    if (widget.holdFor != null) return widget.holdFor!;
    // ~70ms per character, clamped. Tuned to outlast the spoken line rather
    // than the read: system TTS runs at rate 0.45, so an aside that vanished
    // at reading speed would cut the keeper off mid-sentence — and for a
    // pre-reader the voice is the whole message.
    final chars = (_shownText ?? widget.text ?? '').length;
    final ms = (chars * 70).clamp(2500, 6500);
    return Duration(milliseconds: ms);
  }

  void _present() {
    _holdTimer?.cancel();
    // The keeper arriving is an event, and it was a silent one. `Sfx.bubbleIn`
    // was written for exactly this and played by nothing.
    ref.read(feedbackEngineProvider).bubble();
    setState(() => _shownText = widget.text);
    _slide.forward(from: 0);
    _holdTimer = Timer(_hold, () {
      if (!mounted) return;
      _slide.reverse().whenComplete(() {
        if (!mounted) return;
        setState(() => _shownText = null);
        widget.onDismissed?.call();
      });
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _shownText;
    if (text == null) return const SizedBox.shrink();

    return IgnorePointer(
      // Never eats a tap: the child can keep playing straight through the
      // keeper talking, which is the entire point of the widget.
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_slide.value);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(-120 * (1 - t), 0),
              child: child,
            ),
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  widget.portraitAsset,
                  height: widget.portraitHeight,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
