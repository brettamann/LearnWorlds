// MapSideRail — the map's controls, sized for the person using them.
//
// They used to be four 24px Material icons in the app bar, in the top-right
// corner, about as far from a five-year-old's reach and attention as a screen
// allows. Anything she is expected to find has to be big and where she is
// already looking, and on a map she is looking at the middle.
//
// So they come down the side instead. There is room for it: the map renders as
// a centred square, which on any landscape screen leaves a column of unused
// space on both edges — this puts one of them to work rather than stretching
// the map into it, because node positions are painted into the artwork and
// must not move.
//
// Icons still carry the meaning, since she cannot read the labels. The labels
// are for whoever is sitting next to her.

import 'package:flutter/material.dart';

import '../common/read_aloud_gate.dart';

/// Diameter of one rail button. Four times the area of the icon buttons this
/// replaced, and comfortably past any tap-target guidance for small hands.
const double kMapRailButtonSize = 84;

/// Total width the rail asks for, button plus breathing room.
const double kMapRailWidth = 128;

const Color _kInk = Color(0xFF2B2318);
const Color _kFace = Color(0xFFFDF3DF);
const Color _kActiveFace = Color(0xFFFFC65C);

class MapSideRail extends StatelessWidget {
  const MapSideRail({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kMapRailWidth,
      child: SingleChildScrollView(
        // Scrolls rather than overflows: a short landscape window on a phone
        // cannot fit five of these, and a clipped rail would silently lose
        // whichever control ended up last.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  // scaleDown only acts when something genuinely does not fit,
                  // so the buttons are untouched. It is here for the coin HUD,
                  // which grows with the balance: at four digits its 42pt
                  // numerals are wider than the rail, and a Row cannot scroll
                  // sideways out of that.
                  child: FittedBox(fit: BoxFit.scaleDown, child: child),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapRailButton extends StatelessWidget {
  const MapRailButton({
    super.key,
    required this.icon,
    required this.caption,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;

  /// Shown under the button. Not load bearing — the child playing cannot read
  /// it, and the icon has to carry the meaning on its own.
  ///
  /// Named "caption" rather than "label" on purpose. On a map screen a
  /// label is a place name, and place names are spoken — map_labels_test
  /// forbids inlining one because narration_script.dart could never enumerate
  /// it. This text is never spoken, and the different name is what keeps that
  /// distinction real rather than a comment nobody reads.
  final String caption;

  final VoidCallback onPressed;

  /// Draws the button as engaged. Used by Decorate, which is a mode rather
  /// than a destination.
  final bool active;

  @override
  Widget build(BuildContext context) {
    // Gated, which it was not. The rail exists so these controls are somewhere
    // a five-year-old can hit; having moved them there, all five were a bare
    // InkWell - no tap sound, because `Sfx.uiTap` lives inside the gate, and
    // no voice, under a caption she cannot read. Two of the five are the whole
    // reward economy (the shop and the card album) and a third is the only
    // open-ended play in the game (decorate mode).
    //
    // The gate wraps the whole column rather than the disc alone: the caption
    // reads as part of the button, so a tap that lands on it should work.
    return Semantics(
      button: true,
      label: caption,
      child: ReadAloudGate(
        label: caption,
        onTap: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: active ? _kActiveFace : _kFace,
              shape: const CircleBorder(
                // The same heavy border NextArrowButton carries. A pale button
                // on a painted map needs an outline or it disappears into the
                // artwork behind it.
                side: BorderSide(color: _kInk, width: 4),
              ),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: SizedBox(
                  width: kMapRailButtonSize,
                  height: kMapRailButtonSize,
                  child: Icon(icon, size: 40, color: _kInk),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              // Bounded so the caption wraps rather than laying out on one long
              // line and being scaled to nothing by the FittedBox above.
              width: kMapRailButtonSize + 20,
              child: Text(
                caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                  shadows: [Shadow(color: Colors.white70, blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
