// CharacterCreatorScreen — the kid's Buddy designer, and (in shop mode) the
// place her coins finally buy something.
//
// One screen, two presentations:
//
//   create — the wardrobe. Shows only parts she owns, with no prices and no
//            coin balance. A first-run kid can tap every tile and every tile
//            works; onboarding never turns into a storefront. If a category
//            has parts she doesn't own yet, a single shop tile sits at the end
//            of the grid as the way through.
//   shop   — the storefront. Shows every part. Owned ones equip on tap; locked
//            ones are dimmed with a price chip and buy-then-equip on tap.
//
// Locked tiles staying visible is a deliberate exception to
// specs/shared/ui-affordances.md ("missing buttons, not disabled buttons"):
// in a shop, the thing you cannot afford yet is the reason to come back. The
// rule still holds in create mode, which shows owned parts only.
//
// Behavior kept from the original creator:
//   - Every tap on a swatch immediately updates the preview *and* applies the
//     change to the saved appearance — there is no "confirm" step. K-grade UX:
//     what they touch is what they get.
//   - The Save coordinator persists on each change so closing the screen
//     without explicit save still keeps the new look.
//   - A category with nothing to choose between is hidden rather than shown
//     as a tab with a single chip.
//
// Layout: portrait phone gets a stacked layout; landscape / tablet (the
// default target) gets the preview on the left, picker on the right.
//
// Claims the music bed. This is where she comes to spend what a sub-mode just
// paid her, so it is reached with the music already playing and used to be the
// place it died — which read as the reward screen being the boring bit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../coordinators/shop.dart';
import '../../data/buddy_shop_catalog.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../models/buddy_appearance.dart';
import '../../navigation/routes.dart';
import '../../providers/buddy_appearance_provider.dart';
import '../../providers/buddy_wardrobe_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_colors.dart';
import '../characters/buddy_widget.dart';
import '../common/answer_feedback.dart';
import '../rewards/coin_hud.dart';
import '../scopes/music_bed_scope.dart';

/// Which face of the screen to show. Defaults to `create` everywhere so a
/// caller that predates the shop cannot accidentally drop a five-year-old
/// into a storefront.
enum BuddyScreenMode { create, shop }

class CharacterCreatorScreen extends ConsumerStatefulWidget {
  const CharacterCreatorScreen({super.key, this.mode = BuddyScreenMode.create});

  final BuddyScreenMode mode;

  @override
  ConsumerState<CharacterCreatorScreen> createState() =>
      _CharacterCreatorScreenState();
}

class _CharacterCreatorScreenState
    extends ConsumerState<CharacterCreatorScreen> {
  BuddyPartKind _category = BuddyPartKind.body;

  bool get _isShop => widget.mode == BuddyScreenMode.shop;

  /// Which tabs are worth showing.
  ///
  /// In create mode a category earns a tab once there are two things to choose
  /// between — a tab holding one swatch is noise. Hats are the exception: "no
  /// hat" is always a real choice, so one owned hat is enough. In shop mode a
  /// category earns a tab if anything in it is actually for sale.
  ///
  /// Both rules were written before there was anything but one arm and one
  /// leg, and both did the right thing on their own when three of each landed:
  /// the shop grew an Arms tab and a Legs tab the moment those parts had a
  /// price, and the creator still shows neither until she has *bought* one,
  /// because owning a single option is not a choice. Mouth is the one category
  /// still in the state arms and legs were in.
  List<BuddyPartKind> _availableCategories(Set<String> owned) {
    final cats = <BuddyPartKind>[];
    for (final kind in BuddyPartKind.values) {
      final parts = buddyPartsOfKind(kind);
      if (_isShop) {
        if (parts.any((p) => buddyPartPrice(kind, p.id) > 0)) cats.add(kind);
        continue;
      }
      final ownedCount = parts.where((p) {
        final key = buddyOwnershipKey(kind, p.id);
        return kBuddyFreeParts.contains(key) || owned.contains(key);
      }).length;
      final threshold = kind == BuddyPartKind.hat ? 1 : 2;
      if (ownedCount >= threshold) cats.add(kind);
    }
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(buddyWardrobeProvider);
    final categories = _availableCategories(owned);
    // A purchase can add a tab and a fresh save can remove one, so never trust
    // the remembered selection to still be on the strip.
    final category = categories.contains(_category)
        ? _category
        : (categories.isEmpty ? BuddyPartKind.body : categories.first);

    return MusicBedScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isShop ? 'Buddy Shop' : 'Design your Buddy'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to the island',
            onPressed: () => context.go(Routes.home),
          ),
          actions: [
            if (_isShop)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(child: CoinHud(compact: true)),
              )
            else
              IconButton(
                tooltip: 'Buddy Shop',
                icon: const Icon(Icons.storefront),
                onPressed: () => context.go(Routes.buddyShop),
              ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final previewSize =
                  (isWide ? constraints.maxWidth * 0.42 : constraints.maxWidth)
                      .clamp(220.0, 460.0);
              final preview = _PreviewPane(size: previewSize);
              final picker = _PickerPane(
                category: category,
                categories: categories,
                mode: widget.mode,
                onCategorySelected: (c) => setState(() => _category = c),
              );
              if (isWide) {
                return Row(
                  children: [
                    Expanded(flex: 5, child: preview),
                    const VerticalDivider(width: 1),
                    Expanded(flex: 6, child: picker),
                  ],
                );
              }
              return Column(
                children: [
                  SizedBox(height: previewSize + 32, child: preview),
                  const Divider(height: 1),
                  Expanded(child: picker),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PreviewPane extends ConsumerWidget {
  const _PreviewPane({required this.size});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFF7F2E7),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: BuddyWidget(size: size),
    );
  }
}

class _PickerPane extends ConsumerWidget {
  const _PickerPane({
    required this.category,
    required this.categories,
    required this.mode,
    required this.onCategorySelected,
  });

  final BuddyPartKind category;
  final List<BuddyPartKind> categories;
  final BuddyScreenMode mode;
  final ValueChanged<BuddyPartKind> onCategorySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category strip across the top of the picker.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in categories)
                _CategoryChip(
                  label: _categoryLabel(c),
                  selected: c == category,
                  onTap: () {
                    ref.read(feedbackEngineProvider).uiTap();
                    onCategorySelected(c);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Swatch grid for the selected category.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _SwatchGrid(kind: category, mode: mode),
          ),
        ),
      ],
    );
  }

  String _categoryLabel(BuddyPartKind c) {
    switch (c) {
      case BuddyPartKind.body:
        return 'Body';
      case BuddyPartKind.eyes:
        return 'Eyes';
      case BuddyPartKind.mouth:
        return 'Mouth';
      case BuddyPartKind.arms:
        return 'Arms';
      case BuddyPartKind.legs:
        return 'Legs';
      case BuddyPartKind.hat:
        return 'Hat';
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.buttonGold : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.selectGold : AppColors.neutralRim,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black87 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwatchGrid extends ConsumerStatefulWidget {
  const _SwatchGrid({required this.kind, required this.mode});

  final BuddyPartKind kind;
  final BuddyScreenMode mode;

  @override
  ConsumerState<_SwatchGrid> createState() => _SwatchGridState();
}

class _SwatchGridState extends ConsumerState<_SwatchGrid> {
  /// Per-tile "you cannot afford this yet" shake counters, keyed by ownership
  /// key. Same generation-counter idiom AnswerFeedback uses for wrong answers,
  /// which is exactly what a refused purchase is: a soft no, not an error.
  final Map<String, int> _denied = <String, int>{};

  void _equip(BuddyPartKind kind, String? id) {
    final notifier = ref.read(buddyAppearanceProvider.notifier);
    switch (kind) {
      case BuddyPartKind.body:
        notifier.setBody(id!);
      case BuddyPartKind.eyes:
        notifier.setEyes(id!);
      case BuddyPartKind.mouth:
        notifier.setMouth(id!);
      case BuddyPartKind.arms:
        notifier.setArms(id!);
      case BuddyPartKind.legs:
        notifier.setLegs(id!);
      case BuddyPartKind.hat:
        notifier.setHat(id);
    }
  }

  void _onTap(BuddyPartKind kind, String id) {
    final key = buddyOwnershipKey(kind, id);
    final wardrobe = ref.read(buddyWardrobeProvider.notifier);
    final feedback = ref.read(feedbackEngineProvider);

    if (wardrobe.owns(key)) {
      feedback.uiTap();
      _equip(kind, id);
      return;
    }

    final bought = ref
        .read(shopProvider)
        .buyBuddyPart(key, buddyPartPrice(kind, id));
    if (bought == PurchaseOutcome.cannotAfford) {
      // Not enough coins yet. Reuse the wrong-answer beat rather than an error
      // tone: a shop that scolds is a shop she stops opening.
      feedback.wrong();
      setState(() => _denied[key] = (_denied[key] ?? 0) + 1);
      return;
    }
    // Auto-equip. She just spent her coins on it; making her tap a second time
    // to actually wear it is the kind of step an adult tolerates and a
    // five-year-old reads as the purchase not having worked.
    _equip(kind, id);
  }

  String? _selectedId(BuddyAppearance a, BuddyPartKind kind) {
    switch (kind) {
      case BuddyPartKind.body:
        return a.bodyId;
      case BuddyPartKind.eyes:
        return a.eyesId;
      case BuddyPartKind.mouth:
        return a.mouthId;
      case BuddyPartKind.arms:
        return a.armsId;
      case BuddyPartKind.legs:
        return a.legsId;
      case BuddyPartKind.hat:
        return a.hatId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final isShop = widget.mode == BuddyScreenMode.shop;
    final appearance = ref.watch(buddyAppearanceProvider);
    // Watched, not read: buying a part has to repaint the tile that was locked
    // a frame ago.
    ref.watch(buddyWardrobeProvider);
    final wardrobe = ref.read(buddyWardrobeProvider.notifier);
    final coins = ref.watch(walletProvider);
    final selected = _selectedId(appearance, kind);

    final tiles = <Widget>[];

    // "No hat" comes first so the kid can always bail out of an accessory
    // without hunting for a toggle.
    if (kind == BuddyPartKind.hat) {
      tiles.add(
        _Swatch(
          key: const ValueKey('hat-none'),
          assetPath: null,
          selected: appearance.hatId == null,
          onTap: () {
            ref.read(feedbackEngineProvider).uiTap();
            _equip(BuddyPartKind.hat, null);
          },
        ),
      );
    }

    var anyLocked = false;
    for (final part in buddyPartsOfKind(kind)) {
      final key = buddyOwnershipKey(kind, part.id);
      final owns = wardrobe.owns(key);
      if (!owns) anyLocked = true;
      if (!owns && !isShop) continue;
      final price = buddyPartPrice(kind, part.id);
      tiles.add(
        AnswerFeedback(
          key: ValueKey('feedback-$key'),
          wrongToken: _denied[key] ?? 0,
          shakeExtent: 7,
          child: _Swatch(
            key: ValueKey('${kind.name}-${part.id}'),
            assetPath: part.assetPath,
            selected: owns && selected == part.id,
            lockedPrice: owns ? null : price,
            affordable: owns || coins >= price,
            onTap: () => _onTap(kind, part.id),
          ),
        ),
      );
    }

    // The way out of create mode when there is more to be had. One tile, at
    // the end, only when it leads somewhere.
    if (!isShop && anyLocked) {
      tiles.add(
        _ShopTile(
          key: const ValueKey('swatch-shop'),
          onTap: () {
            ref.read(feedbackEngineProvider).uiTap();
            context.go(Routes.buddyShop);
          },
        ),
      );
    }

    return _GridOfSwatches(items: tiles);
  }
}

class _GridOfSwatches extends StatelessWidget {
  const _GridOfSwatches({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(spacing: 12, runSpacing: 12, children: items),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.assetPath,
    required this.selected,
    required this.onTap,
    this.lockedPrice,
    this.affordable = true,
  });

  /// Sprite shown in the swatch. Null draws a "no thanks" tile — currently
  /// only used by the Hat category for the "no hat" option.
  final String? assetPath;
  final bool selected;
  final VoidCallback onTap;

  /// Non-null when the kid does not own this yet; draws the price chip.
  final int? lockedPrice;

  /// Whether the balance covers [lockedPrice]. Affordable-but-unowned tiles
  /// stay at full colour so what she can buy *right now* reads at a glance.
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    final locked = lockedPrice != null;
    Widget sprite = path == null
        ? const Center(
            child: Icon(Icons.block, size: 36, color: Color(0xFFA39A82)),
          )
        : Image.asset(path, fit: BoxFit.contain);
    if (locked && !affordable) {
      // Drained rather than greyed to nothing: the colour is the whole appeal
      // of a body swatch, so keep enough of it to want.
      sprite = Opacity(opacity: 0.55, child: sprite);
    }

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected
              ? AppColors.selectGold
              : (locked ? const Color(0xFFEDE8DC) : const Color(0xFFE3DED0)),
          width: selected ? 4 : 2,
        ),
      ),
      elevation: selected ? 4 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: 76,
            height: 76,
            child: locked
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      sprite,
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _PriceChip(
                          price: lockedPrice!,
                          affordable: affordable,
                        ),
                      ),
                    ],
                  )
                : sprite,
          ),
        ),
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
        color: affordable ? const Color(0xFF2E7D32) : Colors.black54,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on,
            size: 14,
            color: AppColors.coinGold,
          ),
          const SizedBox(width: 3),
          Text(
            '$price',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3D6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.selectGold, width: 2),
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: SizedBox(
            width: 76,
            height: 76,
            child: Center(
              child: Icon(Icons.storefront, size: 40, color: Color(0xFFB07A12)),
            ),
          ),
        ),
      ),
    );
  }
}
