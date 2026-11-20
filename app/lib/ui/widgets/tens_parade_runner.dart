// TensParadeRunner — the Counting Parade's optional final challenge.
// Despite the historical name, this sub-mode is the kid's "count all
// the way to one hundred by ones" final check: creatures drift across
// the meadow from right to left and the kid taps each one, narrator
// counting along, until 100 are tapped.
//
// Lives at the end of the sub-mode chain and is marked `isChallenge`
// in the activity registry — the Sanctuary picker only surfaces it
// after every regular sub-mode is complete, and it remains optional.
// It is not graded round by round; a successful run pays a one-time bonus
// and grants the Cloud Unicorn, once per visit, and offers "Again!".
//
// Demo: a single creature drifts across the meadow while the hand pointer
// floats with it and taps it once, as the shell's intro. ScaffoldEngine
// skips lessons for `isChallenge` sub-modes (see sanctuary_map_screen
// `_routeForSubMode`), so this self-contained demo is the only intro the kid
// sees.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activities/activity_ids.dart';
import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../data/creature_card_catalog.dart';
import '../../data/parade_species.dart';
import '../../data/sfx_catalog.dart';
import '../../data/tens_parade_words.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_player.dart';
import '../../providers/collection_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../ui/common/count_badge.dart';
import 'counting_challenge_layer.dart';
import 'keeper_choice_overlay.dart';
import 'lesson_hand_pointer.dart';
import 'next_arrow_button.dart';
import 'sanctuary_round_shell.dart';

// The card this challenge exists to award is `kTensParadeChallengeCardId`.
// It is granted outright rather than rolled for: the reward catalog gives it
// exactly one source, `{ type: challenge, challengeActivityId:
// counting-parade }`, and `challenge-counting-parade-chest` guarantees one
// card from a pool containing only this one. A rare that a hundred taps might
// still fail to produce would be a worse reward than no card at all.

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
  /// Bumped by "Again!", which re-keys the shell for a fresh run.
  int _run = 0;

  /// The bonus and the card are paid once per visit, not once per run.
  bool _paid = false;

  /// Whether this visit's payout granted the card. Latched when it is paid,
  /// so the line she hears cannot change under her once the card is hers.
  bool? _earnedCard;

  /// The run's last line. The first run of a visit names what it pays - the
  /// card if she does not have it yet, the coins if she does - and a repeat
  /// run, which pays nothing, promises nothing.
  String _finalLine(bool owned) => _run == 0
      ? tensParadeRewardLine(earnedCard: _earnedCard ?? !owned)
      : kTensParadeRepeatLine;

  /// Fired by the shell as the finale appears.
  void _payOnce() {
    if (_paid) return;
    _paid = true;
    ref.read(walletProvider.notifier).award(kTensParadeRewardCoins);
    // `grant` returns false when she already owns it, which is what keeps
    // the wording honest.
    final earned = ref
        .read(cardCollectionProvider.notifier)
        .grant(kTensParadeChallengeCardId);
    if (earned) {
      ref
          .read(pendingCardRevealProvider.notifier)
          .show(kTensParadeChallengeCardId);
    }
    setState(() => _earnedCard = earned);
  }

  void _again() => setState(() => _run += 1);

  @override
  Widget build(BuildContext context) {
    final owned =
        ref.watch(cardCollectionProvider).contains(kTensParadeChallengeCardId);
    final finalLine = _finalLine(owned);
    return SanctuaryRoundShell(
      key: ValueKey('tens-parade-run-$_run'),
      activityId: ActivityIds.countingParade,
      roundCount: 1,
      conceptIdFor: (_) => 'K.CC.1',
      // Not graded and not paid per round: one bonus, in _payOnce.
      gradeRounds: false,
      // Never spoken by the shell: the demo is the opening and says it.
      introLine: kTensParadeDemoLine,
      introBuilder: (context, start) => _DemoLayer(
        spriteAsset: kParadeFawn.spriteAsset,
        onComplete: start,
      ),
      // A repeat run goes straight back to the meadow.
      skipIntro: widget.skipIntro || _run > 0,
      // One round, so there is no between-round aside.
      keeperLineFor: (_) => finalLine,
      finalLine: finalLine,
      // The challenge gets the higher-energy bed the lesson JSON already
      // names for it, rather than the calm meadow loop.
      musicBed: kChallengeMusicBed,
      celebrationHold: const Duration(seconds: 1),
      onFinale: _payOnce,
      finaleBuilder: (context, done) => KeeperChoiceOverlay(
        dialog: finalLine,
        secondaryLabel: kLabelContinue,
        primaryLabel: 'Again!',
        onSecondary: done,
        onPrimary: _again,
        secondaryButtonKey: const ValueKey('tens-parade-finish'),
        primaryButtonKey: const ValueKey('tens-parade-repeat'),
      ),
      onSequenceComplete: widget.onSequenceComplete,
      background: Image.asset(
        AssetPaths.countingParadeMeadow,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) => _ChallengeBody(c: c),
    );
  }
}

/// The hundred taps: creatures drift by, she taps each, the badge counts.
class _ChallengeBody extends StatefulWidget {
  const _ChallengeBody({required this.c});

  final RoundContext c;

  @override
  State<_ChallengeBody> createState() => _ChallengeBodyState();
}

class _ChallengeBodyState extends State<_ChallengeBody> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CountingChallengeLayer(
            target: kTensParadeTarget,
            // The whole parade cast, so she sees a familiar species mix.
            spriteAssets: <String>[
              for (final s in kParadeSpecies) s.spriteAsset,
            ],
            say: widget.c.say,
            onCountChanged: (value) => setState(() => _count = value),
            onTargetReached: () => widget.c.finish(RoundResult.success),
          ),
        ),
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: CountBadge(
              value: _count,
              target: kTensParadeTarget,
              size: CountBadgeSize.medium,
            ),
          ),
        ),
      ],
    );
  }
}

/// Brief lead-in: one creature drifts left-to-right across the meadow
/// while the hand pointer floats with it and pokes it once mid-screen,
/// matching the tap interaction the kid is about to do for real. The
/// narrator says [kTensParadeDemoLine] once, then the kid taps the Start
/// arrow to begin.
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
      ref.narration.say(kTensParadeDemoLine, cueId: 'tens-parade:demo');
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
        return AnimatedBuilder(
          animation: _drift,
          builder: (context, _) {
            // Read here, inside the builder, so it moves every frame. It
            // used to be read once per layout, outside, and the creature
            // sat off-stage until something else happened to rebuild it.
            final spriteX =
                (-_spriteSize) + _drift.value * (w + _spriteSize * 2);
            // The hand floats just above the creature and pokes once at
            // mid-screen; before the poke fires it sits off-stage right.
            final handTarget = _pokeFired
                ? Offset(
                    spriteX + _spriteSize * 0.55,
                    spriteY - _handSize * 0.65,
                  )
                : Offset(w + _handSize, spriteY - _handSize * 0.65);
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
                        idleHintText: kTensParadeDemoStartHint,
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
