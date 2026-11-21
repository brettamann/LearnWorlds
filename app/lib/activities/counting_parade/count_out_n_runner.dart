// CountOutNRunner — K.CC.5 "count out N" sub-mode of the Counting Parade.
// Each round: the keeper asks for N creatures ("Bring me four fawns."); a
// pool of ~8 creatures sits at the top; the kid drags exactly N into the
// keeper's basket at the bottom. Each correct drop ticks the counter and
// the narrator says "one… two… three…" so the kid hears cardinality.
//
// Three rounds: ask for 4, then 6, then 8. Different creature each round
// for visual variety. The lifecycle is SanctuaryRoundShell's; the first round
// of a visit that did not come from a lesson opens with a short drag demo on
// the real board (`c.showDemo`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/count_out_n_rounds.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../theme/app_decor.dart';
import '../../ui/common/glitter_burst.dart';
import '../../ui/common/target_hint.dart';
import '../../ui/common/timer_scope.dart';
import '../../ui/lesson/lesson_hand_pointer.dart';
import '../../ui/round/sanctuary_round_shell.dart';
import '../activity_ids.dart';
import 'parade_pieces.dart';

class CountOutNRunner extends StatelessWidget {
  const CountOutNRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  Widget build(BuildContext context) {
    return SanctuaryRoundShell(
      activityId: ActivityIds.countingParade,
      roundCount: kCountOutNRounds.length,
      conceptIdFor: (_) => 'K.CC.5',
      introLine: kCountOutNIntro,
      keeperLineFor: (i) => kCountOutNRounds[i].keeperLine,
      finalLine: kCountOutNFinal,
      skipIntro: skipIntro,
      celebrationHold: const Duration(seconds: 1),
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.countingParadeMeadow,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) => CountOutRoundBody(c: c),
    );
  }
}

/// One round: drag exactly the number asked for into the basket.
class CountOutRoundBody extends ConsumerStatefulWidget {
  const CountOutRoundBody({super.key, required this.c});

  final RoundContext c;

  @override
  ConsumerState<CountOutRoundBody> createState() => _CountOutRoundBodyState();
}

class _CountOutRoundBodyState extends ConsumerState<CountOutRoundBody> {
  late final CountOutNRound _round = kCountOutNRounds[widget.c.index];
  final Set<int> _placed = <int>{};

  /// Drop offsets for drags she released somewhere on the board but not in
  /// the basket. They stay where they landed instead of snapping back, so a
  /// kid who cannot hold a drag is not punished for it.
  final Map<int, Offset> _strays = <int, Offset>{};
  int _basketBurst = 0;

  /// Drags attempted after the basket already held enough. This is the only
  /// wrong answer the round has, and it is what makes the round gradeable.
  int _overCapDrops = 0;
  int _missRotation = 0;
  int? _hinted;
  HintLadder? _hints;
  bool _done = false;

  /// True while the one-time drag demo is playing, before her first round.
  late bool _demoing = widget.c.showDemo;

  bool get _open => !_done && !_demoing && !widget.c.locked;
  bool get _targetReached => _placed.length >= _round.targetN;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_demoing) _begin();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  void _begin() {
    widget.c.say(countOutNBasketPrompt(_round));
    _hints = HintLadder(onLevel: _onHint)..start();
  }

  void _onDemoComplete() {
    if (!mounted) return;
    setState(() => _demoing = false);
    _begin();
  }

  int? get _nextAvailable {
    for (var i = 0; i < _round.poolSize; i++) {
      if (!_placed.contains(i)) return i;
    }
    return null;
  }

  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final next = _nextAvailable;
    if (next == null) return;
    answerTargetHint(
      level,
      ring: () => setState(() => _hinted = next),
      chime: ref.read(feedbackEngineProvider).hint,
      say: (line) => widget.c.say(line, replay: false),
      // The drag is the hard part of this mechanic, so the demonstration
      // completes the whole gesture rather than just pointing harder at it.
      demonstrate: () => _onDropped(next, fromHint: true),
    );
  }

  void _onDropped(int idx, {bool fromHint = false}) {
    if (!_open || _placed.contains(idx)) return;
    if (_targetReached) {
      // Over-cap. Bringing more than asked is exactly the error K.CC.5 is
      // about, so it registers as one: soft thud, Buddy tilts, and it counts
      // against the round. The drop is still refused rather than punished.
      setState(() {
        _overCapDrops += 1;
        _missRotation += 1;
      });
      _hints?.poke();
      ref.read(feedbackEngineProvider).wrong();
      widget.c.say(countOutNOverCapLine(_round, _missRotation), replay: false);
      return;
    }
    setState(() {
      _placed.add(idx);
      _strays.remove(idx);
      _basketBurst += 1;
      _hinted = null;
    });
    if (!fromHint) _hints?.poke();
    // One note per creature in the basket, so filling it to four *sounds*
    // like counting to four.
    countAloud(
      widget.c.say,
      ref.read(feedbackEngineProvider),
      step: _placed.length,
      value: _placed.length,
      fromHint: fromHint,
    );
    if (_targetReached) _finish();
  }

  void _finish() {
    _done = true;
    _hints?.pause();
    // Three over-cap drags means she was not tracking the target at all -
    // a genuine miss the mastery ladder should see. One or two, or a
    // demonstration, resolves soft: she got there, with help.
    widget.c.finish(
      gradeRound(misses: _overCapDrops, helped: (_hints?.hintsUsed ?? 0) > 0),
    );
  }

  /// A drag that ended on the board but not in the basket. The creature stays
  /// there until she picks it up again or the round ends.
  void _onStrayDrop(int idx, Offset local) {
    if (!_open || _placed.contains(idx)) return;
    setState(() => _strays[idx] = local);
  }

  @override
  Widget build(BuildContext context) {
    if (_demoing) {
      return _CountOutDemo(
        spriteAsset: _round.species.spriteAsset,
        line: countOutNDemoLine(_round),
        say: widget.c.say,
        onComplete: _onDemoComplete,
      );
    }
    return _CountOutLayer(
      roundIndex: widget.c.index,
      targetN: _round.targetN,
      poolSize: _round.poolSize,
      spriteAsset: _round.species.spriteAsset,
      plural: _round.species.plural,
      placedIndices: _placed,
      strayPositions: _strays,
      basketBurstCounter: _basketBurst,
      hintedIndex: _hinted,
      onDropped: _onDropped,
      onStrayDrop: _onStrayDrop,
      inputLocked: !_open,
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
    required this.hintedIndex,
    required this.onDropped,
    required this.onStrayDrop,
    required this.inputLocked,
  });

  final int roundIndex;
  final int targetN;
  final int poolSize;
  final String spriteAsset;
  final String plural;
  final Set<int> placedIndices;
  final Map<int, Offset> strayPositions;
  final int basketBurstCounter;

  /// Pool creature the hint ladder wants glowed, or null.
  final int? hintedIndex;

  final ValueChanged<int> onDropped;
  final void Function(int idx, Offset localOffset) onStrayDrop;
  final bool inputLocked;

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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: AppDecor.card(radius: 18, shadow: AppShadows.soft),
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
                            key: ValueKey('count-out-r$roundIndex-pool-$i'),
                            index: i,
                            spriteAsset: spriteAsset,
                            position:
                                strayPositions[i] ?? _slotFor(i, w, poolH),
                            spriteSize: _spriteSize,
                            inputLocked: inputLocked,
                            hinted: hintedIndex == i,
                            onStrayDrop: (dropOffset) {
                              final box =
                                  stackContext.findRenderObject() as RenderBox?;
                              if (box == null) return;
                              final local = box.globalToLocal(dropOffset);
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
    required this.hinted,
    required this.onStrayDrop,
  });

  final int index;
  final String spriteAsset;
  final Offset position;
  final double spriteSize;
  final bool inputLocked;

  /// The hint ladder is pointing here. Same soft amber glow the rest of the
  /// game uses for help, so it reads as "this one" rather than as an alert.
  final bool hinted;

  final ValueChanged<Offset> onStrayDrop;

  @override
  Widget build(BuildContext context) {
    Widget sprite = Image.asset(
      spriteAsset,
      width: spriteSize,
      height: spriteSize,
      fit: BoxFit.contain,
    );
    if (hinted) {
      sprite = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.85),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: sprite,
      );
    }
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

class _CountOutDemo extends StatefulWidget {
  const _CountOutDemo({
    required this.spriteAsset,
    required this.line,
    required this.say,
    required this.onComplete,
  });

  final String spriteAsset;

  /// "Watch - I'll show you..."
  final String line;
  final SayLine say;
  final VoidCallback onComplete;

  @override
  State<_CountOutDemo> createState() => _CountOutDemoState();
}

class _CountOutDemoState extends State<_CountOutDemo>
    with TimerScope<_CountOutDemo> {
  static const double _spriteSize = 84;
  static const double _handSize = 96;

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

  void _scheduleTimeline() {
    // 0.0s — narrate the intro.
    afterMs(200, () {
      widget.say(widget.line, replay: false);
    });
    // 1.0s — hand appears at slot 0.
    afterMs(1000, () {
      setState(() {
        _pointerVisible = true;
        _pointerTarget = _slot0;
        _carriedIdx = -1;
        _pokeCounter += 1;
      });
    });
    // 2.0s — pick up the first creature.
    afterMs(2000, () {
      setState(() => _carriedIdx = 0);
    });
    // 2.5s — glide to basket.
    afterMs(2500, () {
      setState(() => _pointerTarget = _basketCenter);
    });
    // 3.5s — drop it. "One!"
    afterMs(3500, () {
      setState(() {
        _consumed.add(0);
        _carriedIdx = -1;
        _placedInDemo = 1;
        _basketBurst += 1;
        _pokeCounter += 1;
      });
      widget.say('One.', replay: false);
    });
    // 4.3s — hand glides to slot 1.
    afterMs(4300, () {
      setState(() => _pointerTarget = _slot1);
    });
    // 5.3s — pick up second creature.
    afterMs(5300, () {
      setState(() => _carriedIdx = 1);
    });
    // 5.8s — glide to basket.
    afterMs(5800, () {
      setState(() => _pointerTarget = _basketCenter);
    });
    // 6.8s — drop it. "Two!"
    afterMs(6800, () {
      setState(() {
        _consumed.add(1);
        _carriedIdx = -1;
        _placedInDemo = 2;
        _basketBurst += 1;
        _pokeCounter += 1;
      });
      widget.say('Two.', replay: false);
    });
    // 7.8s — wrap up + hand off.
    afterMs(7800, () {
      setState(() => _pointerVisible = false);
      widget.say(kCountOutNDemoHandoff, replay: false);
    });
    afterMs(9200, widget.onComplete);
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
                    decoration: AppDecor.card(
                      radius: 18,
                      shadow: AppShadows.soft,
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
