// CountOutNRunner — K.CC.5 "count out N" sub-mode of the Counting Parade.
// Each round: the keeper asks for N creatures ("Give me four fawns!"); a
// pool of ~8 creatures sits at the top; the kid drags exactly N into the
// keeper's basket at the bottom. Each correct drop ticks the counter and
// the narrator says "one… two… three…" so the kid hears cardinality.
//
// Three rounds: ask for 4, then 6, then 8. Different creature each round
// for visual variety. Each round resolves through RoundCoordinator with
// conceptId K.CC.5; `onSequenceComplete` fires after the final
// interstitial.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'glitter_burst.dart';
import 'keeper_intro_overlay.dart';
import 'lesson_hand_pointer.dart';
import 'progress_bar_to_reward.dart';
import 'replay_demo_button.dart';

enum _Phase { intro, demo, counting, celebrating, interstitial }

class _Round {
  const _Round({
    required this.targetN,
    required this.poolSize,
    required this.spriteAsset,
    required this.singular,
    required this.plural,
    required this.keeperLine,
  });

  final int targetN;
  final int poolSize;
  final String spriteAsset;
  final String singular;
  final String plural;
  final String keeperLine;
}

const List<_Round> _kRounds = <_Round>[
  _Round(
    targetN: 4,
    poolSize: 8,
    spriteAsset: AssetPaths.countingParadeFawn,
    singular: 'fawn',
    plural: 'fawns',
    keeperLine: 'Four fawns! Now I need some gryphons.',
  ),
  _Round(
    targetN: 6,
    poolSize: 9,
    spriteAsset: AssetPaths.countingParadeBabyGryphon,
    singular: 'gryphon',
    plural: 'gryphons',
    keeperLine: 'Six gryphons! One more round — the dragons.',
  ),
  _Round(
    targetN: 8,
    poolSize: 10,
    spriteAsset: AssetPaths.countingParadeBabyDragon,
    singular: 'dragon',
    plural: 'dragons',
    keeperLine: 'Eight dragons! You counted out every group.',
  ),
];

const List<String> _kSpelled = [
  'Zero',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
];

class CountOutNRunner extends ConsumerStatefulWidget {
  const CountOutNRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  ConsumerState<CountOutNRunner> createState() => _CountOutNRunnerState();
}

class _CountOutNRunnerState extends ConsumerState<CountOutNRunner> {
  late _Phase _phase =
      widget.skipIntro ? _Phase.counting : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Set<int> _placedIndices = <int>{};
  // Per-creature drop offsets for drags the kid released *somewhere on
  // screen but not in the basket*. We leave them at the drop site instead
  // of snapping back so kids who can't hold a touch / mouse aren't
  // punished. Cleared on round advance.
  Map<int, Offset> _strayPositions = <int, Offset>{};
  int _basketBurstCounter = 0;
  Timer? _celebrationTimer;
  bool _promptSpoken = false;

  // Demo runs once, before the first round. After that the kid already
  // knows the drag mechanic.
  bool _demoShown = false;

  _Round get _currentRound => _kRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == _kRounds.length - 1;
  double get _progress => _completedRounds / _kRounds.length;
  int get _placedCount => _placedIndices.length;
  bool get _targetReached => _placedCount >= _currentRound.targetN;

  String get _introDialog =>
      "Sometimes I just need a few creatures, not all of them! I'll ask for "
      'a number, and you bring me exactly that many. Ready?';

  String get _basketPrompt =>
      'Bring me ${_kSpelled[_currentRound.targetN].toLowerCase()} '
      '${_currentRound.plural}.';

  String get _finalKeeperLine =>
      'Beautifully counted out! Just the number I asked for, every time.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_phase == _Phase.intro) {
        _speakIntro();
      } else {
        _speakBasketPromptOnce();
      }
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
  }

  void _speakIntro() {
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          NarrationLine(
            text: _introDialog,
            cueId: 'count-out:intro',
            speaker: 'sanctuary-keeper-mystic',
          ),
        );
  }

  void _speakBasketPromptOnce() {
    if (_promptSpoken) return;
    _promptSpoken = true;
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: _basketPrompt,
            cueId: 'count-out:r$_roundIndex:prompt',
          ),
        );
  }

  void _onStartFromIntro() {
    if (!_demoShown) {
      setState(() => _phase = _Phase.demo);
      return;
    }
    setState(() => _phase = _Phase.counting);
    _promptSpoken = false;
    _speakBasketPromptOnce();
  }

  void _onDemoComplete() {
    if (!mounted) return;
    setState(() {
      _demoShown = true;
      _phase = _Phase.counting;
      _promptSpoken = false;
    });
    _speakBasketPromptOnce();
  }

  void _onCreatureDropped(int idx) {
    if (_phase != _Phase.counting) return;
    if (_placedIndices.contains(idx)) return;
    if (_targetReached) {
      // Over-cap: gentle "you have enough" line; don't accept the drop.
      ref.read(narrationPlayerProvider.notifier).speak(
            NarrationLine(
              text:
                  "I have enough — that's ${_kSpelled[_currentRound.targetN].toLowerCase()}!",
              cueId: 'count-out:r$_roundIndex:overcap',
            ),
          );
      return;
    }
    setState(() {
      _placedIndices.add(idx);
      _strayPositions.remove(idx);
      _basketBurstCounter += 1;
    });
    final spoken = _placedCount < _kSpelled.length
        ? _kSpelled[_placedCount]
        : _placedCount.toString();
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: '$spoken.',
            cueId: 'count-out:r$_roundIndex:place-$_placedCount',
          ),
        );
    if (_placedCount >= _currentRound.targetN) {
      _finishRound();
    }
  }

  void _finishRound() {
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'counting-parade',
          conceptId: 'K.CC.5',
          success: true,
        );
    setState(() {
      _completedRounds += 1;
      _phase = _Phase.celebrating;
    });
    _celebrationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.interstitial);
      final line = _isLastRound ? _finalKeeperLine : _currentRound.keeperLine;
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: line,
              cueId: 'count-out:r$_roundIndex:interstitial',
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
      _placedIndices = <int>{};
      _strayPositions = <int, Offset>{};
      _basketBurstCounter = 0;
      _promptSpoken = false;
      _phase = _Phase.counting;
    });
    _speakBasketPromptOnce();
  }

  /// Records a drag that ended somewhere on the layer but NOT in the
  /// basket and NOT off-screen. The creature stays at that position
  /// until the kid picks it up again or the round ends.
  void _onStrayDrop(int idx, Offset localOffset) {
    if (_phase != _Phase.counting) return;
    if (_placedIndices.contains(idx)) return;
    setState(() => _strayPositions[idx] = localOffset);
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: "Let's count!",
          startButtonKey: const ValueKey('count-out-start-button'),
          onStart: _onStartFromIntro,
        ),
      _Phase.demo => _CountOutDemo(
          spriteAsset: _currentRound.spriteAsset,
          singular: _currentRound.singular,
          onComplete: _onDemoComplete,
        ),
      _Phase.counting || _Phase.celebrating => _CountOutLayer(
          roundIndex: _roundIndex,
          targetN: _currentRound.targetN,
          poolSize: _currentRound.poolSize,
          spriteAsset: _currentRound.spriteAsset,
          plural: _currentRound.plural,
          placedIndices: _placedIndices,
          strayPositions: _strayPositions,
          basketBurstCounter: _basketBurstCounter,
          onDropped: _onCreatureDropped,
          onStrayDrop: _onStrayDrop,
          inputLocked: _phase == _Phase.celebrating,
          replayPrompt: _basketPrompt,
          replayCueId: 'count-out:replay-r$_roundIndex',
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog:
              _isLastRound ? _finalKeeperLine : _currentRound.keeperLine,
          startLabel: _isLastRound ? 'Continue' : "Let's go!",
          startButtonKey: const ValueKey('count-out-interstitial-next'),
          onStart: _advanceFromInterstitial,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AssetPaths.countingParadeMeadow,
          fit: BoxFit.cover,
        ),
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

class _CountOutLayer extends StatelessWidget {
  const _CountOutLayer({
    required this.roundIndex,
    required this.targetN,
    required this.poolSize,
    required this.spriteAsset,
    required this.plural,
    required this.placedIndices,
    required this.strayPositions,
    required this.basketBurstCounter,
    required this.onDropped,
    required this.onStrayDrop,
    required this.inputLocked,
    required this.replayPrompt,
    required this.replayCueId,
  });

  final int roundIndex;
  final int targetN;
  final int poolSize;
  final String spriteAsset;
  final String plural;
  final Set<int> placedIndices;
  final Map<int, Offset> strayPositions;
  final int basketBurstCounter;
  final ValueChanged<int> onDropped;
  final void Function(int idx, Offset localOffset) onStrayDrop;
  final bool inputLocked;

  /// Narration the (?) button replays. Same line the runner spoke at
  /// the start of the round.
  final String replayPrompt;
  final String replayCueId;

  static const double _spriteSize = 84;
  // Grid layout for the initial pool slots — 5 columns × N rows packed
  // into the top ~30 % of the play area. The basket fills the rest.
  static const int _poolCols = 5;
  static const double _poolHeightFraction = 0.30;
  static const double _basketTopFraction = 0.34;

  Offset _slotFor(int idx, double w, double poolH) {
    final col = idx % _poolCols;
    final row = idx ~/ _poolCols;
    final rows = ((poolSize + _poolCols - 1) ~/ _poolCols).clamp(1, 100);
    final colW = w / _poolCols;
    final rowH = poolH / rows;
    return Offset(
      col * colW + (colW - _spriteSize) / 2,
      row * rowH + (rowH - _spriteSize) / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Bring me $targetN $plural!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
            // Pool + basket live in a single Stack so creatures can be
            // dropped anywhere on the layer and stay there.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final poolH = h * _poolHeightFraction;
                  final basketTop = h * _basketTopFraction;
                  return Builder(
                    builder: (stackContext) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Basket — DragTarget sits at the bottom, taking
                          // the rest of the layer width. Drops anywhere
                          // inside this rectangle count toward the round.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: basketTop,
                            bottom: 0,
                            child: _Basket(
                              roundIndex: roundIndex,
                              targetN: targetN,
                              spriteAsset: spriteAsset,
                              placedIndices: placedIndices,
                              basketBurstCounter: basketBurstCounter,
                              inputLocked: inputLocked,
                              onDropped: onDropped,
                            ),
                          ),
                          // Pool creatures — drawn over the basket so they
                          // can be picked up from any position, including
                          // strays that landed in the basket zone.
                          for (var i = 0; i < poolSize; i++)
                            if (!placedIndices.contains(i))
                              _PoolCreature(
                                key: ValueKey(
                                  'count-out-r$roundIndex-pool-$i',
                                ),
                                index: i,
                                spriteAsset: spriteAsset,
                                position: strayPositions[i] ??
                                    _slotFor(i, w, poolH),
                                spriteSize: _spriteSize,
                                inputLocked: inputLocked,
                                onStrayDrop: (dropOffset) {
                                  final box = stackContext
                                      .findRenderObject() as RenderBox?;
                                  if (box == null) return;
                                  final local =
                                      box.globalToLocal(dropOffset);
                                  // Snap-back zone: ≥ 1/3 of the sprite
                                  // has gone past a stack edge. Anywhere
                                  // else, leave the creature where it
                                  // landed (the user's request — kids
                                  // can't reliably hold a finger / drag).
                                  const minX = -_spriteSize / 3;
                                  final maxX = w - _spriteSize * 2 / 3;
                                  const minY = -_spriteSize / 3;
                                  final maxY = h - _spriteSize * 2 / 3;
                                  if (local.dx < minX ||
                                      local.dx > maxX ||
                                      local.dy < minY ||
                                      local.dy > maxY) {
                                    return;
                                  }
                                  onStrayDrop(i, local);
                                },
                              ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Basket DragTarget — bin_2d sprite fills the bottom 2/3 of the layer.
/// Drops anywhere inside it count toward the round; placed creatures
/// stack as mini-icons across the bottom of the basket.
class _Basket extends StatelessWidget {
  const _Basket({
    required this.roundIndex,
    required this.targetN,
    required this.spriteAsset,
    required this.placedIndices,
    required this.basketBurstCounter,
    required this.inputLocked,
    required this.onDropped,
  });

  final int roundIndex;
  final int targetN;
  final String spriteAsset;
  final Set<int> placedIndices;
  final int basketBurstCounter;
  final bool inputLocked;
  final ValueChanged<int> onDropped;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !inputLocked,
      onAcceptWithDetails: (details) => onDropped(details.data),
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            // Soft amber glow when a creature hovers in.
            boxShadow: hovering
                ? const [
                    BoxShadow(
                      color: Colors.amberAccent,
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Real basket sprite. BoxFit.contain keeps the aspect ratio
              // intact, scaled up to fill the available area.
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Image.asset(
                    AssetPaths.shapeGardenBin2d,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (placedIndices.isEmpty)
                const Text(
                  'Drag here',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    shadows: [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 8,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              // Placed creatures stack inside the bin.
              Padding(
                padding: const EdgeInsets.only(
                  top: 60,
                  left: 16,
                  right: 16,
                  bottom: 32,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final _ in placedIndices)
                      Image.asset(
                        spriteAsset,
                        width: 52,
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${placedIndices.length} / $targetN',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              if (basketBurstCounter > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: GlitterBurst(
                      key: ValueKey(
                        'count-out-burst-r$roundIndex-$basketBurstCounter',
                      ),
                      maxRadius: 120,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One draggable creature in the pool. Lives at `position` (either the
/// computed grid slot or its last stray-drop offset). On `onDragEnd`,
/// reports the global drop position to the host; the host converts to
/// local coordinates and decides whether to leave it (stray) or let it
/// snap back (off-screen / off-stack).
class _PoolCreature extends StatelessWidget {
  const _PoolCreature({
    super.key,
    required this.index,
    required this.spriteAsset,
    required this.position,
    required this.spriteSize,
    required this.inputLocked,
    required this.onStrayDrop,
  });

  final int index;
  final String spriteAsset;
  final Offset position;
  final double spriteSize;
  final bool inputLocked;
  final ValueChanged<Offset> onStrayDrop;

  @override
  Widget build(BuildContext context) {
    final sprite = Image.asset(
      spriteAsset,
      width: spriteSize,
      height: spriteSize,
      fit: BoxFit.contain,
    );
    // Plain Positioned (not AnimatedPositioned): when the kid releases a
    // drag the Draggable's child briefly snaps back to the source slot
    // before our state update lands. With an animated transition the kid
    // sees the sprite glide from "where it used to be" to "where I let
    // go" — which looked like a snap-back. With a plain Positioned the
    // sprite just appears at the new position on the next frame.
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: spriteSize,
      height: spriteSize,
      child: inputLocked
          ? sprite
          : Draggable<int>(
              data: index,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: spriteSize,
                  height: spriteSize,
                  child: sprite,
                ),
              ),
              childWhenDragging: SizedBox(
                width: spriteSize,
                height: spriteSize,
              ),
              onDragEnd: (details) {
                if (details.wasAccepted) return;
                onStrayDrop(details.offset);
              },
              child: sprite,
            ),
    );
  }
}

// ============================================================================
// First-round drag demo — hand pointer auto-walks two creatures into the
// keeper's basket while the narrator counts ("Watch — one… two… now you
// try!"). Plays once per session before the kid takes input.
// ============================================================================

class _CountOutDemo extends ConsumerStatefulWidget {
  const _CountOutDemo({
    required this.spriteAsset,
    required this.singular,
    required this.onComplete,
  });

  final String spriteAsset;
  final String singular;
  final VoidCallback onComplete;

  @override
  ConsumerState<_CountOutDemo> createState() => _CountOutDemoState();
}

class _CountOutDemoState extends ConsumerState<_CountOutDemo> {
  static const double _spriteSize = 84;
  static const double _handSize = 96;

  final List<Timer> _timers = <Timer>[];

  bool _pointerVisible = false;
  int _pokeCounter = 0;
  // Normalised target for the hand. 0..1 within the layer's box.
  Offset _pointerTarget = const Offset(0.16, 0.42);
  // Which creature is currently "carried" (-1 = none). Same index as pool.
  int _carriedIdx = -1;
  // Visual: hides a pool creature once it's been "taken".
  final Set<int> _consumed = <int>{};
  int _basketBurst = 0;
  int _placedInDemo = 0;

  // Two source slots for the demo pool (top half) and one basket slot
  // (bottom). Fixed positions so the hand can glide to known anchors.
  static const Offset _slot0 = Offset(0.20, 0.30);
  static const Offset _slot1 = Offset(0.40, 0.30);
  static const Offset _basketCenter = Offset(0.50, 0.80);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleTimeline();
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _schedule(int ms, VoidCallback action) {
    _timers.add(
      Timer(Duration(milliseconds: ms), () {
        if (!mounted) return;
        action();
      }),
    );
  }

  void _speak(String text, String cueId) {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(text: text, cueId: cueId),
        );
  }

  void _scheduleTimeline() {
    // 0.0s — narrate the intro.
    _schedule(200, () {
      _speak(
        "Watch — I'll show you. Drag each ${widget.singular} into the basket.",
        'count-out:demo:intro',
      );
    });
    // 1.0s — hand appears at slot 0.
    _schedule(1000, () {
      setState(() {
        _pointerVisible = true;
        _pointerTarget = _slot0;
        _carriedIdx = -1;
        _pokeCounter += 1;
      });
    });
    // 2.0s — pick up the first creature.
    _schedule(2000, () {
      setState(() => _carriedIdx = 0);
    });
    // 2.5s — glide to basket.
    _schedule(2500, () {
      setState(() => _pointerTarget = _basketCenter);
    });
    // 3.5s — drop it. "One!"
    _schedule(3500, () {
      setState(() {
        _consumed.add(0);
        _carriedIdx = -1;
        _placedInDemo = 1;
        _basketBurst += 1;
        _pokeCounter += 1;
      });
      _speak('One.', 'count-out:demo:one');
    });
    // 4.3s — hand glides to slot 1.
    _schedule(4300, () {
      setState(() => _pointerTarget = _slot1);
    });
    // 5.3s — pick up second creature.
    _schedule(5300, () {
      setState(() => _carriedIdx = 1);
    });
    // 5.8s — glide to basket.
    _schedule(5800, () {
      setState(() => _pointerTarget = _basketCenter);
    });
    // 6.8s — drop it. "Two!"
    _schedule(6800, () {
      setState(() {
        _consumed.add(1);
        _carriedIdx = -1;
        _placedInDemo = 2;
        _basketBurst += 1;
        _pokeCounter += 1;
      });
      _speak('Two.', 'count-out:demo:two');
    });
    // 7.8s — wrap up + hand off.
    _schedule(7800, () {
      setState(() => _pointerVisible = false);
      _speak('Now you try!', 'count-out:demo:handoff');
    });
    _schedule(9200, widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Carried-creature position rides with the hand pointer when a
        // creature is in transit; otherwise it sits at its source slot.
        Offset creaturePos(int idx) {
          if (_carriedIdx == idx) return _pointerTarget;
          return idx == 0 ? _slot0 : _slot1;
        }

        final handAbs = Offset(
          _pointerTarget.dx * w - _handSize * 0.4,
          _pointerTarget.dy * h - _handSize * 0.85,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Stack(
            children: [
              // Header banner.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Watch — drag creatures into the basket!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              // Pool creatures (top half).
              for (var i = 0; i < 2; i++)
                if (!_consumed.contains(i) || _carriedIdx == i)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOutCubic,
                    left: creaturePos(i).dx * w - _spriteSize / 2,
                    top: creaturePos(i).dy * h - _spriteSize / 2,
                    width: _spriteSize,
                    height: _spriteSize,
                    child: IgnorePointer(
                      child: Image.asset(
                        widget.spriteAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              // Basket — bin_2d sprite, 80 % of the layer width so the
              // "basket" word in the narration matches a real visible
              // basket on screen.
              Builder(
                builder: (_) {
                  final basketWidth = w * 0.8;
                  final basketHeight = h * 0.38;
                  return Positioned(
                    left: _basketCenter.dx * w - basketWidth / 2,
                    top: _basketCenter.dy * h - basketHeight / 2,
                    width: basketWidth,
                    height: basketHeight,
                    child: IgnorePointer(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              AssetPaths.shapeGardenBin2d,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 50,
                              left: 24,
                              right: 24,
                              bottom: 28,
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (var i = 0; i < _placedInDemo; i++)
                                  Image.asset(
                                    widget.spriteAsset,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.contain,
                                  ),
                              ],
                            ),
                          ),
                          if (_basketBurst > 0)
                            Positioned.fill(
                              child: GlitterBurst(
                                key: ValueKey(
                                  'count-out-demo-burst-$_basketBurst',
                                ),
                                maxRadius: 120,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Hand pointer.
              LessonHandPointer(
                visible: _pointerVisible,
                target: handAbs,
                pokeKey: _pokeCounter,
                size: _handSize,
              ),
            ],
          ),
        );
      },
    );
  }
}
