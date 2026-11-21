// One round of counting on: some creatures already counted, a few more walk
// on, and she counts the newcomers on from where the parade already is.
//
// Count Forward From N (start at five, three more) and Count On By Ones
// (start at forty, ten more) are this round with a different picture of what
// is already counted, so they share it. Both used to be eleven hundred lines
// of hand-copied lifecycle between them.
//
// How a round opens, and why it takes two beats
// ---------------------------------------------
// It used to open with the whole board already drawn and one long sentence
// spoken once over the top of it. Everything a kid needed was technically
// there, and none of it told her *when* it was her turn: the only thing
// separating the creatures she had to tap from the ones already counted was a
// line of text printed between the rows, which is nothing at all to a child
// who cannot read.
//
// So the round is staged. The counted side stands alone and bright while the
// narrator names it; a moment later the newcomers walk on from the right
// under the go signal, and the side behind them dims. The handover is carried
// by the picture and the voice at the same moment, and input opens exactly
// when the newcomers land.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../ui/common/count_badge.dart';
import '../../ui/common/target_hint.dart';
import '../../ui/common/timer_scope.dart';
import '../../ui/round/sanctuary_round_shell.dart';
import 'parade_pieces.dart';

/// What differs between the two count-on activities.
class CountOnRoundSpec {
  const CountOnRoundSpec({
    required this.keyPrefix,
    required this.startN,
    required this.arrivalsCount,
    required this.spriteAsset,
    required this.alreadyCountedLine,
    required this.prompt,
    required this.arrivalDelay,
    required this.stepFor,
    required this.doneHint,
    required this.rowLabel,
    required this.counted,
    required this.badgeSize,
    required this.arrivalSize,
    required this.arrivalHeightFactor,
    required this.burstRadius,
    required this.arrivalSpacing,
    required this.scrolls,
  });

  /// 'count-forward' or 'count-on-ones': the newcomers are keyed
  /// '$keyPrefix-r<round>-arrival-<i>' and the arrow '$keyPrefix-done-arrow'.
  final String keyPrefix;

  final int startN;
  final int arrivalsCount;
  final String spriteAsset;

  /// Beat one, naming what is already counted.
  final String alreadyCountedLine;

  /// Beat two, the go signal - and what the "?" button replays.
  final String prompt;

  /// How long the counted side stands alone before the newcomers walk on -
  /// about as long as it takes to say [alreadyCountedLine].
  final Duration arrivalDelay;

  /// The ladder note for a tap, from the taps this round and the number said.
  final int Function(int taps, int value) stepFor;

  final String doneHint;

  /// Printed over the newcomers. For whoever is sitting next to her; it is
  /// not load bearing.
  final String rowLabel;

  /// The already-counted side, given whether the newcomers have landed (it
  /// dims as they do).
  final Widget Function(bool landed) counted;

  final CountBadgeSize badgeSize;
  final double arrivalSize;
  final double arrivalHeightFactor;
  final double burstRadius;
  final double arrivalSpacing;

  /// True when the whole board scrolls (ten newcomers under a stack of
  /// cards); false when the newcomers take the space left under a short row.
  final bool scrolls;
}

class CountOnRoundBody extends ConsumerStatefulWidget {
  const CountOnRoundBody({super.key, required this.c, required this.spec});

  final RoundContext c;
  final CountOnRoundSpec spec;

  @override
  ConsumerState<CountOnRoundBody> createState() => _CountOnRoundBodyState();
}

class _CountOnRoundBodyState extends ConsumerState<CountOnRoundBody>
    with TimerScope<CountOnRoundBody> {
  final Set<int> _tapped = <int>{};

  /// Counted newcomers wander off a beat after their tap, so a kid who keeps
  /// re-tapping the same one sees it leave.
  final Set<int> _exited = <int>{};

  /// False until the newcomers have walked on.
  bool _landed = false;

  /// False through the two-beat opening; input opens as they land.
  bool _arrived = false;
  bool _done = false;
  int? _hinted;
  HintLadder? _hints;

  CountOnRoundSpec get _s => widget.spec;
  bool get _open => _arrived && !_done && !widget.c.locked;
  bool get _allTapped => _tapped.length == _s.arrivalsCount;
  int get _count => _s.startN + _tapped.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _begin();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  /// Name what is counted, walk the newcomers on, hand over.
  ///
  /// The two lines go out together but not at once: the second is queued
  /// behind the first rather than cutting it off. The timers pace the picture
  /// to match.
  void _begin() {
    widget.c.say(_s.alreadyCountedLine, replay: false);
    widget.c.say(_s.prompt, queue: true);
    after(_s.arrivalDelay, () => setState(() => _landed = true));
    // Hints start only once she can act on one, or the ladder would be
    // counting her hesitation while the game was still talking.
    after(_s.arrivalDelay + kArrivalWalk, () {
      setState(() => _arrived = true);
      _hints = HintLadder(onLevel: _onHint)..start();
    });
  }

  int? get _nextUntapped {
    for (var i = 0; i < _s.arrivalsCount; i++) {
      if (!_tapped.contains(i)) return i;
    }
    return null;
  }

  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final next = _nextUntapped;
    if (next == null) return;
    answerTargetHint(
      level,
      ring: () => setState(() => _hinted = next),
      chime: ref.read(feedbackEngineProvider).hint,
      say: (line) => widget.c.say(line, replay: false),
      demonstrate: () => _tap(next, fromHint: true),
    );
  }

  void _tap(int i, {bool fromHint = false}) {
    if (!_open || _tapped.contains(i)) return;
    setState(() {
      _tapped.add(i);
      _hinted = null;
    });
    if (!fromHint) _hints?.poke();
    countAloud(
      widget.c.say,
      ref.read(feedbackEngineProvider),
      step: _s.stepFor(_tapped.length, _count),
      value: _count,
      fromHint: fromHint,
    );
    after(const Duration(milliseconds: 900), () {
      setState(() => _exited.add(i));
    });
  }

  void _onDone() {
    if (_done || !_allTapped) return;
    setState(() => _done = true);
    _hints?.pause();
    // Every newcomer is a correct target, so help is the only thing that
    // separates a clean round from a soft one; it cannot be failed.
    widget.c.finish(gradeRound(helped: (_hints?.hintsUsed ?? 0) > 0));
  }

  @override
  Widget build(BuildContext context) {
    final label = AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: _landed ? 1 : 0,
      child: Text(
        _s.rowLabel,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
    final arrivals = Wrap(
      alignment: WrapAlignment.center,
      spacing: _s.arrivalSpacing,
      runSpacing: _s.arrivalSpacing,
      children: [
        for (var i = 0; i < _s.arrivalsCount; i++)
          ArrivingCreature(
            key: ValueKey('${_s.keyPrefix}-r${widget.c.index}-arrival-$i'),
            spriteAsset: _s.spriteAsset,
            size: _s.arrivalSize,
            heightFactor: _s.arrivalHeightFactor,
            burstRadius: _s.burstRadius,
            landed: _landed,
            tapped: _tapped.contains(i),
            gone: _exited.contains(i),
            pointed: _hinted == i,
            onTap: _open ? () => _tap(i) : null,
          ),
      ],
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              CountBadge(
                value: _count,
                target: _s.startN + _s.arrivalsCount,
                size: _s.badgeSize,
              ),
              const SizedBox(height: 12),
              if (_s.scrolls)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _s.counted(_landed),
                        const SizedBox(height: 8),
                        label,
                        const SizedBox(height: 6),
                        arrivals,
                      ],
                    ),
                  ),
                )
              else ...[
                _s.counted(_landed),
                const SizedBox(height: 8),
                label,
                const SizedBox(height: 4),
                Expanded(child: Center(child: arrivals)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        ParadeDoneShelf(
          arrowKey: ValueKey('${_s.keyPrefix}-done-arrow'),
          visible: _allTapped && !_done,
          idleHintText: _s.doneHint,
          onDone: _onDone,
        ),
      ],
    );
  }
}
