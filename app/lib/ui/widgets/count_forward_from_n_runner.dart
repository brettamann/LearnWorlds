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
//
// How a round opens, and why it takes two beats
// ---------------------------------------------
// It used to open with the whole board already drawn and one long sentence
// spoken once over the top of it. Everything a kid needed was technically
// there, and none of it told her *when* it was her turn: the only thing
// separating the creatures she had to tap from the ones already counted was
// the phrase "new arrivals" printed between the rows, which is nothing at all
// to a child who cannot read.
//
// So the round is staged now. The counted row stands alone and bright while
// the narrator names it; a moment later the newcomers walk on from the right
// under the go signal, and the row behind them dims. The handover is carried
// by the picture and the voice at the same moment, and input opens exactly
// when the newcomers land.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../data/count_forward_from_n_rounds.dart';
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

/// How long the counted row stands alone before the newcomers walk on —
/// about as long as it takes to say "We already counted three fawns."
const Duration _kArrivalDelay = Duration(milliseconds: 1100);

/// The walk-on itself. Input opens when they land, so this is also the last
/// stretch of the lock.
const Duration _kArrivalWalk = Duration(milliseconds: 750);

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
  late _Phase _phase = widget.skipIntro ? _Phase.arriving : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Set<int> _tappedArrivals = <int>{};
  // Counted arrivals wander off-screen a beat after their tap so kids
  // who keep re-tapping the same one see it leave.
  Set<int> _exitedArrivals = <int>{};
  final Map<int, Timer> _exitTimers = <int, Timer>{};
  Timer? _celebrationTimer;

  /// False until the newcomers have walked on. Drives the whole opening: the
  /// arrivals are off-stage right, the row behind them is at full strength,
  /// and the "new arrivals" label is still hidden.
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

  CountForwardRound get _currentRound => kCountForwardRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == kCountForwardRounds.length - 1;
  bool get _allTapped => _tappedArrivals.length == _currentRound.arrivalsCount;
  int get _currentCount => _currentRound.startN + _tappedArrivals.length;
  double get _progress => _completedRounds / kCountForwardRounds.length;

  String get _introDialog =>
      "Sometimes we don't start at one. We can start at the number we left "
      'off! Watch — I count on from there.';

  String get _alreadyCountedLine =>
      countForwardAlreadyCountedLine(_currentRound);

  String get _countingPrompt => countForwardPrompt(_currentRound);

  String get _finalKeeperLine =>
      'You counted all the new creatures! Wonderful work.';

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
        _beginRound();
      }
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
        ref.narration.say(
          warmHintLine(2),
          cueId: 'count-forward:r$_roundIndex:hint-point',
        );
      case HintLevel.demonstrate:
        feedback.hint();
        ref.narration.say(
          warmHintLine(3),
          cueId: 'count-forward:r$_roundIndex:hint-demo',
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

  void _speakIntro() {
    ref.narration.say(
      _introDialog,
      cueId: 'count-forward:intro',
      speaker: kKeeperSpeaker,
      caption: false,
    );
  }

  /// Open a round: name what is counted, walk the newcomers on, hand over.
  ///
  /// The two lines go out together but not at once — `enqueue` waits for the
  /// first to finish rather than cutting it off, which is the entire reason
  /// the narration queue exists. The timers pace the picture to match: the
  /// counted row gets the length of the first line to itself, then the
  /// newcomers arrive under the second.
  void _beginRound() {
    _arriveTimer?.cancel();
    _unlockTimer?.cancel();
    setState(() {
      _phase = _Phase.arriving;
      _arrivalsLanded = false;
    });

    final narration = ref.narration;
    narration.speak(
      NarrationLine(
        text: _alreadyCountedLine,
        cueId: 'count-forward:r$_roundIndex:already-counted',
      ),
    );
    narration.enqueue(
      NarrationLine(
        text: _countingPrompt,
        cueId: 'count-forward:r$_roundIndex:prompt',
      ),
    );

    _arriveTimer = Timer(_kArrivalDelay, () {
      if (!mounted) return;
      setState(() => _arrivalsLanded = true);
    });
    // Hints only start once she can actually act on one. Starting the ladder
    // during a locked opening would have it counting her hesitation while the
    // game was still talking.
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
    // Climbs from where the parade already is: counting on from five sounds
    // like continuing a scale rather than starting a new one, which is
    // exactly the idea K.CC.2 is teaching.
    ref.read(feedbackEngineProvider).countStep(_currentCount);
    final spoken = _currentCount < kSpelledCounts.length
        ? kSpelledCounts[_currentCount]
        : _currentCount.toString();
    // Queued, not spoken, when the ladder did this tap. `speak` cuts off
    // whatever is in flight, and what is in flight at that moment is the
    // demonstration's own explanation - the one line in the round that
    // says why. See HintLadder.
    final say = ref.narration;
    final line = NarrationLine(
      text: '$spoken.',
      cueId: 'count-forward:r$_roundIndex:tap-${_tappedArrivals.length}',
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

    // Every arrival is a correct target, so a hint is the only thing that
    // separates a clean round from a soft one.
    final result = gradeRound(helped: (_hints?.hintsUsed ?? 0) > 0);
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'counting-parade',
          conceptId: 'K.CC.2',
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
          cueId: 'count-forward:r$_roundIndex:interstitial',
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
        cueId: 'count-forward:r$_roundIndex:interstitial',
        speaker: kKeeperSpeaker,
        caption: false,
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
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: "Let's count!",
          startButtonKey: const ValueKey('count-forward-start-button'),
          onStart: _onStartFromIntro,
        ),
      _Phase.arriving ||
      _Phase.counting ||
      _Phase.celebrating ||
      _Phase.transition =>
        _CountForwardLayer(
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
          replayCueId: 'count-forward:replay-r$_roundIndex',
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _finalKeeperLine,
          startLabel: 'Continue',
          startButtonKey: const ValueKey('count-forward-interstitial-next'),
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

class _CountForwardLayer extends StatelessWidget {
  const _CountForwardLayer({
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

  /// False during the opening, while the newcomers are still off-stage. Fades
  /// the counted row back and reveals the arrivals row with them.
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
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          // Full strength while the narrator is naming these,
                          // then dimmed as the newcomers land. That handover
                          // is the "your turn now" cue, drawn rather than
                          // written.
                          opacity: arrivalsLanded ? 0.45 : 1,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Image.asset(
                                spriteAsset,
                                width: _spriteSize * 0.75,
                                height: _spriteSize * 0.75,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Kept for whoever is sitting next to her; it is not load
                  // bearing. The narration and the walk-on carry the same
                  // information for the kid actually playing.
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: arrivalsLanded ? 1 : 0,
                    child: const Text(
                      '— new arrivals —',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
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
                                // Off-stage right before they arrive and
                                // off-stage right once they are counted, so
                                // one pair of offsets covers both. The zero
                                // duration is what stops the first build
                                // animating them in from nowhere.
                                final waiting = !arrivalsLanded;
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: (inputLocked || gone)
                                      ? null
                                      : () => onTap(i),
                                  child: AnimatedSlide(
                                    duration:
                                        waiting ? Duration.zero : _kArrivalWalk,
                                    curve: gone
                                        ? Curves.easeInQuart
                                        : Curves.easeOutCubic,
                                    offset: (gone || waiting)
                                        ? const Offset(2.2, 0)
                                        : Offset.zero,
                                    child: AnimatedOpacity(
                                      duration: waiting
                                          ? Duration.zero
                                          : const Duration(milliseconds: 600),
                                      opacity: (gone || waiting) ? 0 : 1,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          AnimatedFawn(
                                            active: tappedArrivals.contains(i),
                                            pointed: hintedArrival == i,
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
