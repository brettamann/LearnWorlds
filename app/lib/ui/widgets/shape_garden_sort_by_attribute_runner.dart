// ShapeGardenSortByAttributeRunner — K.G.4 "analyze, compare, and sort
// two- and three-dimensional shapes ... using informal language to
// describe their similarities, differences, and other attributes."
//
// Three rounds, each sorting by a different attribute the K.G.4 standard
// names: number of sides (3 / 4 / 5+ baskets), size (small / big), and
// curves vs corners (round / pointy). The rounds and every line live in
// data/sort_attribute_words.dart; SanctuaryRoundShell runs the visit, and
// SortAttributeRoundBody is one round's drag-into-baskets.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activities/activity_ids.dart';
import '../../data/asset_paths.dart';
import '../../data/sort_attribute_words.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../theme/app_colors.dart';
import '../common/target_hint.dart';
import 'answer_feedback.dart';
import 'glitter_burst.dart';
import 'sanctuary_round_shell.dart';
import 'touch_here_halo.dart';

class ShapeGardenSortByAttributeRunner extends StatelessWidget {
  const ShapeGardenSortByAttributeRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  Widget build(BuildContext context) {
    return SanctuaryRoundShell(
      activityId: ActivityIds.shapeGarden,
      roundCount: kSortAttributeRounds.length,
      conceptIdFor: (_) => 'K.G.4',
      introLine: kSortAttributeIntro,
      startLabel: kSortAttributeStartLabel,
      keeperLineFor: (i) => kSortAttributeRounds[i].keeperLine,
      finalLine: kSortAttributeFinal,
      skipIntro: skipIntro,
      celebrationHold: const Duration(seconds: 1),
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.shapeGardenBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) => SortAttributeRoundBody(c: c),
    );
  }
}

/// One round: drag every shape into the basket for this round's attribute.
class SortAttributeRoundBody extends ConsumerStatefulWidget {
  const SortAttributeRoundBody({super.key, required this.c});

  final RoundContext c;

  @override
  ConsumerState<SortAttributeRoundBody> createState() =>
      _SortAttributeRoundBodyState();
}

class _SortAttributeRoundBodyState
    extends ConsumerState<SortAttributeRoundBody> {
  late final SortRound _round = kSortAttributeRounds[widget.c.index];

  /// Item id -> the basket it landed in.
  final Map<String, String> _placement = <String, String>{};
  int _burstKey = 0;

  /// What the ladder is pointing at: the shape to move, and once it has
  /// escalated, the basket it belongs in.
  String? _hintedItemId;
  String? _hintedBinId;
  HintLadder? _hints;

  /// Wrong-basket drops this round; also rotates the warm miss line.
  int _wrongDrops = 0;

  /// Item id -> wrong drops on it, driving the shake.
  final Map<String, int> _wrongTokens = <String, int>{};
  bool _done = false;

  bool get _open => !_done && !widget.c.locked;

  static const double _kSmallSize = 64;
  static const double _kLargeSize = 110;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.c.say(sortAttributePrompt(_round.attribute));
      _hints = HintLadder(onLevel: _onHint)..start();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  /// Escalating help, in the order the mechanic is hard in.
  ///
  /// Sorting has two questions in it and only the second one is the lesson:
  /// which shape to pick up is arbitrary, which basket it goes in is K.G.4.
  /// So the first rung rings a shape - that is the arbitrary half, handed to
  /// her for free - and only the second rings the basket, which is the answer.
  /// The top rung drops it, and the drop speaks the basket's name behind the
  /// hint line, which is the reason as well as the confirmation.
  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final item = _nextUnplaced();
    if (item == null) return;
    answerTargetHint(
      level,
      ring: () => setState(() {
        _hintedItemId = item.id;
        if (level == HintLevel.point) _hintedBinId = item.targetBinId;
      }),
      chime: ref.read(feedbackEngineProvider).hint,
      say: (line) => widget.c.say(line, replay: false),
      demonstrate: () => _onDropped(item, item.targetBinId, fromHint: true),
    );
  }

  SortItem? _nextUnplaced() =>
      _round.items.where((it) => !_placement.containsKey(it.id)).firstOrNull;

  /// A tap on a basket says its name. A tap is not an answer here - the
  /// answer is a drop - which is what makes it safe to spend on curiosity.
  /// Without a caption: the word is already printed under the basket.
  void _onBinTapped(String binId) {
    ref.narration.say(
      kSortBinLabels[binId] ?? binId,
      cueId: 'sort:bin:$binId',
      caption: false,
    );
  }

  void _onDropped(SortItem item, String binId, {bool fromHint = false}) {
    if (!_open || _placement.containsKey(item.id)) return;
    if (!fromHint) _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    if (binId != item.targetBinId) {
      setState(() {
        _wrongTokens[item.id] = (_wrongTokens[item.id] ?? 0) + 1;
      });
      feedback.wrong();
      widget.c.say(
        sortAttributeMissLine(_wrongDrops++, _round.attribute),
        replay: false,
      );
      return;
    }
    setState(() {
      _placement[item.id] = binId;
      _burstKey += 1;
      _hintedItemId = null;
      _hintedBinId = null;
    });
    // Two sounds, in this order: the thing landing, then the answer being
    // right.
    feedback
      ..drop()
      ..correct();
    // Queued when the ladder made this drop, so it does not cut off the
    // hint line it follows.
    widget.c.say(
      kSortBinLabels[binId] ?? binId,
      replay: false,
      queue: fromHint,
    );
    if (_placement.length < _round.items.length) return;
    _done = true;
    _hints?.pause();
    // adaptive-scaffolding.md: a round that needed a demonstration "counts as
    // soft-success; does NOT advance promotion streak".
    widget.c.finish(
      gradeRound(
        misses: _wrongDrops,
        helped: (_hints?.hintsUsed ?? 0) > 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unplaced =
        _round.items.where((it) => !_placement.containsKey(it.id)).toList();
    return Column(
      children: [
        // Pool of unplaced shapes — wraps so it stays tappable as items
        // disappear into baskets.
        Expanded(
          flex: 3,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 18,
            children: [
              for (final it in unplaced)
                // The item bounces back on a wrong basket, which is silent by
                // itself — the shake is what tells her the game noticed.
                AnswerFeedback(
                  key: ValueKey('sort-item-fb-${it.id}'),
                  wrongToken: _wrongTokens[it.id] ?? 0,
                  child: _DraggableSortItem(
                    key: ValueKey('sort-item-${it.id}'),
                    item: it,
                    size: it.isLarge ? _kLargeSize : _kSmallSize,
                    hinted: _hintedItemId == it.id,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Baskets — flexed rather than sized by their content: each holds an
        // `Expanded`, which under the unbounded height a non-flex Column
        // child gets is the one thing a Flex may not do. (It threw on every
        // frame until every_sub_mode_opens_test rendered the round.)
        Expanded(
          flex: 2,
          child: Row(
            children: [
              for (final binId in _round.binIds) ...[
                Expanded(
                  child: _BinDropTarget(
                    key: ValueKey('sort-bin-$binId'),
                    binId: binId,
                    placed: _round.items
                        .where((it) => _placement[it.id] == binId)
                        .toList(),
                    burstKey: _burstKey,
                    inputLocked: !_open,
                    hinted: _hintedBinId == binId,
                    onAccept: (item) => _onDropped(item, binId),
                    onLabelTap: () => _onBinTapped(binId),
                  ),
                ),
                if (binId != _round.binIds.last) const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DraggableSortItem extends StatelessWidget {
  const _DraggableSortItem({
    super.key,
    required this.item,
    required this.size,
    this.hinted = false,
  });

  final SortItem item;
  final double size;

  /// Ringed by the hint ladder. The ring never takes the touch, so she can
  /// still pick the shape up through it - which is the point.
  final bool hinted;

  @override
  Widget build(BuildContext context) {
    final sprite = Image.asset(
      item.asset,
      fit: BoxFit.contain,
      width: size,
      height: size,
    );
    return Draggable<SortItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: size, height: size, child: sprite),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: sprite),
      child: hinted
          ? SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: sprite),
                  TouchHereRingOutside(around: Size.square(size)),
                ],
              ),
            )
          : sprite,
    );
  }
}

/// What a basket looks like: the shapes that belong in it, then its name.
///
/// It used to be the name alone - twelve-point type in an amber pill over a
/// 28px basket icon - which is the whole of the task written in a language the
/// player cannot read. Sorting is telling the bins apart; she could not, so
/// every drop was a guess and getting one right taught her nothing.
class _BinHeader extends StatelessWidget {
  const _BinHeader({required this.binId});

  final String binId;

  static const double _basketHeight = 76;
  static const double _exemplarHeight = 42;

  /// Drops the shapes into the basket's body rather than its handle. The
  /// sprite is a hoop over a bowl and the bowl is the bottom half of it.
  static const double _basketMouth = _basketHeight * 0.24;

  @override
  Widget build(BuildContext context) {
    final exemplars = kSortBinExemplars[binId] ?? const <SortBinExemplar>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _basketHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                AssetPaths.shapeGardenBin2d,
                height: _basketHeight,
                fit: BoxFit.contain,
              ),
              // Sitting in the basket rather than above it, because "these
              // go in here" is the sentence the picture has to say.
              Padding(
                padding: const EdgeInsets.only(top: _basketMouth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final ex in exemplars)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SizedBox(
                          height: _exemplarHeight * ex.scale,
                          width: _exemplarHeight * ex.scale,
                          child: Image.asset(ex.asset, fit: BoxFit.contain),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Kept, unlike the landmark captions on the Where's Buddy clearing,
        // and for a reason that is about where it sits rather than who can
        // read it: this is a fixed header on a card, not a caption floating
        // over a field she has to judge distances across. It costs nothing
        // and it is what an adult sitting next to her reads out.
        Text(
          kSortBinLabels[binId] ?? binId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _BinDropTarget extends StatelessWidget {
  const _BinDropTarget({
    super.key,
    required this.binId,
    required this.placed,
    required this.burstKey,
    required this.inputLocked,
    required this.onAccept,
    required this.onLabelTap,
    this.hinted = false,
  });

  final String binId;
  final List<SortItem> placed;
  final int burstKey;
  final bool inputLocked;

  /// The ladder has escalated far enough to name the basket. It wears the
  /// same amber it already wears when a shape is being held over it, so the
  /// hint and the drop preview are one visual idea rather than two.
  final bool hinted;
  final ValueChanged<SortItem> onAccept;

  /// Say this basket's name. A tap on a basket has no meaning in the mechanic
  /// - the answer is a drop, not a tap - which is exactly what makes it safe
  /// to spend on curiosity.
  final VoidCallback onLabelTap;

  @override
  Widget build(BuildContext context) {
    return DragTarget<SortItem>(
      onWillAcceptWithDetails: (_) => !inputLocked,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        final highlighted = candidate.isNotEmpty || hinted;
        // The whole basket hears the tap, not just the picture on it. A
        // five-year-old aiming at a 76px icon on a 350px card would mostly
        // miss, and there is no competing gesture to protect: dropping is
        // handled by the drag system through the DragTarget below, which a
        // tap handler above it does not intercept.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onLabelTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: highlighted ? 0.85 : 0.65,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    highlighted ? Colors.amber.shade400 : AppColors.neutralRim,
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
                _BinHeader(binId: binId),
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
                                it.asset,
                                fit: BoxFit.contain,
                              ),
                            ),
                        ],
                      ),
                      if (placed.isNotEmpty)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: GlitterBurst(
                              key: ValueKey('bin-burst-$binId-$burstKey'),
                              maxRadius: math.min(80, 12 + placed.length * 8.0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
