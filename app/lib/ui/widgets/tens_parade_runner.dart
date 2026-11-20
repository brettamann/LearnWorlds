// TensParadeRunner — the Counting Parade's optional final challenge.
// Despite the historical name, this sub-mode is the kid's "count all
// the way to one hundred by ones" final check: creatures drift across
// the meadow from right to left and the kid taps each one, narrator
// counting along, until 100 are tapped.
//
// Lives at the end of the sub-mode chain and is marked `isChallenge`
// in the activity registry — the Sanctuary picker only surfaces it
// after every regular sub-mode is complete, and it remains optional.
// Successful completion awards a one-time bonus to the wallet.
//
// Demo phase: a single creature drifts across the meadow while the
// hand pointer floats with it and taps it once. Replaces what used to
// be the K.CC.1 by-tens lesson hand-off, which didn't match the
// challenge's count-by-ones mechanic. ScaffoldEngine skips lessons for
// `isChallenge` sub-modes (see sanctuary_map_screen `_routeForSubMode`)
// so this self-contained demo is the only intro the kid sees.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../data/creature_card_catalog.dart';
import '../../data/sfx_catalog.dart';
import '../../data/tens_parade_words.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../platform/sfx_engine.dart';
import '../../providers/collection_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../ui/common/count_badge.dart';
import 'buddy_companion.dart';
import 'counting_challenge_layer.dart';
import 'keeper_choice_overlay.dart';
import 'lesson_hand_pointer.dart';
import 'next_arrow_button.dart';
import 'progress_bar_to_reward.dart';

enum _Phase { demo, challenge, reward }

/// How many taps the kid needs to land the bonus.
const int _kTarget = 100;

// The card this challenge exists to award is `kTensParadeChallengeCardId`.
// It is granted outright rather than rolled for: the reward catalog gives it
// exactly one source, `{ type: challenge, challengeActivityId:
// counting-parade }`, and `challenge-counting-parade-chest` guarantees one
// card from a pool containing only this one. A rare that a hundred taps might
// still fail to produce would be a worse reward than no card at all.

/// Sprites the flying creatures are picked from. Mirrors the canonical
/// parade sequence so the kid sees a familiar species mix.
const List<String> _kChallengeSprites = <String>[
  AssetPaths.countingParadeFawn,
  AssetPaths.countingParadeBabyGryphon,
  AssetPaths.countingParadeBabyDragon,
  AssetPaths.countingParadeBabyUnicorn,
  AssetPaths.countingParadeBabyPhoenix,
  AssetPaths.countingParadeBabyCentaur,
  AssetPaths.countingParadeBabyToucan,
  AssetPaths.countingParadeGoldenEgg,
];

class TensParadeRunner extends ConsumerStatefulWidget {
  const TensParadeRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  ConsumerState<TensParadeRunner> createState() => _TensParadeRunnerState();
}

class _TensParadeRunnerState extends ConsumerState<TensParadeRunner> {
  late _Phase _phase = widget.skipIntro ? _Phase.challenge : _Phase.demo;
  int _count = 0;

  /// Read eagerly — `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfxForDispose;

  /// True when this run is the one that earned the Cloud Unicorn, so a replay
  /// does not promise her a card she already has.
  bool _earnedCard = false;

  String get _rewardDialog => tensParadeRewardLine(earnedCard: _earnedCard);

  @override
  void initState() {
    super.initState();
    _sfxForDispose = ref.read(sfxEngineProvider);
    // Claimed here, not in the post-frame callback below: the release in
    // dispose() is unconditional, so the claim has to be too, or a teardown
    // before the first frame gives back a claim it never took. See
    // SfxEngine.releaseMusicBed for what that costs.
    // The challenge gets the higher-energy bed the lesson JSON already
    // names for it, rather than the calm meadow loop.
    unawaited(_sfxForDispose!.startMusicBed(kChallengeMusicBed));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedbackEngineProvider).resetRound();
    });
  }

  @override
  void dispose() {
    final sfx = _sfxForDispose;
    if (sfx != null) sfx.releaseMusicBed();
    super.dispose();
  }

  void _onDemoComplete() {
    if (!mounted) return;
    setState(() {
      _count = 0;
      _phase = _Phase.challenge;
    });
    ref.read(feedbackEngineProvider).resetRound();
  }

  void _onCountChanged(int value) {
    setState(() => _count = value);
  }

  void _onTargetReached() {
    ref.read(walletProvider.notifier).award(kTensParadeRewardCoins);
    ref.read(feedbackEngineProvider).celebrate();
    // Grant before the dialog is built, because the dialog reads _earnedCard.
    // `grant` returns false on a replay, which is what keeps the wording
    // honest the second time through.
    final earned = ref
        .read(cardCollectionProvider.notifier)
        .grant(kTensParadeChallengeCardId);
    if (earned) {
      ref
          .read(pendingCardRevealProvider.notifier)
          .show(kTensParadeChallengeCardId);
    }
    setState(() {
      _earnedCard = earned;
      _phase = _Phase.reward;
    });
    ref.narration.say(
      _rewardDialog,
      cueId: 'tens-parade:reward',
      speaker: kKeeperSpeaker,
      caption: false,
    );
  }

  void _repeat() {
    setState(() {
      _count = 0;
      _phase = _Phase.challenge;
    });
    ref.read(feedbackEngineProvider).resetRound();
  }

  void _finish() {
    widget.onSequenceComplete();
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.demo => _DemoLayer(
          spriteAsset: AssetPaths.countingParadeFawn,
          onComplete: _onDemoComplete,
        ),
      _Phase.challenge => Stack(
          children: [
            Positioned.fill(
              child: CountingChallengeLayer(
                target: _kTarget,
                spriteAssets: _kChallengeSprites,
                onCountChanged: _onCountChanged,
                onTargetReached: _onTargetReached,
              ),
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: CountBadge(
                  value: _count,
                  target: _kTarget,
                  size: CountBadgeSize.medium,
                ),
              ),
            ),
          ],
        ),
      _Phase.reward => KeeperChoiceOverlay(
          dialog: _rewardDialog,
          secondaryLabel: 'Continue',
          primaryLabel: 'Again!',
          onSecondary: _finish,
          onPrimary: _repeat,
          secondaryButtonKey: const ValueKey('tens-parade-finish'),
          primaryButtonKey: const ValueKey('tens-parade-repeat'),
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
                  progress:
                      _phase == _Phase.challenge || _phase == _Phase.reward
                          ? (_count / _kTarget).clamp(0.0, 1.0)
                          : 0.0,
                  celebrate: _phase == _Phase.reward,
                ),
              ),
              Expanded(child: phaseContent),
            ],
          ),
        ),
        if (_phase == _Phase.challenge) const BuddyCompanionCorner(),
      ],
    );
  }
}

/// Brief lead-in: one creature drifts left-to-right across the meadow
/// while the hand pointer floats with it and pokes it once mid-screen,
/// matching the tap interaction the kid is about to do for real. The
/// narrator says "Count the animals with me out loud as they do their
/// parade!" once, then the kid taps the Start arrow to begin.
class _DemoLayer extends ConsumerStatefulWidget {
  const _DemoLayer({
    required this.spriteAsset,
    required this.onComplete,
  });

  final String spriteAsset;
  final VoidCallback onComplete;

  @override
  ConsumerState<_DemoLayer> createState() => _DemoLayerState();
}

class _DemoLayerState extends ConsumerState<_DemoLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  // The hand starts off-stage to the right, glides in alongside the
  // creature, pokes once, then fades out. We bump `_pokeKey` to fire
  // the pointer's poke animation.
  int _pokeKey = 0;
  bool _pokeFired = false;
  bool _readyToStart = false;
  Timer? _pokeTimer;

  static const double _spriteSize = 120;
  static const double _handSize = 84;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _readyToStart = true);
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.narration.say(
        'Count the animals with me out loud as they do their parade!',
        cueId: 'tens-parade:demo',
      );
      _drift.forward();
      // Fire the hand-poke roughly mid-screen so the kid sees a tap on
      // the creature as it passes — same beat we ask of them.
      _pokeTimer = Timer(const Duration(milliseconds: 2100), () {
        if (!mounted) return;
        setState(() {
          _pokeFired = true;
          _pokeKey += 1;
        });
      });
    });
  }

  @override
  void dispose() {
    _pokeTimer?.cancel();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Vertical band the creature drifts through — keep it well
        // above the bottom button area.
        final spriteY = h * 0.42;
        final spriteX = (-_spriteSize) + _drift.value * (w + _spriteSize * 2);
        // The hand floats just above the creature and pokes once at
        // mid-screen; before the poke fires it sits off-stage right.
        final handTarget = _pokeFired
            ? Offset(
                spriteX + _spriteSize * 0.55,
                spriteY - _handSize * 0.65,
              )
            : Offset(w + _handSize, spriteY - _handSize * 0.65);

        return AnimatedBuilder(
          animation: _drift,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned(
                  left: spriteX,
                  top: spriteY,
                  width: _spriteSize,
                  height: _spriteSize,
                  child: Image.asset(
                    widget.spriteAsset,
                    fit: BoxFit.contain,
                  ),
                ),
                LessonHandPointer(
                  visible: _pokeFired && !_readyToStart,
                  target: handTarget,
                  pokeKey: _pokeKey,
                  size: _handSize,
                ),
                if (_readyToStart)
                  Positioned(
                    right: 24,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: NextArrowButton(
                        key: const ValueKey('tens-parade-demo-start'),
                        idleHintEnabled: true,
                        idleHintText: 'Tap the arrow to start the challenge!',
                        onPressed: widget.onComplete,
                        label: kLabelStart,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
