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
// Idle hint: if `idleHintEnabled` is true the button fires a periodic
// narration nudge ("Tap the arrow to continue!") and plays a bigger hop
// every 10 s of inactivity. Used at completion moments where a K-grader
// might not yet recognise the wiggling arrow as "the way forward."
//
// It gives up after [kMaxIdleHints]. Five nudges is a minute of a voice asking
// a child to do something; if it has not worked by then she is not there, and
// a game that keeps calling out to an empty room is worse than one that waits
// quietly. The arrow keeps its wiggle and glow, so whenever she does come back
// there is still something moving to aim at.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/button_labels.dart';
import '../../engines/narration/narration_player.dart';
import '../../theme/app_colors.dart';

/// How many idle nudges before the button assumes nobody is listening.
const int kMaxIdleHints = 5;

class NextArrowButton extends ConsumerStatefulWidget {
  const NextArrowButton({
    super.key,
    required this.onPressed,
    this.size = 96,
    this.label,
    this.color = AppColors.buttonGold,
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
    if (_hintFireCount >= kMaxIdleHints) return;
    _idleTimer = Timer(widget.idleHintInterval, _fireHint);
  }

  void _fireHint() {
    if (!mounted) return;
    _hintFireCount += 1;
    _hint
      ..reset()
      ..forward();
    ref.narration.say(
      widget.idleHintText,
      cueId: '${widget.idleHintCueIdPrefix}:$_hintFireCount',
    );
    _scheduleNextHint();
  }

  void _handlePressed() {
    _idleTimer?.cancel();
    widget.onPressed();
  }

  @override
  void didUpdateWidget(NextArrowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different line means a different beat, which means she got here by
    // doing something — so the nudges start over. Without this, a button that
    // survives from one beat to the next inherits a spent counter and never
    // speaks again.
    if (widget.idleHintText != oldWidget.idleHintText ||
        widget.idleHintEnabled != oldWidget.idleHintEnabled) {
      _hintFireCount = 0;
      if (widget.idleHintEnabled) {
        _scheduleNextHint();
      } else {
        _idleTimer?.cancel();
      }
    }
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
      label: widget.label ?? kLabelNext,
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
                        color:
                            widget.color.withValues(alpha: 0.55 + glowT * 0.35),
                        blurRadius: 22 + glowT * 14 + hintEnvelope * 18,
                        spreadRadius: 2 + glowT * 4 + hintEnvelope * 6,
                      ),
                      BoxShadow(
                        color:
                            Colors.amber.withValues(alpha: 0.25 + glowT * 0.25),
                        blurRadius: 40 + glowT * 20,
                        spreadRadius: 6 + glowT * 6,
                      ),
                    ],
                  ),
                  child: Material(
                    // A dark ring, not decoration. The button is warm amber and
                    // the meadow behind it is bright yellow-green, so on the
                    // real background the disc dissolved into the leaves — for
                    // the one control that means "go", on the one screen where
                    // a stuck child has nothing else to aim at.
                    shape: const CircleBorder(
                      side: BorderSide(color: Color(0xFF2B2318), width: 4),
                    ),
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
                              color: Colors.black54,
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
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2B2318), width: 2),
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
