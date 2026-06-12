// LongParadeRunner — K.CC.1 "count by tens" sub-mode of the Counting
// Parade. The K.CC.1 lesson teaches that a tight group of ten can be
// counted as one chunk; this activity practices that exact skill:
// each round presents N groups of 10 creatures (laid out as 2 × 5
// grids inside cluster cards) and the kid taps each cluster in order.
// The narrator says "Ten. Twenty. Thirty." while the count badge ticks
// up by ten per tap.
//
// Three rounds: 3 clusters (30) → 4 clusters (40) → 5 clusters (50).
// Each round resolves through RoundCoordinator with conceptId K.CC.1.
// The cluster cards wrap so they use the full vertical area on a tablet
// and stay big enough to tap comfortably.

import 'dart:async';

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

enum _Phase { intro, counting, celebrating, interstitial }

class _Round {
  const _Round({
    required this.clusterCount,
    required this.spriteAsset,
    required this.singular,
    required this.plural,
    required this.keeperLine,
  });

  final int clusterCount;
  final String spriteAsset;
  final String singular;
  final String plural;
  final String keeperLine;

  int get totalCreatures => clusterCount * 10;
}

// K.CC.1 standard: "Count to 100 by ones and by tens." So this sub-mode
// runs eight rounds — one per creature in the canonical parade sequence
// — climbing from 30 → 40 → 50 → 60 → 70 → 80 → 90 → 100, finishing on
// the golden eggs at one hundred.
const List<_Round> _kRounds = <_Round>[
  _Round(
    clusterCount: 3,
    spriteAsset: AssetPaths.countingParadeFawn,
    singular: 'fawn',
    plural: 'fawns',
    keeperLine: 'Thirty fawns! Next: more groups of ten — gryphons.',
  ),
  _Round(
    clusterCount: 4,
    spriteAsset: AssetPaths.countingParadeBabyGryphon,
    singular: 'gryphon',
    plural: 'gryphons',
    keeperLine: 'Forty gryphons! Now the dragons.',
  ),
  _Round(
    clusterCount: 5,
    spriteAsset: AssetPaths.countingParadeBabyDragon,
    singular: 'dragon',
    plural: 'dragons',
    keeperLine: 'Fifty dragons! Look — here come the unicorns.',
  ),
  _Round(
    clusterCount: 6,
    spriteAsset: AssetPaths.countingParadeBabyUnicorn,
    singular: 'unicorn',
    plural: 'unicorns',
    keeperLine: 'Sixty unicorns! Phoenix babies are next.',
  ),
  _Round(
    clusterCount: 7,
    spriteAsset: AssetPaths.countingParadeBabyPhoenix,
    singular: 'phoenix',
    plural: 'phoenixes',
    keeperLine: 'Seventy phoenixes! Centaur babies, please.',
  ),
  _Round(
    clusterCount: 8,
    spriteAsset: AssetPaths.countingParadeBabyCentaur,
    singular: 'centaur',
    plural: 'centaurs',
    keeperLine: 'Eighty centaurs! The toucan babies are waiting.',
  ),
  _Round(
    clusterCount: 9,
    spriteAsset: AssetPaths.countingParadeBabyToucan,
    singular: 'toucan',
    plural: 'toucans',
    keeperLine: 'Ninety toucans! Last group — the golden eggs.',
  ),
  _Round(
    clusterCount: 10,
    spriteAsset: AssetPaths.countingParadeGoldenEgg,
    singular: 'golden egg',
    plural: 'golden eggs',
    keeperLine:
        "One hundred! You counted to one hundred by tens — that's amazing.",
  ),
];

const List<String> _kTensSpelled = <String>[
  'Zero',
  'Ten',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
  'One hundred',
];

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
  late _Phase _phase =
      widget.skipIntro ? _Phase.counting : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Set<int> _tappedClusters = <int>{};
  // Cluster wanders off after its tap so kids stop re-tapping a group
  // they've already counted. Each tap gets its own delay timer.
  Set<int> _exitedClusters = <int>{};
  final Map<int, Timer> _exitTimers = <int, Timer>{};
  Map<int, int> _burstCounters = <int, int>{};
  Timer? _celebrationTimer;

  _Round get _currentRound => _kRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == _kRounds.length - 1;
  bool get _allTapped =>
      _tappedClusters.length == _currentRound.clusterCount;
  int get _currentCount => _tappedClusters.length * 10;
  double get _progress => _completedRounds / _kRounds.length;

  String get _introDialog =>
      "Today's parade is HUGE — but we won't count one by one. Each group "
      'is ten. Tap each group and count by tens together!';

  String get _countingPrompt =>
      'Tap each group of ${_currentRound.plural} — count by tens out loud '
      'with me!';

  String get _finalKeeperLine =>
      'One hundred! Counting by tens carries you all the way there.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_phase == _Phase.intro) {
        _speakIntro();
      } else {
        _speakCountingPrompt();
      }
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    for (final t in _exitTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _speakIntro() {
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          NarrationLine(
            text: _introDialog,
            cueId: 'long-parade:intro',
            speaker: 'sanctuary-keeper-mystic',
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
    _speakCountingPrompt();
  }

  void _tapCluster(int idx) {
    if (_phase != _Phase.counting) return;
    if (_tappedClusters.contains(idx)) return;
    setState(() {
      _tappedClusters.add(idx);
      _burstCounters[idx] = (_burstCounters[idx] ?? 0) + 1;
    });
    final n = _tappedClusters.length;
    final spoken = n < _kTensSpelled.length
        ? _kTensSpelled[n]
        : (n * 10).toString();
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: '$spoken.',
            cueId: 'long-parade:r$_roundIndex:tap-$n',
          ),
        );
    _exitTimers[idx] = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _exitedClusters.add(idx));
    });
  }

  void _finishRound() {
    if (!_allTapped) return;
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'counting-parade',
          conceptId: 'K.CC.1',
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
              cueId: 'long-parade:r$_roundIndex:interstitial',
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
    for (final t in _exitTimers.values) {
      t.cancel();
    }
    _exitTimers.clear();
    setState(() {
      _roundIndex += 1;
      _tappedClusters = <int>{};
      _exitedClusters = <int>{};
      _burstCounters = <int, int>{};
      _phase = _Phase.counting;
    });
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
      _Phase.counting || _Phase.celebrating => _LongParadeLayer(
          roundIndex: _roundIndex,
          clusterCount: _currentRound.clusterCount,
          spriteAsset: _currentRound.spriteAsset,
          tappedClusters: _tappedClusters,
          exitedClusters: _exitedClusters,
          burstCounters: _burstCounters,
          currentCount: _currentCount,
          targetCount: _currentRound.totalCreatures,
          onTapCluster: _tapCluster,
          onDone: _finishRound,
          allTapped: _allTapped,
          inputLocked: _phase == _Phase.celebrating,
          replayPrompt: _countingPrompt,
          replayCueId: 'long-parade:replay-r$_roundIndex',
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog:
              _isLastRound ? _finalKeeperLine : _currentRound.keeperLine,
          startLabel: _isLastRound ? 'Continue' : "Let's go!",
          startButtonKey:
              const ValueKey('long-parade-interstitial-next'),
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

class _LongParadeLayer extends StatelessWidget {
  const _LongParadeLayer({
    required this.roundIndex,
    required this.clusterCount,
    required this.spriteAsset,
    required this.tappedClusters,
    required this.exitedClusters,
    required this.burstCounters,
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
                                burstCounter: burstCounters[c] ?? 0,
                                onTap: (inputLocked ||
                                        exitedClusters.contains(c))
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
                      label: 'Done',
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
    required this.burstCounter,
    required this.onTap,
  });

  final String spriteAsset;
  final bool tapped;

  /// Once true the cluster slides off-screen + fades. Hit-testing is
  /// already disabled by the parent passing `onTap: null`.
  final bool gone;

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
              color: Colors.white.withValues(alpha: tapped ? 0.75 : 0.55),
              borderRadius: BorderRadius.circular(20),
              boxShadow: tapped
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
