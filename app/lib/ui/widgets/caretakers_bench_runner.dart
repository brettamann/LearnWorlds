// Caretaker's Bench - K.MD.1 (describe attributes) and K.MD.2 (compare two).
//
// Two tools on a workbench, both drawn in code so that they cannot lie:
//
// - **A balance scale** whose beam tips by the difference in what is on its
//   pans. She puts the pumpkin and the apple on the scale herself - a tap
//   sends each to its pan - and watches the heavy side go down, and only then
//   is asked which is heavier. The tipping is the evidence; the question is
//   whether she can read it.
// - **Caterpillars** made of round segments, lined up against the same start
//   line. Their lengths are exactly what the round says, and a child who
//   wants to can count the segments - that is measuring, which is where K.MD
//   is headed.
//
// The spec's `describe-attributes` has her drag attribute *words* onto an
// object. She cannot read them. So describing is done the way a
// five-year-old describes: "Which one is heavy?" with two things in front of
// her, and the narrator names both attributes once she has chosen - "The
// pumpkin is heavy. The feather is light." The words are learned by hearing
// them next to the thing.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activities/activity_ids.dart';
import '../../data/asset_paths.dart';
import '../../data/caretakers_bench_words.dart';
import '../../data/round_pick.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_colors.dart';
import '../common/timer_scope.dart';
import 'answer_feedback.dart';
import 'glitter_burst.dart';
import 'sanctuary_round_shell.dart';
import 'touch_here_halo.dart';

class CaretakersBenchRunner extends ConsumerWidget {
  const CaretakersBenchRunner({
    super.key,
    required this.onSequenceComplete,
    this.subMode = kBenchSubDescribe,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final String subMode;
  final bool skipIntro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rounds = benchRoundsFor(
      subMode,
      seed: roundSeed(ref.watch(sessionIdProvider), subMode),
    );
    return SanctuaryRoundShell(
      activityId: ActivityIds.caretakersBench,
      roundCount: rounds.length,
      conceptIdFor: (i) => subMode == kBenchSubDescribe ? 'K.MD.1' : 'K.MD.2',
      introLine: kBenchIntro,
      keeperLineFor: benchKeeperLine,
      finalLine: kBenchFinal,
      skipIntro: skipIntro,
      musicBed:
          subMode == kBenchSubOrder ? kChallengeMusicBed : kDefaultMusicBed,
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.caretakersBenchBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) =>
          BenchRoundBody(round: rounds[c.index], c: c),
    );
  }
}

class BenchRoundBody extends ConsumerStatefulWidget {
  const BenchRoundBody({super.key, required this.round, required this.c});

  final BenchRound round;
  final RoundContext c;

  @override
  ConsumerState<BenchRoundBody> createState() => _BenchRoundBodyState();
}

class _BenchRoundBodyState extends ConsumerState<BenchRoundBody>
    with TimerScope<BenchRoundBody> {
  HintLadder? _hints;
  bool _done = false;
  bool _busy = false;
  int _misses = 0;

  /// Weighing: which things are on their pan.
  final Set<int> _onPan = <int>{};
  bool _asked = false;

  /// The second thing has landed and the beam may tip. Separate from "both on
  /// the pans" so that the second one glides to its pan like the first did,
  /// and then the scale moves.
  bool _tipped = false;

  /// Ordering: the caterpillars tapped so far, in order.
  final List<int> _ordered = <int>[];

  int? _ringed;
  int? _chosen;
  final Map<int, int> _wrong = <int, int>{};

  BenchRound get _r => widget.round;
  bool get _open => !_done && !_busy && !widget.c.locked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.c.say(benchPrompt(_r));
      _hints = HintLadder(onLevel: _onHint)..start();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  /// The next caterpillar in shortest-to-longest order that is not yet tapped.
  int _nextInOrder() {
    final left = <int>[
      for (var i = 0; i < _r.cats.length; i++)
        if (!_ordered.contains(i)) i,
    ]..sort((a, b) => _r.cats[a].segments.compareTo(_r.cats[b].segments));
    return left.first;
  }

  void _onTap(int i, {bool fromHint = false}) {
    if (!_open) return;
    if (!fromHint) _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    setState(() => _ringed = null);

    if (_r.usesScale && !_asked) {
      if (_onPan.contains(i)) {
        feedback.sparkle();
        return;
      }
      setState(() => _onPan.add(i));
      feedback.drop();
      if (_onPan.length < 2) return;
      // Both on: let the beam swing and settle before asking her to read it.
      setState(() => _busy = true);
      after(const Duration(milliseconds: 520), () {
        setState(() => _tipped = true);
      });
      after(const Duration(milliseconds: 1800), () {
        setState(() {
          _busy = false;
          _asked = true;
        });
        widget.c.say(benchWeighQuestion(_r));
        _hints?.start();
      });
      return;
    }

    if (_r.task == BenchTask.orderThree) {
      if (_ordered.contains(i)) return;
      if (i != _nextInOrder()) {
        _miss(i);
        return;
      }
      setState(() => _ordered.add(i));
      feedback.countStep(_ordered.length);
      widget.c.say(
        kBenchOrderLines[_ordered.length - 1],
        replay: false,
        queue: fromHint,
      );
      if (_ordered.length == _r.cats.length) {
        widget.c.say(benchDone(_r), replay: false, queue: true);
        _finish();
      }
      return;
    }

    if (i != _r.answer) {
      _miss(i);
      return;
    }
    setState(() => _chosen = i);
    feedback.correct();
    widget.c.say(benchDone(_r), replay: false);
    _finish();
  }

  void _miss(int i) {
    setState(() {
      _wrong[i] = (_wrong[i] ?? 0) + 1;
      _misses += 1;
    });
    ref.read(feedbackEngineProvider).wrong();
    widget.c.say(benchMiss(_r, _misses), replay: false);
  }

  void _finish() {
    _done = true;
    _hints?.pause();
    final helped = (_hints?.hintsUsed ?? 0) > 0;
    widget.c.finish(
      gradeRound(misses: _misses, helped: helped),
    );
  }

  void _onHint(HintLevel level) {
    if (!mounted || !_open || level == HintLevel.none) return;
    final feedback = ref.read(feedbackEngineProvider);
    // Loading the scale is just getting things into place, so the top rung
    // does that for her. Every other rung only ever points: the choosing is
    // the lesson.
    if (_r.usesScale && !_asked) {
      final next = _onPan.contains(0) ? 1 : 0;
      if (level == HintLevel.demonstrate) {
        feedback.hint();
        widget.c.say(warmHintLine(3), replay: false);
        _onTap(next, fromHint: true);
      } else {
        setState(() => _ringed = next);
        if (level == HintLevel.point) {
          feedback.hint();
          widget.c.say(benchPrompt(_r), replay: false);
        }
      }
      return;
    }
    final target = _r.task == BenchTask.orderThree ? _nextInOrder() : _r.answer;
    switch (level) {
      case HintLevel.none:
      case HintLevel.highlight:
        return;
      case HintLevel.point:
        feedback.hint();
        widget.c.say(benchLookHint(_r), replay: false);
      case HintLevel.demonstrate:
        feedback.hint();
        setState(() => _ringed = target);
        widget.c.say(warmHintLine(3), replay: false);
    }
  }

  // ---- drawing --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (_r.usesScale) return _scaleLayout(box.biggest);
        if (_r.usesThings) return _pairLayout(box.biggest);
        return _caterpillarLayout(box.biggest);
      },
    );
  }

  Widget _tappable(int i, Size size, Widget child, {Key? key}) {
    return GestureDetector(
      key: key ?? ValueKey('bench-choice-$i'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(i),
      child: AnswerFeedback(
        wrongToken: _wrong[i] ?? 0,
        child: SizedBox.fromSize(
          size: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: child),
              if (_ringed == i) TouchHereRingOutside(around: size),
              if (_chosen == i || _ordered.contains(i))
                Positioned.fill(
                  child: IgnorePointer(
                    child: GlitterBurst(
                      key: ValueKey('bench-burst-$i-${_ordered.indexOf(i)}'),
                      maxRadius: size.shortestSide,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Which one is heavy?" - two things side by side, big.
  Widget _pairLayout(Size s) {
    final side = math.min(200.0, s.height * 0.42);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) SizedBox(width: side * 0.6),
            _tappable(
              i,
              Size.square(side),
              Image.asset(_r.things[i].asset, fit: BoxFit.contain),
            ),
          ],
        ],
      ),
    );
  }

  Widget _caterpillarLayout(Size s) {
    final n = _r.cats.length;
    // Floors on everything: a first layout pass can be tiny, and a negative
    // size is an assertion rather than a small caterpillar.
    final rowH = math.max(40.0, math.min(118.0, (s.height - 40) / n));
    final maxSeg = _r.cats.map((c) => c.segments).reduce(math.max);
    const lineX = kBuddyCornerReserve + 20;
    final room = math.max(0.0, s.width - lineX - 60);
    final seg = math.max(
      12.0,
      math.min(rowH * 0.62, room / (maxSeg * 0.82 + 1.4)),
    );
    final top = (s.height - rowH * n) / 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The start line: every caterpillar's tail touches it, which is what
        // makes comparing their other ends a fair question.
        Positioned(
          left: lineX - 3,
          top: top - 10,
          width: 6,
          height: rowH * n + 20,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.wood,
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
        ),
        for (var i = 0; i < n; i++)
          Positioned(
            left: lineX,
            top: top + i * rowH,
            child: _tappable(
              i,
              Size(caterpillarWidth(_r.cats[i].segments, seg), rowH),
              Align(
                alignment: Alignment.centerLeft,
                child: Caterpillar(
                  segments: _r.cats[i].segments,
                  colour: Color(_r.cats[i].argb),
                  segment: seg,
                  medal: _ordered.contains(i) ? _ordered.indexOf(i) + 1 : null,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _scaleLayout(Size s) {
    final a = _r.things[0];
    final b = _r.things[1];
    final loaded = _tipped;
    // Right heavier tips the right pan down, which in screen space is a
    // clockwise turn. Capped, so a watermelon does not flip the beam over.
    final tilt = loaded
        ? ((b.weight - a.weight) * 0.06).clamp(-0.26, 0.26).toDouble()
        : 0.0;
    final standH = math.min(s.height * 0.72, 380.0);
    final beam = math.min(s.width * 0.56, standH * 1.35);
    final pivot = Offset(s.width / 2, s.height - standH * 0.95);
    final thing = math.min(118.0, standH * 0.32);
    final panDrop = standH * 0.3;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: tilt),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.elasticOut,
      builder: (context, angle, _) {
        Offset panAt(int side) {
          final dx = (side == 0 ? -1 : 1) * beam / 2;
          final end =
              pivot + Offset(dx * math.cos(angle), dx * math.sin(angle));
          return end + Offset(0, panDrop);
        }

        Offset thingAt(int i) {
          if (_onPan.contains(i)) {
            return panAt(i) - Offset(0, thing * 0.42);
          }
          // Waiting on the bench, well out to either side of the scale.
          final x = i == 0
              ? math.max(
                  kBuddyCornerReserve + thing / 2,
                  pivot.dx - beam / 2 - thing * 1.3,
                )
              : math.min(
                  s.width - thing / 2 - 8,
                  pivot.dx + beam / 2 + thing * 1.3,
                );
          return Offset(x, s.height - thing / 2 - 20);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Drawn in a square box aligned to its top, so that the knob at the
            // top of the post is at a known place - about 7% of the way down
            // the image - and the beam's pivot can sit exactly on it. In a
            // taller box BoxFit.contain letterboxed the image and the beam
            // floated a hand's width above the post it was meant to rest on.
            Positioned(
              left: pivot.dx - standH / 2,
              top: pivot.dy - standH * 0.07,
              width: standH,
              height: standH,
              child: Image.asset(
                AssetPaths.caretakersScaleStand,
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BeamPainter(
                    pivot: pivot,
                    half: beam / 2,
                    angle: angle,
                    drop: panDrop,
                    pan: thing * 1.1,
                  ),
                ),
              ),
            ),
            for (var i = 0; i < 2; i++)
              AnimatedPositioned(
                key: ValueKey('bench-thing-$i'),
                duration: _onPan.contains(i) && loaded
                    ? Duration.zero
                    : const Duration(milliseconds: 480),
                curve: Curves.easeOutBack,
                left: thingAt(i).dx - thing / 2,
                top: thingAt(i).dy - thing / 2,
                child: _tappable(
                  i,
                  Size.square(thing),
                  Image.asset(_r.things[i].asset, fit: BoxFit.contain),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BeamPainter extends CustomPainter {
  const _BeamPainter({
    required this.pivot,
    required this.half,
    required this.angle,
    required this.drop,
    required this.pan,
  });

  final Offset pivot;
  final double half;
  final double angle;
  final double drop;
  final double pan;

  @override
  void paint(Canvas canvas, Size size) {
    const brass = Color(0xFFD9A441);
    const dark = Color(0xFF6B4A1A);
    final u = Offset(math.cos(angle), math.sin(angle));
    final l = pivot - u * half;
    final r = pivot + u * half;
    final beam = Paint()
      ..color = brass
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final edge = Paint()
      ..color = dark
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(l, r, edge)
      ..drawLine(l, r, beam)
      ..drawCircle(pivot, 12, Paint()..color = dark)
      ..drawCircle(pivot, 8, Paint()..color = brass);
    for (final end in <Offset>[l, r]) {
      final panTop = end + Offset(0, drop);
      final string = Paint()
        ..color = dark
        ..strokeWidth = 3;
      canvas
        ..drawLine(end, panTop - Offset(pan * 0.45, 0), string)
        ..drawLine(end, panTop + Offset(pan * 0.45, 0), string);
      final bowl = Path()
        ..moveTo(panTop.dx - pan / 2, panTop.dy)
        ..quadraticBezierTo(
          panTop.dx,
          panTop.dy + pan * 0.55,
          panTop.dx + pan / 2,
          panTop.dy,
        )
        ..close();
      canvas
        ..drawPath(bowl, Paint()..color = brass)
        ..drawPath(
          bowl,
          Paint()
            ..color = dark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
    }
  }

  @override
  bool shouldRepaint(_BeamPainter old) =>
      old.angle != angle || old.pivot != pivot || old.half != half;
}

/// How wide a caterpillar of [segments] is when each segment is [segment]
/// across.
double caterpillarWidth(int segments, double segment) =>
    segment * (segments * 0.82 + 1.4);

/// A caterpillar drawn from round segments with a smiling head at the right.
class Caterpillar extends StatelessWidget {
  const Caterpillar({
    super.key,
    required this.segments,
    required this.colour,
    required this.segment,
    this.medal,
  });

  final int segments;
  final Color colour;
  final double segment;

  /// Its place once ordered: 1 shortest.
  final int? medal;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(caterpillarWidth(segments, segment), segment * 1.5),
      painter: _CaterpillarPainter(
        segments: segments,
        colour: colour,
        segment: segment,
        medal: medal,
      ),
    );
  }
}

class _CaterpillarPainter extends CustomPainter {
  const _CaterpillarPainter({
    required this.segments,
    required this.colour,
    required this.segment,
    required this.medal,
  });

  final int segments;
  final Color colour;
  final double segment;
  final int? medal;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * 0.58;
    final r = segment / 2;
    final outline = Paint()
      ..color = const Color(0xFF2B2B2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final light = Color.lerp(colour, Colors.white, 0.35)!;
    for (var i = 0; i < segments; i++) {
      final c = Offset(r + i * segment * 0.82, cy + (i.isEven ? 0 : -r * 0.12));
      canvas
        ..drawCircle(c, r, Paint()..color = i.isEven ? colour : light)
        ..drawCircle(c, r, outline);
      // Little feet.
      canvas.drawLine(
        c + Offset(-r * 0.3, r * 0.9),
        c + Offset(-r * 0.3, r * 1.15),
        outline,
      );
    }
    final hr = r * 1.18;
    final head = Offset(r + segments * segment * 0.82 + hr * 0.1, cy - r * 0.2);
    canvas
      ..drawCircle(head, hr, Paint()..color = colour)
      ..drawCircle(head, hr, outline);
    // Antennae.
    for (final dx in <double>[-0.35, 0.35]) {
      final base = head + Offset(dx * hr, -hr * 0.85);
      final tip = base + Offset(dx * hr * 0.6, -hr * 0.6);
      canvas
        ..drawLine(base, tip, outline)
        ..drawCircle(tip, hr * 0.13, Paint()..color = const Color(0xFF2B2B2B));
    }
    // Face: two eyes and a smile.
    final eye = Paint()..color = const Color(0xFF2B2B2B);
    canvas
      ..drawCircle(head + Offset(-hr * 0.3, -hr * 0.15), hr * 0.13, eye)
      ..drawCircle(head + Offset(hr * 0.3, -hr * 0.15), hr * 0.13, eye)
      ..drawArc(
        Rect.fromCenter(
          center: head + Offset(0, hr * 0.12),
          width: hr * 0.8,
          height: hr * 0.6,
        ),
        0.3,
        math.pi - 0.6,
        false,
        outline,
      );
    if (medal != null) {
      final m = Offset(head.dx + hr * 1.3, cy - r * 0.2);
      canvas
        ..drawCircle(m, r * 0.6, Paint()..color = AppColors.coinGold)
        ..drawCircle(m, r * 0.6, outline);
      // Dots for its place - one, two, three - rather than a numeral.
      for (var k = 0; k < medal!; k++) {
        canvas.drawCircle(
          m + Offset((k - (medal! - 1) / 2) * r * 0.32, 0),
          r * 0.1,
          eye,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CaterpillarPainter old) =>
      old.segments != segments || old.medal != medal || old.segment != segment;
}
