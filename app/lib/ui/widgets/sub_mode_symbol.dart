// SubModeSymbol — draws the picture on a sub-mode picker card.
//
// The picker's whole job is to let a child who cannot read choose between two
// and six games. She has three channels for that: what she hears (the sheet
// reads the options out as it opens), what she remembers of having played
// them, and this picture. The picture used to be a borrowed sprite — a
// toucan for hide-and-seek, a grey outline cylinder for a creature home —
// which gave the first two channels nothing to attach to.
//
// So a symbol is a miniature of the round now, and it is drawn from the same
// data the round is drawn from:
//
//   PickerSprite   one sprite, for the two activities where one sprite is
//                  already the honest answer.
//   PickerScene    an arrangement — landmark sprites and, where it belongs,
//                  the kid's actual Buddy in the colours she chose. Where's
//                  Buddy's three sub-modes differ by *where Buddy is*, so
//                  where Buddy is is what the three cards show.
//   PickerHabitat  the finished habitat, laid out from `kHabitatBlueprints`
//                  with the same stick-and-clay geometry `_EdgeWidget` uses
//                  in the runner. Retune a blueprint and the card follows.
//
// Buddy is drawn with `idleAnimations: false`, and that is load-bearing
// twice: a picker holding six breathing Buddies is six animation controllers
// running behind a modal, and — see the trap noted in app/README.md — a test
// that calls `pumpAndSettle` anywhere near a breathing BuddyWidget never
// returns.

import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';
import '../../data/build_a_habitat_blueprints.dart';
import '../../data/sub_mode_picker_data.dart';
import 'buddy_widget.dart';
import 'habitat_frame_layout.dart';

class SubModeSymbol extends StatelessWidget {
  const SubModeSymbol({
    super.key,
    required this.symbol,
    required this.size,
  });

  final PickerSymbol symbol;

  /// Side of the square the symbol is drawn into.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: switch (symbol) {
        PickerSprite(:final asset) => Image.asset(asset, fit: BoxFit.contain),
        PickerScene(:final layers) => _Scene(layers: layers, size: size),
        PickerHabitat(:final blueprintIndex) => _HabitatThumb(
            blueprint: kHabitatBlueprints[blueprintIndex],
            size: size,
          ),
      },
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({required this.layers, required this.size});

  final List<PickerSceneLayer> layers;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // Nothing is clipped: a landmark drawn at 0.76 of the box with its
      // centre at 0.62 runs past the right edge on purpose, so the card reads
      // as a window onto a scene rather than a specimen on a card.
      clipBehavior: Clip.none,
      children: <Widget>[
        for (final layer in layers)
          Positioned(
            left: (layer.x - layer.size / 2) * size,
            top: (layer.y - layer.size / 2) * size,
            width: layer.size * size,
            height: layer.size * size,
            child: layer.isBuddy
                ? BuddyWidget(size: layer.size * size, idleAnimations: false)
                : Transform.scale(
                    scaleX: layer.flip ? -1 : 1,
                    child: Image.asset(layer.asset!, fit: BoxFit.contain),
                  ),
          ),
      ],
    );
  }
}

/// The finished build: sticks along every edge, clay at every corner, roof
/// pieces on top — the same three passes, in the same order, as the runner.
class _HabitatThumb extends StatelessWidget {
  const _HabitatThumb({required this.blueprint, required this.size});

  final HabitatBlueprint blueprint;
  final double size;

  @override
  Widget build(BuildContext context) {
    // The arithmetic moved to HabitatFrameLayout when the K.G.5 lesson needed
    // the identical frame: a lesson that shows a slightly different triangle
    // from the one the round asks her to build has introduced the wrong thing.
    final layout = HabitatFrameLayout(
      blueprint: blueprint,
      width: size,
      height: size,
    );
    final clay = layout.clayDiameter;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (var i = 0; i < blueprint.edges.length; i++)
          Builder(
            builder: (_) {
              final e = layout.edge(i);
              return Positioned(
                left: e.topLeft.dx,
                top: e.topLeft.dy,
                width: e.length,
                height: layout.stickThickness,
                child: Transform.rotate(
                  angle: e.angle,
                  child: Image.asset(
                    AssetPaths.buildAHabitatStick,
                    fit: BoxFit.fill,
                  ),
                ),
              );
            },
          ),
        for (var i = 0; i < blueprint.corners.length; i++)
          Positioned(
            left: layout.corner(i).dx - clay / 2,
            top: layout.corner(i).dy - clay / 2,
            width: clay,
            height: clay,
            child: Image.asset(
              AssetPaths.buildAHabitatClayBall,
              fit: BoxFit.contain,
            ),
          ),
        for (final piece in blueprint.roof)
          Builder(
            builder: (_) {
              final r = layout.roofRect(piece);
              return Positioned(
                left: r.left,
                top: r.top,
                width: r.width,
                height: r.height,
                child: Image.asset(piece.placedAsset, fit: BoxFit.contain),
              );
            },
          ),
      ],
    );
  }
}
