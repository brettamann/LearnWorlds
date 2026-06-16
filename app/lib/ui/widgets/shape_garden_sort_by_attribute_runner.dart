// ShapeGardenSortByAttributeRunner — K.G.4 "analyze, compare, and sort
// two- and three-dimensional shapes ... using informal language to
// describe their similarities, differences, and other attributes."
//
// Three rounds, each sorting by a different attribute the K.G.4
// standard names (color, size, shape, number of sides):
//   1. number of sides   — 3 / 4 / 5+ bins
//   2. size              — small / big bins
//   3. curves vs corners — round / pointy bins
//
// Each round resolves through RoundCoordinator (conceptId K.G.4).
// Shapes reuse the existing 2D shape sprites; bins reuse the K.G.3
// `bin_2d.png` with a header overlay describing the attribute.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'continue_arrow_shelf.dart';
import 'glitter_burst.dart';
import 'keeper_intro_overlay.dart';
import 'next_arrow_button.dart';
import 'progress_bar_to_reward.dart';
import 'replay_demo_button.dart';

enum _Phase { intro, sorting, celebrating, interstitial }

/// One sortable instance. The shape's kind + a variant (for the
/// sprite), plus the bin id it actually belongs in for this round.
class _SortItem {
  const _SortItem({
    required this.id,
    required this.kind,
    required this.variant,
    required this.targetBinId,
    required this.isLarge,
  });

  final String id;

  /// Canonical shape kind (`triangle`, `square`, ...).
  final String kind;
  final String variant;

  /// Bin id this item belongs in for the current round's attribute.
  final String targetBinId;

  /// True when this sprite renders at the "big" size for the size
  /// round; ignored on other attributes.
  final bool isLarge;
}

/// One bin definition for the current attribute.
class _Bin {
  const _Bin({required this.id, required this.label});
  final String id;
  final String label;
}

/// One round of sorting by a specific attribute.
class _Round {
  const _Round({
    required this.attribute,
    required this.attributeWord,
    required this.bins,
    required this.items,
    required this.keeperLine,
  });

  final String attribute;
  final String attributeWord;
  final List<_Bin> bins;
  final List<_SortItem> items;
  final String keeperLine;
}

const List<_Round> _kRounds = <_Round>[
  // Round 1 — sort by number of sides. Mirrors the lesson runtime.
  _Round(
    attribute: 'sides',
    attributeWord: 'number of sides',
    bins: <_Bin>[
      _Bin(id: '3-sides', label: '3 sides'),
      _Bin(id: '4-sides', label: '4 sides'),
      _Bin(id: '5plus-sides', label: '5+ sides'),
    ],
    items: <_SortItem>[
      _SortItem(
        id: 'tri-1',
        kind: 'triangle',
        variant: 'yellow',
        targetBinId: '3-sides',
        isLarge: false,
      ),
      _SortItem(
        id: 'tri-2',
        kind: 'triangle',
        variant: 'leaf',
        targetBinId: '3-sides',
        isLarge: false,
      ),
      _SortItem(
        id: 'sq-1',
        kind: 'square',
        variant: 'green',
        targetBinId: '4-sides',
        isLarge: false,
      ),
      _SortItem(
        id: 'rect-1',
        kind: 'rectangle',
        variant: 'stone',
        targetBinId: '4-sides',
        isLarge: false,
      ),
      _SortItem(
        id: 'pent-1',
        kind: 'pentagon',
        variant: 'starfruit',
        targetBinId: '5plus-sides',
        isLarge: false,
      ),
      _SortItem(
        id: 'hex-1',
        kind: 'hexagon',
        variant: 'honeycomb',
        targetBinId: '5plus-sides',
        isLarge: false,
      ),
    ],
    keeperLine:
        'Sides sorted! Triangles, squares + rectangles, pentagons + hexagons.',
  ),
  // Round 2 — sort by size (big vs small).
  _Round(
    attribute: 'size',
    attributeWord: 'size',
    bins: <_Bin>[
      _Bin(id: 'small', label: 'small'),
      _Bin(id: 'big', label: 'big'),
    ],
    items: <_SortItem>[
      _SortItem(
        id: 'small-circle',
        kind: 'circle',
        variant: 'sunflower',
        targetBinId: 'small',
        isLarge: false,
      ),
      _SortItem(
        id: 'small-square',
        kind: 'square',
        variant: 'gray',
        targetBinId: 'small',
        isLarge: false,
      ),
      _SortItem(
        id: 'small-tri',
        kind: 'triangle',
        variant: 'petal',
        targetBinId: 'small',
        isLarge: false,
      ),
      _SortItem(
        id: 'big-circle',
        kind: 'circle',
        variant: 'daisy',
        targetBinId: 'big',
        isLarge: true,
      ),
      _SortItem(
        id: 'big-rect',
        kind: 'rectangle',
        variant: 'wood',
        targetBinId: 'big',
        isLarge: true,
      ),
      _SortItem(
        id: 'big-hex',
        kind: 'hexagon',
        variant: 'terracotta',
        targetBinId: 'big',
        isLarge: true,
      ),
    ],
    keeperLine: 'Big to one side, small to the other — perfect.',
  ),
  // Round 3 — curves vs corners (round vs pointy).
  _Round(
    attribute: 'curves',
    attributeWord: 'curves or corners',
    bins: <_Bin>[
      _Bin(id: 'round', label: 'round'),
      _Bin(id: 'pointy', label: 'pointy'),
    ],
    items: <_SortItem>[
      _SortItem(
        id: 'round-1',
        kind: 'circle',
        variant: 'sunflower',
        targetBinId: 'round',
        isLarge: false,
      ),
      _SortItem(
        id: 'round-2',
        kind: 'semicircle_half',
        variant: 'green',
        targetBinId: 'round',
        isLarge: false,
      ),
      _SortItem(
        id: 'round-3',
        kind: 'semicircle_quarter',
        variant: 'brown',
        targetBinId: 'round',
        isLarge: false,
      ),
      _SortItem(
        id: 'pointy-1',
        kind: 'triangle',
        variant: 'yellow',
        targetBinId: 'pointy',
        isLarge: false,
      ),
      _SortItem(
        id: 'pointy-2',
        kind: 'pentagon',
        variant: 'starfruit',
        targetBinId: 'pointy',
        isLarge: false,
      ),
      _SortItem(
        id: 'pointy-3',
        kind: 'hexagon',
        variant: 'honeycomb',
        targetBinId: 'pointy',
        isLarge: false,
      ),
    ],
    keeperLine:
        "Round things together, pointy things together. That's grouping by curves.",
  ),
];

class ShapeGardenSortByAttributeRunner extends ConsumerStatefulWidget {
  const ShapeGardenSortByAttributeRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  ConsumerState<ShapeGardenSortByAttributeRunner> createState() =>
      _ShapeGardenSortByAttributeRunnerState();
}

class _ShapeGardenSortByAttributeRunnerState
    extends ConsumerState<ShapeGardenSortByAttributeRunner> {
  late _Phase _phase = widget.skipIntro ? _Phase.sorting : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Map<String, String> _placement = <String, String>{}; // itemId → binId
  int _burstKey = 0;
  Timer? _celebrationTimer;

  _Round get _currentRound => _kRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == _kRounds.length - 1;
  double get _progress => _completedRounds / _kRounds.length;
  bool get _allPlaced =>
      _placement.length == _currentRound.items.length;

  String get _introDialog =>
      "Let's group the shapes! I'll tell you what to sort by — the "
      'number of sides, the size, or whether they have curves or '
      'corners. Drop each shape into the basket that matches.';

  String get _prompt =>
      'Sort by ${_currentRound.attributeWord}. Drop each shape in the '
      'right basket!';

  String get _finalKeeperLine =>
      'Every shape sorted! You can group things by all kinds of '
      'differences.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_phase == _Phase.sorting) _speakPrompt();
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
  }

  void _speakPrompt() {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: _prompt,
            cueId: 'sort-attr:r$_roundIndex:prompt',
          ),
        );
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.sorting);
    _speakPrompt();
  }

  /// Called when a draggable item is dropped on a bin. If the bin is
  /// the item's target, lock it in; otherwise narrate the correction
  /// and let the kid try again.
  void _onDropped({required _SortItem item, required _Bin bin}) {
    if (_placement.containsKey(item.id)) return;
    final correct = bin.id == item.targetBinId;
    if (!correct) {
      ref.read(narrationPlayerProvider.notifier).speak(
            NarrationLine(
              text: 'Not quite — try another basket.',
              cueId: 'sort-attr:r$_roundIndex:wrong-${item.id}',
            ),
          );
      return;
    }
    setState(() {
      _placement = <String, String>{..._placement, item.id: bin.id};
      _burstKey += 1;
    });
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: bin.label,
            cueId: 'sort-attr:r$_roundIndex:right-${item.id}',
          ),
        );
    if (_allPlaced) _finishRound();
  }

  void _finishRound() {
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'shape-garden',
          conceptId: 'K.G.4',
          success: true,
        );
    setState(() {
      _completedRounds += 1;
      _phase = _Phase.celebrating;
    });
    _celebrationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.interstitial);
      final line =
          _isLastRound ? _finalKeeperLine : _currentRound.keeperLine;
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: line,
              cueId: 'sort-attr:r$_roundIndex:interstitial',
              speaker: 'sanctuary-keeper-mystic',
            ),
          );
    });
  }

  void _advanceFromInterstitial() {
    if (_isLastRound) {
      widget.onSequenceComplete();
      return;
    }
    setState(() {
      _roundIndex += 1;
      _placement = <String, String>{};
      _phase = _Phase.sorting;
    });
    _speakPrompt();
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: "Let's sort!",
          startButtonKey: const ValueKey('sort-attr-start-button'),
          onStart: _onStartFromIntro,
        ),
      _Phase.sorting || _Phase.celebrating => _SortingLayer(
          round: _currentRound,
          placement: _placement,
          burstKey: _burstKey,
          inputLocked: _phase == _Phase.celebrating,
          onDropped: _onDropped,
          replayPrompt: _prompt,
          replayCueId: 'sort-attr:replay-r$_roundIndex',
          allDone: _phase == _Phase.celebrating,
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _isLastRound ? _finalKeeperLine : _currentRound.keeperLine,
          startLabel: _isLastRound ? 'Continue' : 'Next round!',
          startButtonKey: const ValueKey('sort-attr-interstitial-next'),
          onStart: _advanceFromInterstitial,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AssetPaths.shapeGardenBackground, fit: BoxFit.cover),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: ProgressBarToReward(
                  progress: _progress,
                  celebrate: _phase == _Phase.celebrating,
                ),
              ),
              Expanded(child: phaseContent),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortingLayer extends StatelessWidget {
  const _SortingLayer({
    required this.round,
    required this.placement,
    required this.burstKey,
    required this.inputLocked,
    required this.onDropped,
    required this.replayPrompt,
    required this.replayCueId,
    required this.allDone,
  });

  final _Round round;
  final Map<String, String> placement;
  final int burstKey;
  final bool inputLocked;
  final void Function({required _SortItem item, required _Bin bin})
      onDropped;
  final String replayPrompt;
  final String replayCueId;
  final bool allDone;

  static const double _kSmallSize = 64;
  static const double _kLargeSize = 110;

  @override
  Widget build(BuildContext context) {
    final unplaced =
        round.items.where((it) => !placement.containsKey(it.id)).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            kReplayDemoShelf(
              child: ReplayDemoButton(
                label: replayPrompt,
                cueId: replayCueId,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  // Pool of unplaced shapes — wraps so it stays
                  // tappable as items disappear into bins.
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      spacing: 18,
                      runSpacing: 18,
                      children: [
                        for (final it in unplaced)
                          _DraggableSortItem(
                            key: ValueKey('sort-item-${it.id}'),
                            item: it,
                            size:
                                it.isLarge ? _kLargeSize : _kSmallSize,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bins row — one drag target per bin label.
                  Row(
                    children: [
                      for (final bin in round.bins) ...[
                        Expanded(
                          child: _BinDropTarget(
                            key: ValueKey('sort-bin-${bin.id}'),
                            bin: bin,
                            placed: round.items
                                .where(
                                  (it) => placement[it.id] == bin.id,
                                )
                                .toList(),
                            burstKey: burstKey,
                            inputLocked: inputLocked,
                            onAccept: (item) =>
                                onDropped(item: item, bin: bin),
                          ),
                        ),
                        if (bin != round.bins.last)
                          const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            kContinueArrowShelf(
              child: allDone
                  ? const NextArrowButton(
                      key: ValueKey('sort-attr-done-arrow'),
                      idleHintEnabled: true,
                      onPressed: _noop,
                      label: 'Nice!',
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

void _noop() {}

class _DraggableSortItem extends StatelessWidget {
  const _DraggableSortItem({
    super.key,
    required this.item,
    required this.size,
  });

  final _SortItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sprite = Image.asset(
      AssetPaths.shapeGarden2dSprite(item.kind, item.variant),
      fit: BoxFit.contain,
      width: size,
      height: size,
    );
    return Draggable<_SortItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: size, height: size, child: sprite),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: sprite),
      child: sprite,
    );
  }
}

class _BinDropTarget extends StatelessWidget {
  const _BinDropTarget({
    super.key,
    required this.bin,
    required this.placed,
    required this.burstKey,
    required this.inputLocked,
    required this.onAccept,
  });

  final _Bin bin;
  final List<_SortItem> placed;
  final int burstKey;
  final bool inputLocked;
  final ValueChanged<_SortItem> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_SortItem>(
      onWillAcceptWithDetails: (_) => !inputLocked,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        final highlighted = candidate.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: highlighted ? 0.85 : 0.65,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlighted
                  ? Colors.amber.shade400
                  : const Color(0xFFD8D2C2),
              width: highlighted ? 4 : 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          constraints: const BoxConstraints(minHeight: 120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    AssetPaths.shapeGardenBin2d,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          bin.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Items already in this bin — drawn small so the kid
              // sees how the bin is filling up.
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final it in placed)
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: Image.asset(
                              AssetPaths.shapeGarden2dSprite(
                                it.kind,
                                it.variant,
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                    if (placed.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: GlitterBurst(
                            key: ValueKey('bin-burst-${bin.id}-$burstKey'),
                            maxRadius: math.min(80, 12 + placed.length * 8.0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
