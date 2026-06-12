// CountForwardFromNRunner — K.CC.2 "counting on" sub-mode of the Counting
// Parade. Each round shows N pre-counted creatures (faint numerals above
// them) plus M new arrivals; the kid taps each new arrival in order while
// the narrator counts on from N+1.
//
// Three rounds escalate the count: start at 3 (+3 fawns), start at 5 (+3
// gryphons), start at 7 (+3 dragons). Each round resolves through
// RoundCoordinator with conceptId K.CC.2 so mastery streak + 5-coin
// payout match honest play; `onSequenceComplete` fires after the final
// interstitial.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'animated_fawn.dart';
import 'continue_arrow_shelf.dart';
import 'glitter_burst.dart';
import 'keeper_intro_overlay.dart';
import 'next_arrow_button.dart';
import 'progress_bar_to_reward.dart';
import 'replay_demo_button.dart';

enum _Phase { intro, counting, celebrating, interstitial }

class _Round {
  const _Round({
    required this.startN,
    required this.arrivalsCount,
    required this.spriteAsset,
    required this.singular,
    required this.plural,
    required this.keeperLine,
  });

  final int startN;
  final int arrivalsCount;
  final String spriteAsset;
  final String singular;
  final String plural;
  final String keeperLine;

  int get finalCount => startN + arrivalsCount;
}

const List<_Round> _kRounds = <_Round>[
  _Round(
    startN: 3,
    arrivalsCount: 3,
    spriteAsset: AssetPaths.countingParadeFawn,
    singular: 'fawn',
    plural: 'fawns',
    keeperLine: 'Six fawns! Now some gryphons are catching up.',
  ),
  _Round(
    startN: 5,
    arrivalsCount: 3,
    spriteAsset: AssetPaths.countingParadeBabyGryphon,
    singular: 'gryphon',
    plural: 'gryphons',
    keeperLine: 'Eight gryphons! Last one — the dragons.',
  ),
  _Round(
    startN: 7,
    arrivalsCount: 3,
    spriteAsset: AssetPaths.countingParadeBabyDragon,
    singular: 'dragon',
    plural: 'dragons',
    keeperLine: 'Ten dragons! Beautifully counted on.',
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
  'Eleven',
  'Twelve',
];

class CountForwardFromNRunner extends ConsumerStatefulWidget {
  const CountForwardFromNRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  ConsumerState<CountForwardFromNRunner> createState() =>
      _CountForwardFromNRunnerState();
}

class _CountForwardFromNRunnerState
    extends ConsumerState<CountForwardFromNRunner> {
  late _Phase _phase =
      widget.skipIntro ? _Phase.counting : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Set<int> _tappedArrivals = <int>{};
  // Counted arrivals wander off-screen a beat after their tap so kids
  // who keep re-tapping the same one see it leave.
  Set<int> _exitedArrivals = <int>{};
  final Map<int, Timer> _exitTimers = <int, Timer>{};
  Timer? _celebrationTimer;

  _Round get _currentRound => _kRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == _kRounds.length - 1;
  bool get _allTapped =>
      _tappedArrivals.length == _currentRound.arrivalsCount;
  int get _currentCount => _currentRound.startN + _tappedArrivals.length;
  double get _progress => _completedRounds / _kRounds.length;

  String get _introDialog =>
      "Sometimes we don't start at one. We can start at the number we left "
      'off! Watch — I count on from there.';

  String get _countingPrompt =>
      'We have ${_kSpelled[_currentRound.startN].toLowerCase()} already. '
      'Touch each new ${_currentRound.singular} — and count out loud with me!';

  String get _finalKeeperLine =>
      'You counted all the new creatures! Wonderful work.';

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
            cueId: 'count-forward:intro',
            speaker: 'sanctuary-keeper-mystic',
          ),
        );
  }

  void _speakCountingPrompt() {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: _countingPrompt,
            cueId: 'count-forward:r$_roundIndex:prompt',
          ),
        );
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.counting);
    _speakCountingPrompt();
  }

  void _tapArrival(int idx) {
    if (_phase != _Phase.counting) return;
    if (_tappedArrivals.contains(idx)) return;
    setState(() => _tappedArrivals.add(idx));
    final spoken = _currentCount < _kSpelled.length
        ? _kSpelled[_currentCount]
        : _currentCount.toString();
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: '$spoken.',
            cueId: 'count-forward:r$_roundIndex:tap-${_tappedArrivals.length}',
          ),
        );
    _exitTimers[idx] = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _exitedArrivals.add(idx));
    });
  }

  void _finishRound() {
    if (!_allTapped) return;
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'counting-parade',
          conceptId: 'K.CC.2',
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
              cueId: 'count-forward:r$_roundIndex:interstitial',
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
      _tappedArrivals = <int>{};
      _exitedArrivals = <int>{};
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
          startButtonKey: const ValueKey('count-forward-start-button'),
          onStart: _onStartFromIntro,
        ),
      _Phase.counting || _Phase.celebrating => _CountForwardLayer(
          roundIndex: _roundIndex,
          startN: _currentRound.startN,
          arrivalsCount: _currentRound.arrivalsCount,
          spriteAsset: _currentRound.spriteAsset,
          tappedArrivals: _tappedArrivals,
          exitedArrivals: _exitedArrivals,
          currentCount: _currentCount,
          finalCount: _currentRound.finalCount,
          onTap: _tapArrival,
          onDone: _finishRound,
          allTapped: _allTapped,
          inputLocked: _phase == _Phase.celebrating,
          replayPrompt: _countingPrompt,
          replayCueId: 'count-forward:replay-r$_roundIndex',
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog:
              _isLastRound ? _finalKeeperLine : _currentRound.keeperLine,
          startLabel: _isLastRound ? 'Continue' : "Let's go!",
          startButtonKey:
              const ValueKey('count-forward-interstitial-next'),
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

class _CountForwardLayer extends StatelessWidget {
  const _CountForwardLayer({
    required this.roundIndex,
    required this.startN,
    required this.arrivalsCount,
    required this.spriteAsset,
    required this.tappedArrivals,
    required this.exitedArrivals,
    required this.currentCount,
    required this.finalCount,
    required this.onTap,
    required this.onDone,
    required this.allTapped,
    required this.inputLocked,
    required this.replayPrompt,
    required this.replayCueId,
  });

  final int roundIndex;
  final int startN;
  final int arrivalsCount;
  final String spriteAsset;
  final Set<int> tappedArrivals;
  final Set<int> exitedArrivals;
  final int currentCount;
  final int finalCount;
  final ValueChanged<int> onTap;
  final VoidCallback onDone;
  final bool allTapped;
  final bool inputLocked;

  /// Narration the (?) button replays. Same line the runner spoke at
  /// the start of the round.
  final String replayPrompt;
  final String replayCueId;

  static const double _spriteSize = 96;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                  _CountBadge(value: currentCount, target: finalCount),
                  const SizedBox(height: 12),
            // Pre-counted row — faint, with numerals above each.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < startN; i++)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                      Opacity(
                        opacity: 0.45,
                        child: Image.asset(
                          spriteAsset,
                          width: _spriteSize * 0.75,
                          height: _spriteSize * 0.75,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '— new arrivals —',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            // Arrivals row — interactive.
            Expanded(
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (var i = 0; i < arrivalsCount; i++)
                      Builder(
                        key: ValueKey(
                          'count-forward-r$roundIndex-arrival-$i',
                        ),
                        builder: (_) {
                          final gone = exitedArrivals.contains(i);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: (inputLocked || gone)
                                ? null
                                : () => onTap(i),
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeInQuart,
                              offset: gone
                                  ? const Offset(2.2, 0)
                                  : Offset.zero,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 700),
                                opacity: gone ? 0 : 1,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    AnimatedFawn(
                                      active: tappedArrivals.contains(i),
                                      pointed: false,
                                      width: _spriteSize,
                                      height: _spriteSize * 1.2,
                                      spriteAsset: spriteAsset,
                                    ),
                                    if (tappedArrivals.contains(i))
                                      const Positioned.fill(
                                        child: IgnorePointer(
                                          child:
                                              GlitterBurst(maxRadius: 70),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
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
                      key: const ValueKey('count-forward-done-arrow'),
                      idleHintEnabled: true,
                      idleHintText:
                          'Nice counting! Tap the arrow to keep going.',
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
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }
}
