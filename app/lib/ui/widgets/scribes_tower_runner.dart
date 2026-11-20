// Scribe's Tower - K.CC.3: read and write numerals.
//
// Three kinds of round, all built from two pieces:
//
// - **Trace** - the numeral on a parchment, a green dot and a firefly at the
//   start, and ink that follows her finger. See `numeral_tracer.dart` for
//   every choice made about how forgiving that is.
// - **Write from a cue** - fireflies to count first, then the same numeral
//   over a much fainter guide. The count comes first so that what she writes
//   is a number she knows, not a shape she is copying.
// - **Find the number** - three numeral cards, no dots, and the name of one
//   of them. This is the reading half of the standard, so the dots that every
//   other number card in the game carries are off - but a wrong card shows its
//   dots after she taps it, so a miss tells her what that card says.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activities/activity_ids.dart';
import '../../data/asset_paths.dart';
import '../../data/number_words.dart';
import '../../data/scribes_tower_words.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../providers/session_provider.dart';
import '../common/timer_scope.dart';
import 'answer_feedback.dart';
import 'number_choice.dart';
import 'numeral_tracer.dart';
import 'sanctuary_round_shell.dart';
import 'touch_here_halo.dart';
import 'touch_target.dart';

class ScribesTowerRunner extends ConsumerWidget {
  const ScribesTowerRunner({
    super.key,
    required this.onSequenceComplete,
    this.subMode = kScribeSubTrace,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final String subMode;
  final bool skipIntro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rounds = scribeRoundsFor(
      subMode,
      seed: ref.watch(sessionIdProvider).hashCode,
    );
    return SanctuaryRoundShell(
      activityId: ActivityIds.scribesTower,
      roundCount: rounds.length,
      conceptIdFor: (_) => 'K.CC.3',
      introLine: kScribeIntro,
      keeperLineFor: scribeKeeperLine,
      finalLine: kScribeFinal,
      skipIntro: skipIntro,
      musicBed:
          subMode == kScribeSubTeens ? kChallengeMusicBed : kDefaultMusicBed,
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.scribesTowerBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) => ScribeRoundBody(
        round: rounds[c.index],
        c: c,
        teens: subMode == kScribeSubTeens,
      ),
    );
  }
}

class ScribeRoundBody extends ConsumerStatefulWidget {
  const ScribeRoundBody({
    super.key,
    required this.round,
    required this.c,
    this.teens = false,
  });

  final ScribeRound round;
  final RoundContext c;
  final bool teens;

  @override
  ConsumerState<ScribeRoundBody> createState() => _ScribeRoundBodyState();
}

class _ScribeRoundBodyState extends ConsumerState<ScribeRoundBody>
    with TimerScope<ScribeRoundBody> {
  HintLadder? _hints;
  bool _done = false;
  bool _ringStart = false;
  int _demoToken = 0;

  // write-from-cue: the fireflies to count first.
  late final bool _counting = widget.round.task == ScribeTask.writeFromCue;
  final Set<int> _counted = <int>{};
  int? _ringedFly;

  // match
  late final List<int> _choices = numberChoicesFor(
    widget.round.numeral,
    seed: widget.c.index + 11,
    min: widget.teens ? 11 : 0,
    max: widget.teens ? 19 : 10,
  );
  int? _answered;
  int? _hintedCard;
  final Map<int, int> _wrong = <int, int>{};
  final Set<int> _revealed = <int>{};
  int _misses = 0;

  ScribeRound get _r => widget.round;
  bool get _open => !_done && !widget.c.locked;
  bool get _allCounted => _counted.length >= _r.numeral;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.c.showDemo && _r.task == ScribeTask.trace) {
        widget.c.say(kScribeDemo, replay: false);
        setState(() => _demoToken++);
        after(const Duration(milliseconds: 2600), _begin);
      } else {
        _begin();
      }
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  void _begin() {
    widget.c.say(scribePrompt(_r), queue: true);
    _hints?.dispose();
    _hints = HintLadder(onLevel: _onHint)..start();
  }

  // ---- tracing ------------------------------------------------------------

  void _onTraceDone() {
    if (_done) return;
    _done = true;
    _hints?.pause();
    ref.read(feedbackEngineProvider).correct();
    widget.c.say(scribeDone(_r), replay: false);
    widget.c.finish(
      gradeRound(helped: (_hints?.hintsUsed ?? 0) > 0),
    );
  }

  // ---- counting fireflies -----------------------------------------------

  void _onFly(int i, {bool fromHint = false}) {
    if (!_open || !_counting || _counted.contains(i) || _allCounted) return;
    // Not poked when the ladder did it. A poke restarts the ladder, and a
    // ladder that restarts itself from its own top rung counts one firefly
    // every fifteen seconds until it has counted them all - the game doing
    // her turn, which is the thing the first real play session reported.
    if (!fromHint) _hints?.poke();
    setState(() {
      _counted.add(i);
      _ringedFly = null;
    });
    final n = _counted.length;
    ref.read(feedbackEngineProvider).countStep(n);
    if (!_allCounted) {
      widget.c.say('${spellCount(n)}.', replay: false, queue: fromHint);
      return;
    }
    widget.c.say(scribeCueCount(_r.numeral));
    _hints?.start();
  }

  // ---- matching ---------------------------------------------------------

  void _onPick(int n) {
    if (!_open) return;
    _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    if (n != _r.numeral) {
      setState(() {
        _wrong[n] = (_wrong[n] ?? 0) + 1;
        // Show what she did tap: the dots under the card she chose.
        if (!widget.teens) _revealed.add(n);
        _misses += 1;
        if (_misses >= 2) _hintedCard = _r.numeral;
      });
      feedback.wrong();
      widget.c.say(scribeMatchMiss(_r.numeral, _misses), replay: false);
      return;
    }
    _done = true;
    _hints?.pause();
    setState(() {
      _answered = n;
      _hintedCard = null;
    });
    feedback.correct();
    widget.c.say(scribeDone(_r), replay: false);
    widget.c.finish(
      gradeRound(misses: _misses, helped: (_hints?.hintsUsed ?? 0) > 0),
    );
  }

  // ---- help ---------------------------------------------------------------

  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final feedback = ref.read(feedbackEngineProvider);
    if (_r.task == ScribeTask.match) {
      switch (level) {
        case HintLevel.none:
        case HintLevel.highlight:
          return;
        case HintLevel.point:
          feedback.hint();
          widget.c.say(scribePrompt(_r), replay: false);
        case HintLevel.demonstrate:
          feedback.hint();
          setState(() => _hintedCard = _r.numeral);
          widget.c.say(warmHintLine(3), replay: false);
      }
      return;
    }
    if (_counting && !_allCounted) {
      final next = List<int>.generate(_r.numeral, (i) => i)
          .firstWhere((i) => !_counted.contains(i), orElse: () => -1);
      if (next < 0) return;
      switch (level) {
        case HintLevel.none:
          return;
        case HintLevel.highlight:
          setState(() => _ringedFly = next);
        case HintLevel.point:
          feedback.hint();
          widget.c.say(warmHintLine(2), replay: false);
        case HintLevel.demonstrate:
          feedback.hint();
          _onFly(next, fromHint: true);
      }
      return;
    }
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _ringStart = true);
      case HintLevel.point:
        feedback.hint();
        widget.c.say(kScribeFollow, replay: false);
      case HintLevel.demonstrate:
        // The firefly flies the stroke for her to watch. It draws nothing she
        // keeps: the stroke is still hers to trace.
        feedback.hint();
        widget.c.say(kScribeDemo, replay: false);
        setState(() => _demoToken++);
    }
  }

  // ---- drawing ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_r.task == ScribeTask.match) return _buildMatch();
    return LayoutBuilder(
      builder: (context, box) {
        final showFlies = _counting;
        // Fireflies keep a proper tap size and wrap onto a second row when
        // there are too many for one, rather than shrinking under the floor
        // or running off the edge - ten of them, on a narrow window, did both.
        final flySize = math.max(
          kMinTouchTarget,
          math.min(96.0, box.maxWidth / math.max(1, _r.numeral) - 10),
        );
        final perRow = math.max(1, (box.maxWidth / (flySize + 8)).floor());
        final flyRows = (_r.numeral / perRow).ceil();
        final flyBand = showFlies ? flyRows * (flySize + 8) + 8 : 0.0;
        final writing = !_counting || _allCounted;
        return Column(
          children: [
            if (showFlies)
              SizedBox(
                height: flyBand,
                child: _FireflyRow(
                  count: _r.numeral,
                  counted: _counted,
                  ringed: _ringedFly,
                  size: flySize,
                  onTap: _onFly,
                ),
              ),
            Expanded(
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: writing ? 1 : 0.35,
                  child: _Parchment(
                    child: IgnorePointer(
                      ignoring: !writing,
                      child: NumeralTracer(
                        key: ValueKey('tracer-${widget.c.index}'),
                        numeral: _r.numeral,
                        guideOpacity: _counting ? 0.35 : 1,
                        ringStart: _ringStart,
                        demoToken: _demoToken,
                        locked: !_open,
                        onProgress: () {
                          _hints?.poke();
                          if (_ringStart) setState(() => _ringStart = false);
                        },
                        onStray: () =>
                            widget.c.say(kScribeStartHere, replay: false),
                        onStrokeDone: () {
                          ref.read(feedbackEngineProvider).sparkle();
                          widget.c.say(kScribeNextPart, replay: false);
                        },
                        onDone: _onTraceDone,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatch() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _choices.length; i++) ...[
            if (i > 0) const SizedBox(width: 40),
            NumberCard(
              key: ValueKey('number-card-${_choices[i]}'),
              value: _choices[i],
              width: 190,
              showDots: _revealed.contains(_choices[i]),
              hinted: _hintedCard == _choices[i] && _answered == null,
              glowing: _answered == _choices[i],
              dimmed: _answered != null && _answered != _choices[i],
              wrongToken: _wrong[_choices[i]] ?? 0,
              burstToken: _answered == _choices[i] ? 1 : 0,
              onTap: _open ? () => _onPick(_choices[i]) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _Parchment extends StatelessWidget {
  const _Parchment({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final h = math.min(box.maxHeight, 540.0);
        final w = math.min(box.maxWidth * 0.9, h * 1.15);
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6E0),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFC9A86A), width: 5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: child,
        );
      },
    );
  }
}

class _FireflyRow extends StatelessWidget {
  const _FireflyRow({
    required this.count,
    required this.counted,
    required this.ringed,
    required this.size,
    required this.onTap,
  });

  final int count;
  final Set<int> counted;
  final int? ringed;
  final double size;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        runSpacing: 8,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                key: ValueKey('scribe-fly-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: AnswerFeedback(
                          correctToken: counted.contains(i) ? 1 : 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: counted.contains(i) ? 1 : 0.7,
                            child: Image.asset(
                              AssetPaths.countingParadeFireflySprite,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      if (ringed == i)
                        TouchHereRingOutside(around: Size.square(size)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
