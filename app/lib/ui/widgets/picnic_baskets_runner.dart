// Picnic Baskets - K.CC.6 (compare two groups) and K.CC.7 (compare numerals).
//
// A unicorn and a dragon at a picnic, each with a row of treats on plates in
// front of them. Two strategies, and the round tells her which to use:
//
// - **Matching.** A tap on a treat gives it a partner in the other row, joined
//   by a ribbon. When one row runs out, whatever is left over is the
//   difference, and the answer is whoever has leftovers - no counting needed,
//   which is exactly why matching comes first. A treat with no partner left
//   says so ("It is left over!") rather than doing nothing.
// - **Counting.** A tap counts a treat; the count builds up as dots under the
//   diner. Then who has more.
//
// Every two-diner round offers "the same" as an answer - a card with both of
// their faces - because a tie is a real outcome and a child who has only ever
// seen one side win will not think of it.
//
// Numeral rounds (K.CC.7) are "which number is bigger?" rather than the spec's
// `<` `>` `=` tiles: those symbols are first-grade (1.NBT.3), and the
// kindergarten standard is the comparison itself. A wrong pick shows the dots
// under both numbers, so the miss turns into something she can see.
//
// The treats sit on white plates. The blanket is red gingham; red cherries on
// it disappear.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/number_words.dart';
import '../../data/picnic_baskets_words.dart';
import '../../data/round_pick.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../providers/session_provider.dart';
import '../common/timer_scope.dart';
import 'answer_feedback.dart';
import 'glitter_burst.dart';
import 'number_choice.dart';
import 'sanctuary_round_shell.dart';
import 'touch_here_halo.dart';

class PicnicBasketsRunner extends ConsumerWidget {
  const PicnicBasketsRunner({
    super.key,
    required this.onSequenceComplete,
    this.subMode = kPicnicSubMatch,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final String subMode;
  final bool skipIntro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rounds = picnicRoundsFor(
      subMode,
      seed: roundSeed(ref.watch(sessionIdProvider), subMode),
    );
    return SanctuaryRoundShell(
      activityId: 'picnic-baskets',
      roundCount: rounds.length,
      conceptIdFor: (_) => subMode == kPicnicSubNumerals ? 'K.CC.7' : 'K.CC.6',
      introLine: kPicnicIntro,
      keeperLineFor: picnicKeeperLine,
      finalLine: kPicnicFinal,
      skipIntro: skipIntro,
      musicBed:
          subMode == kPicnicSubThree ? kChallengeMusicBed : 'sanctuary-picnic',
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(AssetPaths.picnicBackground, fit: BoxFit.cover),
      roundBuilder: (context, c) =>
          PicnicRoundBody(round: rounds[c.index], c: c),
    );
  }
}

/// One treat: row is the diner, index its place on their plate row.
typedef _Treat = (int row, int index);

enum _Step { act, ask, askFewest, done }

class PicnicRoundBody extends ConsumerStatefulWidget {
  const PicnicRoundBody({super.key, required this.round, required this.c});

  final PicnicRound round;
  final RoundContext c;

  @override
  ConsumerState<PicnicRoundBody> createState() => _PicnicRoundBodyState();
}

class _PicnicRoundBodyState extends ConsumerState<PicnicRoundBody>
    with TimerScope<PicnicRoundBody> {
  HintLadder? _hints;
  _Step _step = _Step.act;
  bool _busy = false;
  int _misses = 0;

  /// Matching: the pairs made, top-row index to bottom-row index.
  final List<(int, int)> _pairs = <(int, int)>[];
  final Set<_Treat> _leftover = <_Treat>{};

  /// Counting: which treats have been counted.
  final Set<_Treat> _counted = <_Treat>{};

  final Map<Object, int> _wrong = <Object, int>{};
  Object? _ringed;
  int? _chosenDiner;
  bool _chosenSame = false;
  bool _revealDots = false;

  PicnicRound get _r => widget.round;
  bool get _open => !_busy && !widget.c.locked && _step != _Step.done;
  int get _rows => _r.counts.length;
  bool get _asking => _step == _Step.ask || _step == _Step.askFewest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.c.say(picnicPrompt(_r));
      if (_r.task == PicnicTask.numerals) setState(() => _step = _Step.ask);
      _hints = HintLadder(onLevel: _onHint)..start();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  bool _paired(_Treat t) => t.$1 == 0
      ? _pairs.any((p) => p.$1 == t.$2)
      : _pairs.any((p) => p.$2 == t.$2);

  int? _firstFree(int row) {
    for (var i = 0; i < _r.counts[row]; i++) {
      if (!_paired((row, i)) && !_leftover.contains((row, i))) return i;
    }
    return null;
  }

  // ---- acting -----------------------------------------------------------

  void _onTreat(_Treat t, {bool fromHint = false}) {
    if (!_open) return;
    if (_step != _Step.act) {
      ref.read(feedbackEngineProvider).sparkle();
      return;
    }
    if (!fromHint) _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    setState(() => _ringed = null);
    if (_r.task == PicnicTask.match) {
      if (_paired(t) || _leftover.contains(t)) {
        setState(() => _wrong[t] = (_wrong[t] ?? 0) + 1);
        feedback.sparkle();
        return;
      }
      // Pairing stops the moment one row runs out, so there is always a
      // partner here; the leftovers are shown and named when the question
      // arrives instead.
      final partner = _firstFree(1 - t.$1)!;
      setState(() {
        _pairs.add(t.$1 == 0 ? (t.$2, partner) : (partner, t.$2));
      });
      feedback.countStep(_pairs.length);
      final minCount = math.min(_r.counts[0], _r.counts[1]);
      if (_pairs.length >= minCount) _ask();
      return;
    }
    // Counting.
    if (_counted.contains(t)) {
      setState(() => _wrong[t] = (_wrong[t] ?? 0) + 1);
      feedback.sparkle();
      return;
    }
    setState(() => _counted.add(t));
    final inRow = _counted.where((x) => x.$1 == t.$1).length;
    feedback.countStep(inRow);
    widget.c.say('${spellCount(inRow)}.', replay: false, queue: fromHint);
    final total = _r.counts.fold<int>(0, (a, b) => a + b);
    if (_counted.length >= total) _ask();
  }

  void _ask() {
    if (_step != _Step.act) return;
    setState(() => _busy = true);
    // A beat to see the leftovers before the question lands on top of them.
    after(const Duration(milliseconds: 900), () {
      setState(() {
        _busy = false;
        _step = _Step.ask;
      });
      if (_r.task == PicnicTask.match && !_r.same) {
        widget.c.say(kPicnicLeftOver, replay: false, queue: true);
      }
      widget.c.say(picnicAsk(_r), queue: true);
      _hints?.start();
    });
  }

  // ---- answering --------------------------------------------------------

  void _onDiner(int i) {
    if (!_open) return;
    if (!_asking) {
      // A tap on the unicorn before there is a question is still a tap on
      // the unicorn.
      ref.read(feedbackEngineProvider).sparkle();
      return;
    }
    _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    final fewest = _step == _Step.askFewest;
    final right = _r.task == PicnicTask.numerals
        ? (_r.counts[0] > _r.counts[1] ? 0 : 1)
        : (fewest ? _r.fewest : _r.most);
    if (i != right) return _miss(i);
    feedback.correct();
    setState(() {
      _chosenDiner = i;
      _ringed = null;
    });
    if (_r.task == PicnicTask.three && !fewest) {
      widget.c.say(picnicDoneMost(_r), replay: false);
      setState(() => _busy = true);
      after(const Duration(milliseconds: 1500), () {
        setState(() {
          _busy = false;
          _chosenDiner = null;
          _step = _Step.askFewest;
        });
        widget.c.say(kPicnicAskFewest, queue: true);
        _hints?.start();
      });
      return;
    }
    widget.c.say(
      _r.task == PicnicTask.three ? picnicDoneFewest(_r) : picnicDone(_r),
      replay: false,
    );
    _finish();
  }

  void _onSame() {
    if (!_open || !_asking) return;
    _hints?.poke();
    if (!_r.same) return _miss('same');
    ref.read(feedbackEngineProvider).correct();
    setState(() => _chosenSame = true);
    widget.c.say(picnicDone(_r), replay: false);
    _finish();
  }

  void _miss(Object key) {
    setState(() {
      _wrong[key] = (_wrong[key] ?? 0) + 1;
      _misses += 1;
      _revealDots = true;
    });
    ref.read(feedbackEngineProvider).wrong();
    widget.c.say(picnicMiss(_r, _misses), replay: false);
  }

  void _finish() {
    _step = _Step.done;
    _hints?.pause();
    final helped = (_hints?.hintsUsed ?? 0) > 0;
    widget.c.finish(
      gradeRound(misses: _misses, helped: helped),
    );
  }

  // ---- help ---------------------------------------------------------------

  Object? _answerKey() {
    if (_r.task == PicnicTask.numerals) {
      return _r.counts[0] > _r.counts[1] ? 0 : 1;
    }
    if (_step == _Step.askFewest) return _r.fewest;
    return _r.same ? 'same' : _r.most;
  }

  _Treat? _nextTreat() {
    if (_r.task == PicnicTask.match) {
      final top = _firstFree(0);
      if (top != null && _firstFree(1) != null) return (0, top);
      return null;
    }
    for (var row = 0; row < _rows; row++) {
      for (var i = 0; i < _r.counts[row]; i++) {
        if (!_counted.contains((row, i))) return (row, i);
      }
    }
    return null;
  }

  void _onHint(HintLevel level) {
    if (!mounted || !_open || level == HintLevel.none) return;
    final feedback = ref.read(feedbackEngineProvider);
    if (_asking) {
      if (level == HintLevel.highlight) return;
      feedback.hint();
      if (level == HintLevel.point) {
        // "Look at the dots" needs dots to look at.
        if (_r.task == PicnicTask.numerals) setState(() => _revealDots = true);
        widget.c.say(picnicLookHint(_r), replay: false);
      } else {
        setState(() => _ringed = _answerKey());
        widget.c.say(warmHintLine(3), replay: false);
      }
      return;
    }
    final t = _nextTreat();
    if (t == null) return;
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _ringed = t);
      case HintLevel.point:
        setState(() => _ringed = t);
        feedback.hint();
        widget.c.say(warmHintLine(2), replay: false);
      case HintLevel.demonstrate:
        feedback.hint();
        widget.c.say(warmHintLine(3), replay: false);
        _onTreat(t, fromHint: true);
    }
  }

  // ---- drawing ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final geo = _PicnicGeometry(box.biggest, _r);
        final showSame =
            _asking && _rows == 2 && _r.task != PicnicTask.numerals;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (_r.task == PicnicTask.match)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RibbonPainter(
                      <(Offset, Offset)>[
                        for (final p in _pairs)
                          (
                            geo.treatCenter(0, p.$1),
                            geo.treatCenter(1, p.$2),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            for (var row = 0; row < _rows; row++) ...[
              _diner(geo, row),
              // The number is what she will tap - "which number is bigger?"
              // - so it is a target of its own. It used to be drawn inside
              // the diner and outside its box, where it painted but could not
              // be hit: tapping the 7 did nothing, and only the unicorn
              // beside it answered.
              if (_r.task == PicnicTask.numerals)
                Positioned(
                  left: geo.dinerRect(row).right + 8,
                  top: geo.dinerRect(row).center.dy - geo.card * 0.5,
                  child: AnswerFeedback(
                    wrongToken: _wrong[row] ?? 0,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        NumberCard(
                          key: ValueKey('number-card-${_r.counts[row]}'),
                          value: _r.counts[row],
                          width: geo.card,
                          showDots: _revealDots,
                          glowing: _chosenDiner == row,
                          onTap: () => _onDiner(row),
                        ),
                        if (_ringed == row)
                          TouchHereRingOutside(
                            around: Size(geo.card, geo.card * 1.15),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_r.task != PicnicTask.numerals)
                for (var i = 0; i < _r.counts[row]; i++) _treat(geo, row, i),
            ],
            if (showSame)
              Positioned(
                right: 4,
                top: geo.size.height / 2 - 70,
                child: _SameCard(
                  onTap: _onSame,
                  wrongToken: _wrong['same'] ?? 0,
                  ringed: _ringed == 'same',
                  chosen: _chosenSame,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _diner(_PicnicGeometry geo, int row) {
    final d = _r.diners[row];
    final rect = geo.dinerRect(row);
    final counted = _counted.where((t) => t.$1 == row).length;
    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        key: ValueKey('picnic-diner-$row'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _onDiner(row),
        child: AnswerFeedback(
          wrongToken: _wrong[row] ?? 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: Image.asset(d.asset, fit: BoxFit.contain)),
              if (_r.task == PicnicTask.count || _r.task == PicnicTask.three)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -geo.plate * 0.28,
                  child: Center(
                    child: DotFrame(count: counted, cell: geo.plate * 0.24),
                  ),
                ),
              if (_ringed == row) TouchHereRingOutside(around: rect.size),
              if (_chosenDiner == row)
                Positioned.fill(
                  child: IgnorePointer(
                    child: GlitterBurst(
                      key: ValueKey('diner-burst-$row-$_step'),
                      maxRadius: rect.width,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _treat(_PicnicGeometry geo, int row, int i) {
    final t = (row, i);
    final c = geo.treatCenter(row, i);
    final p = geo.plate;
    final done = _paired(t) || _counted.contains(t);
    final left = _leftover.contains(t) ||
        (_asking && _r.task == PicnicTask.match && !_paired(t));
    return Positioned(
      left: c.dx - p / 2,
      top: c.dy - p / 2,
      width: p,
      height: p,
      child: GestureDetector(
        key: ValueKey('picnic-treat-$row-$i'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTreat(t),
        child: AnswerFeedback(
          wrongToken: _wrong[t] ?? 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: left
                          ? const Color(0xFFFFB300)
                          : (done
                              ? const Color(0xFF7CC242)
                              : const Color(0xFFD8C6A0)),
                      width: left || done ? 5 : 2,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 6),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(p * 0.14),
                  child: Image.asset(_r.treat.asset, fit: BoxFit.contain),
                ),
              ),
              if (_ringed == t) TouchHereRingOutside(around: Size.square(p)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PicnicGeometry {
  _PicnicGeometry(this.size, this.round) {
    final rows = round.counts.length;
    rowH = (size.height - 20) / rows;
    diner = math.min(150, rowH * 0.8);
    card = math.min(150, rowH * 0.62);
    final maxCount = round.counts.reduce(math.max);
    x0 = kBuddyCornerReserve + diner + 24;
    final room = size.width - x0 - 170;
    plate = math.max(
      62,
      math.min(math.min(98, rowH * 0.62), room / (maxCount * 1.12)),
    );
  }

  final Size size;
  final PicnicRound round;
  late final double rowH;
  late final double diner;
  late final double card;
  late final double x0;
  late final double plate;

  double rowY(int row) => 10 + rowH * (row + 0.5);

  Rect dinerRect(int row) {
    if (round.task == PicnicTask.numerals) {
      // Side by side for the numeral rounds, each holding up a card.
      final cx = size.width * (row == 0 ? 0.3 : 0.62);
      return Rect.fromCenter(
        center: Offset(cx - card * 0.5, size.height * 0.5),
        width: diner,
        height: diner,
      );
    }
    return Rect.fromCenter(
      center: Offset(kBuddyCornerReserve + diner / 2, rowY(row)),
      width: diner,
      height: diner,
    );
  }

  Offset treatCenter(int row, int i) =>
      Offset(x0 + plate * 0.5 + i * plate * 1.12, rowY(row));
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter(this.links);
  final List<(Offset, Offset)> links;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = const Color(0x66FFD54F)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final ribbon = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in links) {
      canvas
        ..drawLine(a, b, glow)
        ..drawLine(a, b, ribbon);
    }
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.links.length != links.length;
}

/// "They have the same" - both faces, with an equals sign between them.
class _SameCard extends StatelessWidget {
  const _SameCard({
    required this.onTap,
    required this.wrongToken,
    required this.ringed,
    required this.chosen,
  });

  final VoidCallback onTap;
  final int wrongToken;
  final bool ringed;
  final bool chosen;

  @override
  Widget build(BuildContext context) {
    const size = Size(150, 140);
    return GestureDetector(
      key: const ValueKey('picnic-same'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnswerFeedback(
        wrongToken: wrongToken,
        child: SizedBox.fromSize(
          size: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: chosen ? const Color(0xFFFFF4C9) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: chosen
                          ? const Color(0xFFFFB300)
                          : const Color(0xFFD8C6A0),
                      width: chosen ? 5 : 3,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        kPicnicUnicorn.asset,
                        width: 48,
                        height: 48,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '=',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4A3220),
                          ),
                        ),
                      ),
                      Image.asset(
                        kPicnicDragon.asset,
                        width: 48,
                        height: 48,
                      ),
                    ],
                  ),
                ),
              ),
              if (ringed) const TouchHereRingOutside(around: size),
            ],
          ),
        ),
      ),
    );
  }
}
