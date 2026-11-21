// RevealCard — the "here is a creature, look at it" card, in one place.
//
// Two beats use it and they should look like siblings, because to a
// five-year-old they are the same gesture: the game stops, holds up a picture,
// and tells her what it is.
//
//   - CardRevealOverlay — a creature card she has just earned.
//   - The Counting Parade's species intro — who she is about to count.
//
// The card is deliberately the only text-heavy surface in the game, and the
// text is deliberately not the point. She cannot read it. The picture is what
// she reads, the spoken line is what she hears, and the words on the card are
// there so an adult sitting next to her knows what is going on.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The card face: a small label, a big picture, a name.
class RevealCardFace extends StatelessWidget {
  const RevealCardFace({
    super.key,
    required this.eyebrow,
    required this.spriteAsset,
    required this.title,
    required this.accent,
    this.footer,
  });

  /// The little line above the picture — "A new friend!", "Look who's next!".
  final String eyebrow;

  final String spriteAsset;

  /// The creature's name, in the biggest type on the card.
  final String title;

  /// Border and eyebrow colour. Warm across the board per
  /// specs/shared/art-direction.md — rarity reads as a shift in metal, not a
  /// jump in volume.
  final Color accent;

  /// Optional strip under the name. The reveal uses it for the tap prompt.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent, width: 6),
        boxShadow: const [
          BoxShadow(blurRadius: 40, color: Colors.black54, spreadRadius: 4),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            eyebrow,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: Image.asset(spriteAsset, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.parchmentInk,
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 14), footer!],
        ],
      ),
    );
  }
}

/// Dims the scene and flips the card in over it.
///
/// The quarter-turn as it lands is what makes it read as a card being turned
/// over rather than a dialog appearing — worth keeping when the two callers
/// diverge in every other respect.
class RevealCardStage extends StatelessWidget {
  const RevealCardStage({
    super.key,
    required this.animation,
    required this.child,
    this.onTap,
    this.dim = 0.55,
  });

  final Animation<double> animation;
  final Widget child;

  /// Tap anywhere. Null makes the whole stage inert, which is right for a
  /// card that advances on its own.
  final VoidCallback? onTap;

  final double dim;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final v = animation.value.clamp(0.0, 1.0);
            final t = Curves.easeOutBack.transform(v);
            final fade = Curves.easeOut.transform((v * 2).clamp(0.0, 1.0));
            return ColoredBox(
              color: Colors.black.withValues(alpha: dim * fade),
              child: Center(
                child: Transform.scale(
                  scale: 0.7 + 0.3 * t,
                  child: Transform.rotate(
                    angle: (1 - t) * 0.35,
                    child: Opacity(opacity: fade, child: child),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// "Tap anywhere to keep going", for a child who cannot read it.
///
/// The hand is the message; the words are for the adult. It fades in a beat
/// after the card lands rather than with it, so the picture gets her attention
/// first and the instruction arrives once she has looked.
class TapAnywherePrompt extends StatefulWidget {
  const TapAnywherePrompt({super.key, required this.accent});

  final Color accent;

  @override
  State<TapAnywherePrompt> createState() => _TapAnywherePromptState();
}

class _TapAnywherePromptState extends State<TapAnywherePrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Opacity(
          opacity: 0.55 + 0.45 * t,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: Offset(0, -3 * t),
                child: Icon(Icons.touch_app, size: 26, color: widget.accent),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tap anywhere',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7A6A52),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
