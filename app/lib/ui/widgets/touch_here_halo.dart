// The ring that says "touch here".
//
// Drawn over whatever it is pointing at rather than inside it, so that every
// place in the game that needs to say "this one" says it the same way: the
// lesson's We-Try gate, and the four runners whose idle-help had nothing to
// point with. It is asking her for something, so it has to read as an
// invitation and not as an alarm: `art-direction.md` wants reward and prompt
// signals "warm, not loud", which rules out the red-ring-and-arrow treatment
// this could easily have become.
//
// It breathes rather than blinking. A blink is a warning light; a slow swell
// is a thing waiting patiently, and she can take as long as she likes.
//
// It expects to be a child of a `Stack`, and positions itself from [rect] in
// that stack's coordinate space.

import 'package:flutter/material.dart';

/// The ring, positioned onto a rect in an enclosing `Stack`.
///
/// Use this when the thing being pointed at was measured rather than laid
/// out here - a lesson stage registers its targets and the halo is drawn over
/// them from outside. When the ring can simply be a sibling of the thing, use
/// [TouchHereRing] and let the layout do the positioning.
class TouchHereHalo extends StatelessWidget {
  const TouchHereHalo({
    super.key,
    required this.rect,
    this.urgent = false,
  });

  /// Where the stage drew the target, in this overlay's coordinate space.
  final Rect rect;

  /// Set once she has been waiting past the lesson's hesitation threshold.
  /// Brightens and quickens a little - still an invitation, just a more
  /// obvious one.
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    // Generous padding: the ring sits outside the sprite, so it never covers
    // the thing she is being asked to look at.
    return Positioned.fromRect(
      rect: rect.inflate(rect.shortestSide * 0.10 + 9),
      child: TouchHereRing(urgent: urgent),
    );
  }
}

/// The ring, drawn just *outside* the box it is given.
///
/// Put it in a `Stack(clipBehavior: Clip.none)` alongside the thing it points
/// at, sized to that thing. The outset is not decoration: the ring is stroked
/// with a nine-pixel blur, and drawn on a sixty-four-pixel sprite that blur
/// washes the sprite out - so the shape she is being asked to pick up becomes
/// the palest one on the board. That is the same mistake, in a second form,
/// that the `BoxShadow` version of this made: a highlight that reads as
/// "disabled".
class TouchHereRingOutside extends StatelessWidget {
  const TouchHereRingOutside({
    super.key,
    required this.around,
    this.urgent = false,
  });

  /// The drawn size of the thing being ringed. Only its shorter side is used,
  /// and only to size the gap, which matches [TouchHereHalo]'s.
  final Size around;

  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final pad = around.shortestSide * 0.10 + 9;
    return Positioned(
      left: -pad,
      top: -pad,
      right: -pad,
      bottom: -pad,
      child: TouchHereRing(urgent: urgent),
    );
  }
}

/// The ring, filling whatever box it is given.
///
/// Prefer [TouchHereRingOutside] when the thing being ringed is a sprite;
/// this one is for a target that is already an empty outline, where there is
/// nothing underneath for the blur to wash out. It never takes a touch, so it
/// can sit on top of a target without stopping her from tapping it - which
/// matters, because the whole point of the ring is that she is about to.
class TouchHereRing extends StatefulWidget {
  const TouchHereRing({super.key, this.urgent = false});

  final bool urgent;

  @override
  State<TouchHereRing> createState() => _TouchHereRingState();
}

class _TouchHereRingState extends State<TouchHereRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(TouchHereRing old) {
    super.didUpdateWidget(old);
    if (widget.urgent != old.urgent) {
      _pulse.duration = Duration(milliseconds: widget.urgent ? 900 : 1400);
      _pulse
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_pulse.value);
          return Transform.scale(
            scale: 0.96 + t * 0.06,
            child: CustomPaint(
              painter: _RingPainter(
                glow: (widget.urgent ? 0.46 : 0.34) + t * 0.22,
                width: widget.urgent ? 6 : 5,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A ring, and only a ring.
///
/// The obvious build of this is a circular `DecoratedBox` with a `BoxShadow`,
/// and it is wrong in a way that is invisible in code: a box shadow on a
/// circle is a blurred *filled* disc drawn behind the box, so the glow lands
/// on top of the sprite and washes it out. Rendered next to its three
/// unhaloed neighbours, the fawn she was being asked to touch was the palest
/// one on screen - the highlight reading as "this one is disabled".
///
/// Stroking a blurred circle keeps the light on the ring, where it was meant
/// to be, and leaves the middle exactly as bright as it was.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.glow, required this.width});

  final double glow;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    // A stadium, not a circle. A circle is sized by the shorter side, so on a
    // tall target it rings the middle and leaves the rest outside - and the
    // first tall target this met was a column of ten baby gryphons in the
    // lesson about groups of ten, where the ring landed on two of them. This
    // is a circle whenever the target is square, which is most of them.
    final inset = Rect.fromLTWH(0, 0, size.width, size.height).deflate(width);
    final rrect = RRect.fromRectXY(
      inset,
      inset.shortestSide / 2,
      inset.shortestSide / 2,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2.6
        ..color = Colors.amber.shade300.withValues(alpha: glow * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = Colors.amber.shade400.withValues(alpha: glow + 0.3),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.glow != glow || old.width != width;
}
