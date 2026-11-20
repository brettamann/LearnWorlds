// The decorate tray — her box of things, and the shop, in one strip.
//
// Deliberately not a separate shop screen. The Buddy shop is its own route
// because dressing Buddy is a thing you go and do; decorating is a thing you
// do *while looking at the map*, and sending her to a storefront and back
// would break the one continuous surface the whole feature depends on.
// Appendix A of the engagement plan is specific that every return to a menu is
// a decision point where a five-year-old can disengage.
//
// Owned items are bright and draggable. Unowned ones are dimmed with a price
// chip and buy on tap — the same deliberate exception to
// specs/shared/ui-affordances.md's "missing buttons, not disabled buttons"
// that the Buddy shop takes, and for the same reason: in a shop, hiding what
// you cannot afford removes the reason to come back.
//
// The tray is also the bin. Dragging a placed decoration onto it takes it off
// the map, which is the only "undo" a pre-reader can be expected to find.

import 'package:flutter/material.dart';

import '../../data/button_labels.dart';
import '../../data/sanctuary_decor_catalog.dart';

class DecorTray extends StatelessWidget {
  const DecorTray({
    super.key,
    required this.owns,
    required this.coins,
    required this.onBuy,
    required this.onTapOwned,
    required this.onPlace,
    required this.onRemove,
    required this.onDone,
  });

  final bool Function(String decorId) owns;
  final int coins;

  /// Tapping a locked tile. The caller decides whether she can afford it and
  /// what to say either way; the tray never speaks.
  final void Function(DecorItem item) onBuy;

  /// Tapping an owned tile — says its name.
  final void Function(DecorItem item) onTapOwned;

  /// A tile dragged onto the map, in global coordinates.
  final void Function(DecorItem item, Offset globalPosition) onPlace;

  /// A placed decoration dragged back onto the tray.
  final void Function(int instanceId) onRemove;

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    // Ordered by tier so the cheap things she already owns are first and the
    // two special items sit at the end where they read as a goal.
    final items = <DecorItem>[
      for (final tier in DecorTier.values)
        ...kSanctuaryDecor.where((i) => i.tier == tier),
    ];

    return DragTarget<int>(
      onAcceptWithDetails: (details) => onRemove(details.data),
      builder: (context, candidate, _) {
        final armed = candidate.isNotEmpty;
        return Container(
          height: 132,
          decoration: BoxDecoration(
            color: armed ? const Color(0xFF5A4632) : const Color(0xFF3A352D),
            border: const Border(
              top: BorderSide(color: Color(0xFFE0A53C), width: 3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  children: [
                    for (final item in items)
                      _TrayTile(
                        key: ValueKey('decor-tile-${item.id}'),
                        item: item,
                        owned: owns(item.id),
                        affordable: coins >= decorPrice(item.id),
                        onBuy: () => onBuy(item),
                        onTapOwned: () => onTapOwned(item),
                        onPlace: (global) => onPlace(item, global),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 8),
                child: _DoneButton(onPressed: onDone),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrayTile extends StatelessWidget {
  const _TrayTile({
    super.key,
    required this.item,
    required this.owned,
    required this.affordable,
    required this.onBuy,
    required this.onTapOwned,
    required this.onPlace,
  });

  final DecorItem item;
  final bool owned;
  final bool affordable;
  final VoidCallback onBuy;
  final VoidCallback onTapOwned;
  final void Function(Offset globalPosition) onPlace;

  @override
  Widget build(BuildContext context) {
    final sprite = SizedBox(
      width: 64,
      height: 64,
      child: Image.asset(item.spriteAsset, fit: BoxFit.contain),
    );

    final tile = Container(
      width: 92,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: owned ? const Color(0xFFFFF8E7) : const Color(0xFF2E2A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: owned ? const Color(0xFFE0A53C) : const Color(0xFF4A443A),
          width: owned ? 3 : 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Locked items keep their real picture, just dimmed. A silhouette
          // would hide the one thing that makes her want it.
          owned ? sprite : Opacity(opacity: 0.45, child: sprite),
          const SizedBox(height: 2),
          owned
              ? Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3B3226),
                  ),
                )
              : _PriceChip(price: decorPrice(item.id), affordable: affordable),
        ],
      ),
    );

    if (!owned) {
      return GestureDetector(
        onTap: onBuy,
        behavior: HitTestBehavior.opaque,
        child: tile,
      );
    }

    return GestureDetector(
      onTap: onTapOwned,
      child: Draggable<DecorItem>(
        data: item,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragEnd: (details) {
          // `wasAccepted` is false out here — the map is not a DragTarget, so
          // that the whole map surface stays droppable without competing with
          // the lesson nodes for the gesture. The screen decides whether the
          // release point was inside the map.
          onPlace(details.offset);
        },
        feedback: Transform.translate(
          offset: const Offset(-32, -32),
          child: Opacity(opacity: 0.85, child: sprite),
        ),
        child: tile,
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.price, required this.affordable});

  final int price;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: affordable ? const Color(0xFFE0A53C) : const Color(0xFF4A443A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on,
            size: 13,
            color:
                affordable ? const Color(0xFF3B3226) : const Color(0xFF9A8F7C),
          ),
          const SizedBox(width: 3),
          Text(
            '$price',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: affordable
                  ? const Color(0xFF3B3226)
                  : const Color(0xFF9A8F7C),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // A big green tick rather than the word "Done": she cannot read it, and
    // this is the only control that leaves the mode.
    return Semantics(
      button: true,
      label: kLabelFinishDecorating,
      child: GestureDetector(
        key: const ValueKey('decor-done'),
        onTap: onPressed,
        child: Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF6FBF73),
          ),
          child: const Icon(Icons.check, size: 44, color: Colors.white),
        ),
      ),
    );
  }
}
