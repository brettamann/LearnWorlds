// NextArrowButton — the canonical "you finished, go to the next thing" CTA.
// A big, kid-thumb-sized circular button with a right-facing arrow, a soft
// pulsing glow, and a gentle side-to-side wiggle so a K-grader sees it
// without being told.
//
// USE THIS for any "the activity / lesson / round is done, advance" moment:
//   - Lesson Continue (after iShow finishes).
//   - Round-complete sheet ("Back to the Sanctuary" / next round).
//   - Sub-mode end screens, foundry-creation confirmation, daily-quest finish.
//
// DO NOT USE for in-progress actions like "Let's count!" (those are
// activity-specific calls-to-action and shouldn't share the same affordance
// as "I'm done, proceed"). See specs/shared/ui-affordances.md.
//
// Idle hint: if `idleHintEnabled` is true the button fires a periodic
// narration nudge ("Tap the arrow to continue!") and plays a bigger hop
// every 10 s of inactivity. Used at completion moments where a K-grader
// might not yet recognise the wiggling arrow as "the way forward."

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';

class NextArrowButton extends ConsumerStatefulWidget {
  const NextArrowButton({
    super.key,
    required this.onPressed,
    this.size = 96,
    this.label,
    this.color = const Color(0xFFFFC53D),
    this.idleHintEnabled = false,
    this.idleHintText = 'Tap the arrow to continue!',
    this.idleHintCueIdPrefix = 'next-arrow:idle-hint',
    this.idleHintInterval = const Duration(seconds: 10),
  });

  final VoidCallback onPressed;

  /// Diameter of the circular button.
  final double size;

  /// Optional caption rendered beneath the button. Kept short ("Continue",
  /// "Next round"). Null hides the caption — the arrow speaks for itself.
  final String? label;

  /// Body / glow tint. Default is a warm sanctuary-amber.
  final Color color;

  /// Enable the periodic "did you mean to tap this?" hint. Off by default
  /// so non-completion arrows (e.g. KeeperIntro's "Let's count!") aren't
  /// nagging the kid who is just listening to setup narration.
  final bool idleHintEnabled;

  /// Narration spoken at each hint firing.
  final String idleHintText;

  /// Cue-id prefix used per fire — the actual cue-id appends a counter so
  /// the narration player doesn't dedupe successive hints.
  final String idleHintCueIdPrefix;

  /// Time without a tap before the first / next hint fires. Resets when
  /// the kid taps the arrow (which doesn't matter — the widget is gone
  /// by then — but keeps the model clean).
  final Duration idleHintInterval;

  @override
  ConsumerState<NextArrowButton> createState() => _NextArrowButtonState();
}

class _NextArrowButtonState extends ConsumerState<NextArrowButton>
    with TickerProviderStateMixin {
  late final AnimationController _wiggle;
  late final AnimationController _glow;
  late final AnimationController _hint;
  Timer? _idleTimer;
  int _hintFireCount = 0;

  @override
  void initState() {
    super.initState();
    _wiggle = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _glow = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);
    _hint = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    if (widget.idleHintEnabled) {
      _scheduleNextHint();
    }
  }

  void _scheduleNextHint() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.idleHintInterval, _fireHint);
  }

  void _fireHint() {
    if (!mounted) return;
    _hintFireCount += 1;
    _hint
      ..reset()
      ..forward();
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: widget.idleHintText,
            cueId: '${widget.idleHintCueIdPrefix}:$_hintFireCount',
          ),
        );
    _scheduleNextHint();
  }

  void _handlePressed() {
    _idleTimer?.cancel();
    widget.onPressed();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _wiggle.dispose();
    _glow.dispose();
    _hint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Deliberately NOT wrapped in ReadAloudGate. Live testing showed the
    // gate's tap-narration ("Next" / "Continue" / "Done") races with the
    // next-screen's own narration call — on Chrome the speak/cancel/speak
    // sequence sometimes dropped the second utterance, so the kid heard
    // "Next" and never the round prompt they actually needed. The arrow
    // is visually self-explanatory (big amber wiggling target with an
    // idle-hint nudge), so skipping the label narration costs nothing.
    // Other gated widgets (banners, map nodes) still narrate on tap.
    return Semantics(
      button: true,
      label: widget.label ?? 'Next',
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_wiggle, _glow, _hint]),
      builder: (context, _) {
        // Wiggle: sine wave between -1..1, scaled to ~±5°.
        final wiggleT = math.sin(_wiggle.value * 2 * math.pi - math.pi / 2);
        // Hint boost: a one-shot bump that rises then falls. Multiplies
        // wiggle amplitude and inflates the button briefly.
        // `hintEnvelope` peaks at ~mid-animation then falls off.
        final h = _hint.value;
        final hintEnvelope = h == 0 ? 0.0 : math.sin(h * math.pi);
        final angle = wiggleT * (0.085 + hintEnvelope * 0.1); // up to ~10.6°
        final scaleBoost = 1 + hintEnvelope * 0.25; // up to 1.25×
        // Glow: pulsing intensity 0.55..1.0 with shadow blur/spread varying.
        final glowT = _glow.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: scaleBoost,
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color
                            .withValues(alpha: 0.55 + glowT * 0.35),
                        blurRadius:
                            22 + glowT * 14 + hintEnvelope * 18,
                        spreadRadius:
                            2 + glowT * 4 + hintEnvelope * 6,
                      ),
                      BoxShadow(
                        color: Colors.amber
                            .withValues(alpha: 0.25 + glowT * 0.25),
                        blurRadius: 40 + glowT * 20,
                        spreadRadius: 6 + glowT * 6,
                      ),
                    ],
                  ),
                  child: Material(
                    shape: const CircleBorder(),
                    color: widget.color,
                    elevation: 6,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _handlePressed,
                      child: SizedBox(
                        width: widget.size,
                        height: widget.size,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: widget.size * 0.6,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
