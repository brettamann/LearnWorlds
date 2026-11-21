// Fluency Within 5 - K.OA.5: add and subtract within five, quickly.
//
// Buddy's practice clearing. Each puzzle shows the acorns and the numerals
// together - two acorns over a "2", a plus, one acorn over a "1" - and is said
// out loud ("Two plus one?"), and she answers on a card that carries its dots.
// Taking away shows the acorns being taken: they fade out where they stood,
// so "three take away one" is three acorns with one gone.
//
// Fluency is speed, and speed is where a five-year-old is most easily made
// anxious, so there is no clock anywhere. Three puzzles to a round, straight
// after one another; three right in a row makes Buddy celebrate. The
// challenge drops the acorns and the dots and leaves just the numbers -
// which is what fluent means - but still waits for her.
//
// The ordinary game gets there by itself as she gets surer. At the pictorial
// layer the cards lose their dots and she counts the acorns; at the abstract
// layer the acorns go too. A miss, or the hint ladder's help, brings back one
// layer for that puzzle only - the acorns reappear over the numbers she is
// stuck on - and the next puzzle starts back where she is.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/fluency_words.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/concept_state.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_colors.dart';
import '../../ui/common/number_choice.dart';
import '../../ui/common/timer_scope.dart';
import '../../ui/round/sanctuary_round_shell.dart';
import '../activity_ids.dart';
import '../sub_mode_ids.dart';

class FluencyRunner extends ConsumerWidget {
  const FluencyRunner({
    super.key,
    required this.onSequenceComplete,
    this.subMode = FluencyWithin5Modes.casual,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final String subMode;
  final bool skipIntro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rounds = fluencyRoundsFor(
      subMode,
      seed: ref.watch(sessionIdProvider).hashCode,
    );
    return SanctuaryRoundShell(
      activityId: ActivityIds.fluencyWithin5,
      roundCount: rounds.length,
      conceptIdFor: (_) => 'K.OA.5',
      introLine: kFluencyIntro,
      keeperLineFor: fluencyKeeperLine,
      finalLine: kFluencyFinal,
      skipIntro: skipIntro,
      musicBed: subMode == FluencyWithin5Modes.speedRun
          ? kChallengeMusicBed
          : kDefaultMusicBed,
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.wheresBuddyBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) => FluencyRoundBody(
        facts: rounds[c.index],
        c: c,
        numeralsOnly: subMode == FluencyWithin5Modes.speedRun,
      ),
    );
  }
}

class FluencyRoundBody extends ConsumerStatefulWidget {
  const FluencyRoundBody({
    super.key,
    required this.facts,
    required this.c,
    this.numeralsOnly = false,
  });

  final List<FluencyFact> facts;
  final RoundContext c;
  final bool numeralsOnly;

  @override
  ConsumerState<FluencyRoundBody> createState() => _FluencyRoundBodyState();
}

class _FluencyRoundBodyState extends ConsumerState<FluencyRoundBody>
    with TimerScope<FluencyRoundBody> {
  HintLadder? _hints;
  int _i = 0;
  int _streak = 0;
  int _misses = 0;
  bool _busy = false;
  bool _done = false;
  int? _answered;
  int? _hinted;
  Map<int, int> _wrong = <int, int>{};

  /// The hint ladder has had to help with this puzzle.
  bool _helped = false;

  FluencyFact get _f => widget.facts[_i];
  bool get _open => !_busy && !_done && !widget.c.locked;

  /// How much support this puzzle is drawn with. The challenge is numbers
  /// only by definition and never steps down - its miss line is "say the
  /// numbers out loud", not "count the acorns", because there are none.
  CpaLayer get _drawAt => widget.numeralsOnly
      ? CpaLayer.abstract
      : supportLayer(
          widget.c.layer,
          misses: _wrong.isNotEmpty || _helped ? 1 : 0,
        );

  /// No acorns on screen, so the nudge is about the numbers.
  bool get _numbersOnlyNow => _drawAt == CpaLayer.abstract;

  late List<int> _choices = _choicesFor(0);

  List<int> _choicesFor(int i) => numberChoicesFor(
    widget.facts[i].answer,
    seed: widget.c.index * 7 + i,
    max: 5,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.c.say(fluencyQuestion(_f));
      _hints = HintLadder(onLevel: _onHint)..start();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  void _onPick(int n) {
    if (!_open) return;
    _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    if (n != _f.answer) {
      setState(() {
        _wrong = <int, int>{..._wrong, n: (_wrong[n] ?? 0) + 1};
        _misses += 1;
        _streak = 0;
        if ((_wrong.values.fold<int>(0, (a, b) => a + b)) >= 2) {
          _hinted = _f.answer;
        }
      });
      feedback.wrong();
      // Said after the miss has brought the acorns back, so "count the
      // acorns" points at something - except in the challenge, which has none.
      widget.c.say(
        fluencyMiss(_misses, numeralsOnly: _numbersOnlyNow),
        replay: false,
      );
      return;
    }
    feedback.correct();
    setState(() {
      _answered = n;
      _hinted = null;
      _streak += 1;
      _busy = true;
    });
    widget.c.say(fluencyRight(_f), replay: false);
    if (_streak == 3) {
      feedback.celebrate();
      widget.c.say(kFluencyStreak, replay: false, queue: true);
    }
    if (_i == widget.facts.length - 1) {
      _done = true;
      _hints?.pause();
      final helped = (_hints?.hintsUsed ?? 0) > 0;
      widget.c.finish(gradeRound(misses: _misses, helped: helped, failAt: 4));
      return;
    }
    after(const Duration(milliseconds: 1700), () {
      setState(() {
        _i += 1;
        _answered = null;
        _wrong = <int, int>{};
        _helped = false;
        _choices = _choicesFor(_i);
        _busy = false;
      });
      widget.c.say(fluencyQuestion(_f), queue: true);
      _hints?.start();
    });
  }

  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final feedback = ref.read(feedbackEngineProvider);
    switch (level) {
      case HintLevel.none:
      case HintLevel.highlight:
        return;
      case HintLevel.point:
        feedback.hint();
        // Help is a layer down, the same as a miss: at abstract this is the
        // moment the acorns come back, and the line tells her to use them.
        setState(() => _helped = true);
        widget.c.say(
          _numbersOnlyNow ? kFluencyNumbersHint : kFluencyCount,
          replay: false,
        );
      case HintLevel.demonstrate:
        feedback.hint();
        setState(() => _hinted = _f.answer);
        widget.c.say(warmHintLine(3), replay: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final acorn = (box.maxHeight * 0.13).clamp(44.0, 72.0);
        return Column(
          children: [
            const SizedBox(height: 8),
            // Which of the three puzzles this is - three little acorns that
            // fill in, so the end of the round is something she can see coming.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = 0; k < widget.facts.length; k++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Opacity(
                      opacity: k < _i || (k == _i && _answered != null)
                          ? 1
                          : 0.3,
                      child: Image.asset(
                        AssetPaths.carePantryAcorn,
                        width: 34,
                        height: 34,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _Puzzle(
                    key: ValueKey('puzzle-$_i'),
                    fact: _f,
                    acorn: acorn,
                    showAcorns: _drawAt != CpaLayer.abstract,
                  ),
                ),
              ),
            ),
            NumberChoiceRow(
              choices: _choices,
              cardWidth: 128,
              showDots: _drawAt == CpaLayer.concrete,
              answered: _answered,
              hinted: _hinted,
              wrongTokens: _wrong,
              locked: !_open,
              onPick: _onPick,
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

/// "2 + 1": each number with its acorns above it.
class _Puzzle extends StatelessWidget {
  const _Puzzle({
    super.key,
    required this.fact,
    required this.acorn,
    required this.showAcorns,
  });

  final FluencyFact fact;
  final double acorn;
  final bool showAcorns;

  @override
  Widget build(BuildContext context) {
    const numeral = TextStyle(
      fontSize: 84,
      fontWeight: FontWeight.w900,
      color: AppColors.cardInk,
      height: 1,
    );
    Widget group(int n, {int takenAway = 0}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showAcorns)
          SizedBox(
            key: const ValueKey('fluency-acorns'),
            height: acorn * 1.1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var k = 0; k < n; k++)
                  Opacity(
                    opacity: k >= n - takenAway ? 0.22 : 1,
                    child: Image.asset(
                      AssetPaths.carePantryAcorn,
                      width: acorn,
                      height: acorn,
                    ),
                  ),
              ],
            ),
          ),
        Text('$n', style: numeral),
      ],
    );
    final Widget body;
    if (fact.plus) {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          group(fact.a),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Text('+', style: numeral),
          ),
          group(fact.b),
        ],
      );
    } else {
      // Taking away: all of them drawn, the ones taken faded where they
      // stood - so the picture is still "three" with one gone, not "two".
      body = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          group(fact.a, takenAway: fact.b),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Text('−', style: numeral),
          ),
          Text('${fact.b}', style: numeral),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(36, 20, 36, 20),
      decoration: BoxDecoration(
        color: const Color(0xEEFFFBF0),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardRim, width: 4),
      ),
      child: FittedBox(child: body),
    );
  }
}
