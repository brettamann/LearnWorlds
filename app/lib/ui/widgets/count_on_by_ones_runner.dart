// CountOnByOnesRunner — K.CC.1 "count to 100 by ones" + K.CC.2 "count
// forward from a given number" sub-mode of the Counting Parade. Each
// round picks up where the kid left off and counts a decade by ones:
// round 1 starts at 10 and climbs to 20, round 2 starts at 20 and
// climbs to 30, and so on through round 9 finishing at 100.
//
// Layout per round: a single filled cluster-of-ten card on the left
// shows the kid where we are (e.g. "10"), and ten individual creatures
// on the right are the new arrivals to tap one-by-one. The narrator
// confirms each tap with the next number ("Eleven. Twelve. ...") and
// the count badge ticks up alongside it.
//
// Each round resolves through RoundCoordinator with conceptId K.CC.1
// so streak + 5-coin payouts match the rest of the parade. The host's
// `onSequenceComplete` fires after the final interstitial.

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
    required this.spriteAsset,
    required this.singular,
    required this.plural,
    required this.keeperLine,
  });

  /// Where we pick up counting from — 10, 20, ..., 90.
  final int startN;
  final String spriteAsset;
  final String singular;
  final String plural;
  final String keeperLine;

  /// Always 10 — we cross one decade per round.
  int get arrivalsCount => 10;

  int get finalCount => startN + arrivalsCount;
}

// One round per decade. Climbs the same sprite ladder as the long parade
// so the kid sees a familiar species sequence regardless of how they got
// here.
const List<_Round> _kRounds = <_Round>[
  _Round(
    startN: 10,
    spriteAsset: AssetPaths.countingParadeFawn,
    singular: 'fawn',
    plural: 'fawns',
    keeperLine: 'Twenty fawns! Now the gryphons join in.',
  ),
  _Round(
    startN: 20,
    spriteAsset: AssetPaths.countingParadeBabyGryphon,
    singular: 'gryphon',
    plural: 'gryphons',
    keeperLine: 'Thirty gryphons! Dragons are next.',
  ),
  _Round(
    startN: 30,
    spriteAsset: AssetPaths.countingParadeBabyDragon,
    singular: 'dragon',
    plural: 'dragons',
    keeperLine: 'Forty dragons! Look — unicorns are catching up.',
  ),
  _Round(
    startN: 40,
    spriteAsset: AssetPaths.countingParadeBabyUnicorn,
    singular: 'unicorn',
    plural: 'unicorns',
    keeperLine: 'Fifty unicorns! Phoenix babies, please.',
  ),
  _Round(
    startN: 50,
    spriteAsset: AssetPaths.countingParadeBabyPhoenix,
    singular: 'phoenix',
    plural: 'phoenixes',
    keeperLine: 'Sixty phoenixes! Centaur babies next.',
  ),
  _Round(
    startN: 60,
    spriteAsset: AssetPaths.countingParadeBabyCentaur,
    singular: 'centaur',
    plural: 'centaurs',
    keeperLine: 'Seventy centaurs! Toucan babies, here you go.',
  ),
  _Round(
    startN: 70,
    spriteAsset: AssetPaths.countingParadeBabyToucan,
    singular: 'toucan',
    plural: 'toucans',
    keeperLine: 'Eighty toucans! Last two groups — fawns again.',
  ),
  _Round(
    startN: 80,
    spriteAsset: AssetPaths.countingParadeFawn,
    singular: 'fawn',
    plural: 'fawns',
    keeperLine: 'Ninety fawns! One more decade — the golden eggs.',
  ),
  _Round(
    startN: 90,
    spriteAsset: AssetPaths.countingParadeGoldenEgg,
    singular: 'golden egg',
    plural: 'golden eggs',
    keeperLine: 'One hundred! You counted all the way to one hundred by ones.',
  ),
];

const List<String> _kSpelled = <String>[
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
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
  'Twenty',
  'Twenty-one',
  'Twenty-two',
  'Twenty-three',
  'Twenty-four',
  'Twenty-five',
  'Twenty-six',
  'Twenty-seven',
  'Twenty-eight',
  'Twenty-nine',
  'Thirty',
  'Thirty-one',
  'Thirty-two',
  'Thirty-three',
  'Thirty-four',
  'Thirty-five',
  'Thirty-six',
  'Thirty-seven',
  'Thirty-eight',
  'Thirty-nine',
  'Forty',
  'Forty-one',
  'Forty-two',
  'Forty-three',
  'Forty-four',
  'Forty-five',
  'Forty-six',
  'Forty-seven',
  'Forty-eight',
  'Forty-nine',
  'Fifty',
  'Fifty-one',
  'Fifty-two',
  'Fifty-three',
  'Fifty-four',
  'Fifty-five',
  'Fifty-six',
  'Fifty-seven',
  'Fifty-eight',
  'Fifty-nine',
  'Sixty',
  'Sixty-one',
  'Sixty-two',
  'Sixty-three',
  'Sixty-four',
  'Sixty-five',
  'Sixty-six',
  'Sixty-seven',
  'Sixty-eight',
  'Sixty-nine',
  'Seventy',
  'Seventy-one',
  'Seventy-two',
  'Seventy-three',
  'Seventy-four',
  'Seventy-five',
  'Seventy-six',
  'Seventy-seven',
  'Seventy-eight',
  'Seventy-nine',
  'Eighty',
  'Eighty-one',
  'Eighty-two',
  'Eighty-three',
  'Eighty-four',
  'Eighty-five',
  'Eighty-six',
  'Eighty-seven',
  'Eighty-eight',
  'Eighty-nine',
  'Ninety',
  'Ninety-one',
  'Ninety-two',
  'Ninety-three',
  'Ninety-four',
  'Ninety-five',
  'Ninety-six',
  'Ninety-seven',
  'Ninety-eight',
  'Ninety-nine',
  'One hundred',
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

class CountOnByOnesRunner extends ConsumerStatefulWidget {
  const CountOnByOnesRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  ConsumerState<CountOnByOnesRunner> createState() =>
      _CountOnByOnesRunnerState();
}

class _CountOnByOnesRunnerState
    extends ConsumerState<CountOnByOnesRunner> {
  late _Phase _phase =
      widget.skipIntro ? _Phase.counting : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Set<int> _tappedArrivals = <int>{};
  // Counted arrivals wander off a beat after their tap so kids who keep
  // trying to re-tap one already counted see it leave.
  Set<int> _exitedArrivals = <int>{};
  final Map<int, Timer> _exitTimers = <int, Timer>{};
  Timer? _celebrationTimer;

  _Round get _currentRound => _kRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == _kRounds.length - 1;
  bool get _allTapped =>
      _tappedArrivals.length == _currentRound.arrivalsCount;
  int get _currentCount => _currentRound.startN + _tappedArrivals.length;
  double get _progress => _completedRounds / _kRounds.length;

  String get _countingPrompt {
    final start = _kTensSpelled[_currentRound.startN ~/ 10].toLowerCase();
    final end = _kTensSpelled[_currentRound.finalCount ~/ 10].toLowerCase();
    return "We're at $start. Touch each new ${_currentRound.singular} — "
        'count by ones up to $end!';
  }

  String get _finalKeeperLine =>
      'One hundred! Counting by ones got you all the way there. '
      'Amazing work.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // _Phase.intro is the animated _DemoLayer, which owns its own
      // narration timeline. Only speak the round prompt when we land
      // directly in the counting phase (i.e. skipIntro = true).
      if (_phase == _Phase.counting) {
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

  void _speakCountingPrompt() {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: _countingPrompt,
            cueId: 'count-on-ones:r$_roundIndex:prompt',
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
    final next = _currentCount;
    final spoken = next < _kSpelled.length ? _kSpelled[next] : next.toString();
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: '$spoken.',
            cueId: 'count-on-ones:r$_roundIndex:tap-${_tappedArrivals.length}',
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
              cueId: 'count-on-ones:r$_roundIndex:interstitial',
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
      _Phase.intro => _DemoLayer(onComplete: _onStartFromIntro),
      _Phase.counting || _Phase.celebrating => _CountOnByOnesLayer(
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
          replayCueId: 'count-on-ones:replay-r$_roundIndex',
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog:
              _isLastRound ? _finalKeeperLine : _currentRound.keeperLine,
          startLabel: _isLastRound ? 'Continue' : "Let's go!",
          startButtonKey:
              const ValueKey('count-on-ones-interstitial-next'),
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

class _CountOnByOnesLayer extends StatelessWidget {
  const _CountOnByOnesLayer({
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

  // Tap-target sprite size for the new arrivals — large enough for K
  // pointer accuracy but small enough that ten fit in a wrap.
  static const double _arrivalSize = 76;

  @override
  Widget build(BuildContext context) {
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
                  _CountBadge(value: currentCount, target: finalCount),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // "Already counted" cluster card on top — a
                          // static visual anchor showing where we picked
                          // up. Each card = 10, so we render one card per
                          // ten in startN.
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (var c = 0; c < startN ~/ 10; c++)
                                _CompletedClusterCard(
                                  spriteAsset: spriteAsset,
                                  label: '${(c + 1) * 10}',
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '— count by ones —',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Interactive arrivals — ten individuals to tap.
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (var i = 0; i < arrivalsCount; i++)
                                Builder(
                                  key: ValueKey(
                                    'count-on-ones-r$roundIndex-arrival-$i',
                                  ),
                                  builder: (_) {
                                    final gone = exitedArrivals.contains(i);
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: (inputLocked || gone)
                                          ? null
                                          : () => onTap(i),
                                      child: AnimatedSlide(
                                        duration: const Duration(
                                          milliseconds: 700,
                                        ),
                                        curve: Curves.easeInQuart,
                                        offset: gone
                                            ? const Offset(2.2, 0)
                                            : Offset.zero,
                                        child: AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 700,
                                          ),
                                          opacity: gone ? 0 : 1,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            clipBehavior: Clip.none,
                                            children: [
                                              AnimatedFawn(
                                                active: tappedArrivals
                                                    .contains(i),
                                                pointed: false,
                                                width: _arrivalSize,
                                                height:
                                                    _arrivalSize * 1.15,
                                                spriteAsset: spriteAsset,
                                              ),
                                              if (tappedArrivals
                                                  .contains(i))
                                                const Positioned.fill(
                                                  child: IgnorePointer(
                                                    child: GlitterBurst(
                                                      maxRadius: 56,
                                                    ),
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
                      key: const ValueKey('count-on-ones-done-arrow'),
                      idleHintEnabled: true,
                      idleHintText:
                          'Beautifully counted! Tap the arrow to keep going.',
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

/// A small filled cluster card showing one completed group of ten with
/// its running total label. Anchors the kid in the count — "we've
/// already counted these tens, now we add ones."
class _CompletedClusterCard extends StatelessWidget {
  const _CompletedClusterCard({
    super.key,
    required this.spriteAsset,
    required this.label,
  });

  final String spriteAsset;
  final String label;

  static const double _creatureSize = 22;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < 5; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    spriteAsset,
                    width: _creatureSize,
                    height: _creatureSize,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 3),
                  Image.asset(
                    spriteAsset,
                    width: _creatureSize,
                    height: _creatureSize,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
        ],
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

/// Animated lead-in for the count-on-by-ones sub-mode. Plays a three-act
/// demo:
///
///   1. **Count to ten** — ten fawn sprites pop into a 2×5 grid one by
///      one; narrator says "one… two… three… ten" in time with each
///      appearance.
///   2. **Collapse to a "10" cluster** — the grid becomes a labelled
///      cluster card; narrator: "When we count to ten we get a special
///      new number. The ones start over." (Mirrors how the count-by-tens
///      lesson visualises a group-of-ten.)
///   3. **Build the decades** — nine more cluster cards land one at a
///      time, narrator counting "twenty… thirty… … one hundred."
///
/// After the decades land, the narrator says "Let's count all the
/// different tens!" and the Start arrow appears. Tapping Start fires
/// `onComplete` (which advances the runner into the counting rounds).
class _DemoLayer extends ConsumerStatefulWidget {
  const _DemoLayer({required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<_DemoLayer> createState() => _DemoLayerState();
}

class _DemoLayerState extends ConsumerState<_DemoLayer> {
  // `_step` encodes the entire demo timeline:
  //   0       — idle (pre-first-frame)
  //   1..10   — counting sprites (visible count == _step)
  //   11      — first cluster collapses + "ones start over" narration
  //   12..20  — additional decade clusters; total clusters == _step - 10
  //   21      — kickoff line + Start arrow visible
  int _step = 0;
  final List<Timer> _timers = <Timer>[];
  bool _showStart = false;

  /// The whole demo uses a single species — keeps the visual story
  /// simple. Mythical creatures are picked over the fawn so the demo
  /// feels distinct from the count-the-parade intro.
  static const String _sprite = AssetPaths.countingParadeBabyGryphon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleDemo();
    });
  }

  void _scheduleDemo() {
    var t = 350;
    // Count one through ten. 600ms between arrivals keeps pace with the
    // narrator without feeling slow for a tablet audience.
    for (var i = 1; i <= 10; i++) {
      final value = i;
      _timers.add(
        Timer(Duration(milliseconds: t), () {
          if (!mounted) return;
          setState(() => _step = value);
          _speak(_kSpelled[value], 'demo:count-$value');
        }),
      );
      t += 600;
    }
    // Beat after the last "ten" before the cluster collapses + the
    // explanation plays. Long enough to feel deliberate.
    t += 700;
    _timers.add(
      Timer(Duration(milliseconds: t), () {
        if (!mounted) return;
        setState(() => _step = 11);
        _speak(
          'When we count to ten, we get a special new number. '
          'And the ones start over.',
          'demo:collapse',
        );
      }),
    );
    // Hold on the single "10" cluster long enough for the narration to
    // breathe (~5s spoken).
    t += 5200;
    // Decades two through ten — one card slides in per beat.
    for (var i = 2; i <= 10; i++) {
      final value = i;
      _timers.add(
        Timer(Duration(milliseconds: t), () {
          if (!mounted) return;
          setState(() => _step = 10 + value);
          _speak(_kTensSpelled[value], 'demo:decade-$value');
        }),
      );
      t += 1100;
    }
    // Kickoff — narration + Start arrow appear together.
    t += 500;
    _timers.add(
      Timer(Duration(milliseconds: t), () {
        if (!mounted) return;
        setState(() {
          _step = 21;
          _showStart = true;
        });
        _speak("Let's count all the different tens!", 'demo:kickoff');
      }),
    );
  }

  void _speak(String text, String cueId) {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(text: '$text.', cueId: cueId),
        );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  /// Top-of-stage badge value. Climbs by ones during the counting
  /// phase, then by tens once the first cluster lands.
  int get _badgeValue {
    if (_step >= 1 && _step <= 10) return _step;
    if (_step >= 11) return ((_step - 10).clamp(1, 10)) * 10;
    return 0;
  }

  /// Number of completed cluster cards to draw.
  int get _clusterCount {
    if (_step < 11) return 0;
    return (_step - 10).clamp(1, 10);
  }

  bool get _isCounting => _step >= 1 && _step <= 10;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _CountBadge(value: _badgeValue, target: 100),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 650),
                      child: _isCounting
                          ? _DemoCountingGrid(
                              key: const ValueKey('demo-grid'),
                              spriteAsset: _sprite,
                              visibleCount: _step,
                            )
                          : _DemoClusterWrap(
                              key: const ValueKey('demo-clusters'),
                              spriteAsset: _sprite,
                              clusterCount: _clusterCount,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            kContinueArrowShelf(
              child: _showStart
                  ? NextArrowButton(
                      key: const ValueKey('count-on-ones-demo-start'),
                      idleHintEnabled: true,
                      idleHintText:
                          'Tap the arrow when you are ready to count!',
                      onPressed: widget.onComplete,
                      label: 'Start',
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The "count to ten" stage — a 2×5 grid of sprite slots inside a soft
/// white card. Sprites pop in as `visibleCount` climbs.
class _DemoCountingGrid extends StatelessWidget {
  const _DemoCountingGrid({
    super.key,
    required this.spriteAsset,
    required this.visibleCount,
  });

  final String spriteAsset;
  final int visibleCount;

  static const double _spriteSize = 64;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 0; row < 5; row++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var col = 0; col < 2; col++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _PopInSprite(
                          spriteAsset: spriteAsset,
                          visible: (row * 2 + col + 1) <= visibleCount,
                          size: _spriteSize,
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

/// One sprite slot in the counting grid. Hidden slots take their full
/// space (so the grid doesn't reflow as sprites appear) and reveal with
/// an `easeOutBack` pop so each arrival has a beat to it.
class _PopInSprite extends StatelessWidget {
  const _PopInSprite({
    required this.spriteAsset,
    required this.visible,
    required this.size,
  });

  final String spriteAsset;
  final bool visible;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        scale: visible ? 1.0 : 0.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: visible ? 1.0 : 0.0,
          child: Image.asset(
            spriteAsset,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// The "decade clusters" stage — a Wrap of completed cluster cards.
/// Adds one card per beat as `clusterCount` climbs from 1 to 10.
class _DemoClusterWrap extends StatelessWidget {
  const _DemoClusterWrap({
    super.key,
    required this.spriteAsset,
    required this.clusterCount,
  });

  final String spriteAsset;
  final int clusterCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var c = 0; c < clusterCount; c++)
                _CompletedClusterCard(
                  key: ValueKey('demo-cluster-$c'),
                  spriteAsset: spriteAsset,
                  label: '${(c + 1) * 10}',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
