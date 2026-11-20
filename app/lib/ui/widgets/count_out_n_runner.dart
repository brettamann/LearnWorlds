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

import '../../activities/activity_ids.dart';
import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/count_out_n_rounds.dart';
import '../../data/number_words.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../platform/sfx_engine.dart';
import '../../theme/app_decor.dart';
import '../common/timer_scope.dart';
import 'buddy_companion.dart';
import 'glitter_burst.dart';
import 'keeper_aside.dart';
import 'keeper_intro_overlay.dart';
import 'lesson_hand_pointer.dart';
import 'playfield_scaffold.dart';
import 'replay_demo_button.dart';

enum _Phase {
  intro,
  demo,
  counting,

  /// Keeper speaks over the live meadow and advances the round herself.
  transition,

  celebrating,

  /// Final beat only — the reward payoff, which is meant to interrupt.
  interstitial,
}

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
  late _Phase _phase = widget.skipIntro ? _Phase.counting : _Phase.intro;
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

  /// Bumped to (re)present the between-round keeper aside.
  int _asideToken = 0;

  /// Drags attempted after the basket already held enough. This is the only
  /// wrong answer the round has, and it is what makes the round gradeable.
  int _overCapDrops = 0;
  int _missRotation = 0;

  /// Pool creature the hint ladder is glowing, if any.
  int? _hintedIndex;

  HintLadder? _hints;

  /// Read eagerly — `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfxForDispose;

  CountOutNRound get _currentRound => kCountOutNRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == kCountOutNRounds.length - 1;
  double get _progress => _completedRounds / kCountOutNRounds.length;
  int get _placedCount => _placedIndices.length;
  bool get _targetReached => _placedCount >= _currentRound.targetN;

  String get _introDialog =>
      "Sometimes I just need a few creatures, not all of them! I'll ask for "
      'a number, and you bring me exactly that many. Ready?';

  String get _basketPrompt => countOutNBasketPrompt(_currentRound);

  String get _finalKeeperLine =>
      'Beautifully counted out! Just the number I asked for, every time.';

  String get _overCapLine => countOutNOverCapLine(_currentRound, _missRotation);

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
      if (_phase == _Phase.intro) {
        _speakIntro();
      } else {
        _startHints();
        _speakBasketPromptOnce();
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

  void _startHints() {
    _hints?.dispose();
    _hints = HintLadder(onLevel: _onHintLevel)..start();
  }

  void _onHintLevel(HintLevel level) {
    if (!mounted || _phase != _Phase.counting) return;
    final next = _nextAvailable();
    if (next == null) return;
    final feedback = ref.read(feedbackEngineProvider);
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _hintedIndex = next);
      case HintLevel.point:
        setState(() => _hintedIndex = next);
        feedback.hint();
        ref.narration
            .say(warmHintLine(2), cueId: 'count-out:r$_roundIndex:hint-point');
      case HintLevel.demonstrate:
        // Do one for her. The drag is the hard part of this mechanic, so the
        // demonstration completes the whole gesture rather than just pointing
        // harder at it.
        feedback.hint();
        ref.narration
            .say(warmHintLine(3), cueId: 'count-out:r$_roundIndex:hint-demo');
        _onCreatureDropped(next, fromHint: true);
    }
  }

  int? _nextAvailable() {
    for (var i = 0; i < _currentRound.poolSize; i++) {
      if (!_placedIndices.contains(i)) return i;
    }
    return null;
  }

  void _speakIntro() {
    ref.narration.say(
      _introDialog,
      cueId: 'count-out:intro',
      speaker: kKeeperSpeaker,
      caption: false,
    );
  }

  void _speakBasketPromptOnce() {
    if (_promptSpoken) return;
    _promptSpoken = true;
    ref.narration.say(_basketPrompt, cueId: 'count-out:r$_roundIndex:prompt');
  }

  void _onStartFromIntro() {
    if (!_demoShown) {
      setState(() => _phase = _Phase.demo);
      return;
    }
    setState(() => _phase = _Phase.counting);
    _promptSpoken = false;
    _startHints();
    _speakBasketPromptOnce();
  }

  void _onDemoComplete() {
    if (!mounted) return;
    setState(() {
      _demoShown = true;
      _phase = _Phase.counting;
      _promptSpoken = false;
    });
    _startHints();
    _speakBasketPromptOnce();
  }

  void _onCreatureDropped(int idx, {bool fromHint = false}) {
    if (_phase != _Phase.counting) return;
    if (_placedIndices.contains(idx)) return;
    if (_targetReached) {
      // Over-cap. This is the wrong answer for "count out N" — bringing more
      // than asked is exactly the error the standard is about — so it now
      // registers as one: soft thud, Buddy tilts, and it counts against the
      // round. The drop is still refused rather than punished.
      setState(() {
        _overCapDrops += 1;
        _missRotation += 1;
      });
      _hints?.poke();
      ref.read(feedbackEngineProvider).wrong();
      ref.narration.say(
        _overCapLine,
        cueId: 'count-out:r$_roundIndex:overcap-$_overCapDrops',
      );
      return;
    }
    setState(() {
      _placedIndices.add(idx);
      _strayPositions.remove(idx);
      _basketBurstCounter += 1;
      _hintedIndex = null;
    });
    if (!fromHint) _hints?.poke();
    // One note per creature in the basket, so filling it to four *sounds*
    // like counting to four.
    ref.read(feedbackEngineProvider).countStep(_placedCount);
    final spoken = _placedCount < kSpelledCounts.length
        ? kSpelledCounts[_placedCount]
        : _placedCount.toString();
    // Queued, not spoken, when the ladder did this tap. `speak` cuts off
    // whatever is in flight, and what is in flight at that moment is the
    // demonstration's own explanation - the one line in the round that
    // says why. See HintLadder.
    final say = ref.narration;
    final line = NarrationLine(
      text: '$spoken.',
      cueId: 'count-out:r$_roundIndex:place-$_placedCount',
    );
    if (fromHint) {
      say.enqueue(line);
    } else {
      say.speak(line);
    }
    if (_placedCount >= _currentRound.targetN) {
      _finishRound();
    }
  }

  void _finishRound() {
    _hints?.pause();

    // Three over-cap drags means she was not tracking the target at all —
    // that is a genuine miss and the mastery ladder should see it. One or two,
    // or a demonstration, resolves soft: she got there, with help.
    final hintsUsed = _hints?.hintsUsed ?? 0;
    final result = gradeRound(misses: _overCapDrops, helped: hintsUsed > 0);
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: ActivityIds.countingParade,
          conceptId: 'K.CC.5',
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
          cueId: 'count-out:r$_roundIndex:interstitial',
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
        cueId: 'count-out:r$_roundIndex:interstitial',
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
      _placedIndices = <int>{};
      _strayPositions = <int, Offset>{};
      _basketBurstCounter = 0;
      _promptSpoken = false;
      _overCapDrops = 0;
      _missRotation = 0;
      _hintedIndex = null;
      _phase = _Phase.counting;
    });
    ref.read(feedbackEngineProvider).resetRound();
    _startHints();
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
      _Phase.counting ||
      _Phase.celebrating ||
      _Phase.transition =>
        _CountOutLayer(
          roundIndex: _roundIndex,
          targetN: _currentRound.targetN,
          poolSize: _currentRound.poolSize,
          spriteAsset: _currentRound.spriteAsset,
          plural: _currentRound.plural,
          placedIndices: _placedIndices,
          strayPositions: _strayPositions,
          basketBurstCounter: _basketBurstCounter,
          hintedIndex: _hintedIndex,
          onDropped: _onCreatureDropped,
          onStrayDrop: _onStrayDrop,
          inputLocked: _phase != _Phase.counting,
          replayPrompt: _basketPrompt,
          replayCueId: 'count-out:replay-r$_roundIndex',
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _finalKeeperLine,
          startLabel: 'Continue',
          startButtonKey: const ValueKey('count-out-interstitial-next'),
          onStart: widget.onSequenceComplete,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AssetPaths.countingParadeMeadow,
          fit: BoxFit.cover,
        ),
        PlayfieldScaffold(
          progress: _progress,
          celebrate: _phase == _Phase.celebrating,
          child: phaseContent,
        ),
        if (_phase != _Phase.intro &&
            _phase != _Phase.demo &&
            _phase != _Phase.interstitial)
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

  /// Pool creature the hint ladder wants glowed, or null.
  final int? hintedIndex;

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
                    decoration:
                        AppDecor.card(radius: 18, shadow: AppShadows.soft),
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
                                      hinted: hintedIndex == i,
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

class _CountOutDemoState extends ConsumerState<_CountOutDemo>
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
      ref.narration.say(
        "Watch — I'll show you. Drag each ${widget.singular} into the basket.",
        cueId: 'count-out:demo:intro',
      );
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
      ref.narration.say('One.', cueId: 'count-out:demo:one');
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
      ref.narration.say('Two.', cueId: 'count-out:demo:two');
    });
    // 7.8s — wrap up + hand off.
    afterMs(7800, () {
      setState(() => _pointerVisible = false);
      ref.narration.say('Now you try!', cueId: 'count-out:demo:handoff');
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
                    decoration:
                        AppDecor.card(radius: 18, shadow: AppShadows.soft),
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
