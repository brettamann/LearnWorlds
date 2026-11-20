// AnswerFeedback — the visual half of the shared correct/wrong reaction.
//
// Wraps a gameplay actor (a creature sprite, a shape, a drop target) and plays
// the standard reaction when a token changes. Uses the same generation-counter
// idiom GlitterBurst already documents, because several runners are already
// keeping exactly these ints around (shape_garden_runner's `_burstCounters`).
//
//   correctToken++ → sparkle burst + a quick scale pop
//   wrongToken++   → horizontal shake + a brief desaturation
//
// The wrong reaction is deliberately soft. specs/shared/art-direction.md rules
// out red flashing, and specs/shared/playtest-watchlist.md tracks over-harsh
// miss feedback as a live risk — so this is a shake and a wash of colour
// draining out, not an error state. It exists to answer one question a
// five-year-old was previously left to guess at: *did the game even notice
// that I tapped?*
//
// Audio and haptics are NOT fired here — the runner owns those through
// FeedbackEngine, because a counting runner needs its pitch-ladder note rather
// than the generic chime.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glitter_burst.dart';

class AnswerFeedback extends StatefulWidget {
  const AnswerFeedback({
    super.key,
    required this.child,
    this.correctToken = 0,
    this.wrongToken = 0,
    this.suppressCorrectPop = false,
    this.burstColor = const Color(0xFFFFE08A),
    this.shakeExtent = 10,
  });

  final Widget child;

  /// Bump to play the correct reaction.
  final int correctToken;

  /// Bump to play the wrong reaction.
  final int wrongToken;

  /// Set when the wrapped actor already animates itself on success — the
  /// parade creatures hop via AnimatedFawn, and stacking a second scale pop on
  /// top reads as a glitch. The sparkle burst still fires.
  final bool suppressCorrectPop;

  final Color burstColor;

  /// Peak horizontal displacement of the wrong-answer shake, in logical px.
  final double shakeExtent;

  @override
  State<AnswerFeedback> createState() => _AnswerFeedbackState();
}

class _AnswerFeedbackState extends State<AnswerFeedback>
    with TickerProviderStateMixin {
  late final AnimationController _wrong;
  late final AnimationController _correct;

  /// Bumped alongside `correctToken` so each burst gets a fresh key and
  /// therefore a fresh particle spread.
  int _burstGeneration = 0;
  bool _showBurst = false;

  @override
  void initState() {
    super.initState();
    _wrong = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _correct = AnimationController(
      duration: const Duration(milliseconds: 340),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(AnswerFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wrongToken != oldWidget.wrongToken) {
      _wrong.forward(from: 0);
    }
    if (widget.correctToken != oldWidget.correctToken) {
      _burstGeneration++;
      setState(() => _showBurst = true);
      if (!widget.suppressCorrectPop) _correct.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _wrong.dispose();
    _correct.dispose();
    super.dispose();
  }

  /// Drains colour toward grey as [t] rises. Used at a shallow depth so the
  /// actor reads as "set aside" rather than "broken".
  ColorFilter _desaturate(double t) {
    final s = 1.0 - t;
    const lr = 0.2126;
    const lg = 0.7152;
    const lb = 0.0722;
    return ColorFilter.matrix(<double>[
      lr + s * (1 - lr), lg * (1 - s), lb * (1 - s), 0, 0, //
      lr * (1 - s), lg + s * (1 - lg), lb * (1 - s), 0, 0, //
      lr * (1 - s), lg * (1 - s), lb + s * (1 - lb), 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_wrong, _correct]),
          builder: (context, child) {
            final w = _wrong.value;
            // Three oscillations, amplitude decaying to zero so it settles
            // instead of stopping dead.
            final dx = w == 0
                ? 0.0
                : math.sin(w * 3 * 2 * math.pi) * widget.shakeExtent * (1 - w);
            // Peak the desaturation mid-shake and recover, so the actor is
            // never left looking disabled.
            final grey = w == 0 ? 0.0 : (1 - (w - 0.5).abs() * 2) * 0.45;

            final c = _correct.value;
            // One half-sine: swell out and settle back to rest.
            final pop = c == 0 ? 1.0 : 1.0 + math.sin(c * math.pi) * 0.12;

            Widget content = child!;
            if (grey > 0.001) {
              content = ColorFiltered(
                colorFilter: _desaturate(grey),
                child: content,
              );
            }
            return Transform.translate(
              offset: Offset(dx, 0),
              child: pop == 1.0
                  ? content
                  : Transform.scale(scale: pop, child: content),
            );
          },
          child: widget.child,
        ),
        if (_showBurst)
          Positioned.fill(
            child: GlitterBurst(
              key: ValueKey<int>(_burstGeneration),
              color: widget.burstColor,
            ),
          ),
      ],
    );
  }
}
