// The decorations, drawn on the Sanctuary map.
//
// Draw order matters and is not arbitrary. This layer sits ABOVE the fog and
// BELOW the parchment banners:
//
//   - above the fog, because a decoration that vanishes the moment she lets go
//     of it reads as the app eating her mushroom. Fog covers unexplored
//     regions, and she is perfectly likely to put something there.
//   - below the banners, because the banner is the tappable half of every
//     lesson node (see `_buildNode`'s two passes). A rainbow arch parked over
//     a node disc is fine and even funny; one that swallowed the tap target
//     and stopped her starting a lesson would not be.
//
// In editing mode every placement becomes draggable and gains a soft halo, so
// the difference between "my map" and "my map I can rearrange" is visible
// without a word of text.

import 'package:flutter/material.dart';

import '../../data/sanctuary_decor_catalog.dart';
import '../../models/decor_placement.dart';

/// A placed decoration was dropped somewhere.
///
/// Reports the release point in *global* coordinates and lets the screen do
/// the conversion, exactly as the tray does for a new item. Both drags then
/// resolve through one piece of arithmetic instead of two that can disagree.
typedef DecorMoved = void Function(int instanceId, Offset globalPosition);

class SanctuaryDecorLayer extends StatelessWidget {
  const SanctuaryDecorLayer({
    super.key,
    required this.placements,
    required this.size,
    required this.editing,
    this.onMoved,
    this.onTapped,
  });

  final List<DecorPlacement> placements;
  final Size size;

  /// True while the decorate tray is open.
  final bool editing;

  final DecorMoved? onMoved;
  final void Function(DecorPlacement placement)? onTapped;

  @override
  Widget build(BuildContext context) {
    final shortest = size.shortestSide;
    return Positioned.fill(
      // Not editing: purely scenery. IgnorePointer keeps every tap falling
      // through to the lesson nodes underneath, so decorating the map can
      // never make the game harder to play.
      child: IgnorePointer(
        ignoring: !editing,
        child: Stack(
          children: [
            for (final placement in placements)
              if (decorItemById(placement.decorId) case final item?)
                _PlacedDecor(
                  key: ValueKey('decor-${placement.instanceId}'),
                  placement: placement,
                  item: item,
                  mapSize: size,
                  width: shortest * item.widthFraction,
                  editing: editing,
                  onMoved: onMoved,
                  onTapped: onTapped,
                ),
          ],
        ),
      ),
    );
  }
}

class _PlacedDecor extends StatelessWidget {
  const _PlacedDecor({
    super.key,
    required this.placement,
    required this.item,
    required this.mapSize,
    required this.width,
    required this.editing,
    required this.onMoved,
    required this.onTapped,
  });

  final DecorPlacement placement;
  final DecorItem item;
  final Size mapSize;
  final double width;
  final bool editing;
  final DecorMoved? onMoved;
  final void Function(DecorPlacement placement)? onTapped;

  @override
  Widget build(BuildContext context) {
    final left = placement.x * mapSize.width - width / 2;
    final top = placement.y * mapSize.height - width / 2;

    final sprite = SizedBox(
      width: width,
      height: width,
      child: Image.asset(item.spriteAsset, fit: BoxFit.contain),
    );

    if (!editing) {
      return Positioned(left: left, top: top, child: sprite);
    }

    final highlighted = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x33FFFFFF),
        border: Border.all(color: const Color(0x88FFE9A8), width: 2),
      ),
      child: Padding(padding: const EdgeInsets.all(4), child: sprite),
    );

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => onTapped?.call(placement),
        // Dragged by its centre. `feedback` is the same sprite at the same
        // size, so what she is holding looks exactly like what she will get —
        // a scaled-up drag ghost makes a five-year-old aim wrong.
        child: Draggable<int>(
          data: placement.instanceId,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          // `wasAccepted` means the tray took it — the tray is a DragTarget so
          // that dropping a decoration back into the box is how she removes
          // one. Moving and removing are the same gesture with two endings.
          onDragEnd: (details) {
            if (details.wasAccepted) return;
            onMoved?.call(placement.instanceId, details.offset);
          },
          feedback: Transform.translate(
            offset: Offset(-width / 2, -width / 2),
            child: Opacity(opacity: 0.85, child: sprite),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: highlighted),
          child: highlighted,
        ),
      ),
    );
  }
}
