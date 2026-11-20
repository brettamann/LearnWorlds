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
import '../../data/button_labels.dart';
import '../../data/sfx_catalog.dart';
import '../../data/sort_attribute_words.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../platform/sfx_engine.dart';
import '../../theme/app_colors.dart';
import 'answer_feedback.dart';
import 'buddy_companion.dart';
import 'continue_arrow_shelf.dart';
import 'glitter_burst.dart';
import 'keeper_aside.dart';
import 'keeper_intro_overlay.dart';
import 'next_arrow_button.dart';
import 'playfield_scaffold.dart';
import 'replay_demo_button.dart';
import 'touch_here_halo.dart';

enum _Phase {
  intro,
  sorting,

  /// Keeper speaks over the live garden and advances the round herself.
  transition,

  celebrating,

  /// Final beat only — the reward payoff, which is meant to interrupt.
  interstitial,
}

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
  const _Bin({required this.id});
  final String id;

  /// Drawn on the basket and read aloud when it is tapped.
  String get label => kSortBinLabels[id] ?? id;
}

/// One round of sorting by a specific attribute.
class _Round {
  const _Round({
    required this.attribute,
    required this.bins,
    required this.items,
    required this.keeperLine,
  });

  final String attribute;

  /// Words spoken in "Sort by <word>." Read from the shared catalog rather
  /// than stored, so narration_script.dart can enumerate the same string the
  /// runner speaks. See sort_attribute_words.dart.
  String get attributeWord => kSortAttributeWords[attribute] ?? attribute;
  final List<_Bin> bins;
  final List<_SortItem> items;
  final String keeperLine;
}

const List<_Round> _kRounds = <_Round>[
  // Round 1 — sort by number of sides. Mirrors the lesson runtime.
  _Round(
    attribute: 'sides',
    bins: <_Bin>[
      _Bin(id: '3-sides'),
      _Bin(id: '4-sides'),
      _Bin(id: '5plus-sides'),
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
    bins: <_Bin>[
      _Bin(id: 'small'),
      _Bin(id: 'big'),
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
    bins: <_Bin>[
      _Bin(id: 'round'),
      _Bin(id: 'pointy'),
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

  /// Bumped to (re)present the between-round keeper aside.
  int _asideToken = 0;

  /// What the ladder is pointing at: the shape to move, and once it has
  /// escalated, the basket it belongs in.
  String? _hintedItemId;
  String? _hintedBinId;

  HintLadder? _hints;

  /// Wrong-basket drops this round.
  int _wrongDrops = 0;
  int _missRotation = 0;

  /// Item id → wrong drops on it, driving the shake.
  Map<String, int> _wrongTokens = <String, int>{};

  /// Read eagerly — `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfxForDispose;

  _Round get _currentRound => _kRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == _kRounds.length - 1;
  double get _progress => _completedRounds / _kRounds.length;
  bool get _allPlaced => _placement.length == _currentRound.items.length;

  String get _introDialog =>
      "Let's group the shapes! I'll tell you what to sort by — the "
      'number of sides, the size, or whether they have curves or '
      'corners. Drop each shape into the basket that matches.';

  String get _prompt => sortAttributePrompt(_currentRound.attribute);

  String get _finalKeeperLine =>
      'Every shape sorted! You can group things by all kinds of '
      'differences.';

  @override
  void initState() {
    super.initState();
    _sfxForDispose = ref.read(sfxEngineProvider);
    // Claimed here, not in the post-frame callback below: the release in
    // dispose() is unconditional, so the claim has to be too, or a teardown
    // before the first frame gives back a claim it never took. See
    // SfxEngine.releaseMusicBed for what that costs.
    unawaited(_sfxForDispose!.startMusicBed(kDefaultMusicBed));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedbackEngineProvider).resetRound();
      if (_phase == _Phase.sorting) {
        _speakPrompt();
        _startHints();
      }
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    _celebrationTimer?.cancel();
    final sfx = _sfxForDispose;
    if (sfx != null) sfx.releaseMusicBed();
    super.dispose();
  }

  void _speakPrompt() {
    ref.narration.say(_prompt, cueId: 'sort-attr:r$_roundIndex:prompt');
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.sorting);
    _speakPrompt();
    _startHints();
  }

  void _startHints() {
    _hints?.dispose();
    _hints = HintLadder(onLevel: _onHintLevel)..start();
  }

  /// Escalating help, in the order the mechanic is hard in.
  ///
  /// Sorting has two questions in it and only the second one is the lesson:
  /// which shape to pick up is arbitrary, which basket it goes in is K.G.4.
  /// So the first rung rings a shape - that is the arbitrary half, handed to
  /// her for free - and only the second rings the basket, which is the answer.
  ///
  /// Until this existed a child who could not tell three sides from four
  /// could sit in front of the baskets indefinitely with nothing happening,
  /// and this is the round where that is most likely: it is the one that asks
  /// about a property of a shape rather than about the shape.
  void _onHintLevel(HintLevel level) {
    if (!mounted || _phase != _Phase.sorting) return;
    final item = _nextUnplacedItem();
    if (item == null) return;
    final feedback = ref.read(feedbackEngineProvider);
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _hintedItemId = item.id);
      case HintLevel.point:
        setState(() {
          _hintedItemId = item.id;
          _hintedBinId = item.targetBinId;
        });
        feedback.hint();
        ref.narration
            .say(warmHintLine(2), cueId: 'sort-attr:r$_roundIndex:hint-point');
      case HintLevel.demonstrate:
        final bin = _binFor(item);
        if (bin == null) return;
        feedback.hint();
        ref.narration
            .say(warmHintLine(3), cueId: 'sort-attr:r$_roundIndex:hint-demo');
        // The drop speaks the basket's name behind that line, which is the
        // reason as well as the confirmation - "three sides" is why it went
        // there.
        _onDropped(item: item, bin: bin, fromHint: true);
    }
  }

  _SortItem? _nextUnplacedItem() {
    for (final it in _currentRound.items) {
      if (!_placement.containsKey(it.id)) return it;
    }
    return null;
  }

  _Bin? _binFor(_SortItem item) {
    for (final b in _currentRound.bins) {
      if (b.id == item.targetBinId) return b;
    }
    return null;
  }

  /// Called when a draggable item is dropped on a bin. If the bin is
  /// the item's target, lock it in; otherwise narrate the correction
  /// and let the kid try again.
  /// A tap on a basket says its name.
  ///
  /// The clips for these seven lines were rendered a long time ago - the
  /// recording script lists them and its note says "read aloud when a basket
  /// is tapped" - and nothing ever listened for the tap, so they sat on disk
  /// unplayable. Now they play. It is `speakWithoutCaption` because the word
  /// is already printed under the basket, and it is safe to fire on a bare tap
  /// because a tap is not an answer here: the answer is a drop.
  void _onBinTapped(_Bin bin) {
    ref.narration.say(bin.label, cueId: 'sort:bin:${bin.id}', caption: false);
  }

  void _onDropped({
    required _SortItem item,
    required _Bin bin,
    bool fromHint = false,
  }) {
    if (_placement.containsKey(item.id)) return;
    if (!fromHint) _hints?.poke();
    final correct = bin.id == item.targetBinId;
    if (!correct) {
      setState(() {
        _wrongDrops += 1;
        _wrongTokens = <String, int>{
          ..._wrongTokens,
          item.id: (_wrongTokens[item.id] ?? 0) + 1,
        };
      });
      ref.read(feedbackEngineProvider).wrong();
      ref.narration.say(
        '${warmMissLine(_missRotation++)} '
        'Sort by ${_currentRound.attributeWord}.',
        cueId: 'sort-attr:r$_roundIndex:wrong-${item.id}-$_wrongDrops',
      );
      return;
    }
    setState(() {
      _placement = <String, String>{..._placement, item.id: bin.id};
      _burstKey += 1;
      _hintedItemId = null;
      _hintedBinId = null;
    });
    // Two sounds, in this order: the thing landing, then the answer being
    // right. `Sfx.drop` had no call site at all, so three of the game's
    // mechanics are drags in which nothing was ever heard to be put down.
    ref.read(feedbackEngineProvider)
      ..drop()
      ..correct();
    // Queued, not spoken, when the ladder did this drop. See HintLadder.
    final say = ref.narration;
    final line = NarrationLine(
      text: bin.label,
      cueId: 'sort-attr:r$_roundIndex:right-${item.id}',
    );
    if (fromHint) {
      say.enqueue(line);
    } else {
      say.speak(line);
    }
    if (_allPlaced) _finishRound();
  }

  void _finishRound() {
    _hints?.pause();
    // adaptive-scaffolding.md: a round that needed a demonstration "counts as
    // soft-success; does NOT advance promotion streak". Nothing punitive -
    // she still gets the coins - but the mastery ladder should not read a
    // round the game finished for her as evidence that she has it.
    final hintsUsed = _hints?.hintsUsed ?? 0;
    final result = gradeRound(misses: _wrongDrops, helped: hintsUsed > 0);
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'shape-garden',
          conceptId: 'K.G.4',
          result: result,
        );
    setState(() {
      _completedRounds += 1;
      _phase = _Phase.celebrating;
    });

    final feedback = ref.read(feedbackEngineProvider);
    if (_isLastRound) {
      feedback.celebrate();
      _celebrationTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => _phase = _Phase.interstitial);
        ref.narration.say(
          _finalKeeperLine,
          cueId: 'sort-attr:r$_roundIndex:interstitial',
          speaker: kKeeperSpeaker,
          caption: false,
        );
      });
      return;
    }

    feedback.roundPass();
    _celebrationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.transition;
        _asideToken += 1;
      });
      ref.narration.say(
        _currentRound.keeperLine,
        cueId: 'sort-attr:r$_roundIndex:interstitial',
        speaker: kKeeperSpeaker,
        caption: false,
      );
    });
  }

  /// Fired by the keeper aside retiring itself, not by a button.
  void _advanceToNextRound() {
    if (!mounted || _phase != _Phase.transition) return;
    setState(() {
      _roundIndex += 1;
      _placement = <String, String>{};
      _wrongTokens = <String, int>{};
      _wrongDrops = 0;
      _missRotation = 0;
      _hintedItemId = null;
      _hintedBinId = null;
      _phase = _Phase.sorting;
    });
    ref.read(feedbackEngineProvider).resetRound();
    _speakPrompt();
    _startHints();
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
      _Phase.sorting ||
      _Phase.celebrating ||
      _Phase.transition =>
        _SortingLayer(
          round: _currentRound,
          placement: _placement,
          burstKey: _burstKey,
          wrongTokens: _wrongTokens,
          inputLocked: _phase != _Phase.sorting,
          hintedItemId: _hintedItemId,
          hintedBinId: _hintedBinId,
          onDropped: ({required item, required bin}) =>
              _onDropped(item: item, bin: bin),
          onBinTapped: _onBinTapped,
          replayPrompt: _prompt,
          replayCueId: 'sort-attr:replay-r$_roundIndex',
          allDone: _phase != _Phase.sorting,
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _finalKeeperLine,
          startLabel: 'Continue',
          startButtonKey: const ValueKey('sort-attr-interstitial-next'),
          onStart: widget.onSequenceComplete,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AssetPaths.shapeGardenBackground, fit: BoxFit.cover),
        PlayfieldScaffold(
          progress: _progress,
          celebrate: _phase == _Phase.celebrating,
          child: phaseContent,
        ),
        if (_phase != _Phase.intro && _phase != _Phase.interstitial)
          const BuddyCompanionCorner(),
        if (_phase == _Phase.transition)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: KeeperAside(
              text: _currentRound.keeperLine,
              token: _asideToken,
              onDismissed: _advanceToNextRound,
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
    required this.wrongTokens,
    required this.inputLocked,
    required this.hintedItemId,
    required this.hintedBinId,
    required this.onDropped,
    required this.onBinTapped,
    required this.replayPrompt,
    required this.replayCueId,
    required this.allDone,
  });

  final _Round round;
  final Map<String, String> placement;
  final int burstKey;

  /// Item id → wrong drops on it. Drives the shake.
  final Map<String, int> wrongTokens;

  final bool inputLocked;

  /// What the hint ladder is pointing at, if anything.
  final String? hintedItemId;
  final String? hintedBinId;

  final void Function({required _SortItem item, required _Bin bin}) onDropped;
  final ValueChanged<_Bin> onBinTapped;
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
                    flex: 3,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      spacing: 18,
                      runSpacing: 18,
                      children: [
                        for (final it in unplaced)
                          // The item bounces back on a wrong basket, which is
                          // silent by itself — the shake is what tells her the
                          // game noticed the attempt.
                          AnswerFeedback(
                            key: ValueKey('sort-item-fb-${it.id}'),
                            wrongToken: wrongTokens[it.id] ?? 0,
                            child: _DraggableSortItem(
                              key: ValueKey('sort-item-${it.id}'),
                              item: it,
                              size: it.isLarge ? _kLargeSize : _kSmallSize,
                              hinted: hintedItemId == it.id,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bins row — one drag target per bin label.
                  //
                  // Flexed rather than sized by its content, and that is a
                  // bug fix rather than a preference. A non-flex child of a
                  // Column is laid out with unbounded height so it can report
                  // its intrinsic size, and each basket contains an `Expanded`
                  // for the shapes dropped into it — which under an unbounded
                  // height is the one thing a Flex is not allowed to do. This
                  // round threw `RenderFlex children have non-zero flex but
                  // incoming height constraints are unbounded` on every frame
                  // it was on screen, followed by a `RenderBox was not laid
                  // out`, and had done since it was written.
                  //
                  // Nothing caught it because nothing had ever rendered it:
                  // `every_sub_mode_opens_test` mounted the activity and
                  // stopped at the keeper's intro, one arrow tap short of the
                  // playfield. It taps through now.
                  Expanded(
                    flex: 2,
                    child: Row(
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
                              hinted: hintedBinId == bin.id,
                              onAccept: (item) =>
                                  onDropped(item: item, bin: bin),
                              onLabelTap: () => onBinTapped(bin),
                            ),
                          ),
                          if (bin != round.bins.last) const SizedBox(width: 12),
                        ],
                      ],
                    ),
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
                      label: kLabelNice,
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
    this.hinted = false,
  });

  final _SortItem item;
  final double size;

  /// Ringed by the hint ladder. The ring never takes the touch, so she can
  /// still pick the shape up through it - which is the point.
  final bool hinted;

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
  const _BinHeader({required this.bin});

  final _Bin bin;

  static const double _basketHeight = 76;
  static const double _exemplarHeight = 42;

  /// Drops the shapes into the basket's body rather than its handle. The
  /// sprite is a hoop over a bowl and the bowl is the bottom half of it.
  static const double _basketMouth = _basketHeight * 0.24;

  @override
  Widget build(BuildContext context) {
    final exemplars = kSortBinExemplars[bin.id] ?? const <SortBinExemplar>[];
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
          bin.label,
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
    required this.bin,
    required this.placed,
    required this.burstKey,
    required this.inputLocked,
    required this.onAccept,
    required this.onLabelTap,
    this.hinted = false,
  });

  final _Bin bin;
  final List<_SortItem> placed;
  final int burstKey;
  final bool inputLocked;

  /// The ladder has escalated far enough to name the basket. It wears the
  /// same amber it already wears when a shape is being held over it, so the
  /// hint and the drop preview are one visual idea rather than two.
  final bool hinted;
  final ValueChanged<_SortItem> onAccept;

  /// Say this basket's name. A tap on a basket has no meaning in the mechanic
  /// - the answer is a drop, not a tap - which is exactly what makes it safe
  /// to spend on curiosity.
  final VoidCallback onLabelTap;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_SortItem>(
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
                _BinHeader(bin: bin),
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
          ),
        );
      },
    );
  }
}
