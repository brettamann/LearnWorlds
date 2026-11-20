// CountOnByOnesRunner — K.CC.1 "count to 100 by ones" + K.CC.2 "count
// forward from a given number" sub-mode of the Counting Parade. Each
// round joins the parade at a given number and counts the next decade by
// ones: 10 → 20, then 40 → 50, 70 → 80, and 90 → 100.
//
// It used to walk all nine decades in order, picking up exactly where the
// previous round stopped. That was ninety taps of the identical interaction
// in one sitting. Sampling four decades instead keeps the hard part — the
// decade boundary, which is the whole difficulty of counting on — and drops
// the sitting to forty taps. Starting somewhere other than "wherever we
// happened to stop" is also a truer reading of K.CC.2, which is about
// counting on from *any* given number rather than from the beginning.
//
// Layout per round: a single filled cluster-of-ten card on the left
// shows the kid where we are (e.g. "10"), and ten individual creatures
// on the right are the new arrivals to tap one-by-one. The narrator
// confirms each tap with the next number ("Eleven. Twelve. ...") and
// the count badge ticks up alongside it.
//
// The round opens in two beats, the same staging as Count Forward From N and
// for the same reason: everything used to be on screen at once under a single
// sentence spoken once, and nothing in that marked the moment the game stopped
// explaining and started waiting. Now the cluster cards stand alone while the
// narrator says where we are, then the newcomers walk on under the go signal
// and the cards behind them dim. Input opens as they land.
//
// Each round resolves through RoundCoordinator with conceptId K.CC.1
// so streak + 5-coin payouts match the rest of the parade. The host's
// `onSequenceComplete` fires after the final interstitial.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../data/count_on_by_ones_rounds.dart';
import '../../data/number_words.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../platform/sfx_engine.dart';
import 'animated_fawn.dart';
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

  /// The two-beat round opening. Input is locked; the newcomers are walking
  /// on. Ends the moment they land.
  arriving,

  counting,

  /// Keeper speaks over the live meadow and advances the round herself.
  transition,

  celebrating,

  /// Final beat only — the reward payoff, which is meant to interrupt.
  interstitial,
}

/// How long the counted cluster stands alone before the newcomers walk on —
/// about as long as it takes to say "We're at forty already."
const Duration _kArrivalDelay = Duration(milliseconds: 1000);

/// The walk-on itself. Input opens when they land.
const Duration _kArrivalWalk = Duration(milliseconds: 750);

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

class _CountOnByOnesRunnerState extends ConsumerState<CountOnByOnesRunner> {
  late _Phase _phase = widget.skipIntro ? _Phase.arriving : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Set<int> _tappedArrivals = <int>{};
  // Counted arrivals wander off a beat after their tap so kids who keep
  // trying to re-tap one already counted see it leave.
  Set<int> _exitedArrivals = <int>{};
  final Map<int, Timer> _exitTimers = <int, Timer>{};
  Timer? _celebrationTimer;

  /// False until the newcomers have walked on. Drives the opening: they are
  /// off-stage right, the cluster cards behind them are at full strength, and
  /// the row label is still hidden.
  bool _arrivalsLanded = false;
  Timer? _arriveTimer;
  Timer? _unlockTimer;

  /// Bumped to (re)present the between-round keeper aside.
  int _asideToken = 0;

  /// Arrival the hint ladder is glowing, if any.
  int? _hintedArrival;

  HintLadder? _hints;

  /// Read eagerly — `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfxForDispose;

  CountOnByOnesRound get _currentRound => kCountOnByOnesRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == kCountOnByOnesRounds.length - 1;
  bool get _allTapped => _tappedArrivals.length == _currentRound.arrivalsCount;
  int get _currentCount => _currentRound.startN + _tappedArrivals.length;
  double get _progress => _completedRounds / kCountOnByOnesRounds.length;

  String get _alreadyCountedLine =>
      countOnByOnesAlreadyCountedLine(_currentRound);

  String get _countingPrompt => countOnByOnesPrompt(_currentRound);

  String get _finalKeeperLine =>
      'One hundred! Counting by ones got you all the way there. '
      'Amazing work.';

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
      // _Phase.intro is the animated _DemoLayer, which owns its own
      // narration timeline. Only open a round when we land straight in it
      // (i.e. skipIntro = true).
      if (_phase == _Phase.arriving) _beginRound();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    _celebrationTimer?.cancel();
    _arriveTimer?.cancel();
    _unlockTimer?.cancel();
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

  void _onHintLevel(HintLevel level) {
    if (!mounted || _phase != _Phase.counting) return;
    final next = _nextUntapped();
    if (next == null) return;
    final feedback = ref.read(feedbackEngineProvider);
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _hintedArrival = next);
      case HintLevel.point:
        setState(() => _hintedArrival = next);
        feedback.hint();
        ref.read(narrationPlayerProvider.notifier).speak(
              NarrationLine(
                text: warmHintLine(2),
                cueId: 'count-on-ones:r$_roundIndex:hint-point',
              ),
            );
      case HintLevel.demonstrate:
        feedback.hint();
        ref.read(narrationPlayerProvider.notifier).speak(
              NarrationLine(
                text: warmHintLine(3),
                cueId: 'count-on-ones:r$_roundIndex:hint-demo',
              ),
            );
        _tapArrival(next, fromHint: true);
    }
  }

  int? _nextUntapped() {
    for (var i = 0; i < _currentRound.arrivalsCount; i++) {
      if (!_tappedArrivals.contains(i)) return i;
    }
    return null;
  }

  /// Open a round: say where we are, walk the newcomers on, hand over.
  ///
  /// The two lines go out together but not at once — `enqueue` waits for the
  /// first to finish rather than cutting it off. The timers pace the picture to
  /// match: the cluster gets the length of the first line to itself, then the
  /// newcomers arrive under the second.
  void _beginRound() {
    _arriveTimer?.cancel();
    _unlockTimer?.cancel();
    setState(() {
      _phase = _Phase.arriving;
      _arrivalsLanded = false;
    });

    final narration = ref.read(narrationPlayerProvider.notifier);
    narration.speak(
      NarrationLine(
        text: _alreadyCountedLine,
        cueId: 'count-on-ones:r$_roundIndex:already-counted',
      ),
    );
    narration.enqueue(
      NarrationLine(
        text: _countingPrompt,
        cueId: 'count-on-ones:r$_roundIndex:prompt',
      ),
    );

    _arriveTimer = Timer(_kArrivalDelay, () {
      if (!mounted) return;
      setState(() => _arrivalsLanded = true);
    });
    // Hints start only once she can act on one, or the ladder would be
    // counting her hesitation while the game was still talking.
    _unlockTimer = Timer(_kArrivalDelay + _kArrivalWalk, () {
      if (!mounted || _phase != _Phase.arriving) return;
      setState(() => _phase = _Phase.counting);
      _startHints();
    });
  }

  void _onStartFromIntro() => _beginRound();

  void _tapArrival(int idx, {bool fromHint = false}) {
    if (_phase != _Phase.counting) return;
    if (_tappedArrivals.contains(idx)) return;
    setState(() {
      _tappedArrivals.add(idx);
      _hintedArrival = null;
    });
    if (!fromHint) _hints?.poke();
    // Note this is keyed off the taps *this round*, not the absolute count:
    // the scale climbs the same ten steps whether the parade is at ten or at
    // ninety, so crossing each decade sounds identical. That is the point of
    // the exercise — ninety-one through one hundred is the same walk as
    // eleven through twenty.
    ref.read(feedbackEngineProvider).countStep(_tappedArrivals.length);
    final next = _currentCount;
    final spoken =
        next < kSpelledCounts.length ? kSpelledCounts[next] : next.toString();
    // Queued, not spoken, when the ladder did this tap. `speak` cuts off
    // whatever is in flight, and what is in flight at that moment is the
    // demonstration's own explanation - the one line in the round that
    // says why. See HintLadder.
    final say = ref.read(narrationPlayerProvider.notifier);
    final line = NarrationLine(
      text: '$spoken.',
      cueId: 'count-on-ones:r$_roundIndex:tap-${_tappedArrivals.length}',
    );
    if (fromHint) {
      say.enqueue(line);
    } else {
      say.speak(line);
    }
    _exitTimers[idx] = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _exitedArrivals.add(idx));
    });
  }

  void _finishRound() {
    if (!_allTapped) return;
    _hints?.pause();

    // Every arrival is a correct target, so the only thing separating a clean
    // round from a soft one is whether the ladder had to demonstrate.
    final result = (_hints?.hintsUsed ?? 0) > 0
        ? RoundResult.softSuccess
        : RoundResult.success;
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
                cueId: 'count-on-ones:r$_roundIndex:interstitial',
                speaker: 'sanctuary-keeper-mystic',
              ),
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
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: _currentRound.keeperLine,
              cueId: 'count-on-ones:r$_roundIndex:interstitial',
              speaker: 'sanctuary-keeper-mystic',
            ),
          );
    });
  }

  /// Fired by the keeper aside retiring itself, not by a button.
  void _advanceToNextRound() {
    if (!mounted || _phase != _Phase.transition) return;
    for (final t in _exitTimers.values) {
      t.cancel();
    }
    _exitTimers.clear();
    setState(() {
      _roundIndex += 1;
      _tappedArrivals = <int>{};
      _exitedArrivals = <int>{};
      _hintedArrival = null;
    });
    ref.read(feedbackEngineProvider).resetRound();
    _beginRound();
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => _DemoLayer(onComplete: _onStartFromIntro),
      _Phase.arriving ||
      _Phase.counting ||
      _Phase.celebrating ||
      _Phase.transition =>
        _CountOnByOnesLayer(
          roundIndex: _roundIndex,
          startN: _currentRound.startN,
          arrivalsCount: _currentRound.arrivalsCount,
          spriteAsset: _currentRound.spriteAsset,
          tappedArrivals: _tappedArrivals,
          exitedArrivals: _exitedArrivals,
          arrivalsLanded: _arrivalsLanded,
          hintedArrival: _hintedArrival,
          currentCount: _currentCount,
          finalCount: _currentRound.finalCount,
          onTap: _tapArrival,
          onDone: _finishRound,
          allTapped: _allTapped,
          inputLocked: _phase != _Phase.counting,
          replayPrompt: _countingPrompt,
          replayCueId: 'count-on-ones:replay-r$_roundIndex',
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _finalKeeperLine,
          startLabel: 'Continue',
          startButtonKey: const ValueKey('count-on-ones-interstitial-next'),
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

class _CountOnByOnesLayer extends StatelessWidget {
  const _CountOnByOnesLayer({
    required this.roundIndex,
    required this.startN,
    required this.arrivalsCount,
    required this.spriteAsset,
    required this.tappedArrivals,
    required this.exitedArrivals,
    required this.arrivalsLanded,
    required this.hintedArrival,
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

  /// False during the opening, while the newcomers are still off-stage. Holds
  /// the counted cluster at full strength and the row label hidden.
  final bool arrivalsLanded;

  /// Arrival the hint ladder wants glowed, or null. Rendered through
  /// AnimatedFawn's existing `pointed` state.
  final int? hintedArrival;

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
                          //
                          // Full strength while the narrator names it, then
                          // dimmed as the newcomers land. That handover is the
                          // "your turn now" cue, drawn rather than written.
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 600),
                            opacity: arrivalsLanded ? 0.6 : 1,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (var c = 0; c < startN ~/ 10; c++)
                                  _CompletedClusterCard(
                                    spriteAsset: spriteAsset,
                                    label: decadeLabel(c),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Kept for whoever is sitting next to her; it is not
                          // load bearing. The narration and the walk-on carry
                          // the same information for the kid playing.
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 600),
                            opacity: arrivalsLanded ? 1 : 0,
                            child: const Text(
                              '— count by ones —',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
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
                                    // Off-stage right before they arrive and
                                    // off-stage right once counted, so one
                                    // pair of offsets covers both. The zero
                                    // duration is what stops the first build
                                    // animating them in from nowhere.
                                    final waiting = !arrivalsLanded;
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: (inputLocked || gone)
                                          ? null
                                          : () => onTap(i),
                                      child: AnimatedSlide(
                                        duration: waiting
                                            ? Duration.zero
                                            : _kArrivalWalk,
                                        curve: gone
                                            ? Curves.easeInQuart
                                            : Curves.easeOutCubic,
                                        offset: (gone || waiting)
                                            ? const Offset(2.2, 0)
                                            : Offset.zero,
                                        child: AnimatedOpacity(
                                          duration: waiting
                                              ? Duration.zero
                                              : const Duration(
                                                  milliseconds: 600,
                                                ),
                                          opacity: (gone || waiting) ? 0 : 1,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            clipBehavior: Clip.none,
                                            children: [
                                              AnimatedFawn(
                                                active:
                                                    tappedArrivals.contains(i),
                                                pointed: hintedArrival == i,
                                                width: _arrivalSize,
                                                height: _arrivalSize * 1.15,
                                                spriteAsset: spriteAsset,
                                              ),
                                              if (tappedArrivals.contains(i))
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
          _speak('${kSpelledCounts[value]}.', 'demo:count-$value');
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
          _speak('${kSpelledTens[value]}.', 'demo:decade-$value');
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

  /// Speaks [text] exactly as given.
  ///
  /// It used to append a full stop, which was right for the bare number words
  /// it was first written for and wrong for everything else: the two sentences
  /// below arrived as "...start over.." and "...tens!.". Clips are looked up
  /// by the words spoken, so neither could ever match its recording and both
  /// stayed in the browser synth voice. Callers pass a finished sentence.
  void _speak(String text, String cueId) {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(text: text, cueId: cueId),
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
                      label: kLabelStart,
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
                  label: decadeLabel(c),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
