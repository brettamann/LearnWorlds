// CharacterCreatorScreen — the kid's mix-and-match Buddy designer.
// Lives behind the "Home" region on the island map. Big live preview on
// the left, category tabs on the right (Body / Eyes / Mouth / Arms /
// Legs), and a wrap of swatches inside each tab.
//
// Behavior:
//   - Every tap on a swatch immediately updates the preview *and*
//     applies the change to the saved appearance — there's no
//     "confirm" step. K-grade UX: what they touch is what they get.
//   - The Save coordinator persists on each change so closing the
//     screen without explicit save still keeps the new look.
//   - Mouth tab is hidden when only one option exists (currently the
//     case) so the kid doesn't see a tab with a single chip.
//
// Layout: portrait phone gets a stacked layout; landscape / tablet
// (the default target) gets the preview on the left, picker on the
// right.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/buddy_parts_catalog.dart';
import '../../providers/buddy_appearance_provider.dart';
import '../../providers/save_provider.dart';
import '../widgets/buddy_widget.dart';

class CharacterCreatorScreen extends ConsumerStatefulWidget {
  const CharacterCreatorScreen({super.key});

  @override
  ConsumerState<CharacterCreatorScreen> createState() =>
      _CharacterCreatorScreenState();
}

enum _Category { body, eyes, mouth, arms, legs, hat }

class _CharacterCreatorScreenState
    extends ConsumerState<CharacterCreatorScreen> {
  _Category _category = _Category.body;

  /// Persist on every change so the kid never loses a tweak. Fire-and-
  /// forget — the save is small and the round-coordinator pattern keeps
  /// concurrent writes coalesced.
  void _persist() {
    ref.read(saveCoordinatorProvider).persist();
  }

  List<_Category> get _availableCategories {
    // Hide the Mouth tab when there's only one option — a tab with a
    // single swatch is just noise to a K kid.
    final cats = <_Category>[];
    for (final c in _Category.values) {
      if (c == _Category.mouth && kBuddyMouths.length <= 1) continue;
      cats.add(c);
    }
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _availableCategories;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design your Buddy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to the island',
          onPressed: () => context.go('/'),
        ),
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
              category: _category,
              categories: categories,
              onCategorySelected: (c) => setState(() => _category = c),
              onChanged: _persist,
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
    required this.onCategorySelected,
    required this.onChanged,
  });

  final _Category category;
  final List<_Category> categories;
  final ValueChanged<_Category> onCategorySelected;
  final VoidCallback onChanged;

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
                  onTap: () => onCategorySelected(c),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Swatch grid for the selected category.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _SwatchGrid(category: category, onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  String _categoryLabel(_Category c) {
    switch (c) {
      case _Category.body:
        return 'Body';
      case _Category.eyes:
        return 'Eyes';
      case _Category.mouth:
        return 'Mouth';
      case _Category.arms:
        return 'Arms';
      case _Category.legs:
        return 'Legs';
      case _Category.hat:
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
      color: selected ? const Color(0xFFFFC53D) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color:
              selected ? const Color(0xFFEAA916) : const Color(0xFFD8D2C2),
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

class _SwatchGrid extends ConsumerWidget {
  const _SwatchGrid({required this.category, required this.onChanged});

  final _Category category;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(buddyAppearanceProvider);
    final notifier = ref.read(buddyAppearanceProvider.notifier);
    switch (category) {
      case _Category.body:
        return _GridOfSwatches(
          items: [
            for (final o in kBuddyBodies)
              _Swatch(
                key: ValueKey('body-${o.id}'),
                assetPath: o.assetPath,
                selected: appearance.bodyId == o.id,
                onTap: () {
                  notifier.setBody(o.id);
                  onChanged();
                },
              ),
          ],
        );
      case _Category.eyes:
        return _GridOfSwatches(
          items: [
            for (final o in kBuddyEyes)
              _Swatch(
                key: ValueKey('eyes-${o.id}'),
                assetPath: o.assetPath,
                selected: appearance.eyesId == o.id,
                onTap: () {
                  notifier.setEyes(o.id);
                  onChanged();
                },
              ),
          ],
        );
      case _Category.mouth:
        return _GridOfSwatches(
          items: [
            for (final o in kBuddyMouths)
              _Swatch(
                key: ValueKey('mouth-${o.id}'),
                assetPath: o.assetPath,
                selected: appearance.mouthId == o.id,
                onTap: () {
                  notifier.setMouth(o.id);
                  onChanged();
                },
              ),
          ],
        );
      case _Category.arms:
        return _GridOfSwatches(
          items: [
            for (final o in kBuddyArms)
              _Swatch(
                key: ValueKey('arms-${o.id}'),
                // Show the right-side sprite as the swatch — it tends
                // to be the more recognizable silhouette of the pair.
                assetPath: o.rightAsset,
                selected: appearance.armsId == o.id,
                onTap: () {
                  notifier.setArms(o.id);
                  onChanged();
                },
              ),
          ],
        );
      case _Category.legs:
        return _GridOfSwatches(
          items: [
            for (final o in kBuddyLegs)
              _Swatch(
                key: ValueKey('legs-${o.id}'),
                assetPath: o.rightAsset,
                selected: appearance.legsId == o.id,
                onTap: () {
                  notifier.setLegs(o.id);
                  onChanged();
                },
              ),
          ],
        );
      case _Category.hat:
        return _GridOfSwatches(
          items: [
            // "No hat" swatch — first option so the kid can always
            // bail out of an accessory without hunting for a toggle.
            _Swatch(
              key: const ValueKey('hat-none'),
              assetPath: null,
              selected: appearance.hatId == null,
              onTap: () {
                notifier.setHat(null);
                onChanged();
              },
            ),
            for (final o in kBuddyHats)
              _Swatch(
                key: ValueKey('hat-${o.id}'),
                assetPath: o.assetPath,
                selected: appearance.hatId == o.id,
                onTap: () {
                  notifier.setHat(o.id);
                  onChanged();
                },
              ),
          ],
        );
    }
  }
}

class _GridOfSwatches extends StatelessWidget {
  const _GridOfSwatches({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items,
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  /// Sprite shown in the swatch. Null draws a "no thanks" tile —
  /// currently only used by the Hat category for the "no hat" option.
  final String? assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color:
              selected ? const Color(0xFFEAA916) : const Color(0xFFE3DED0),
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
            child: path == null
                ? const Center(
                    child: Icon(
                      Icons.block,
                      size: 36,
                      color: Color(0xFFA39A82),
                    ),
                  )
                : Image.asset(path, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
