// LongParadeRunner — K.CC.1 "count by tens" sub-mode of the Counting
// Parade. The K.CC.1 lesson teaches that a tight group of ten can be
// counted as one chunk; this activity practices that exact skill:
// each round presents N groups of 10 creatures (laid out as 2 × 5
// grids inside cluster cards) and the kid taps each cluster in order.
// The narrator says "Ten. Twenty. Thirty." while the count badge ticks
// up by ten per tap.
//
// Four rounds: 3 clusters (30) → 5 (50) → 7 (70) → 10 (100).
// Each round resolves through RoundCoordinator with conceptId K.CC.1.
// The cluster cards wrap so they use the full vertical area on a tablet
// and stay big enough to tap comfortably.
//
// Feedback follows the Counting Parade pattern: each cluster tapped sounds
// the next note up the scale, so counting by tens *sounds* like climbing,
// and the between-round keeper line plays over the live meadow rather than
// through a blocking modal.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../data/long_parade_rounds.dart';
import '../../data/number_words.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../platform/sfx_engine.dart';
import 'buddy_companion.dart';
import 'continue_arrow_shelf.dart';
import 'glitter_burst.dart';
import 'keeper_aside.dart';
import 'keeper_intro_overlay.dart';
import 'next_arrow_button.dart';
import 'playfield_scaffold.dart';
import 'replay_demo_button.dart';

enum _Phase {
  intro,
  counting,

  /// Keeper talks over the live meadow and advances the round herself. See
  /// the same phase on CountTheParadeRunner for why the blocking version
  /// went away.
  transition,

  celebrating,

  /// Final beat only — the reward payoff, which is meant to interrupt.
  interstitial,
}

class LongParadeRunner extends ConsumerStatefulWidget {
  const LongParadeRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  ConsumerState<LongParadeRunner> createState() => _LongParadeRunnerState();
}

class _LongParadeRunnerState extends ConsumerState<LongParadeRunner> {
  late _Phase _phase = widget.skipIntro ? _Phase.counting : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Set<int> _tappedClusters = <int>{};
  // Cluster wanders off after its tap so kids stop re-tapping a group
  // they've already counted. Each tap gets its own delay timer.
  Set<int> _exitedClusters = <int>{};
  final Map<int, Timer> _exitTimers = <int, Timer>{};
  Map<int, int> _burstCounters = <int, int>{};
  Timer? _celebrationTimer;

  /// Bumped to (re)present the between-round keeper aside.
  int _asideToken = 0;

  /// Cluster the hint ladder is glowing, if any.
  int? _hintedCluster;

  HintLadder? _hints;

  /// Read eagerly — `ref.read` is illegal once dispose() has begun, and
  /// dispose() is where the music bed has to stop.
  SfxEngine? _sfxForDispose;

  LongParadeRound get _currentRound => kLongParadeRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == kLongParadeRounds.length - 1;
  bool get _allTapped => _tappedClusters.length == _currentRound.clusterCount;
  int get _currentCount => _tappedClusters.length * 10;
  double get _progress => _completedRounds / kLongParadeRounds.length;

  String get _introDialog =>
      "Today's parade is HUGE — but we won't count one by one. Each group "
      'is ten. Tap each group and count by tens together!';

  String get _countingPrompt => longParadeCountingPrompt(_currentRound);

  String get _finalKeeperLine =>
      'One hundred! Counting by tens carries you all the way there.';

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
        _speakCountingPrompt();
      }
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    _celebrationTimer?.cancel();
    for (final t in _exitTimers.values) {
      t.cancel();
    }
    final sfx = _sfxForDispose;
    if (sfx != null) sfx.releaseMusicBed();
    super.dispose();
  }

  void _startHints() {
    _hints?.dispose();
    _hints = HintLadder(onLevel: _onHintLevel)..start();
  }

  /// Escalating help for a kid who has stalled. There is no wrong cluster to
  /// tap here, so being stuck looks like doing nothing at all — which is
  /// exactly the state that used to produce no response of any kind.
  void _onHintLevel(HintLevel level) {
    if (!mounted || _phase != _Phase.counting) return;
    final next = _nextUntapped();
    if (next == null) return;
    final feedback = ref.read(feedbackEngineProvider);
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _hintedCluster = next);
      case HintLevel.point:
        setState(() => _hintedCluster = next);
        feedback.hint();
        ref.read(narrationPlayerProvider.notifier).speak(
              NarrationLine(
                text: warmHintLine(2),
                cueId: 'long-parade:r$_roundIndex:hint-point',
              ),
            );
      case HintLevel.demonstrate:
        feedback.hint();
        ref.read(narrationPlayerProvider.notifier).speak(
              NarrationLine(
                text: warmHintLine(3),
                cueId: 'long-parade:r$_roundIndex:hint-demo',
              ),
            );
        _tapCluster(next, fromHint: true);
    }
  }

  int? _nextUntapped() {
    for (var c = 0; c < _currentRound.clusterCount; c++) {
      if (!_tappedClusters.contains(c)) return c;
    }
    return null;
  }

  void _speakIntro() {
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          NarrationLine(
            text: _introDialog,
            cueId: 'long-parade:intro',
            speaker: kKeeperSpeaker,
          ),
        );
  }

  void _speakCountingPrompt() {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: _countingPrompt,
            cueId: 'long-parade:r$_roundIndex:prompt',
          ),
        );
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.counting);
    _startHints();
    _speakCountingPrompt();
  }

  void _tapCluster(int idx, {bool fromHint = false}) {
    if (_phase != _Phase.counting) return;
    if (_tappedClusters.contains(idx)) return;
    setState(() {
      _tappedClusters.add(idx);
      _burstCounters[idx] = (_burstCounters[idx] ?? 0) + 1;
      _hintedCluster = null;
    });
    // A hint-driven tap must not reset the ladder, or a stalled kid would be
    // demonstrated at forever instead of the round resolving as a soft pass.
    if (!fromHint) _hints?.poke();
    final n = _tappedClusters.length;
    // Same pitch ladder as counting by ones: ten, twenty, thirty each sound a
    // step higher, so counting by tens is audibly the same kind of climb.
    ref.read(feedbackEngineProvider).countStep(n);
    final spoken =
        n < kSpelledTens.length ? kSpelledTens[n] : (n * 10).toString();
    // Queued, not spoken, when the ladder did this tap. `speak` cuts off
    // whatever is in flight, and what is in flight at that moment is the
    // demonstration's own explanation - the one line in the round that
    // says why. See HintLadder.
    final say = ref.read(narrationPlayerProvider.notifier);
    final line = NarrationLine(
      text: '$spoken.',
      cueId: 'long-parade:r$_roundIndex:tap-$n',
    );
    if (fromHint) {
      say.enqueue(line);
    } else {
      say.speak(line);
    }
    _exitTimers[idx] = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _exitedClusters.add(idx));
    });
  }

  void _finishRound() {
    if (!_allTapped) return;
    _hints?.pause();

    // Every cluster here is a correct target — there is nothing wrong to tap
    // — so the only thing separating a clean round from a soft one is whether
    // the ladder had to demonstrate. adaptive-scaffolding.md §Hint Layer: a
    // round that needed a hint counts as soft-success and does not advance
    // the promotion streak.
    final result = gradeRound(helped: (_hints?.hintsUsed ?? 0) > 0);
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'counting-parade',
          conceptId: 'K.CC.1',
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
        ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
              NarrationLine(
                text: _finalKeeperLine,
                cueId: 'long-parade:r$_roundIndex:interstitial',
                speaker: kKeeperSpeaker,
              ),
            );
      });
      return;
    }

    feedback.roundPass();
    // Non-final: the keeper speaks over the live meadow and the aside
    // advances the round when it retires itself. No tap required.
    _celebrationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.transition;
        _asideToken += 1;
      });
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: _currentRound.keeperLine,
              cueId: 'long-parade:r$_roundIndex:interstitial',
              speaker: kKeeperSpeaker,
            ),
          );
    });
  }

  /// Fired by the keeper aside retiring itself. Guards on the phase because
  /// the exit animation can land after the widget has already moved on.
  void _advanceToNextRound() {
    if (!mounted || _phase != _Phase.transition) return;
    for (final t in _exitTimers.values) {
      t.cancel();
    }
    _exitTimers.clear();
    setState(() {
      _roundIndex += 1;
      _tappedClusters = <int>{};
      _exitedClusters = <int>{};
      _burstCounters = <int, int>{};
      _hintedCluster = null;
      _phase = _Phase.counting;
    });
    // Back to the bottom of the scale — every round is its own climb.
    ref.read(feedbackEngineProvider).resetRound();
    _startHints();
    _speakCountingPrompt();
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: "Let's count!",
          startButtonKey: const ValueKey('long-parade-start-button'),
          onStart: _onStartFromIntro,
        ),
      // The meadow stays up through the transition, which is the point of
      // the aside — the child can keep looking at what she just counted
      // while the keeper talks over it.
      _Phase.counting ||
      _Phase.celebrating ||
      _Phase.transition =>
        _LongParadeLayer(
          roundIndex: _roundIndex,
          clusterCount: _currentRound.clusterCount,
          spriteAsset: _currentRound.spriteAsset,
          tappedClusters: _tappedClusters,
          exitedClusters: _exitedClusters,
          burstCounters: _burstCounters,
          hintedCluster: _hintedCluster,
          currentCount: _currentCount,
          targetCount: _currentRound.totalCreatures,
          onTapCluster: _tapCluster,
          onDone: _finishRound,
          allTapped: _allTapped,
          inputLocked: _phase != _Phase.counting,
          replayPrompt: _countingPrompt,
          replayCueId: 'long-parade:replay-r$_roundIndex',
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _finalKeeperLine,
          startLabel: 'Continue',
          startButtonKey: const ValueKey('long-parade-interstitial-next'),
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
        // Outer stack, not inside the layer: the layer's left edge is the
        // replay-demo shelf and Buddy would collide with it.
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

class _LongParadeLayer extends StatelessWidget {
  const _LongParadeLayer({
    required this.roundIndex,
    required this.clusterCount,
    required this.spriteAsset,
    required this.tappedClusters,
    required this.exitedClusters,
    required this.burstCounters,
    required this.hintedCluster,
    required this.currentCount,
    required this.targetCount,
    required this.onTapCluster,
    required this.onDone,
    required this.allTapped,
    required this.inputLocked,
    required this.replayPrompt,
    required this.replayCueId,
  });

  final int roundIndex;
  final int clusterCount;
  final String spriteAsset;
  final Set<int> tappedClusters;
  final Set<int> exitedClusters;
  final Map<int, int> burstCounters;

  /// Cluster the hint ladder wants glowed, or null.
  final int? hintedCluster;

  final int currentCount;
  final int targetCount;
  final ValueChanged<int> onTapCluster;
  final VoidCallback onDone;
  final bool allTapped;
  final bool inputLocked;

  /// Narration the (?) button replays. Same line the runner spoke at
  /// the start of the round.
  final String replayPrompt;
  final String replayCueId;

  // Single creature size inside a cluster. 44 keeps individual sprites
  // visible without dominating the cluster card.
  static const double _creatureSize = 44;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                  _CountBadge(value: currentCount, target: targetCount),
                  const SizedBox(height: 12),
                  Expanded(
                    // Late rounds (8–10 clusters) overflow the natural Wrap
                    // height even with reflow — wrap in a SingleChildScrollView
                    // so the kid can scroll if their device is small.
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (var c = 0; c < clusterCount; c++)
                              _ClusterCard(
                                key: ValueKey(
                                  'long-parade-r$roundIndex-cluster-$c',
                                ),
                                spriteAsset: spriteAsset,
                                tapped: tappedClusters.contains(c),
                                gone: exitedClusters.contains(c),
                                hinted: hintedCluster == c,
                                burstCounter: burstCounters[c] ?? 0,
                                onTap:
                                    (inputLocked || exitedClusters.contains(c))
                                        ? null
                                        : () => onTapCluster(c),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            kContinueArrowShelf(
              child: allTapped
                  ? NextArrowButton(
                      key: const ValueKey('long-parade-done-arrow'),
                      idleHintEnabled: true,
                      idleHintText:
                          'Great counting by tens! Tap the arrow to keep going.',
                      onPressed: onDone,
                      label: kLabelDone,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// One group-of-ten card — 2 cols × 5 rows of creature sprites with a
/// "10" label and a tap-to-count interaction.
class _ClusterCard extends StatelessWidget {
  const _ClusterCard({
    super.key,
    required this.spriteAsset,
    required this.tapped,
    required this.gone,
    required this.hinted,
    required this.burstCounter,
    required this.onTap,
  });

  final String spriteAsset;
  final bool tapped;

  /// Once true the cluster slides off-screen + fades. Hit-testing is
  /// already disabled by the parent passing `onTap: null`.
  final bool gone;

  /// The hint ladder is pointing here. Same soft amber glow AnimatedFawn uses
  /// for its `pointed` state, so help looks the same everywhere in the game.
  final bool hinted;

  final int burstCounter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInQuart,
      offset: gone ? const Offset(2.0, 0) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: gone ? 0 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(alpha: tapped || hinted ? 0.75 : 0.55),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: tapped || hinted
                      ? const [
                          BoxShadow(
                            color: Colors.amber,
                            blurRadius: 26,
                            spreadRadius: 3,
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 2 cols × 5 rows of creatures.
                    for (var row = 0; row < 5; row++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              spriteAsset,
                              width: _LongParadeLayer._creatureSize,
                              height: _LongParadeLayer._creatureSize,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 6),
                            Image.asset(
                              spriteAsset,
                              width: _LongParadeLayer._creatureSize,
                              height: _LongParadeLayer._creatureSize,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tapped
                            ? Colors.amber.shade100
                            : Colors.brown.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '10',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (burstCounter > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: GlitterBurst(
                      key: ValueKey('long-parade-cluster-burst-$burstCounter'),
                      maxRadius: 110,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.value, required this.target});

  final int value;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '$value / $target',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }
}
